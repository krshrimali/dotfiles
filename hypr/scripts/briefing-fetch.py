#!/usr/bin/env python3
"""
Daily briefing fetcher — deterministic, stdlib-only.

Pulls from structured sources so it is reliable (no scraping, no AI required):
  - Hacker News  (top stories via the public Firebase API)
  - arXiv        (recent cs.LG / cs.CL / cs.AI, keyword-ranked)
  - GitHub       (latest releases of a watchlist — your "radar")

Writes a readable markdown digest to:
  ~/.local/share/briefings/today.md   (symlink-ish: always the latest)
  ~/.local/share/briefings/YYYY-MM-DD.md   (archive)

This is the *local desktop* layer (feeds Super+N + notify-send). The richer,
AI-summarised version arrives by email from the cloud /schedule routine.

Tune the CONFIG block below to taste — it's meant to be edited.
"""

from __future__ import annotations
import json
import os
import sys
import urllib.request
import urllib.parse
import xml.etree.ElementTree as ET
from datetime import datetime, timezone, timedelta
from pathlib import Path

# ─────────────────────────── CONFIG (edit me) ───────────────────────────────
HN_COUNT = 8           # how many Hacker News stories to show
HN_MIN_SCORE = 50      # ignore HN stories below this score

ARXIV_CATS = ["cs.LG", "cs.CL", "cs.AI"]   # arXiv categories to scan
ARXIV_SHOW = 8                              # papers to show
# Papers whose title/abstract match these rank to the top (case-insensitive).
KEYWORDS = [
    "llm", "large language model", "transformer", "agent", "reasoning",
    "diffusion", "reinforcement learning", "rlhf", "fine-tun", "quantiz",
    "inference", "retrieval", "rag", "distillation", "pytorch", "attention",
]

# GitHub "radar" — tools you care about. Shows the latest release of each.
GH_WATCH = [
    "pytorch/pytorch",
    "ggml-org/llama.cpp",
    "hyprwm/Hyprland",
    "ollama/ollama",
    "anthropics/claude-code",
]
GH_FRESH_DAYS = 21     # flag releases newer than this many days as 🆕

TIMEOUT = 12           # per-request seconds
OUT_DIR = Path.home() / ".local/share/briefings"
UA = "briefing-fetch/1.0 (+personal hyprland digest)"
# ─────────────────────────────────────────────────────────────────────────────


def get(url: str, *, as_json: bool = True):
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=TIMEOUT) as r:
        data = r.read()
    return json.loads(data) if as_json else data.decode("utf-8", "replace")


def warn(msg: str) -> None:
    print(f"[briefing-fetch] {msg}", file=sys.stderr)


# ───────────────────────────── Hacker News ──────────────────────────────────
def fetch_hn() -> list[str]:
    try:
        ids = get("https://hacker-news.firebaseio.com/v0/topstories.json")[:30]
    except Exception as e:
        warn(f"HN topstories failed: {e}")
        return ["_Hacker News unavailable._"]
    rows = []
    for sid in ids:
        if len(rows) >= HN_COUNT:
            break
        try:
            it = get(f"https://hacker-news.firebaseio.com/v0/item/{sid}.json")
        except Exception:
            continue
        if not it or it.get("type") != "story":
            continue
        score = it.get("score", 0)
        if score < HN_MIN_SCORE:
            continue
        title = it.get("title", "(untitled)")
        url = it.get("url", f"https://news.ycombinator.com/item?id={sid}")
        comments = it.get("descendants", 0)
        hn = f"https://news.ycombinator.com/item?id={sid}"
        rows.append(f"- **[{title}]({url})** · {score}▲ · "
                    f"[{comments} comments]({hn})")
    return rows or ["_No HN stories above the score threshold._"]


