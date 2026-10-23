---
name: log
description: Save progress. Use when the user says "log it", "save this", "note that", "update the status", "done for today", or after finishing meaningful work (a decision, a deliverable, a status change).
---

# Log: save today's progress

1. Work out the project (the current folder, or the one the user named; see `core/PROJECTS.md`).
2. Update `projects/<project>/STATUS.md`:
   - **Last updated:** today's date (run `date +%Y-%m-%d`, don't guess).
   - Refresh **Now**, **Next** and **Blockers** so they are true right now. Remove finished items.
   - Add today's line at the **top** of the Daily log: `- YYYY-MM-DD · what happened`.
   - Keep the file under about 40 lines. Trim the oldest log lines if needed.
3. Append one line to `log/log.md`:
   `YYYY-MM-DD · <project> · what happened · next action`
4. Meaning, not noise: no file lists, no transcripts, no secrets.
5. Reply in one line: what you logged and where.
