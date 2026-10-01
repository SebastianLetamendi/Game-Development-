# Build-in-public videos

How to turn the real work on Campus Delivery Dash into short videos: the
tools, a privacy checklist, the workflow, video ideas and the honesty rules.

## The idea

Every video has one subject: **"Building my first game with AI while
learning the code."** Claude Code implements, Codex reviews, and you decide,
test and learn to explain the code ([AGENTS.md](../AGENTS.md)).

- **The material is real work.** Bugs, fixes, prop designs and playtests
  are original footage. The brief lists it as a success goal: "There is
  real footage of bugs, fixes and playtests to make videos from"
  ([PROJECT-BRIEF.md](../PROJECT-BRIEF.md)).
- **Videos are distribution first:** for the game and for a portfolio of
  what you can do. They are not an income plan.
- **Assume $0 from the platforms at the start.** Their payout schemes need
  a large audience first ([thresholds](#monetisation-thresholds)).
- **The game is not public yet.** Say so, and promise no release date.

## Recording with OBS

1. Download [OBS for Apple Silicon](https://obsproject.com/download), open
   the disk image and drag OBS into Applications
   ([OBS installation](https://obsproject.com/kb/mac-installation)).
2. Open OBS. When macOS asks for screen recording and microphone access,
   allow both. If you missed a request, look in System Settings, under
   Privacy & Security; OBS may need a restart afterwards.
3. Capture one window, such as Roblox Studio, rather than the whole
   display, so notifications stay out of the shot. Source names differ
   between OBS versions: look for window capture.
4. In OBS Settings, under Output, set the recording path to a folder
   outside this repository (see [below](#where-video-files-go)).
5. Record a 20-second test and play it back before any long session: check
   the picture, the sound, and that nothing private shows.

## Editing

Use your existing editor if it handles a vertical 1080 x 1920 timeline, or
install [DaVinci Resolve Free](https://www.blackmagicdesign.com/products/davinciresolve).
The paid Studio edition has extra AI features, so do not assume a
tutorial's automatic captions or effects are free. Typing captions by hand
is fine. This project has no budget for paid video or AI video tools.

## Where video files go

Video files are large and this repository is public. Keep recordings,
voice takes and editor project files in
`~/Documents/AI Studio/Videos/recordings/` and finished exports in
`~/Documents/AI Studio/Videos/exports/`, next to your other project
folders ([SETUP.md](SETUP.md#backups-and-git)). `.gitignore` is only a
safety net: it ignores folders named `recordings/` and `exports/` and
`.mov`, `.mp4` and `.mkv` files, but not audio, images or editor project
files. Read `git status` before every commit.

## Before you hit record

A frame that shows a secret stays public once it is uploaded.

- [ ] Email, messages and chat apps closed; a Focus mode such as Do Not
      Disturb on, so no notification pops up.
- [ ] Only the windows you mean to show are open: no tabs for school, work,
      banking or personal accounts, nothing naming your school or home.
- [ ] Terminal is fresh or cleared (Cmd+K): old output can hold tokens,
      sign-in links or file paths. Its prompt shows your Mac user name.
- [ ] No API keys, tokens, passwords, `.env` files or the Roblox cookie
      (`.ROBLOSECURITY`), not even for a second in an editor tab.
- [ ] No account, usage or billing pages for Claude, Codex, Roblox or
      anything else. Screens such as `/status` show account details.
- [ ] Your Roblox account name: the Studio window may show it, and Roblox
      shows names above characters and in the player list. Crop or blur it
      if you prefer. Clients and Servers tests use Player1 and Player2.
- [ ] Nobody else's username, face or voice without their permission, plus
      a parent's or guardian's for anyone under 18
      ([PLAYTEST.md](PLAYTEST.md#privacy-and-consent)).

## The workflow

1. **Record gameplay** while you work: a case from
   [TEST-PLAN.md](TEST-PLAN.md), a fix, a Blender session, a playtest.
2. **Pick one moment.** One bug, one fix, one prop or one finding per video.
3. **Ask the agent for three truthful hooks.** A hook is the opening line
   that makes viewers keep watching. For example, ask Claude Code:

   > Read STATUS.md and docs/TEST-PLAN.md. My clip shows test T13, where
   > the game says "Delivery refused: that trip was impossibly fast."
   > Suggest three opening lines for a vertical video. Each must be true
   > as STATUS.md describes the project. No hype, no claims about money.

   Pick one, put it in your own words and check it against `STATUS.md`.
4. **Write a short explanation** of what happened, why, and what you
   learned, using real names such as `RoundService` or `MAX_TRAVEL_SPEED`.
5. **Record your voice** in a quiet room, after a short test take.
6. **Edit on a 1080 x 1920 timeline** (vertical: 1080 pixels wide, 1920
   tall). Reframe the widescreen recording; crop out anything private.
7. **Correct the captions.** Read every line, typed or automatic.
   Automatic captions often mishear Luau, Roblox Studio or ProximityPrompt.
8. **Export a clean master:** one full-quality file with no platform
   watermarks, in `exports/`. Watch it once against the checklist.
9. **Upload separately to each platform** yourself, and set its disclosure
   options each time. Do not re-post a download from another app. Agents
   must not upload videos or post for you ([AGENTS.md](../AGENTS.md)).

**Keep text away from interface overlays:** each app covers the edges,
mostly the bottom and right, with buttons, your name and the description.
Keep captions nearer the middle, clear of the game's top bar (objective
and countdown). Then **check the video on your phone** before posting.

## Video ideas from this project

Five repeatable concepts, each tied to this repository. Film only what
really happened: nothing has been played in Studio yet
([STATUS.md](../STATUS.md)), so the first playtest is your first chance.

### 1. A mechanic, before and after

[`Marker.luau`](../src/client/Marker.luau) shows a beacon (orange over the
Depot, green over the mailbox), the place name and distance in studs, and a
guide line, and hides every prompt except the one the current step needs.
For a "before" without changing code, run test T16's Command Bar line in a
player window: it switches every prompt on, as if `Marker` did not hide
them. `Marker` hides them again with each update from the server (start,
pickup, delivery, any message), so run the line again just before each
shot. A change made as a task, such as a taller `BEACON_HEIGHT`, works too:
record the old version before Claude Code starts.

### 2. A funny bug and its cause

No bugs are known yet, because nothing has been played: keep OBS running
during the first playtest. Show the bug, the exact red Output line, the
cause in the code, and the fix once `tools/check.sh` passes and you have
played it. Label anything broken on purpose: renaming the Depot to `DepotX`
(test T14) shows the **Setup problem** panel, a planned test, not a bug.

### 3. One Blender prop from scratch

Make one of the five props in [ASSETS.md](ASSETS.md), from Blender to the
game. The package is the most visible: one part named `PackageTemplate` in
`ServerStorage` replaces the carried brown box (`PackageVisual.luau`). Show
the scale check and any import problem you fixed, and say which steps the
Blender connector did and which you did.

### 4. A playtester finds a flaw

A tester's moment of confusion is often the most useful clip, and it leads
straight to the next task ([PLAYTEST.md](PLAYTEST.md)). Use footage only of
testers who agreed to be in a video, blur names, call them by ID
(tester T1), and show the fix and the retest with someone new.

### 5. A challenge: a level with five objects

Can a new player understand a map of only five objects? The scripts need a
`StartPad`, a `Depot` and at least one part in a `Destinations` folder, all
in a model named `CampusMap` ([map contract](ARCHITECTURE.md#map-contract)).
Three mailboxes make five objects, and Output counts them:
`[CampusDeliveryDash] Ready: 3 destinations, 90-second rounds.`
Anchor the parts, set the model's `ModelStreamingMode` to `Persistent`, and
build it in a separate copy of the place (File > Save to File As...): the
game itself keeps its six buildings.

### Bonus: how the server refuses a teleport delivery

The project's main rule: the server decides; clients ask and display.
[Test T13](TEST-PLAN.md#t13-a-teleport-delivery-is-refused) moves you next
to the mailbox with one Command Bar line. The server divides the distance
from the Depot to that mailbox by `MAX_TRAVEL_SPEED` (32 studs per second;
walking is 16), and `RoundLogic.deliver` refuses any quicker trip:
"Delivery refused: that trip was impossibly fast." In test T12, setting
your own Best to 99999 changes only your own screen. Be honest about the
limit: a retry a few seconds later is accepted
([security model](ARCHITECTURE.md#security-model)). Film it only after you
have run T13 yourself.

## Honesty rules

- **Real results only.** No staged bugs presented as accidents, no scores
  you did not get, and no "it works" before you have played it (the same
  rule agents follow in [AGENTS.md](../AGENTS.md)). Label re-creations.
- **Say who did what.** Do not claim the AI did something it did not, or
  that you did what the AI did.
- **No revenue claims.** No promises or hints of earnings you have not made.
- **Disclose realistic synthetic content where the platform requires it**,
  such as a realistic AI voice or person. Read the current rules for
  [YouTube](https://support.google.com/youtube/answer/14328491?hl=en-au) and
  [TikTok](https://newsroom.tiktok.com/new-labels-for-disclosing-ai-generated-content-ca?lang=en-CA).
- **Only owned or properly licensed music, visuals and voices.** Your own
  voice and game footage are the simplest choice.
- **No repetitive, mass-produced or barely changed content.** Original
  AI-assisted videos may qualify for monetisation, but mass-produced videos
  or the same clip re-posted with small changes can fail the rules
  ([YouTube's monetisation policies](https://support.google.com/youtube/answer/1311392?hl=en)).

## Monetisation thresholds

| Programme | Requirements |
|---|---|
| TikTok Creator Rewards | 18 or older, an eligible region, a personal account in good standing, 10,000 followers, 100,000 views in 30 days, original videos longer than one minute |
| YouTube Partner Program | 1,000 subscribers, and either 10 million valid public Shorts views in 90 days or 4,000 eligible public watch hours in 12 months |

These rules change, and age and region rules apply. Check the official
pages before relying on them:
[TikTok Creator Rewards](https://newsroom.tiktok.com/introducing-the-new-creator-rewards-program?lang=en),
[YouTube Partner Program](https://support.google.com/youtube/answer/72851?hl=en).

## Video log

One row per published video, linked to its evidence (a test case, task or
commit). Keep it in a private note, or here if you are happy to link your
channels from this public repository. Never add tester names or earnings.

```markdown
| Date | Concept | What it shows | Length | Platform links | What you learned |
|---|---|---|---|---|---|
| YYYY-MM-DD | One of the five concepts | The moment and its evidence, e.g. T13 | m:ss | YouTube, TikTok | What worked, what to change |
```

## How often

Aim for 1 to 3 good videos a week while you learn. Coursework comes first.
Budget about an hour a week for video, so record during sessions you were
doing anyway and keep edits short. A week without real progress is a
week without a video, and that is fine.
