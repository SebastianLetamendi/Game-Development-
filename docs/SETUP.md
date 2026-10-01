# Setup

How to go from nothing installed to playing Campus Delivery Dash in Roblox
Studio on a Mac. Follow the sections in order the first time; after that you
will mostly need [Put the game into Studio](#put-the-game-into-studio) and
[Troubleshooting](#troubleshooting). Commands such as `claude` go in the
Terminal app; slash commands such as `/status` go *inside* Claude Code or
Codex. Studio's menus sometimes move between versions: if a path here does
not match, look for the same name in the other tabs.

## What you need

| What | What it is for | Needed? |
|---|---|---|
| A Mac with Apple Silicon and macOS 26 or newer | Running the automated checks | Yes |
| A Roblox account and Roblox Studio | Building and playing the game | Yes |
| Terminal and Git | Commands, downloading the repository, code checkpoints | Yes |
| Claude Code | The implementer: changes code, can work in Studio through MCP | Recommended |
| Codex | The reviewer: checks changes independently | Recommended |
| A code editor, such as [VS Code](https://code.visualstudio.com/docs/setup/mac) | Reading and editing files | Optional |

### Get the repository

The repository is already on GitHub at
<https://github.com/SebastianLetamendi/Game-Development->. You download
("clone") a copy of it once.

1. Open Terminal: press Cmd+Space, type `Terminal`, press Return.
2. Type `git --version`. If macOS offers to install the command line
   developer tools, accept, wait, then try again. They include Python 3,
   which the checks also need.
3. Make the folders and clone the repository. If macOS asks whether Terminal
   may access your Documents folder, click **Allow** (if you clicked Don't
   Allow, turn Terminal on in System Settings > Privacy & Security > Files &
   Folders and run the commands again):

```sh
mkdir -p ~/Documents/"AI Studio/Places"
cd ~/Documents/"AI Studio"
git clone https://github.com/SebastianLetamendi/Game-Development- "Campus Delivery Dash"
```

On its own, `git clone` names the folder after the repository
(`Game-Development-`); the last part picks a friendlier name, in quotes
because it has spaces. `Places` is for Studio place files, outside Git.

**Opening Terminal in the project folder.** Every later command runs there.
In a new Terminal window, type `cd` and a space, drag the
`Campus Delivery Dash` folder from Finder into the window, and press Return.
`ls` should then list `README.md`, `AGENTS.md`, `src` and `tools`.

## Install the checking tools

Run `tools/install-dev-tools.sh` once, then `tools/check.sh`. The first
downloads pinned, checksum-verified versions of Luau, luau-lsp, Rojo and
StyLua into `.tools/` inside the project (ignored by Git); it writes nowhere
else and needs no password. It needs an Apple Silicon Mac with macOS 26 or
newer (the pinned Luau build requires it), or Linux x86_64, which GitHub
uses. On other processors it stops with `Unsupported platform`; on an older
macOS it installs, but `tools/check.sh` cannot run Luau, so update macOS
first.

`tools/check.sh` runs six checks and prints `passed` after each. Success ends
with `All checks passed.` Lines starting with `[INFO]` or `[WARN]` from
luau-lsp are normal; only a `FAILED:` line means a check failed. The checks
catch typos, type errors and broken rules, but never run the game: only
playing it in Studio shows that.

## Claude Code

Claude Code is the implementer. Started in the project folder, it reads
[`CLAUDE.md`](../CLAUDE.md), which also pulls in [`AGENTS.md`](../AGENTS.md).

1. Install it with Anthropic's installer:
   `curl -fsSL https://claude.ai/install.sh | bash`
2. Open a **new** Terminal window and check the install with
   `claude --version` and `claude doctor`.
3. In the project folder, run `claude` and sign in with your Claude
   subscription account.
4. Inside Claude Code, `/status` shows which account is signed in and
   `/model` shows or changes the model. Use your everyday model for normal
   work (see "Using the plan's usage allowance well" in `CLAUDE.md`).

Keep your usage on the subscription. **Do not set `ANTHROPIC_API_KEY`**: if
that environment variable is set, Claude Code can switch to separately billed
API usage (`echo $ANTHROPIC_API_KEY` should print an empty line). Leave paid
usage credits and automatic reload turned off in your Claude account.
More: [Claude Code setup](https://code.claude.com/docs/en/setup),
[model selection](https://support.claude.com/en/articles/11940350-claude-code-model-configuration).

## Codex as reviewer

Codex checks Claude Code's work independently. It reads `AGENTS.md`
automatically; the "Reviewing" section there is its checklist.

1. Type `codex --version`. If the command is missing, install it from the
   [Codex CLI](https://learn.chatgpt.com/docs/codex/cli) page.
2. Run `codex` in the project folder and sign in with your **ChatGPT
   account**, not an API key: API-key sign-in uses separately billed OpenAI
   Platform usage ([authentication](https://learn.chatgpt.com/docs/auth)).
3. Check the account with `codex login status` in Terminal, and usage with
   `/status` inside Codex.

Example review request, after Claude Code has finished a task:

> Review the uncommitted changes against TASK.md, following the "Reviewing"
> section of AGENTS.md. Run tools/check.sh and include its result. Report
> findings from most to least serious, each with the file, the line, a
> scenario where it goes wrong and a suggested fix. Do not edit any files.

## Roblox Studio and its MCP connection

MCP (Model Context Protocol) is a connection that lets an AI client, such as
Claude Code, look at and operate another app. Studio has an MCP server built
in, so no third-party plugin is needed. Install Claude Code first, then:

1. Download Studio from the
   [official setup guide](https://create.roblox.com/docs/studio/setup), open
   the Mac installer and sign in with your Roblox account.
2. Create a new place from the **Baseplate** template. Do not publish it, so
   it stays private.
3. Save it into `Places` (File > Save to File As..., for example
   `CampusDeliveryDash.rbxl`) and make a backup ([Backups and Git](#backups-and-git)).
4. In Studio, open **Assistant**, click its three-dot menu, choose
   **Manage MCP Servers** and turn on **Enable Studio as MCP server**
   (Roblox's [MCP instructions](https://create.roblox.com/docs/studio/mcp)).
5. Expand **Quick connect** and enable **Claude Code**. Codex CLI is also
   supported, if you want Codex to be able to look at the place.
6. If a recently installed client is missing, reconnect or restart Studio.
   Confirm that the client's connection indicator shows it as connected.
7. Start `claude` in the project folder (restart it if it was already
   running). Inside Claude Code, `/mcp` lists its connections.

Make the first request read-only: "Inspect the active place and list its
objects; make no edits." If that works, try one obvious change in the
throwaway Baseplate, such as adding a single part. **Only one agent edits the
live Studio place at a time**; a second agent can review files or a diff.

## Put the game into Studio

The scripts in `src/` are the source of truth; Studio only gets a copy. To
change the game later, edit `src/` (or have Claude Code do it), run
`tools/check.sh --fix` to regenerate `dist/InstallIntoStudio.luau`, and
install again. Edits made only inside Studio are overwritten by the next
install and never reach Git.

Each route creates the same 11 scripts in the same three folders:

| Folder in Studio's Explorer | Scripts |
|---|---|
| ReplicatedStorage > CampusDeliveryDash | Config, Net, RoundLogic |
| ServerScriptService > CampusDeliveryDash | Main, MapBuilder, MapContract, PackageVisual, RoundService |
| StarterPlayer > StarterPlayerScripts > CampusDeliveryDash | Hud, Main, Marker |

Before any route: your place is open, you are **not** playing (Edit mode),
and you have saved a backup.

### Route A (recommended): Claude Code through MCP

1. With Studio connected, start `claude` in the project folder. The
   suggested first prompt in [`TASK.md`](../TASK.md) has it look at the place
   and recommend a route before changing anything.
2. Ask it to install, for example:

   > I saved a backup of the place and Studio is in Edit mode. Run the
   > contents of dist/InstallIntoStudio.luau in Studio through the MCP
   > connection, without changing the file. Then tell me what the installer
   > printed and list the scripts in the three CampusDeliveryDash folders.

3. It should report
   `Campus Delivery Dash installed: 11 scripts. Save the place, then press Play.`
   Check the Explorer yourself against the table above, then save the place.
   If Claude Code says its Studio tools cannot run the installer, use Route B.

### Route B: one paste into the Command Bar

1. Make sure Studio is not playing. Open the Command Bar (View tab >
   Command Bar) and the Output window (View tab > Output).
2. In Terminal, in the project folder, run
   `pbcopy < dist/InstallIntoStudio.luau`. This copies the whole installer
   (over 2,000 lines) to the clipboard.
3. Click in the Command Bar, paste with Cmd+V and press Return.
4. The Output window should show
   `Campus Delivery Dash installed: 11 scripts. Save the place, then press Play.`
   Save the place. If that line does not appear (a red error, or nothing at
   all, for example because the paste was cut short), use Route C below.

Edit > Undo reverses the whole install in one step. The installer replaces
only the three folders above and leaves the rest of the place, map included.

### Route C (optional): Rojo

[Rojo](https://rojo.space) turns `src/` into Roblox scripts, following
`default.project.json`. `tools/install-dev-tools.sh` already put it in
`.tools/bin/`, which is not on your PATH (the folders Terminal searches for
commands), so type the full path:

```sh
.tools/bin/rojo build default.project.json -o CampusDeliveryDash.rbxlx
```

Open that file in Studio (File > Open from File..., or double-click it in
Finder). It holds only the scripts, with no baseplate or spawn point; when
you press Play, the game builds its own ground and spawn. Git ignores the
file, so if you start building in it, save it into `Places`.

To sync live instead, run `.tools/bin/rojo plugin install` once and restart
Studio. Then run `.tools/bin/rojo serve` in the project folder, leave that
window open, and click **Connect** in the Rojo plugin (Plugins tab). Studio
now updates whenever a file in `src/` changes. Press Ctrl+C to stop.

## First run

1. Open the Output window (View tab > Output) and press **Play**. You should
   see these lines and no red errors (the first two appear only while the
   place has no `CampusMap` of its own):

   ```
   [CampusDeliveryDash] No CampusMap in Workspace, so the greybox map was built for this test.
   [CampusDeliveryDash] To edit the map by hand, see the comment at the top of MapBuilder.
   [CampusDeliveryDash] Ready: 6 destinations, 90-second rounds.
   ```

2. A panel titled "Campus Delivery Dash" appears. Click **Start delivery**.
   Your character moves to the green START pad, the top bar shows the timer
   starting at 1:30 with "Pick up the package at the Depot" under it.
3. Follow the orange beacon to the Depot and hold **E** at the
   **Pick up package** prompt (on a touch screen, touch and hold it briefly).
4. Follow the green beacon and guide line to the building named in the top
   bar, and hold **E** at **Deliver package** by its blue mailbox.
5. The results panel says "Delivered!" (or "New best!") with your time,
   score and best. **Play again** starts a new round. **Stop** ends the test.

Also wait out one round: "Time's up!" and a **Try again** button should
appear. Then work through [TEST-PLAN.md](TEST-PLAN.md) and write the real
results in [`STATUS.md`](../STATUS.md).

## Make the map editable (optional)

Until you do this, the server builds a fresh greybox campus at every Play,
and it disappears when you stop. To keep a copy you can change by hand,
install the scripts, make sure Studio is not playing, and run this line (also
at the top of `src/server/MapBuilder.luau`) in the Command Bar:

```lua
require(game.ServerScriptService.CampusDeliveryDash.MapBuilder).build(workspace)
```

A `CampusMap` model appears in Workspace. Save the place. From then on the
server uses your edited `Workspace.CampusMap`. Keep the
[map contract](ARCHITECTURE.md#map-contract): `StartPad`, `Depot` and the
`Destinations` folder must stay, and those parts must stay **Anchored**;
everything else is scenery. Map edits live
in the place file, not in Git. The installer never touches `CampusMap`, but
nothing else backs it up either, so keep dated backups.

## Backups and Git

**Place backups.** Map edits and anything else built in Studio exist only in
place files. Before an install, a larger agent change or a map edit, save
the place, then duplicate the file in Finder (Cmd+D) and rename the copy
with the date and the coming change, such as
`CampusDelivery-2026-10-01-before-timer.rbxl`. File > Save to File As...
also works, but check which file Studio has open afterwards so later saves
do not overwrite the backup. Keep place files in `Places`: `.gitignore`
excludes `*.rbxl` and `*.rbxlx`, so Git can never restore them.

**One-time Git setup (before your first commit).** Every commit records a
name and an email, and anyone can read them in this public repository. On
github.com open Settings > Emails, tick **Keep my email addresses private**,
and copy the address ending in `@users.noreply.github.com`. Then run, with
your own values:

```sh
git config --global user.name "Your GitHub username"
git config --global user.email "the-noreply-address-you-copied"
```

Your first `git push` asks for a username and a password, and GitHub does not
accept your account password there. Create a token instead: on github.com,
Settings > Developer settings > Personal access tokens > Fine-grained tokens.
Give it access to this repository only, with **Contents: Read and write**,
and paste it as the password (Terminal shows nothing while you paste; press
Return). macOS Keychain remembers it until the token expires (the form's
default is 30 days; you can choose longer). When a later `git push` says
`Authentication failed`, create a new token the same way and paste it at the
next password prompt. Never paste the token into a file, a chat or an agent
prompt.

**Code checkpoints.** Scripts, docs and tools are kept in Git. After a change
passes `tools/check.sh` and you have played it, first look at what would be
published:

```sh
git status
```

Read the list. If anything in it should not be public (notes with real
names, anything containing a password, key or token), stop and ask Claude
Code how to leave it out. Otherwise run these, replacing the example message
with a short description of your change:

```sh
git add -A
git commit -m "Shorten the round timer after the first playtest"
git push
```

You can also ask Claude Code to commit; it only commits when asked.

**This repository is public.** Never commit passwords, API keys, tokens,
Roblox cookies, `.env` files, real tester names or personal records. A secret
committed by accident stays in Git's history: change or revoke it at once.

## Troubleshooting

For tool and connection problems, go through these in order:

1. **A command is missing** (`claude`, `codex`): open a fresh Terminal
   window. If it is still missing, check the installer's PATH instructions.
2. **An MCP server is absent:** run `claude mcp list` or `codex mcp list` in
   Terminal, and type `/mcp` inside the client.
3. **Connected, but the agent cannot act:** check that Studio is open, your
   place is open, and Studio's MCP server is enabled.
4. **The connection is flaky:** retry one harmless read, such as listing
   objects, before allowing any writes.
5. **Always:** keep a saved version of the place you can restore, and never
   fix a connection problem by giving every process unrestricted access.

Problems specific to this game:

| What you see | What to do |
|---|---|
| A "Setup problem" panel | Read the Output window. `[CampusDeliveryDash] Map problem: ...` lines name what the map is missing; fix it using the [map contract](ARCHITECTURE.md#map-contract) and press Play again. For a red script error, paste it exactly to Claude Code. |
| No panel and no `[CampusDeliveryDash]` lines | The scripts are not installed. Check the Explorer and install again. |
| `Stop the play test first: the installer only works in Edit mode.` | Press Stop, then run the installer again. |
| `... already has a CampusMap; delete or rename it first` | The map line already ran. Your map is safe. |
| `Missing tool: ...` from `tools/check.sh` | Run `tools/install-dev-tools.sh`. For `python3`, accept the developer tools install (see [Get the repository](#get-the-repository)). |
| `... check(s) failed.` | Run `tools/check.sh --fix`, then `tools/check.sh`, and read the output just above each `FAILED:` line (between it and the `== ...` heading before it). Paste it to Claude Code if it is unclear. |

## Later tools

- **Blender** and its community MCP connector, for original props once the
  game loop works: [ASSETS.md](ASSETS.md).
- **OBS** for recording, plus a video editor: [VIDEOS.md](VIDEOS.md).
- **Unreal Engine** is for a later project; keep it out of this repository.
