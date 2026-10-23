# Build Your Own Jarvis

A starter kit that turns Claude Code into your own AI operator: one assistant that knows your projects, remembers where each one stands, hands work to a small team of helper agents, and follows rules it can't break.

It is not one giant prompt. It is a few plain text files plus three small scripts (hooks). You can read every one of them in a few minutes.

> **Status:** starter template. Everything in `projects/` is fictional example data. Replace it with your own.

---

## 2-minute setup

You need [Claude Code](https://docs.claude.com/en/docs/claude-code) installed, plus `bash` and `python3` (already on macOS and most Linux machines).

1. Download or clone this folder anywhere you like.
2. Open `CLAUDE.md` and replace `[YOUR NAME]` with your name. Change the assistant's name if you don't want "Jarvis".
3. Open a terminal in this folder and run:
   ```bash
   chmod +x hooks/*.sh scripts/find.py
   claude
   ```
4. Claude Code will ask you to trust the folder and its hooks. Say yes (read the hooks first, they are short).
5. Type: **"Jarvis, where are we?"**

That's it. The hooks are registered in `.claude/settings.json` inside this folder, so nothing in your global `~/.claude` is touched.

**Already have your own `~/.claude/CLAUDE.md` or global hooks?** Claude Code loads those too, and they can override this kit. To try the kit on its own, start it with:

```bash
claude --setting-sources project,local
```

**Want Jarvis in every folder, not just this one?** Later, once you're happy with it, you can copy the parts you like into `~/.claude/CLAUDE.md`. Start local first.

---

## The 7 layers, and where each one lives

| # | Layer | What it does | File(s) |
|---|---|---|---|
| 1 | **Persona** | Who the assistant is, how it talks, what it does first | `CLAUDE.md` |
| 2 | **Knows where it is** | A registry of your projects, so it knows which one you mean | `core/PROJECTS.md` |
| 3 | **The team** | Five helper agents it can hand work to, in parallel | `.claude/agents/*.md` |
| 4 | **Can't forget** | Every project keeps a short `STATUS.md`. A stop hook won't let a session end until it's updated | `projects/*/STATUS.md`, `hooks/status-check.sh`, `hooks/activity.sh` |
| 5 | **The brain** | Local search over all your notes, so it reads 2 files instead of 20 | `scripts/find.py` |
| 6 | **Rules it can't break** | Ask before anything goes outside, no invented facts, no reading secrets, no bulk deletes | `core/RULES.md`, `hooks/file-guard.sh` |
| 7 | **Priority filter** | Build things in the right order, and say so when work is out of order | `core/PRIORITIES.md` |

Plus two skills (reusable routines): `/brief` for the status board and `/log` for saving progress.

---

## Short on time? Start with 3 files tonight

You don't need all seven layers. Start with these three and add the rest later:

1. **`CLAUDE.md`**: who your assistant is and what it must always do.
2. **`STATUS.md`** in each project: Now, Next, Blockers, and a daily log. Under 40 lines.
3. **A stop hook** (`hooks/status-check.sh`): if you changed a project's files and its STATUS.md is out of date, Claude has to update it before it finishes.

Those three alone fix the biggest problem: starting every session from zero.

---

## Daily use

| You say | What happens |
|---|---|
| "Jarvis, where are we?" | Reads every `STATUS.md` and gives you a short board: state, next action, blockers |
| "Where are we on example-agency?" | Status of that one project |
| "Log it" or `/log` | Updates the project's `STATUS.md` and adds one line to `log/log.md` |
| "Research X and build Y" | Splits the job between the researcher and builder agents, in parallel |
| "Find my notes on pricing" | Runs `python3 scripts/find.py pricing` and opens only the matching lines |

## Add your own project

1. Make a folder in `projects/`, for example `projects/my-shop/`. (Already have a project somewhere else? Put a symlink here: `ln -s ~/code/my-shop projects/my-shop`.)
2. Copy a `STATUS.md` from an example project into it and fill it in.
3. Add one row to `core/PROJECTS.md`.
4. Delete the two example projects when you no longer need them.

---

## What it does NOT do

- **It doesn't post, email, pay or deploy on its own.** The rules tell it to draft and wait for your yes. The rules and hooks reduce risk; they are not a security guarantee, so keep Claude Code's own permission prompts on.
- **It doesn't run in the background.** It works when you open Claude Code in this folder.
- **It isn't free compute.** It runs on your normal Claude Code plan. The helper agents use the same plan, so parallel work uses more of your limit.
- **It doesn't send your files anywhere new.** The hooks and search script are local only, with no network calls. (Claude Code itself still sends what it reads to the model, as usual.)

## Folder map

```
build-your-jarvis/
├── CLAUDE.md                 layer 1: the persona and operating manual
├── core/
│   ├── PROJECTS.md           layer 2: project registry
│   ├── RULES.md              layer 6: the rules
│   └── PRIORITIES.md         layer 7: the build-order filter
├── projects/                 your projects (two fictional examples)
├── .claude/
│   ├── settings.json         registers the hooks for this folder
│   ├── agents/               layer 3: researcher, builder, critic, qa, writer
│   └── skills/               /brief and /log
├── hooks/                    layer 4 + 6: status-check, activity, file-guard
├── scripts/find.py           layer 5: local search
└── log/log.md                one line per working session, all projects
```

## Requirements and compatibility

- Claude Code (any recent version with hooks, subagents and skills)
- bash 3.2+ (the macOS default works) and python3 3.8+, standard library only
- Tested on macOS. Written to also run on Linux. Windows: use WSL.

## License

MIT. See `LICENSE`.
