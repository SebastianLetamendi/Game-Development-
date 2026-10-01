# Campus Delivery Dash

A tiny Roblox game, built as a first project while learning game development
with AI coding assistants. Grab a package at the campus Depot, follow the
marker to the right building, and deliver it before the 90-second timer runs
out. Then try to beat your best score.

> **Status:** the code for the first playable round is written and passes
> every automated check, but it has **not been played in Roblox Studio yet**.
> See [`STATUS.md`](STATUS.md) for what has actually been tested.

## Quick start

You need a Mac or PC with [Roblox Studio](https://create.roblox.com/docs/studio/setup).

1. In Studio, create a new **Baseplate** place, save it (File > Save to
   File As...) and make a backup copy
   ([Backups and Git](docs/SETUP.md#backups-and-git)).
2. Put the scripts into the place using one of these routes (details in
   [`docs/SETUP.md`](docs/SETUP.md)):
   - **With Claude Code and Studio's MCP connection:** ask Claude Code to
     install the game from this repository.
   - **One paste, no extra tools:** open View > Command Bar, paste the whole
     of [`dist/InstallIntoStudio.luau`](dist/InstallIntoStudio.luau) and
     press Enter.
   - **With Rojo** (Mac, Route C in [`docs/SETUP.md`](docs/SETUP.md)): run
     `tools/install-dev-tools.sh` once, then
     `.tools/bin/rojo build default.project.json -o CampusDeliveryDash.rbxlx`
     and open the file, or use `.tools/bin/rojo serve` with the Rojo Studio plugin.
3. Press **Play**. The greybox campus is built automatically, and the
   Output window should say `[CampusDeliveryDash] Ready`.
4. Click **Start delivery**, walk to the Depot, hold **E** at the prompt
   (touch and hold it on a phone), follow the green beacon and deliver the
   package.

Then work through [`docs/TEST-PLAN.md`](docs/TEST-PLAN.md).

## How this repository works

| Path | What it is |
|---|---|
| [`PROJECT-BRIEF.md`](PROJECT-BRIEF.md) | What the game is, its rules and what is out of scope |
| [`TASK.md`](TASK.md) | The one task being worked on, with acceptance criteria |
| [`STATUS.md`](STATUS.md) | What works, what was really tested, what is broken |
| [`AGENTS.md`](AGENTS.md) | Rules for every AI agent (Codex reads this) |
| [`CLAUDE.md`](CLAUDE.md) | Extra instructions for Claude Code |
| [`docs/`](docs) | Setup, architecture, test plan, code tour, playtests, assets, videos |
| `src/shared/` | Modules used by both server and client (`Config`, `RoundLogic`, `Net`) |
| `src/server/` | Server scripts: map, round rules, validation |
| `src/client/` | Player scripts: HUD and destination marker |
| `tests/` | Unit tests for the round rules and the installer |
| `tools/` | Tool installer, `check.sh`, installer generator |
| `dist/InstallIntoStudio.luau` | Generated one-paste installer. Do not edit. |

The scripts in `src/` are the source of truth. Studio is where the game
runs; Git is where the code is kept.

### The working loop

Each change follows the same loop:

1. Write the task and its acceptance criteria in `TASK.md`.
2. Claude Code implements one feature.
3. Review the diff, or ask Codex to review it.
4. Run `tools/check.sh`.
5. Play it in Studio.
6. Save a backup of the place and commit.
7. Update `STATUS.md`.

### Automated checks

```sh
tools/install-dev-tools.sh   # once: downloads pinned tools into .tools/
tools/check.sh               # formatting, unit tests, type checks, build
tools/check.sh --fix         # reformat and regenerate the installer first
```

The same checks run on GitHub for every push
(`.github/workflows/checks.yml`). They catch typos, wrong Roblox API use and
broken rules. They do not replace playing the game.

## Learning the code

[`docs/CODE-TOUR.md`](docs/CODE-TOUR.md) walks through each script in the
order it runs, with quiz questions. [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)
is the reference for how the pieces fit together and why the server decides
everything that matters.

## This repository is public

Do not commit passwords, API keys, Roblox cookies, `.env` files, real
tester names, client work, school or job records, or receipts. Keep Studio
place backups, recordings and video exports outside the repository
(`.gitignore` already excludes the usual file types).

## Licence

No licence has been chosen yet, so all rights are reserved by the owner.
Add a `LICENSE` file before inviting others to reuse the code.
