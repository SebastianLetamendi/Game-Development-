# Architecture

How Campus Delivery Dash is put together, and the contracts that the code,
the map and the agents must keep. If a change breaks one of these contracts,
update this file in the same commit.

## Files and where they run

The repository is laid out the way [Rojo](https://rojo.space) expects, and
`default.project.json` says where each folder goes inside Roblox:

| Repository folder | Inside Roblox | Runs on |
|---|---|---|
| `src/shared/` | `ReplicatedStorage.CampusDeliveryDash` | both (modules only) |
| `src/server/` | `ServerScriptService.CampusDeliveryDash` | server only |
| `src/client/` | `StarterPlayer.StarterPlayerScripts.CampusDeliveryDash` | each player's device |

File names follow Rojo's rules: `Name.server.luau` becomes a `Script`,
`Name.client.luau` a `LocalScript`, and `Name.luau` a `ModuleScript`.

| File | Job |
|---|---|
| `shared/Config.luau` | Every tunable number (round length, scoring, cheat limits). |
| `shared/RoundLogic.luau` | The round rules as pure functions. No Roblox APIs, so it is unit-tested. |
| `shared/Net.luau` | Remote names, the `Snapshot` type, and helpers to create or find the remotes. |
| `server/Main.server.luau` | Server entry point: find or build the map, check it, create prompts and remotes, start `RoundService`. |
| `server/MapBuilder.luau` | Builds the greybox campus from parts when `Workspace.CampusMap` is missing. |
| `server/MapContract.luau` | Finds `StartPad`, `Depot` and `Destinations` in the map, reports problems, creates the ProximityPrompts. |
| `server/RoundService.luau` | One session per player; validates every request; calls `RoundLogic`; sends snapshots. |
| `server/PackageVisual.luau` | Welds a package to the character while it carries one (visual only). |
| `client/Main.client.luau` | Client entry point: waits for remotes, applies snapshots, runs the per-frame update. |
| `client/Hud.luau` | Builds the ScreenGui: objective, countdown, messages, title and results panel. |
| `client/Marker.luau` | Beacon, label and guide line to the next objective; shows only the useful prompt. |

`dist/InstallIntoStudio.luau` is generated from these files by
`tools/build_installer.py`. Never edit it by hand.

## The round

Each player has their own round. Several players can play on one server
at once without affecting each other.

```
Idle ──start──▶ ToPickup ──pickUp──▶ ToDropoff ──deliver──▶ Delivered
                   │                     │
                   └──────expire─────────┴──────────────────▶ TimeUp
```

From `Delivered` or `TimeUp`, pressing the button starts a new round.

- **Start**: the server picks a destination at random (never the same one
  twice in a row when there is a choice), sets the deadline to
  `now + ROUND_SECONDS` and moves the character to the `StartPad`.
- **Pick up**: at the Depot prompt. Allowed only in `ToPickup`.
- **Deliver**: at the assigned destination's prompt. Allowed only in
  `ToDropoff`, only at the assigned destination, and only if the trip took
  at least `distance(depot, destination) / MAX_TRAVEL_SPEED` seconds.
- **Time up**: the server ends the round `GRACE_SECONDS` after the deadline.
  A delivery inside the grace window still counts and scores `BASE_POINTS`.
- **Score**: `BASE_POINTS + floor(secondsLeft) * POINTS_PER_SECOND_LEFT`,
  calculated only on the server. With the defaults, 42.7 seconds left
  scores 100 + 42 × 10 = 520.
- **Best**: the highest score this server session, shown on the results
  panel and in the player list (`leaderstats.Best`). It is not saved
  between sessions yet; saving is a later task (see `PROJECT-BRIEF.md`).
- **Respawning** does not end the round. The timer keeps running and the
  package is re-attached to the new character.
- **Leaving** deletes the player's session; pending timers notice and stop.

All times come from `Workspace:GetServerTimeNow()`, which the server and
every client share, so the countdown a player sees matches the server's.

## Network contract

Defined in `src/shared/Net.luau`. The server creates the remotes in
`ReplicatedStorage.CampusDeliveryDash.Remotes` after the map is valid.

| Remote | Direction | Payload |
|---|---|---|
| `StartRound` (RemoteEvent) | client → server | none; any arguments are ignored |
| `GetRoundState` (RemoteFunction) | client → server → client | returns a `Snapshot` (or nil while the player is leaving) |
| `RoundState` (RemoteEvent) | server → one client | a `Snapshot` |

A `Snapshot` contains `seq`, `phase`, `roundId`, `roundSeconds`, `deadline`,
`objective`, `objectivePosition`, `targetId`, `targetName`, `lastScore`,
`lastSeconds`, `best`, `newBest` and `message`. Clients keep only the
snapshot with the highest `seq`.

Pickups and deliveries do **not** use remotes. They arrive through
`ProximityPrompt.Triggered`, which fires on the server with the player.

## Security model

The client is untrusted: anyone can run modified client code. So:

1. No remote accepts a score, time, position, destination or phase.
2. `StartRound` is ignored while a round runs and when repeated within
   `START_COOLDOWN_SECONDS`.
3. Prompt triggers are re-checked on the server: a living character, close
   enough to that part (`PROMPT_DISTANCE + PROMPT_DISTANCE_TOLERANCE + half
   the part's size`), in the right phase, at the right destination.
4. A delivery that is faster than `MAX_TRAVEL_SPEED` allows is refused as
   teleporting.
5. Hiding prompts on the client (in `Marker`) is only for clarity. The server
   never relies on it.

What this does not stop: a cheater who moves at a believable speed but
ignores the route. With no prizes or saved data in this version, that is an
accepted risk. Revisit it before adding paid items or saved progress.

## Map contract

The scripts depend on only these objects. Everything else is scenery and can
be changed freely.

```
Workspace
└── CampusMap            Model (name set by Config.MAP_NAME)
    ├── StartPad         BasePart: where characters go when a round starts
    ├── Depot            BasePart: package pickup point
    └── Destinations     Folder
        ├── Library      BasePart (or a Model with a PrimaryPart)
        ├── Gym          ...one child per address; the Name is the id
        └── ...          optional string attribute DisplayName = what players see
```

- If `Workspace.CampusMap` does not exist when the server starts,
  `MapBuilder` builds the greybox version for that test only.
- To edit the map in Studio, build it once in Edit mode with the Command Bar
  (see the comment at the top of `MapBuilder.luau`), then save the place.
- `MapContract.find` stops the game with clear messages in the Output window
  if `StartPad`, `Depot` or every destination is missing, and warns about
  destinations it has to ignore (wrong class or duplicate name).
- Set `CampusMap.ModelStreamingMode` to `Persistent` (MapBuilder does this),
  so every prompt exists on every client even with instance streaming.
- To use a custom carried package, put a single part named `PackageTemplate`
  in `ServerStorage`.

## Client presentation

- `Hud` shows the title panel while idle, the objective and the countdown
  while running (red for the last 10 seconds), and a results panel after a
  round. The button works with mouse and touch.
- `Marker` shows a beacon (orange for the Depot, green for the destination),
  a label with the place name and distance, and a guide line from the
  character. It enables only the prompt that the current step needs.
- Prompts carry the tag `CampusDeliveryDashPrompt` and the attributes
  `Kind` (`Depot` or `Destination`) and, for destinations, `TargetId`.

## Checks

`tools/check.sh` runs, in order:

1. StyLua formatting check (`stylua.toml`).
2. Luau unit tests: `tests/run.luau` (Config and RoundLogic).
3. Strict type checking and lint with luau-lsp, Roblox API definitions and a
   Rojo sourcemap. This catches misspelled properties, wrong argument types,
   invalid class names and unused variables.
4. `rojo build`, which proves the project file is valid.
5. The Studio installer is up to date with `src/`.
6. Python tests, including running the generated installer against a fake
   Roblox API to confirm it recreates every script exactly.

None of these run the game. Behaviour in Studio (movement, prompts, UI on a
phone, two players) is checked by hand with `docs/TEST-PLAN.md`.

## Known limitations of this version

- Best scores are not saved between sessions (no DataStore yet).
- No sound effects, music or particle effects.
- A gamepad can play, but the Start button needs a mouse, touch or the
  gamepad's on-screen cursor; there is no dedicated controller shortcut.
- The greybox map is plain parts. Blender props replace pieces later
  (`docs/ASSETS.md`).
