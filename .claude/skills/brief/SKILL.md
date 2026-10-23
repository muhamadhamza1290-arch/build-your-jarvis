---
name: brief
description: Cross-project status board. Use when the user asks "where are we?", "brief me", "status", "what's pending", "what should I do today", or asks about all projects at once.
---

# Brief: the "where are we?" board

1. List the projects from `core/PROJECTS.md` (and any `projects/*/STATUS.md` not yet in the table; mention those as "not registered").
2. Read each project's `STATUS.md`. Read nothing else unless a STATUS.md is missing or older than 7 days. If it is, say so and check that project's `ACTIVITY.md` for what changed.
3. Read the last 5 lines of `log/log.md`.
4. Reply with one short block per project:

```
<project> · level <n> · updated <date> (<n> days ago)
  Now:      <one line>
  Next:     <the single next action>
  Blocked:  <what is waiting on [YOUR NAME], or "nothing">
```

5. End with **Today's one thing**: the single most important next action across all projects, with its priority level (core/PRIORITIES.md). Flag any out-of-order work.

Keep the whole board under 25 lines. Don't round bad news up. If a STATUS.md is stale, say "stale" plainly.
