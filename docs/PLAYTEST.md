# Playtesting

How to run playtests of Campus Delivery Dash and turn what you see into the
next task. [TEST-PLAN.md](TEST-PLAN.md) checks that the game works. A
playtest checks something else: whether a new player understands the game,
finishes a round and wants to play another one.

## When to playtest

1. **Solo, in Studio, first.** Work through [TEST-PLAN.md](TEST-PLAN.md)
   and record the real results in [STATUS.md](../STATUS.md). Fix anything
   that stops a round from finishing before anyone else plays.
2. **Outside testers once milestones 1 to 5 hold up** (see the milestones in
   [PROJECT-BRIEF.md](../PROJECT-BRIEF.md)). An outside tester is anyone who
   has not watched the game being built. Before that, they mostly find bugs
   you could have found yourself.
3. **Aim for five outside testers.** The brief's goal is "Five outside
   testers complete a round without help", and milestone 6 is done when
   outside testers finish a round without coaching.

Before each session, play T1 to T4 of the test plan once, so you know the
build in front of the tester works.

## Getting outside testers in safely

There are two ways to let someone play:

| Way | What you need | Good for |
|---|---|---|
| In person, on your computer | Nothing new: they press **Play** in Studio while you watch | Your first one or two testers |
| On their own device | The game published with a limited audience, and the tester given playtest access | Phones, tablets, testers who live elsewhere |

Setting up a limited audience is your job, not an agent's: `AGENTS.md`
says agents must not publish the game or change Creator Dashboard settings.

