# Code tour

A guided reading of the scripts in the order they run, so you can explain
each one in your own words. For the reference version (contracts, the
security model), see [`ARCHITECTURE.md`](ARCHITECTURE.md).

## How to read this

Open each file next to this page and read it from top to bottom, then read
its section here. Take one section per sitting, 20 to 30 minutes. Answer
each quiz question out loud before you open its answer. Functions are named
instead of line numbers: search for the name in your editor.

### Luau basics you will meet

| You see | It means |
|---|---|
| `--!strict`, `local deadline: number?` | Strict type checking, so many mistakes fail `tools/check.sh` instead of the game. `local` makes a variable only this file or block can see; `: number` is a type annotation; `?` means "or nil" (nothing). |
| `{ "Gym", "Library" }`, `{ [string]: BasePart }` | Tables: a list (counted from 1; `#list` is its length) or a dictionary (key to value). |
| `function RoundLogic.start(...)` | A function. It can return several values: `return false, "AlreadyRunning"`. |
| `require(...)`, `return RoundLogic` | Modules: a ModuleScript returns one value, here a table of functions, and `require` loads it. |
| `prompt.Triggered:Connect(fn)` | Events: Roblox calls `fn` every time the event fires. |
| `task.delay(5, fn)` | Call `fn` once, 5 seconds later, without pausing anything. |
| `` `Ready: {count} destinations` `` | String interpolation: each `{...}` inside backticks becomes its value. |
| `if newBest then "New best!" else "Delivered!"` | An if-then-else expression: it picks one of two values. |
| `x += 1`, `a // b`, `value :: number` | Add to a variable; whole-number division; a type cast. |

## 1. The map of the code

