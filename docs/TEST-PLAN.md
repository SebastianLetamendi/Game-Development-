# Test plan

Checks to do by hand in Roblox Studio. `tools/check.sh` proves the code
builds and the rules add up; only playing shows that the game works. These
cases cover every test [`PROJECT-BRIEF.md`](../PROJECT-BRIEF.md) requires.

## How to use this plan

1. Install the scripts into a private Baseplate place, after saving a backup
   copy ([`SETUP.md`](SETUP.md)). Do T1 to T4 (the core round) first.
2. Record each result in [`STATUS.md`](../STATUS.md) with the table at the
   end: **pass**, **fail** plus what happened (copy red or orange Output
   lines exactly, but replace your Roblox username with Player1: the
   repository is public), or **not tried**. Also list failures under "Known
   failures and risks".
3. Never mark a case as passed unless you saw it pass yourself. An agent
   saying "this should work" is not a result.

## Studio tools you will use

Studio's menus move between versions: if a button is not where this table
says, look for the same name in the other tabs.

| Tool | Where | Used for |
|---|---|---|
| **Play** | Home or Test tab, or F5 (fn+F5 on a Mac keyboard; add Shift to stop) | You and the server in one window |
| **Output** | View tab | Script messages: red lines are errors, orange lines are warnings |
| **Explorer**, **Properties** | View tab | Seeing objects and changing their properties |
| **Clients and Servers** | Test tab: choose 2 players, then Start | A server window plus one window per player (Player1, Player2) |
| **Device emulator** | Test tab (Device) | Playing as a phone or tablet with touch controls |
| **Command Bar** | View tab | Running one line of Luau code |
| **Reset Character** | Press Esc while playing to open the Roblox menu | Making your character die and respawn |

The Command Bar runs code in the window you type it in. In a Clients and
Servers test, the server window's runs on the server and a player window's
runs on that player's client, where it can do what a cheater's modified
client could (T12, T13, T16). In Edit mode it changes the place itself.

## T1. The server starts cleanly
**Goal:** the scripts load and nothing errors. **Milestone:** 1.
1. Open the Output window and press **Play**.

**Expected:** `[CampusDeliveryDash] Ready: 6 destinations, 90-second rounds.`
and no red lines (two lines about building the greybox map may come first).
The panel shows **Campus Delivery Dash**, "Pick up the package at the Depot,
then follow the marker and deliver it before the 90-second timer runs out."
and **Start delivery**. The player list shows **Best** 0.

## T2. Happy path, solo on desktop
**Goal:** one full delivery with a correct score. **Milestones:** 2 and 3.
1. Click **Start delivery**. Walk to the Depot (orange counter, DEPOT sign)
   and hold **E** at the **Pick up package** prompt.
2. Follow the beacon to the mailbox and hold **E** at **Deliver package**.

**Expected:**
- On Start: you jump to the green START pad, the top bar counts down from
  1:30 with "Pick up the package at the Depot" under the time, and an orange
  `DEPOT` beacon (with the distance in studs) and a guide line show the way.
- After pickup: you carry a brown box, the top bar says "Deliver the package
  to" plus a building, and a green beacon with its name in capitals (for
  example `SCIENCE HALL`) stands over its mailbox.
- After delivery: the box goes and the panel shows **New best!** (or
  **Delivered!** if Best was not beaten), "Delivered to ... in ... seconds.",
  `Score 680   ·   Best 680` with your numbers, and **Play again**.
- Score = 100 + 10 × whole seconds left, where seconds left = 90 − the time
  shown: 31.4 seconds leaves 58.6, so 100 + 580 = 680. If the time ends in
  .0 the score can be 10 lower, because the panel rounds the time.

## T3. Time runs out
**Goal:** the failure path and Try again. **Milestone:** 3.
1. Start a round, pick up the package and wait. Then click **Try again**.

**Expected:** the timer turns red at 0:10. Less than a second after 0:00
(the server allows a short grace for a last-moment delivery) the top bar and
box disappear, and the panel shows **Time's up!**, "The package didn't
reach" plus the building, the unchanged Best, and **Try again**, which
starts a new round at 1:30. If you let a round run out without picking up
the package, the panel says "You didn't reach the Depot in time." instead.
(Delivering at 0:01 would score exactly 100.)

## T4. Restart picks a new destination
**Goal:** replays never repeat the last destination. **Milestones:** 1 and 3.
1. Play at least five rounds with **Play again**, noting each destination.
   For milestone 1, tick off Library, Science Hall, North Dorm, Cafeteria,
   Gym and Art Studio; walk to any you missed outside a round.

