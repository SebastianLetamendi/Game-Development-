# Status

_Last updated: 2026-10-01_

## Latest working milestone

**None verified in Studio yet.**

The code for milestones 1 to 4 (greybox route, pickup and delivery, round
lifecycle, client/server validation) is written and passes every automated
check. It has **not** been run in Roblox Studio: it was written in a cloud
environment that cannot run Studio. The first Studio playtest is the current
task (`TASK.md`).

| Milestone | Code written | Automated checks | Played in Studio |
|---|---|---|---|
| 1 Greybox route | yes (`MapBuilder`) | builds, type-checks | not yet |
| 2 Pickup and delivery | yes | rules unit-tested | not yet |
| 3 Round lifecycle | yes | rules unit-tested | not yet |
| 4 Client/server behaviour | yes | rules unit-tested | not yet |
| 5 Presentation | partly: beacon, guide line, signs, HUD | type-checks | not yet |
| 6 Playtest | no | n/a | n/a |

## Changed in the last task

Initial project setup:

- Starter kit: `README.md`, `AGENTS.md`, `CLAUDE.md`, `PROJECT-BRIEF.md`,
  `TASK.md`, this file, and the guides in `docs/`.
- Game scripts in `src/` (shared, server and client) and the generated
  `dist/InstallIntoStudio.luau`.
- Tests in `tests/`, checking tools in `tools/`, and the GitHub Actions
  workflow `.github/workflows/checks.yml`.

## Checks actually run

`tools/check.sh` on 2026-10-01 (Linux x86_64), all passed:

- StyLua formatting check
- 30 Luau unit tests (Config and RoundLogic)
- luau-lsp strict type checking and lint against the Roblox API definitions
- `rojo build` of `default.project.json`
- Studio installer is up to date with `src/`
- 5 Python tests, including running the generated installer against a fake
  Roblox API and comparing every script with `src/`

## Not tested yet

Everything that needs Studio: walking the routes, prompts, the HUD on desktop
and phone screens, the marker, respawning, two players, leaving mid-round,
and how the 90-second timer feels.

## Known failures and risks

- No known failures yet, because nothing has been played.
- The route lengths and timer were chosen on paper (about 10 to 20 seconds of
  walking per delivery). Playtests may show the timer is too generous.
- Gamepad players have no dedicated button for Start; Roblox's built-in UI
  navigation is needed to press it.

## Next task

See `TASK.md`: first Studio playtest of the round.

## Ideas parked

Not in scope yet; revisit after playtests.

- Save best scores between sessions (DataStore), only after the round works
  and with failure handling.
- Sounds for pickup, delivery and time running out.
- Replace greybox props with Blender models (`docs/ASSETS.md`).
- Several deliveries per round once one delivery feels good.
