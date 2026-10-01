# Agent rules: Campus Delivery Dash

Every AI agent working in this repository (Codex, Claude Code or any other)
follows these rules. Claude Code also reads `CLAUDE.md`, which adds its own
role on top of this file.

## The project

A tiny Roblox game built by a beginner who is learning to code with AI help.
A player picks up a package at the campus Depot, follows a marker to one of
six buildings and delivers it before a 90-second timer runs out, then sees
their score and plays again. The goal of this version is a playable loop the
owner **understands and can demonstrate**, not a big game.

Read these before starting any task:

1. `PROJECT-BRIEF.md`: what the game is, and what is out of scope.
2. `TASK.md`: the one task being worked on and its acceptance criteria.
3. `STATUS.md`: what works, what was actually tested, what is broken.
4. `docs/ARCHITECTURE.md`: file layout, the round rules, the network and
   map contracts, and the security model.

## Who does what

| Who | Role |
|---|---|
| Owner (the human) | Decides scope and priorities, playtests in Studio, approves every merge, talks to players and testers. Has the final say. |
| Claude Code | Implementer: makes the change described in `TASK.md` (see `CLAUDE.md`). |
| Codex | Reviewer: checks changes independently and reports findings (see "Reviewing" below). Implements only when the owner asks for a separate task. |

One writer at a time: never let two agents edit the same file, the same
`.blend` file or the live Roblox Studio place at the same time. A second agent
can review a diff or exported files while the first one works.

## Rules for every task

### Scope
- Do only what `TASK.md` asks. If you think something else is needed, say so
  and add it to "Ideas parked" in `STATUS.md` instead of building it.
- If `TASK.md` is empty, vague or contradicts `PROJECT-BRIEF.md`, ask the
  owner before writing code.
- Respect the version 1 non-goals in `PROJECT-BRIEF.md` (no economy, shop,
  inventory, AI-driven NPCs, matchmaking, procedural world or saved data
  until the brief says otherwise).

### Code
- `src/` is the source of truth for every script. Studio is where it runs,
  not where it is kept: never leave a fix only in Studio.
- `dist/InstallIntoStudio.luau` is generated. Never edit it by hand; run
  `tools/check.sh --fix` after changing anything in `src/`.
- The server decides everything that matters. Never add a remote that
  accepts a score, time, position or round phase from a client. Follow the
  security model in `docs/ARCHITECTURE.md`.
- Put tunable numbers in `src/shared/Config.luau`. Put round rules in
  `src/shared/RoundLogic.luau` and add a test in `tests/` for each new rule.
- Keep `--!strict` at the top of every Luau file and match the existing
  style: clear names, small functions, comments that explain *why* in plain
  language a beginner can follow.
- If you change a contract (files, remotes, map objects, round rules),
  update `docs/ARCHITECTURE.md` in the same change.

### Evidence, not claims
- Run `tools/check.sh` before saying a change is done, and report what it
  actually printed. If a check fails, say so and show the output.
- Automated checks do not run the game. Never say something "works in
  Studio" unless the owner played it and told you so. Write "not tested in
  Studio yet" when that is the truth.
- At the end of a task, update `STATUS.md`: latest working milestone,
  changed files, checks actually run, known failures, next task.

### Safety and money
- This repository is **public**. Never commit passwords, API keys, tokens,
  cookies (including `.ROBLOSECURITY`), `.env` files, personal details,
  real tester names, client work, school records, job applications, receipts
  or any other financial records.
- Do not set or use `ANTHROPIC_API_KEY` or an OpenAI API key, turn on paid
  usage credits, buy anything, or add paid assets or services. This project
  has no extra software budget.
- Do not install software, add MCP servers, plugins or packages, or change
  global settings without the owner's approval. When approved, use the
  official source.
- Do not publish the game, change Creator Dashboard settings, upload videos
  or post anything on the owner's behalf.
- Ask before anything destructive: deleting files, rewriting Git history,
  force-pushing, or deleting objects in Studio outside the
  `CampusDeliveryDash` folders and `Workspace.CampusMap`.
- With the Roblox Studio MCP connection, start with a harmless read, make
  sure the owner saved a backup copy of the place first, and stop if the
  connection behaves unexpectedly. Never "fix" a connection by granting
  broader permissions.

### Teaching the owner
The owner is learning. After each change:
- explain what changed and why in plain language, naming the files and
  functions involved;
- ask two or three short quiz questions about the change;
- when the owner wants to try something themselves, give hints before
  answers.

## Commands

| Command | What it does |
|---|---|
| `tools/install-dev-tools.sh` | One-time download of the pinned checking tools into `.tools/` (macOS on Apple Silicon or Linux). |
| `tools/check.sh` | Runs every automated check. Must pass before a change is done. |
| `tools/check.sh --fix` | Formats Luau files and regenerates the Studio installer, then checks. |
| `.tools/bin/luau tests/run.luau` | Runs only the Luau unit tests. |

## Reviewing (Codex's main job)

When the owner asks for a review:

1. Read the acceptance criteria in `TASK.md` and the changed files
   (`git diff`, or the files the owner names).
2. Run `tools/check.sh` and include the result.
3. Check, in this order:
   - Are the acceptance criteria actually met?
   - Can a client cheat? Compare against the security model in
     `docs/ARCHITECTURE.md`.
   - What happens on respawn, leaving mid-round, pressing buttons repeatedly,
     a second player, a touch screen and the timer running out mid-action?
     (`docs/TEST-PLAN.md` lists these cases.)
   - Did the change go beyond the task or the brief?
   - Is the code readable for a beginner, and are `STATUS.md` and
     `docs/ARCHITECTURE.md` up to date?
4. Report findings from most to least serious. For each one give the file and
   line, a concrete scenario where it goes wrong, and a suggested fix. If
   you found nothing, say so plainly.
5. Do not edit files during a review unless the owner asks you to.