**Expected:** each round starts from the START pad at 1:30, and no
destination matches the round before (it can come back later). Best, on the
panel and in the player list, is your highest score until you stop (it is
not saved yet). Every building is reachable on foot, including Science
Hall's ramp and the way around the Cafeteria path's road works.

## T5. Pressing Start repeatedly
**Goal:** mashing Start cannot start two rounds. **Milestones:** 3 and 4.
1. Click **Start delivery** five or more times, fast. After the round, do
   the same with **Play again** or **Try again**.

**Expected:** one round starts each time. The timer counts down smoothly
from 1:30, never jumps back, and you are not pulled back to the START pad.
The button is hidden during a round; T12 sends Start anyway.

## T6. Only the right prompt shows
**Goal:** players see only the prompt they need. **Milestone:** 2.
1. Before starting, visit the Depot and the nearest mailbox. Then start a
   round, pick up the package, and visit a wrong mailbox and your own.

**Expected:** no prompts before the round. During it, only the Depot shows
**Pick up package** until pickup. After pickup the Depot and the wrong
mailbox show nothing, and only your destination shows **Deliver package**.

## T7. Respawn while carrying the package
**Goal:** dying does not end the round or lose the package. **Milestone:** 3.
1. Start a round and pick up the package. Press Esc, choose **Reset
   Character** and confirm. Deliver after the respawn.

**Expected:** the timer keeps counting down throughout and the HUD stays on
screen. The new character carries the box again, the guide line starts from
it, and the delivery is accepted.

## T8. Respawn before pickup, and Start while dead
**Goal:** the round survives an early respawn. **Milestone:** 3.
1. Start a round, reset before reaching the Depot, then pick up and deliver.
2. On the results panel, reset and click **Play again** while still dead.

**Expected:** in step 1 the timer keeps running, the orange beacon stays on
the Depot, the new character has no box, and the round finishes normally.
In step 2 the message "Wait until your character has respawned." appears in
yellow on the results panel, just above the button, and no round starts;
after the respawn, Play again works.

## T9. Two players at once
**Goal:** each player has their own round. **Milestones:** 3 and 4.
1. In a 2-player Clients and Servers test, start a round as Player1, then as
   Player2. Deliver with Player1 and let Player2's round run out.

**Expected:** each window has its own timer, destination (chosen separately,
so they may match), beacon and prompts, and sees the other's carried box.
Neither round affects the other, each player has their own Best, and the
server Output has no red lines. If both press Start at the same moment,
they land side by side on the START pad, not inside each other.

## T10. A player leaves mid-round
**Goal:** leaving does not break the game for others. **Milestone:** 4.
1. In a 2-player test, both players start a round and Player2 picks up.
2. Close Player2's window. If Player2 stays in the player list, run
   `game.Players.Player2:Kick()` in the server window's Command Bar.
3. Keep playing as Player1 until 90 seconds after Player2 started.

**Expected:** Player2 and their box disappear, Player1's round finishes
normally, and the server Output has no red lines, including when Player2's
timer would have run out.

## T11. Touch controls
**Goal:** a touch player can finish a round. **Milestones:** 2, 3 and 5.
1. Turn on the device emulator, choose a phone and press **Play** (a click
   counts as a tap). Use the on-screen joystick, tap **Start delivery**, and
   tap and hold each prompt briefly. Repeat with a tablet.

**Expected:** the joystick and jump button appear and taps work. The top
bar, timer, messages and panel are readable, easy to tap, and not covered
by the joystick, jump button or Roblox's own buttons.

## T12. Invalid requests from a client
**Goal:** a modified client cannot award itself points. **Milestone:** 4.
1. Start a 2-player Clients and Servers test. In Player1's Explorer, open
   ReplicatedStorage > CampusDeliveryDash > Remotes.
2. On the title panel, run this in Player1's Command Bar, then run it again
   a few seconds into the round:
   ```lua
   game.ReplicatedStorage.CampusDeliveryDash.Remotes.StartRound:FireServer("score", 99999)
   ```
3. Run `game.Players.LocalPlayer.leaderstats.Best.Value = 99999`, then
   finish the round with a delivery.

**Expected:** Remotes holds only StartRound, RoundState and GetRoundState;
none accepts a score. The first run starts an ordinary round, Best
unchanged; the second does nothing and the timer keeps going. In step 3,
until the delivery only Player1's own player list shows 99999: Player2 and
the server window (Players > Player1 > leaderstats) keep the real Best.
After the delivery, the results panel and every player list show the
server's score and Best. The server Output has no red lines.