1. **Check Roblox's current publishing requirements first.** They change.
   When this guide was written, limited access needed account and age checks
   plus the content questionnaire. Read Roblox's
   [publishing guide](https://create.roblox.com/docs/production/publishing/publish-games-and-places)
   and look at the Audience settings in the Creator Dashboard before you
   start. This project has no budget: if the dashboard asks you to pay for
   something, stop and find out what it is for.
2. **Publish the place from Studio**, after saving a backup copy. The menu
   differs between Studio versions: look in the File menu, or search Studio
   for "Publish to Roblox".
3. **In the Creator Dashboard**, select the game, then go to
   **Configure > Settings > Audience**. Choose **Limited**, then
   **Playtesters**, and save.
4. **Give the testers you invited playtest access** there.

Two rules:

- **Never give Edit permission just so someone can test.** A private game
  can only be played by its owner and by users with Edit permission, but
  Edit lets them change the game itself. Use the Playtesters audience.
- **Do not buy ads to get players.** If the people you invite do not want a
  second round, ads will not fix that. Fix the game instead.

## Running a session

Keep it short: a few rounds, then three questions. Before the tester
starts, fill in the top of an observation sheet (below), have a clock with
seconds ready, and ask about recording (see the next section). If they play
somewhere else, watch through a video call with screen sharing, with their
permission.

Say this, then stop talking:

> Thanks for helping. I'm testing the game, not you, so nothing you do is
> wrong. Play it as if I weren't here, and think out loud: say what you're
> looking at, what you're trying to do and anything that confuses you. I
> won't answer questions while you play, but I'll answer them all at the
> end. Stop whenever you like.

While they play:

- **Do not coach, point or explain.** If they ask something, reply "What do
  you think?" or "What would you try?"
- If they are stuck for a couple of minutes or getting upset, help them,
  and write down exactly where and what you said. A round you helped with
  does not count as finished without coaching.
- Let them stop when they want to. Whether they press **Play again** or
  **Try again** without being asked is one of the most useful things you
  will learn.

What to watch:

| Watch for | What to note |
|---|---|
| Do they understand the goal? | Do they read the title panel and head for the Depot after **Start delivery**? |
| How long the first delivery takes | Time the pickup yourself. The results panel shows the delivery time: "Delivered to ... in ... seconds." |
| Where they get confused or quit | The exact place and moment, and what they said, word for word |
| Do they choose to replay? | Whether they press **Play again** or **Try again** on their own |
| Any bug | What they did just before it. In Studio, copy any red Output lines exactly |

When they stop, ask:

1. "In your own words, what were you supposed to do?"
2. "What was the most confusing moment?"
3. "Would you play again? Why or why not?"

## Privacy and consent

- **Ask before recording** a tester's screen, voice or face, and say what
  the recording is for, such as a build-in-public video. If they say no,
  take written notes only.
- **If a tester is under 18,** ask a parent or guardian for permission too,
  before the session.
- **Never put real names or Roblox usernames in this repository.** It is
  public. Give each tester an ID instead: T1, T2, T3 and so on, in the order
  they play. In `STATUS.md`, write "tester T1" so nobody mixes it up with
  test case T1 in [TEST-PLAN.md](TEST-PLAN.md).
- **Keep notes private** if they contain anything personal. Store filled-in
  sheets and recordings outside the repository folder, and put only an
  anonymous summary in `STATUS.md`.
- **Check recordings before using them.** Roblox shows names above
  characters and in the player list. Crop or blur them, and only use
  footage of people who agreed. Video workflow: [VIDEOS.md](VIDEOS.md).

## Observation sheet

Copy one sheet per tester. Times are from pressing **Start delivery**.

```markdown
# Playtest: tester T_

- Date:
- Device: (computer with keyboard and mouse / phone / tablet)
- Played Campus Delivery Dash before? (no / yes, how often)
- Recording allowed? (no / screen / screen and voice)

## What happened
- Time to first pickup:
- Time to first delivery: (seconds on the results panel, and which round)
- Rounds played:
- Replayed without being asked? (yes / no)
- Best score:
- Coaching given: (none / where, and what you said)

## Notes
- Where confused (quote what they said):
- Bugs seen (and what they did just before):
- One thing they liked:
- One thing to change:
```

## After the session

Finish the sheet straight away, while you remember. When you have notes
from a few testers:

1. **Group the notes.** List every confusion, quit point and bug once, and
   count how many testers hit each one.
2. **Pick one.** Choose the single biggest confusion or blocker: the one
   that stopped the most people finishing a round. If two are close, pick
   the one that happens earlier in the round, because it hides later ones.
3. **Write it as the next task.** Copy the template at the end of
   [TASK.md](../TASK.md) over the current task. Describe what testers did
   in **Why**, using tester IDs, and make each acceptance criterion
   something you can see in Studio.
4. **Record the results in STATUS.md:** the date, how many testers, how
   many finished a round without coaching, how many replayed on their own,
   the main findings, and any bugs (also under "Known failures and risks").
   Mark milestone 6 as verified only when outside testers finish a round
   without coaching.
5. **Park everything else** under "Ideas parked" in `STATUS.md`.
6. **Retest with someone new** after the fix. A returning tester already
   knows the answer.

An example **Why** line (made up): "3 of 5 testers (T1, T2, T4) walked
toward the buildings before picking up the package. T2 said 'where's my
package?'"

Keep the order right:

- **Fix confusion before adding features.** If players cannot finish a
  round, that comes before anything else.
- **No cosmetics or paid items** until players finish rounds and come back
  on their own. Paid items are out of scope for version 1 anyway. Best
  scores are not saved between sessions yet, so a returning player starts
  from Best 0.

## Tuning knobs

Many fixes are one number in
[`src/shared/Config.luau`](../src/shared/Config.luau). Change one thing at
a time, as its own task. Then run `tools/check.sh --fix` and
`tools/check.sh`, reinstall ([SETUP.md](SETUP.md)), and play it yourself
before the next tester.

| Finding | Change | Watch out |
|---|---|---|
| Everyone finishes with lots of time left, or nobody finishes (timer too generous or too harsh) | `ROUND_SECONDS` (90) | `tests/Config.spec.luau` asserts 90 and the brief promises 90 seconds, so change both in the same task. The Output line `Ready: 6 destinations, 90-second rounds.` follows Config by itself, but every doc that gives the round length must change too, including the T2 score example in TEST-PLAN.md. List them with `grep -rn -e '90-second' -e '90 seconds' -e '1:30' -e 'ROUND_SECONDS. 90' -e '47\.3' -e 'left = 90' --include='*.md' .` |
| Fast and slow deliveries score about the same (scores feel flat) | `POINTS_PER_SECOND_LEFT` (10), compared with `BASE_POINTS` (100) | Score = `BASE_POINTS + floor(secondsLeft) * POINTS_PER_SECOND_LEFT`. The brief states "Score = 100 points + 10 points for every whole second left", so change `PROJECT-BRIEF.md` in the same task. Also update the worked examples in [ARCHITECTURE.md](ARCHITECTURE.md), test plan T2, [CODE-TOUR.md](CODE-TOUR.md) (the 520 example and its quiz) and the comment above `scoreFor` in `RoundLogic.luau`. |
| Testers stand at the Depot or a mailbox but cannot trigger the prompt | `PROMPT_DISTANCE` (10 studs) | First check they were in the right place: `Marker.luau` hides every prompt except the one the current step needs. The server's distance check adds `PROMPT_DISTANCE_TOLERANCE`, so it follows automatically. The hold time is `PROMPT_HOLD_SECONDS` (0.25) in Config; keep it well below `GRACE_SECONDS` (0.75), which `tests/Config.spec.luau` checks. |
| An honest tester sees "Delivery refused: that trip was impossibly fast." | Nothing yet | With the default map and walk speed this should not happen (`MAX_TRAVEL_SPEED` is 32, walking is 16). Record it as a bug instead of raising the number. |

When the problem is finding the way rather than a number:

- **Beacon and guide line** are in `src/client/Marker.luau`:
  `BEACON_HEIGHT` (60), `PICKUP_COLOR` (orange) and `DROPOFF_COLOR`
  (green), the beacon's `Transparency` (0.55) and the guide line's
  `Width0` and `Width1` (0.4).
- **Routes and obstacles** are in `src/server/MapBuilder.luau`. Move a
  building in `BUILDINGS` (its door, mailbox, path and hedge gap follow),
  change the Science Hall's `terraceHeight` (8, which makes the ramp), or
  move the `RoadWorks` barrier on the Cafeteria path. The brief says six
  destinations, so adding or removing one is a scope change.
- **Words on screen:** the title text is in `Hud.luau` (`render`), the
  objective lines such as "Pick up the package at the Depot" are in
  `RoundService.luau` (`snapshot`), and refusal messages are in its
  `MESSAGES` table, except "Wrong address. This package goes to ...",
  which is built in `onDestinationTriggered`.

MapBuilder only runs when Workspace has no `CampusMap`. If your place has a
saved `CampusMap`, edit that in Studio instead, keep the
[map contract](ARCHITECTURE.md#map-contract) intact, and save a backup
first: map edits live in the place file, not in Git.
