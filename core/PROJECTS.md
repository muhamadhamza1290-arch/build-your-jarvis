# Project registry

Jarvis uses this table to work out which project you mean and where its files live.
Add one row per project. The two rows below are **fictional examples**: replace or delete them.

| Project | Folder | What it is | Status file |
|---|---|---|---|
| example-agency | `projects/example-agency/` | EXAMPLE: a small design agency finding its first clients | `projects/example-agency/STATUS.md` |
| example-course | `projects/example-course/` | EXAMPLE: an online course being recorded and launched | `projects/example-course/STATUS.md` |

## How to add a project

1. Create `projects/<name>/` (or symlink an existing folder there: `ln -s /path/to/project projects/<name>`).
2. Copy a `STATUS.md` from an example and fill it in.
3. Add a row above.
4. Optional: give the project its own `CLAUDE.md` with rules that apply only there (tone, tools, client do's and don'ts).

## Notes for Jarvis

- If the working directory is inside a folder in this table, that is the current project.
- If [YOUR NAME] names a project, match it to the closest row. Ask if two rows could fit.
- Never mix files or facts between rows (see Rule 3, walls).
