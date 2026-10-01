# Project brief: Campus Delivery Dash

## Pitch

A short Roblox game: grab a package at the campus Depot, follow the marker
to the right building and deliver it before the 90-second timer runs out.
Beat your best score.

## Why this project

It is the first game in a learning plan. It is small enough to finish, and
it teaches the core of Roblox development: parts and collisions, events,
round state, timers, UI and, most importantly, why the server must decide
what counts. The real goal is a playable loop the owner can explain line by
line, demonstrate, and use as material for build-in-public videos.

## Version 1 must have

- **One map**: a fictional campus with a Depot, a start pad and six
  destination buildings (Library, Science Hall, North Dorm, Cafeteria, Gym,
  Art Studio).
- **One player action**: carry a package from the Depot to the assigned
  building's mailbox, using on-screen prompts.
- **One failure condition**: the 90-second timer runs out before delivery.
- **One replay reason**: a score that rewards speed and a best score to beat.

### Rules

- A round starts when the player presses **Start delivery**. The character
  is moved to the start pad and a random destination is chosen (never the
  same one twice in a row).
- The player picks up the package at the Depot, then delivers it at the
  chosen building's mailbox.
- Score = 100 points + 10 points for every whole second left. The best score
  of the session is shown after each round and in the player list.
- Dying does not end the round: the player respawns with the package and the
  timer keeps running.
- Each player plays their own round; several players can play at once on
  one server.
- Numbers such as the timer length and points live in
  `src/shared/Config.luau`, so playtest tweaks are one-line changes.

### Controls

- Desktop: normal Roblox movement; hold **E** at a prompt; click the button.
- Touch (phone or tablet): on-screen joystick; tap the prompt; tap the button.

### Content rules

- The campus, building names and art are fictional and original. No real
  school names, logos, mascots or real people.
- Only original or properly licensed assets, sounds and fonts.
- Suitable for all ages: no violence, no chat features beyond Roblox's own.

## Out of scope for version 1

No trading or currency economy, shop, inventory, AI-driven NPCs or other
calls to AI services from the game, multiplayer matchmaking, procedural or
open world, saved progress (DataStores), or paid items. Roblox already runs
multiplayer servers; we only make sure our server logic is correct for
several players.

Ideas for later go in the "Ideas parked" section of `STATUS.md`.

## Milestones

| # | Milestone | What it teaches | Done when |
|---|---|---|---|
| 1 | Greybox route | Parts, properties, movement, collisions | A player can walk the whole route to every building |
| 2 | Pickup and delivery | Variables, functions, events | Pickup and delivery work every time |
| 3 | Round lifecycle | State, timers, UI | Start, finish, fail and restart all work |
| 4 | Client/server behaviour | Replication and validation | A client cannot award itself points |
| 5 | Presentation | Lighting, sound, importing props | New players understand what to do without being told |
| 6 | Playtest | Debugging and prioritising | Outside testers finish a round without coaching |

`STATUS.md` records which milestones are actually verified.

## Testing requirements

Before calling a milestone done, test in Studio: desktop and touch controls
(device emulator), respawning, a player leaving mid-round, pressing buttons
repeatedly, invalid requests from a client, and a second client. Record the
real results in `STATUS.md`. The step-by-step cases are in
`docs/TEST-PLAN.md`.

## Release path

1. Build and test privately in Studio.
2. When milestones 1 to 5 hold up, invite a few outside playtesters using a
   limited audience (see `docs/PLAYTEST.md`). Check Roblox's current
   publishing requirements first.
3. Fix the biggest confusion testers hit before adding anything new.
4. Only after players come back on their own, consider saved best scores, a
   fair cosmetic extra, or a second map.

## Success looks like

- Five outside testers complete a round without help.
- The owner can explain how a delivery is validated and why the score is
  calculated on the server.
- There is real footage of bugs, fixes and playtests to make videos from.