[`default.project.json`](../default.project.json) puts `src/shared/` in
ReplicatedStorage (the server and every player's device get it),
`src/server/` in ServerScriptService (the server only; players never
receive it) and `src/client/` in StarterPlayerScripts (copied to each
player's device). "Replicate" means Roblox copies something from the
server to players' devices. Parts the server makes in Workspace replicate:
the map, the prompts, the carried package. What a client script makes
stays on that device: the HUD, the marker. The rule behind it all: **the
server decides; clients only ask and display.** The full table is in
[`ARCHITECTURE.md`](ARCHITECTURE.md#files-and-where-they-run).

**Q1.1 Why does the server calculate the score instead of the client?**
<details><summary>Answer</summary>Anyone can run modified client code, so a score sent by a client
could be 99999. The server already knows the deadline and the pickup time, so
<code>RoundLogic.deliver</code> works out the score there and only the result is sent.</details>

**Q1.2 `RoundLogic.luau` is in ReplicatedStorage, so a cheater can read it. Is that a problem?**
<details><summary>Answer</summary>No. Reading the rules does not change them: the round that
counts lives in RoundService on the server. The client scripts do not even require RoundLogic.</details>

## 2. Config.luau

[`src/shared/Config.luau`](../src/shared/Config.luau) is one table of named
numbers: `ROUND_SECONDS` 90, `GRACE_SECONDS` 0.25, `BASE_POINTS` 100,
`POINTS_PER_SECOND_LEFT` 10, `MAX_TRAVEL_SPEED` 32, `PROMPT_DISTANCE` 10,
`PROMPT_DISTANCE_TOLERANCE` 6, `START_COOLDOWN_SECONDS` 1 and `MAP_NAME`
`"CampusMap"`. A playtest note such as "the timer feels too long" becomes a
one-line edit. The file requires nothing, so the tests can load it outside
Studio. Its last line, `return table.freeze(Config)`, makes the table
read-only: a script that tries `Config.ROUND_SECONDS = 10` gets an error
instead of quietly changing the game (the test "Config cannot be changed
while the game runs" checks this).

**Q2.1 Why keep these numbers in one table instead of in each script?**
<details><summary>Answer</summary>One place to tune, a name that explains each number, and no
chance of scripts disagreeing: <code>ROUND_SECONDS</code> is read by RoundLogic, the time-up timer
and the title text.</details>

**Q2.2 What does `table.freeze` protect against?**
<details><summary>Answer</summary>A setting changing while the game runs, by accident or a bad edit: it fails with an error instead.</details>

## 3. RoundLogic.luau

[`src/shared/RoundLogic.luau`](../src/shared/RoundLogic.luau) holds the
rules of one round:

```
Idle ──start──▶ ToPickup ──pickUp──▶ ToDropoff ──deliver──▶ Delivered
                   │                     │
                   └──────expire─────────┴──────────────────▶ TimeUp
```

A `Round` is a plain table (`phase`, `roundId`, `targetId`, `deadline`,
`pickedUpAt`, `best` and a few more). Each action takes the round, the
rules and `now` as a number, and returns `true` or `false` plus a `Reason`.

- **`start`**: refused with `AlreadyRunning` during a round. Otherwise
  `ToPickup`, `roundId` up by one, `deadline = now + ROUND_SECONDS`.
- **`pickUp`**: `AlreadyCarrying` in `ToDropoff`, `NotRunning` unless in
  `ToPickup`, and `TimeUp` (ending the round) past the deadline plus
  `GRACE_SECONDS`. Otherwise `ToDropoff`, with `pickedUpAt = now`.
- **`deliver`** checks, in order: `NotCarrying` (still in `ToPickup`),
  `NotRunning` (not in `ToDropoff`), `TimeUp` (past deadline plus grace;
  ends the round), `WrongTarget` (wrong mailbox; the round goes on) and
  `TooFast` (`now - pickedUpAt < minTravelSeconds`: a teleport). Then it
  sets `Delivered`, the score, `lastSeconds`, `newBest` and `best`.
- **`expire`**: ends a running round once the deadline plus grace has
  passed, and returns `true` only if this call changed the phase.
- **`scoreFor`**: `BASE_POINTS + floor(secondsLeft) * POINTS_PER_SECOND_LEFT`.
  Delivered 47.3 seconds after the start: 42.7 seconds left, floored to
  42, so 100 + 42 × 10 = **520**. In the grace window no time is left: 100.
- **`chooseTarget`**: drops the previous destination (unless that leaves
  nothing) and returns `choices[randomIndex(#choices)]`. Randomness is
  passed in: the server passes a function that uses Roblox's `Random`; a
  test passes `function() return 1 end` and knows the answer.

There is no Roblox code here (time is a number, randomness a function), so
`tests/RoundLogic.spec.luau` checks every rule on your Mac in milliseconds.

**Q3.1 What stops a player from pressing Start twice to reset the timer?**
<details><summary>Answer</summary><code>RoundLogic.start</code> refuses with <code>AlreadyRunning</code> and leaves the
deadline alone. RoundService also ignores Start during a round and within <code>START_COOLDOWN_SECONDS</code>.
The HUD's half-second debounce only stops accidental double clicks; a cheater can skip it.</details>

**Q3.2 A delivery happens with 12.9 seconds left. What is the score?**
<details><summary>Answer</summary>12.9 floors to 12, so 100 + 12 × 10 = 220.</details>

## 4. Main.server.luau

[`src/server/Main.server.luau`](../src/server/Main.server.luau) runs once
when the server starts:

1. Use `Workspace.CampusMap`, or build it with `MapBuilder.build`.
2. Check it with `MapContract.find`, warning `Map problem: ...` for each
   problem.
3. Create the prompts and the remotes.
4. Call `RoundService.start` and print
   `[CampusDeliveryDash] Ready: 6 destinations, 90-second rounds.`

If something essential is missing, it warns "The game did not start. Fix
the map problems above, then press Play again." and `return` stops the
script before step 3. With no remotes, every client shows **Setup problem**
after 30 seconds (case T14 in [`TEST-PLAN.md`](TEST-PLAN.md)).

**Q4.1 You rename Depot to DepotX in a saved map and press Play. What happens?**
<details><summary>Answer</summary>Output warns <code>Map problem: Workspace.CampusMap needs a part
named Depot</code> and "The game did not start...", with no Ready line. After about 30 seconds of
"Connecting to the server...", the screen shows <b>Setup problem</b>.</details>

**Q4.2 Why are the remotes created only after the map check passes?**
<details><summary>Answer</summary>The client treats "no remotes after 30 seconds" as the sign that
the server failed to start (<code>Net.waitForRemotes</code>), so it shows a clear setup problem
instead of a game that cannot work.</details>

## 5. MapBuilder.luau (skim)

[`src/server/MapBuilder.luau`](../src/server/MapBuilder.luau) builds the
greybox campus when Workspace has no `CampusMap`. Enough to tweak it:

- **`BUILDINGS`** lists the six buildings (`id`, `displayName`, `position`,
  `size`, `color`, optional `terraceHeight`). Most tweaks happen here; to
  edit the map by hand in Studio instead, see [`SETUP.md`](SETUP.md).
- **`newPart`** makes an anchored part from a small table of settings, so
  every part is built the same way.
- **`addBuilding`** makes a `CFrame.lookAt(...)` from the building to the
  plaza centre and places the door, sign and mailbox relative to it with
  `at(x, y, z)` (negative `z` is the front, toward the plaza). Only the
  Science Hall has `terraceHeight = 8`: a terrace, reached by a ramp from
  `addRamp`.
- **Mailboxes** are named after the `id`, go into `Destinations` and get a
  `DisplayName` attribute. Paths, trees and hedge gaps are computed in
  `build` from where each building is.
- **Streaming.** With instance streaming on, Roblox sends each player only
  nearby parts. `ModelStreamingMode = Persistent` always sends the whole
  map, so every prompt exists for every player.

**Q5.1 You change the Gym's `position`. Must you also move its door, mailbox and path?**
<details><summary>Answer</summary>No. They are placed relative to the building's facing; the path and hedge gap are computed.</details>

**Q5.2 Why is the map set to `Persistent`?**
<details><summary>Answer</summary>So a far-away mailbox and its prompt always exist on every player's device.</details>

## 6. MapContract.luau

[`src/server/MapContract.luau`](../src/server/MapContract.luau) knows the
map contract: `CampusMap` must hold `StartPad`, `Depot` and a
`Destinations` folder. Everything else is scenery.

- **`asPart`**: a BasePart stands for itself, a Model for its
  `PrimaryPart`, so a Blender model can later replace a plain part.
- **`find`** returns the parts and a list of problems. Missing essentials
  are fatal; a child that is not a part, or a duplicate name, is skipped
  with a warning.
- **`createPrompts`** puts "Pick up package" on the Depot and "Deliver
  package" on each destination. Every prompt gets the tag
  `CampusDeliveryDashPrompt` and a `Kind` attribute (`Depot` or
  `Destination`), plus `TargetId` on destinations. They are for the
  client: `Marker` finds prompts by tag and reads the attributes to decide
  which to show. The server never reads them; each prompt's target is
  fixed when `RoundService.start` connects it.

**Q6.1 You replace the Library mailbox part with a Model. What does it need?**
<details><summary>Answer</summary>The name <code>Library</code>, a place in <code>Destinations</code> and a
<code>PrimaryPart</code>. A <code>DisplayName</code> attribute is optional.</details>

**Q6.2 A cheater changes a prompt's `TargetId` on their own device. Can they deliver anywhere?**
<details><summary>Answer</summary>No. The change stays on their device, and the server does not use the attribute.</details>

## 7. Net.luau

[`src/shared/Net.luau`](../src/shared/Net.luau) is the network contract. A
remote is how a client and the server message each other. There are three:
`StartRound` (client to server, no arguments), `GetRoundState` (the client
asks, the server answers with a `Snapshot`) and `RoundState` (server to one
client, a `Snapshot`). No remote accepts a score, time, position or phase,
because a modified client can send anything through a remote. Pickups and
deliveries come through prompts, which the server re-checks. A `Snapshot`
holds what the client needs to draw (`phase`, `deadline`, `objective`,
`targetName`, scores and more). `seq` goes up by one with every snapshot
for that player, and clients keep only the newest.

**Q7.1 A cheater fires `StartRound` with `("score", 99999)`. What happens?**
<details><summary>Answer</summary>The extra values are ignored: it is the same as pressing Start (test case T12).</details>

**Q7.2 Why does the snapshot hold the `deadline`, not the seconds left?**
<details><summary>Answer</summary>Each client works out the time left every frame from
<code>Workspace:GetServerTimeNow()</code>, a clock shared with the server, so the server only sends
a snapshot when something changes.</details>

## 8. RoundService.luau

[`src/server/RoundService.luau`](../src/server/RoundService.luau) runs every
player's round. `sessions` maps each player to a `Session`: their `round`,
a snapshot counter `seq`, their last Start press, and the `Best` value in
`leaderstats` (the player list). Separate sessions let several players play
at once.

- **`getLivingRoot`** returns the character's `HumanoidRootPart`, or nil
  without a living character. **`isNear`** allows `PROMPT_DISTANCE +
  PROMPT_DISTANCE_TOLERANCE + part.Size.Magnitude / 2` studs (about 18 for
  a mailbox), because the server sees each character slightly behind
  where the player sees it. **`refuse`** sends the matching `MESSAGES` line.
- **Start presses:** the `StartRound` handler drops presses within
  `START_COOLDOWN_SECONDS` of the last one. **`startRound`** then ignores a
  press during a round, and says "Wait until your character has respawned."
  without a living character. Then it calls `chooseTarget` (with
  `random:NextInteger`) and `RoundLogic.start`, uses `PivotTo` to put the
  character just above the `StartPad` facing the Depot (so scores are
  comparable), and calls `scheduleTimeUp`.
- **`onDepotTriggered`** and **`onDestinationTriggered`** silently ignore a
  trigger without a session, a living character or `isNear`, then call
  `RoundLogic`. A delivery passes `minTravelSeconds = distance(mailbox,
  Depot) / MAX_TRAVEL_SPEED`: 192 studs gives 6 seconds, while walking it
  at 16 studs per second takes 12.
- **`scheduleTimeUp`** runs `check` after `ROUND_SECONDS + GRACE_SECONDS`.
  `check` stops if the player left or `roundId` changed, otherwise calls
  `endRoundIfExpired`, and checks again shortly if it woke a moment early.
- **Respawning:** `onCharacterAdded` re-attaches the package in
  `ToDropoff`. **Leaving:** `PlayerRemoving` deletes the session, and
  pending timers notice and stop.

**Q8.1 Why does `scheduleTimeUp` compare `roundId`?**
<details><summary>Answer</summary>A timer belongs to one round. Deliver round 1 early and start
round 2: round 1's timer still wakes up later, and the check makes it stop without touching round
2, which has its own timer. (<code>expire</code> also re-checks the deadline, so today a stale timer
would only cause extra checks, but this keeps each timer to its own round.)</details>

**Q8.2 A player teleports to the right mailbox, 192 studs from the Depot, 2 seconds after pickup. What happens?**
<details><summary>Answer</summary>2 is less than 192 / 32 = 6, so <code>deliver</code> returns
<code>TooFast</code>: "Delivery refused: that trip was impossibly fast." The round continues.</details>

**Q8.3 Why does a player who dies keep the package?**
<details><summary>Answer</summary>Carrying is the <code>ToDropoff</code> phase, stored in the
session, not the character, so <code>onCharacterAdded</code> attaches a package to the new
character. The timer kept running, so dying only cost time.</details>

## 9. PackageVisual.luau

[`src/server/PackageVisual.luau`](../src/server/PackageVisual.luau) shows
the box in the character's hands. It is only a visual: whether a player
"has" the package is the server's `ToDropoff` phase, never this part.
`attach` welds a `CarriedPackage` to the `HumanoidRootPart`, in front of
the chest, with a `WeldConstraint`. It is `Massless`, with collisions,
touches and queries off, so it never changes how the character moves. A
single part named `PackageTemplate` in ServerStorage replaces the default
box.

**Q9.1 A cheater deletes `CarriedPackage` on their own device. Can they still deliver?**
<details><summary>Answer</summary>Yes, if they picked it up: the server only checks the phase. A fake box does not help either.</details>

**Q9.2 Why is the box `Massless`?**
<details><summary>Answer</summary>So it adds no weight and does not change how the character walks or jumps.</details>

## 10. Main.client.luau

[`src/client/Main.client.luau`](../src/client/Main.client.luau) runs on each
player's device and never decides anything. It creates the HUD (whose
button only calls `StartRound:FireServer()`) and the marker. If
`Net.waitForRemotes` finds no remotes within 30 seconds, the script calls
`hud.showSetupProblem()` and stops. Otherwise it connects `RoundState`,
then fetches the first snapshot with `GetRoundState` inside `pcall`, so a
failure warns instead of stopping the script. `apply` drops any snapshot
whose `seq` is not newer. Every frame, `RunService.RenderStepped` updates
the countdown (`hud.tick`) and the guide line (`marker.update`).

**Q10.1 Why does `apply` compare `seq`?**
<details><summary>Answer</summary>The reply to <code>GetRoundState</code> may arrive after a newer
<code>RoundState</code> event. Without the check, it could put the HUD back a step.</details>

**Q10.2 What does the player see if the server never creates the remotes?**
<details><summary>Answer</summary>"Connecting to the server..." for 30 seconds, then <b>Setup problem</b>.</details>

## 11. Hud.luau

[`src/client/Hud.luau`](../src/client/Hud.luau) builds the interface in
code, so it can be reviewed as text: a top bar (objective and timer), a
message line, and a centre panel with one button.

- **`ResetOnSpawn = false`** keeps the HUD when the character respawns.
- **The debounce** ignores presses within `BUTTON_DEBOUNCE_SECONDS` (0.5).
- **`render`** shows the top bar during a round, otherwise the panel:
  "Delivered!" or "New best!" with **Play again**, "Time's up!" with **Try
  again**, or the title with **Start delivery**.
- **`tick`** sets the timer text every frame, red at 10 seconds or less.
- **`formatClock`** rounds up with `math.ceil` and formats `"%d:%02d"`: 90
  shows 1:30, 42.7 shows 0:43, 0.2 shows 0:01, and only 0 shows 0:00.

**Q11.1 What does `formatClock(59.1)` show?**
<details><summary>Answer</summary>59.1 rounds up to 60, so <code>1:00</code>.</details>

**Q11.2 If you deleted the debounce, could a fast clicker start two rounds?**
<details><summary>Answer</summary>No. The server ignores Start during a round and within <code>START_COOLDOWN_SECONDS</code>.</details>

## 12. Marker.luau

[`src/client/Marker.luau`](../src/client/Marker.luau) shows where to go: a
tall beacon (orange over the Depot, green over the destination), a label
with the place name and distance, and a guide line (a Beam) from your
character. It exists only on your device. `render` enables only the prompt
the current step needs; `update` runs every frame to follow the character
after a respawn and refresh the distance. Its `PROMPT_TAG` must match
MapContract's. Hiding prompts is a convenience, not security.

**Q12.1 What would happen if Marker did not hide prompts? Would cheating become possible?**
<details><summary>Answer</summary>Every prompt would show all the time, which is confusing. Using
the wrong one only brings a message such as "Wrong address. This package goes to ..." or "Pick up
the package at the Depot first." Cheating would not become possible: the server re-checks the
phase, target, distance and time on every trigger. A cheater can show hidden prompts on their own
device anyway; test case T16 does exactly that.</details>

**Q12.2 Can Player2 see Player1's green beacon?**
<details><summary>Answer</summary>No. Player1's client script made it, so it exists only on Player1's device.</details>

## 13. The tests

`tests/run.luau` runs the `Config.spec` and `RoundLogic.spec` suites with
`TestKit`, a tiny helper (`suite`, `test`, `equal`, `truthy`, `run`), and
errors if any test failed. `RoundLogic.spec` uses its own `RULES` table,
starts rounds at `T = 1000`, and has the helpers `startedRound` and
`carryingRound` (picked up at `T + 5`). After `tools/install-dev-tools.sh`,
run just the unit tests from the project folder with
`.tools/bin/luau tests/run.luau`. Each test prints `ok` or `FAIL`, then a
total such as `30 passed, 0 failed`. A failure (`ok` lines left out):

```
  FAIL  Config: a round lasts 90 seconds, as the project brief specifies
        ./tests/Config.spec.luau:12: ROUND_SECONDS: expected 90, got 60
29 passed, 1 failed
1 test(s) failed
```

Read it as: which test, the file and line of the failing check, its label,
then expected against actual. The stack trace after it is only the runner.

**Q13.1 Why does `RoundLogic.spec` use its own `RULES` instead of `Config`?**
<details><summary>Answer</summary>So the rule tests use known numbers and do not break when you
tune Config. <code>Config.spec</code> guards the values the brief depends on.</details>

**Q13.2 In the failure above, where is the bug?**
<details><summary>Answer</summary>In <code>Config.luau</code> (60, not 90). <code>Config.spec.luau:12</code> is just the check that caught it.</details>

## Try it yourself

Small, safe changes. Undo each one afterwards unless you mean to keep it
(`git restore <file>`). After any edit in `src/`, `tools/check.sh` reports
the Studio installer as out of date until you run `tools/check.sh --fix`.

1. **Shorter rounds.** Set `ROUND_SECONDS = 60` and run
   `.tools/bin/luau tests/run.luau`. *Expected:* one failure, the Config
   test above (`RoundLogic` tests use their own `RULES`). The brief promises
   90 seconds, so a real change updates `PROJECT-BRIEF.md` and
   `tests/Config.spec.luau` together, as its own task. Otherwise revert.
2. **Predict a score.** Set `POINTS_PER_SECOND_LEFT = 5` and predict the
   score with 42.7 seconds left. *Expected:* 100 + 42 × 5 = 310, and every
   test still passes (why? see Q13.1). To see it in a round, run
   `tools/check.sh --fix` and reinstall ([`SETUP.md`](SETUP.md)). Revert.
3. **Deliver exactly at the deadline.** In `tests/RoundLogic.spec.luau`,
   copy the test "a delivery inside the grace period still counts, for
   base points" and make it deliver at `T + 90`. Predict first.
   *Expected:* 31 passed, with a score of 100: no whole seconds are left,
   but the grace period has not run out. This test is worth keeping.
4. **A seventh destination.** Add an entry to `BUILDINGS` in
   `MapBuilder.luau`, for example `id = "Observatory"` at
   `Vector3.new(-150, 0, 200)`, with a `displayName`, `size` and `color`
   like the others. Check:
   - [ ] The `id` is unique: it becomes the mailbox's name, and a
     duplicate is skipped with a warning.
   - [ ] It is on the ground (`GROUND_SIZE` is 640, so stay well inside
     ±320) and as far out as the others, 225 to 255 studs from the centre.
   - [ ] In Studio, its path, trees and hedge gap appear by themselves;
     check that they miss the other paths and the benches.
   - [ ] If your place has a saved `CampusMap`, test in a backup copy
     without it, or MapBuilder will not run.

   *Expected:* `Ready: 7 destinations, 90-second rounds.` The brief says
   six buildings, so keeping it is a scope change for `TASK.md`.
