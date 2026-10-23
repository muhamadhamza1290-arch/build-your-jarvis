#!/usr/bin/env python3
"""find.py: fast local search over every Markdown/text note in this folder.

Jarvis runs this BEFORE opening files, so it reads 2 files instead of 20.

    python3 scripts/find.py pricing            # file:line  snippet
    python3 scripts/find.py "launch plan" -n 5  # top 5 hits
    python3 scripts/find.py outreach --files    # file names only
    python3 scripts/find.py status -p example-agency   # one project only

How it works: a small SQLite full-text index in .state/find.db. Only files
that changed since the last run are re-read, so it stays fast. Standard
library only, no network, no model calls. Secret files are never indexed.
"""
import argparse
import os
import re
import sqlite3
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
DB = os.path.join(ROOT, ".state", "find.db")
EXTS = {".md", ".txt"}
SKIP_DIRS = {".git", ".state", "node_modules", "__pycache__", "backups", "personal"}
SECRET = re.compile(r"(^\.env|\.pem$|\.key$|\.p12$|^id_rsa|^id_ed25519|credentials|secret)", re.I)


def walk():
    for base, dirs, files in os.walk(ROOT, followlinks=True):
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
        for name in files:
            if os.path.splitext(name)[1].lower() in EXTS and not SECRET.search(name):
                yield os.path.join(base, name)


def connect():
    os.makedirs(os.path.dirname(DB), exist_ok=True)
    con = sqlite3.connect(DB)
    con.execute("CREATE TABLE IF NOT EXISTS files(path TEXT PRIMARY KEY, mtime REAL)")
    try:
        con.execute("CREATE VIRTUAL TABLE IF NOT EXISTS lines USING fts5(path UNINDEXED, lineno UNINDEXED, text)")
        fts = True
    except sqlite3.OperationalError:  # very old SQLite without FTS5: plain table + LIKE
        con.execute("CREATE TABLE IF NOT EXISTS lines(path TEXT, lineno INT, text TEXT)")
        fts = False
    return con, fts


def refresh(con):
    known = dict(con.execute("SELECT path, mtime FROM files"))
    seen = set()
    for full in walk():
        rel = os.path.relpath(full, ROOT)
        seen.add(rel)
        try:
            mtime = os.path.getmtime(full)
        except OSError:
            continue
        if known.get(rel) == mtime:
            continue
        con.execute("DELETE FROM lines WHERE path = ?", (rel,))
        try:
            with open(full, encoding="utf-8", errors="replace") as fh:
                rows = [(rel, i, t.strip()) for i, t in enumerate(fh, 1) if t.strip()]
        except OSError:
            continue
        con.executemany("INSERT INTO lines(path, lineno, text) VALUES (?, ?, ?)", rows)
        con.execute("INSERT OR REPLACE INTO files(path, mtime) VALUES (?, ?)", (rel, mtime))
    for gone in set(known) - seen:
        con.execute("DELETE FROM lines WHERE path = ?", (gone,))
        con.execute("DELETE FROM files WHERE path = ?", (gone,))
    con.commit()


def search(con, fts, words, limit, project):
    terms = [w for w in re.findall(r"[\w-]+", " ".join(words)) if w]
    if not terms:
        return []
    where, args = "", []
    if project:
        where, args = " AND path LIKE ?", ["projects/%s/%%" % project]
    if fts:
        query = " ".join('"%s"*' % t.replace('"', "") for t in terms)
        sql = ("SELECT path, lineno, snippet(lines, 2, '[', ']', '...', 12) FROM lines "
               "WHERE lines MATCH ?" + where + " ORDER BY rank LIMIT ?")
        return con.execute(sql, [query] + args + [limit]).fetchall()
    sql = "SELECT path, lineno, text FROM lines WHERE " + " AND ".join("text LIKE ?" for _ in terms) + where + " LIMIT ?"
    return con.execute(sql, ["%%%s%%" % t for t in terms] + args + [limit]).fetchall()


def main():
    ap = argparse.ArgumentParser(description="Search this folder's notes. Prints file:line and a snippet.")
    ap.add_argument("words", nargs="+", help="words to find (all must match)")
    ap.add_argument("-n", type=int, default=15, help="max results (default 15)")
    ap.add_argument("-p", "--project", help="search only projects/<name>/")
    ap.add_argument("--files", action="store_true", help="print matching file names only")
    a = ap.parse_args()

    con, fts = connect()
    refresh(con)
    hits = search(con, fts, a.words, a.n * (10 if a.files else 1), a.project)
    if not hits:
        print("No matches.")
        return 1
    if a.files:
        names = list(dict.fromkeys(h[0] for h in hits))[: a.n]
        print("\n".join(names))
    else:
        for path, lineno, text in hits:
            print("%s:%s  %s" % (path, lineno, text[:160]))
    return 0


if __name__ == "__main__":
    sys.exit(main())