## T13. A teleport delivery is refused
**Goal:** jumping straight to the mailbox does not count. **Milestone:** 4.
1. In a 1-player Clients and Servers test, paste this into the player
   window's Command Bar without pressing Return. It moves you next to the
   mailbox whose **Deliver package** prompt is showing:
   ```lua
   for _, p in game:GetService("CollectionService"):GetTagged("CampusDeliveryDashPrompt") do if p.Enabled and p:GetAttribute("Kind") == "Destination" then game.Players.LocalPlayer.Character:PivotTo(p.Parent.CFrame * CFrame.new(0, 0, -5)) end end
   ```
2. Start a round and pick up the package. Within about 6 seconds, press
   Return in the Command Bar, click the game view and hold **E** at
   **Deliver package**.

**Expected:** "Delivery refused: that trip was impossibly fast." appears and
the round goes on, box and timer unchanged. A retry a few seconds later is
accepted: the server only refuses trips faster than `MAX_TRAVEL_SPEED` (32
studs per second) allows, about 6 to 8 seconds here, an accepted risk (see
[`ARCHITECTURE.md`](ARCHITECTURE.md)). If the first try was accepted, you
were too slow: retry before recording a fail.

## T14. A map problem is reported clearly
**Goal:** a broken map stops the game with a clear message. **Milestone:** 1.
1. Save a backup. If Workspace has no CampusMap, build an editable one: in
   Edit mode, run this in the Command Bar, then save the place:
   `require(game.ServerScriptService.CampusDeliveryDash.MapBuilder).build(workspace)`
2. Rename Workspace > CampusMap > Depot to `DepotX`. Press **Play**, wait
   30 seconds, then stop, rename it back to `Depot` and play again.
3. Press **Stop**. Untick **Anchored** on Workspace > CampusMap >
   Destinations > Gym, press **Play**, then stop and tick it again.

**Expected:** the first Play warns
`[CampusDeliveryDash] Map problem: Workspace.CampusMap needs a part named Depot`
and `[CampusDeliveryDash] The game did not start. Fix the map problems above, then press Play again.`
with no Ready line. After about 30 seconds of "Connecting to the server...",
the panel says **Setup problem**, "The game did not start on the server. In
Studio, open the Output window to see why." The second Play prints the
Ready line again. In step 3 the warning is
`[CampusDeliveryDash] Map problem: Workspace.CampusMap.Destinations.Gym must be Anchored (or welded to an anchored part)`
and the game does not start, because a loose mailbox could be dragged
around by a cheater.

## T15. Instance streaming
**Goal:** prompts and the beacon work far away with instance streaming
(Roblox sends players only nearby parts of the world). **Milestones:** 1, 2.
1. In Edit mode, check that Workspace's **StreamingEnabled** is ticked in
   Properties (new places have it on). If you had to tick it, untick it
   after the test. With an editable map (T14), check
   that CampusMap's **ModelStreamingMode** is `Persistent`.
2. Play until you deliver to a far building, such as North Dorm.

**Expected:** the beacon and distance label show over the far mailbox even
from the plaza, **Deliver package** appears there, and the delivery counts.

## T16. Wrong address and out-of-order prompts
**Goal:** the server re-checks prompts a modified client shows.
**Milestone:** 4. In a 1-player Clients and Servers test, this line in the
player window's Command Bar shows every prompt. Run it before each hold:
```lua
for _, p in game:GetService("CollectionService"):GetTagged("CampusDeliveryDashPrompt") do p.Enabled = true end
```
1. Before starting a round, hold **E** at the Depot.
2. Start a round and, before pickup, hold **E** at the nearest mailbox.
3. Pick up the package, then hold **E** at the Depot again.
4. Hold **E** at a mailbox that is not your destination.

**Expected:** in order, "Press Start to begin a delivery.", "Pick up the
package at the Depot first.", "You are already carrying a package." and
"Wrong address. This package goes to" plus your destination. Each time, the
round carries on unchanged.

## Results table for STATUS.md

Copy into `STATUS.md`: **pass**, **fail** (with what happened) or **not tried**.

| Case | Date | Result | Notes |
|---|---|---|---|
| T1 Server starts cleanly | | | |
| T2 Happy path, desktop | | | |
| T3 Time runs out | | | |
| T4 Restart, new destination | | | |
| T5 Pressing Start repeatedly | | | |
| T6 Only the right prompt shows | | | |
| T7 Respawn while carrying | | | |
| T8 Respawn before pickup | | | |
| T9 Two players at once | | | |
| T10 Player leaves mid-round | | | |
| T11 Touch controls | | | |
| T12 Invalid client requests | | | |
| T13 Teleport delivery refused | | | |
| T14 Map problem reported | | | |
| T15 Instance streaming | | | |
| T16 Wrong address and prompts | | | |
