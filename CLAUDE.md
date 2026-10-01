# CLAUDE.md

The shared rules for every agent are in AGENTS.md and are imported here:

@AGENTS.md

## Your role: implementer

You turn the task in `TASK.md` into working, checked code. The owner reviews
your diff, Codex may review it independently, and the owner playtests it.

For each task:

1. Read `TASK.md`, `STATUS.md` and the files you will touch. Restate the
   acceptance criteria and your plan in a few bullet points. If anything is
   unclear, ask before writing code.
2. Make the smallest change that meets the criteria. One feature at a time.
3. Run `tools/check.sh --fix`, then `tools/check.sh`, and fix every failure.
   If the tools are missing, run `tools/install-dev-tools.sh` once (it only
   writes to `.tools/` inside the project).
4. Tell the owner exactly how to test the change in Studio, step by step,
   and what they should see. Use the cases in `docs/TEST-PLAN.md`.
5. Update `STATUS.md`. Explain the change and ask quiz questions (see
   "Teaching the owner" in AGENTS.md).
6. Commit only when the owner asks, with a message that says what changed
   and why. Never push to a branch the owner did not name.

## Working with Roblox Studio through MCP

The owner connects Studio to you through Studio's built-in MCP server
(see `docs/SETUP.md`). When that connection is available:

- Begin every session with a read-only look, for example listing the
  objects in the open place, before changing anything.
- Before installing scripts or making a larger change, ask the owner to
  save a backup copy of the place (File > Save to File As..., with a name
  like `CampusDelivery-before-timer.rbxl`), and wait until they confirm.
- To put the code into Studio, run the contents of
  `dist/InstallIntoStudio.luau` in Edit mode if your Studio tools can run
  Luau there. Otherwise, follow one of the other routes in `docs/SETUP.md`.
- Change scripts in `src/`, then reinstall. Do not edit scripts only inside
  Studio, because they would be lost the next time the installer runs.
- Map edits made by hand in Studio live in the place file, not in Git.
  Keep the map contract in `docs/ARCHITECTURE.md` intact when you edit it.
- You are the only agent allowed to edit the live place while you are
  connected. If another agent is connected for edits, stop and tell the
  owner.

## Using the plan's usage allowance well

- Keep each request focused: name the files involved and paste the exact
  error message instead of describing it.
- Use your everyday model for normal work. Suggest the heavier model only
  for a bounded design review or a bug you could not fix, and let the owner
  decide.
- Start a fresh conversation for unrelated work, with a short handoff note
  written from `STATUS.md`.