# ───────────────────────────────── arXiv ────────────────────────────────────
def fetch_arxiv() -> list[str]:
    cat_q = "+OR+".join(f"cat:{c}" for c in ARXIV_CATS)
    url = ("https://export.arxiv.org/api/query?"
           f"search_query={cat_q}"
           "&sortBy=submittedDate&sortOrder=descending&max_results=50")
    try:
        raw = get(url, as_json=False)
        root = ET.fromstring(raw)
    except Exception as e:
        warn(f"arXiv failed: {e}")
        return ["_arXiv unavailable._"]

    ns = {"a": "http://www.w3.org/2005/Atom"}
    entries = []
    for e in root.findall("a:entry", ns):
        title = " ".join((e.findtext("a:title", "", ns)).split())
        summary = " ".join((e.findtext("a:summary", "", ns)).split())
        link = e.findtext("a:id", "", ns)
        authors = [a.findtext("a:name", "", ns)
                   for a in e.findall("a:author", ns)]
        hay = (title + " " + summary).lower()
        score = sum(1 for k in KEYWORDS if k in hay)
        entries.append((score, title, link, authors, summary))

    # keyword matches first, then newest (input is already newest-first)
    entries.sort(key=lambda x: -x[0])
    rows = []
    for score, title, link, authors, summary in entries[:ARXIV_SHOW]:
        who = ", ".join(authors[:3]) + (" et al." if len(authors) > 3 else "")
        tag = " 🎯" if score else ""
        blurb = (summary[:180] + "…") if len(summary) > 180 else summary
        rows.append(f"- **[{title}]({link})**{tag}  \n"
                    f"  <sub>{who}</sub>  \n"
                    f"  {blurb}")
    return rows or ["_No recent papers._"]


# ───────────────────────────── GitHub radar ─────────────────────────────────
def fetch_github() -> list[str]:
    now = datetime.now(timezone.utc)
    rows = []
    for repo in GH_WATCH:
        try:
            rel = get(f"https://api.github.com/repos/{repo}/releases/latest")
        except Exception as e:
            # repos with no "releases" 404 — fall back to tags
            try:
                tags = get(f"https://api.github.com/repos/{repo}/tags")
                if tags:
                    rows.append(f"- **{repo}** → `{tags[0]['name']}` (tag)")
                else:
                    warn(f"GitHub {repo}: no releases or tags")
                continue
            except Exception as e2:
                warn(f"GitHub {repo} failed: {e} / tags fallback failed: {e2}")
                rows.append(f"- **{repo}** _(no release info)_")
                continue
        tag = rel.get("tag_name", "?")
        url = rel.get("html_url", f"https://github.com/{repo}/releases")
        published = rel.get("published_at", "")
        fresh = ""
        try:
            pub = datetime.fromisoformat(published.replace("Z", "+00:00"))
            age = (now - pub).days
            fresh = " 🆕" if age <= GH_FRESH_DAYS else ""
            when = pub.strftime("%b %d")
        except Exception:
            when = published[:10]
        rows.append(f"- **[{repo}]({url})** → `{tag}`{fresh} · {when}")
    return rows or ["_No watched repos._"]


# ─────────────────────────────── assemble ───────────────────────────────────
def main() -> int:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    today = datetime.now()
    date_h = today.strftime("%A, %B %d, %Y")

    hn = fetch_hn()
    papers = fetch_arxiv()
    gh = fetch_github()

    md = []
    md.append(f"# 🗞  Daily Briefing — {date_h}\n")
    md.append(f"<sub>generated {today.strftime('%H:%M')} · local desktop digest "
              f"· the AI deep-dive arrives by email</sub>\n")

    md.append("## 🔬 Research radar — arXiv\n")
    md.append(f"<sub>cats: {', '.join(ARXIV_CATS)} · 🎯 = matches your keywords</sub>\n")
    md.extend(papers)
    md.append("")

    md.append("## 💻 Hacker News\n")
    md.extend(hn)
    md.append("")

    md.append("## 📦 Release radar\n")
    md.extend(gh)
    md.append("")

    md.append("---")
    md.append("<sub>Super+N opens this · edit sources in "
              "`~/.config/hypr/scripts/briefing-fetch.py`</sub>")

    text = "\n".join(md) + "\n"
    archive = OUT_DIR / f"{today.strftime('%Y-%m-%d')}.md"
    latest = OUT_DIR / "today.md"
    archive.write_text(text)
    latest.write_text(text)
    print(f"[briefing-fetch] wrote {latest} ({len(text)} bytes)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
