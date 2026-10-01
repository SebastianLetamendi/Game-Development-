# Assets

How to replace the greybox parts with original props made in Blender,
without breaking the game. The greybox map is plain parts on purpose: it is
for testing the round, not final art.

## When to do this

Props belong to milestone 5, Presentation (see the milestones in
[PROJECT-BRIEF.md](../PROJECT-BRIEF.md)). Start only after milestones 1 to 4
have been played in Studio and recorded in [STATUS.md](../STATUS.md): if
players cannot finish a round, fix that before adding any art. Make the
prop work its own task in [TASK.md](../TASK.md), with acceptance criteria.

Use only original or properly licensed assets. The campus is fictional:
no real school names, logos, mascots or brands (such as a real courier's
logo on the package). No paid asset packs and no paid AI generators: this
project has no software budget.

## The five props

Start with five reusable props. The greybox sizes below come from
[`MapBuilder.luau`](../src/server/MapBuilder.luau) and
[`PackageVisual.luau`](../src/server/PackageVisual.luau). Make each prop
about the size of the part it replaces, so routes, prompts and the marker
still line up. Sizes are in studs, as width x height x depth (Roblox's X, Y
and Z). Every location below is inside `Workspace > CampusMap` except
`ServerStorage`.

| Prop | Replaces | Greybox size | Lives in |
|---|---|---|---|
| Package | The carried brown box and the three `StackedPackage` parts on the Depot | 2 x 1.6 x 1.6 | `ServerStorage` (as `PackageTemplate`) and `Scenery` |
| Mailbox | Each building's mailbox box (the destination part) and its `MailboxPost` | box 3 x 2 x 2.4, post 0.6 x 3 x 0.6 | `Destinations` (box) and the building's model in `Scenery` (post) |
| Bench | `BenchSeat`, `BenchBack` and `BenchBase` of the four plaza benches | seat 6 x 0.6 x 2, back 6 x 2 x 0.4, base 5 x 1.2 x 1 | `Scenery` |
| Kiosk | The `Depot` counter, `DepotSign` and the two `DepotPost` parts | counter 14 x 5 x 4, sign 14 x 3 x 0.4, posts 0.5 x 4 x 0.5 | `Depot` directly in `CampusMap`, the rest in `Scenery` |
| Lamp (optional) | Nothing yet: the greybox has no lamps | about 0.5 x 12 x 0.5 for the post, as a guide | `Scenery` |

### Studs and Blender units

A stud is Roblox's unit of length: the default character walks 16 studs
per second, and the greybox paths are 10 studs wide. Blender has its own
units, shown as metres by default, and they do not always match studs one
to one after export and import. Never trust a conversion you have not
checked:

1. Decide one scale for every prop. The simplest rule is 1 Blender unit =
   1 stud, so the package is 2 x 1.6 x 1.6 in Blender's Dimensions (press N
   over the 3D viewport, Item tab).
2. Height is Z in Blender but Y in Roblox: the 3 x 2 x 2.4 mailbox box is
   X 3, Y 2.4, Z 2 in Blender.
3. Verify with the first prop you import, next to the greybox part it
   replaces. If the size is off, fix it once, in Blender or in the
   importer's options, write down how, and do the same for every prop.

## Connect Blender to Claude Code

Blender is a free 3D modelling app. A community MCP connector lets Claude
Code work in it (MCP is explained in [SETUP.md](SETUP.md#roblox-studio-and-its-mcp-connection)).
The connector, now named `mcp-for-blender`, is community-maintained and
**not affiliated with Blender**. It can **run Python code inside Blender**,
and that code can change or delete files. So install it only from the
official upstream repository, <https://github.com/ahujasid/mcp-for-blender>,
and start in a new test file, not in work you care about. You install it
yourself: agents must not add MCP servers without your approval
([AGENTS.md](../AGENTS.md)).

Steps (commands go in Terminal, not inside Claude Code):

1. Install uv, a tool that runs Python programs
   ([uv installation](https://docs.astral.sh/uv/getting-started/installation/)):
   `curl -LsSf https://astral.sh/uv/install.sh | sh`
2. Open a **fresh** Terminal window and check it with `uv --version`.
3. Run `uvx mcp-for-blender setup` and choose **Claude Code** when it asks
   which AI client to use.
4. Turn off the connector's telemetry (usage data it reports upstream):
   set `DISABLE_TELEMETRY=true` in the MCP server's environment, the
   environment settings of its entry in Claude Code's MCP configuration (the
   upstream README shows where). If a configuration file appears inside this
   repository, read it before committing: no keys or personal paths.
5. Save your work, then quit and reopen both Blender and Claude Code.
6. In Blender, start a new file. With the mouse over the 3D viewport, press
   **N** and open the **MCP for Blender** tab. Confirm the server is running.
7. Inside Claude Code, `/mcp` should list the Blender connection. If not, see
   [Troubleshooting](SETUP.md#troubleshooting).
8. First test, in the new file:

   > Create one low-poly crate in a new collection and save a new file.

   Look at the crate in the viewport yourself before trusting the reply.

### Safe habits in Blender

- **One writer per `.blend` file.** `.blend` files are binary, so Git cannot
  merge two versions. One agent at a time, and not while you edit it too.
- **Save versions before big agent changes** (File > Save As, new number):
  `crate-v01.blend`, `crate-v02.blend`. Going back is opening the older one.
- Keep sessions short, with a clear stopping point. Blender must stay open
  while the agent works.

## Asking for a prop

Ask for **one prop per request**, and spell out:

- **Consistent scale:** the sizes from the table, at 1 unit = 1 stud.
- **Clean names:** such as `Mailbox_Box`, not `Cube.003`.
- **Simple materials:** one or two plain colours. Complex Blender material
  setups do not carry over to Roblox.
- **Low polygon count:** simple shapes with few faces ("low-poly"). The
  Statistics option in the viewport's Overlays menu shows the count.
- **Exportable geometry:** plain mesh objects, rotation and scale applied.

Example:

> In the open Blender file, create one low-poly mailbox in a new collection
> named Mailbox. Use 1 Blender unit = 1 stud. The box is 3 wide, 2 tall and
> 2.4 deep, sitting on a post 0.6 wide, 3 tall and 0.6 deep. Name the
> objects Mailbox_Box and Mailbox_Post. Use at most two simple materials with
> plain colours, and apply rotation and scale. Change nothing outside the
> Mailbox collection. Save the file as mailbox-v01.blend, then tell me each
> object's dimensions and face count.

Then check it visually: orbit around it, read the Dimensions yourself, and
compare it with a plain box of the greybox size (ask for one in a separate
`Reference` collection and leave it out of exports).

## Export and import

1. Save the `.blend`. It is the source; an export is a copy you can redo.
2. Select only the prop's objects. For the package, join them into one
   object (Object > Join), because the carried package must be one part.
3. Use File > Export > FBX (.fbx) or Wavefront (.obj), with the option that
   limits the export to selected objects. FBX and OBJ are safe choices for
   Roblox Studio's 3D Importer; check the importer for other formats.
4. In Studio, save a backup of the place, then open the 3D Importer
   (Import 3D; where it sits depends on your Studio version, so search for
   it if needed). Read its preview and warnings before importing.
5. Check the result. A successful export or import is not proof that any
   of these are right:

| Check | How |
|---|---|
| Scale | Put it next to the greybox part and compare `Size` in Properties with the table above. If it is off, fix it in Blender and import again rather than resizing copies by different amounts: keep one scale. |
| Orientation | It stands upright and faces the right way (toward the path or plaza). |
| Materials | Colours and textures look right. If colours did not come through on an untextured prop, set `Color` and `Material` on the MeshPart in Studio. |
| Collisions | Check each MeshPart's `CollisionFidelity` in Properties (`Box` or `Hull` suits simple props). In a play test, walk into it and jump on it. |

## Swap props in without breaking the game

The scripts depend only on a few named objects, the
[map contract](ARCHITECTURE.md#map-contract). Everything else is scenery.
Before you start:

1. **Bake the map** (save a fixed copy of it in the place). If Workspace
   has no `CampusMap` in Edit mode, the greybox is rebuilt at every Play and
   your props have nowhere to live.
   Follow [Make the map editable](SETUP.md#make-the-map-editable-optional).
2. **Save a dated backup** of the place, such as
   `CampusDelivery-before-props.rbxl` ([Backups and Git](SETUP.md#backups-and-git)).
   Map edits live in the place file, not in Git.
3. **One agent at a time** edits the live place. If Claude Code swaps props
   through Studio's MCP connection, ask it to keep the map contract and
   list its changes, then check the Explorer yourself.

Per prop:

- **Scenery (bench, lamp, kiosk pieces, stacked packages):** replace freely
  inside `Scenery`. Keep every map prop `Anchored`, like the greybox parts,
  and keep paths and the Science Hall ramp clear.
- **Kiosk counter:** keep one part named `Depot` directly in `CampusMap`. A
  single MeshPart named `Depot` can replace the orange counter. The
  **Pick up package** prompt and the orange beacon appear at its centre.
  The word DEPOT is a SurfaceGui (`SignFront`, `SignBack`) on the
  `DepotSign` part, so keep that part or players lose the label.
- **Mailboxes:** each child of `Destinations` is one address. Its Name is
  the id (`Library`, `ScienceHall`, `NorthDorm`, `Cafeteria`, `Gym`,
  `ArtStudio`) and its string attribute `DisplayName` (such as
  `Science Hall`) is what players see. Replace the old box with either
  **one MeshPart** with the same name and attribute (add it in the
  Attributes section of Properties), or **a Model** with that name, the
  attribute on the Model, and its `PrimaryPart` set to the mailbox box.
  The **Deliver package** prompt and green beacon appear at the centre of
  that part, and the server's distance check uses its position and size, so
  keep it where the old box was. Delete the old `MailboxPost` if your
  mailbox has its own post.
- **Carried package:** put one part named `PackageTemplate` directly in
  `ServerStorage`. It must be a single BasePart, such as a MeshPart; a Model
  is ignored and the brown box is used instead. The script clones it and
  makes the copy unanchored, massless and non-colliding, welded in front of
  the chest, so you do not set those yourself. It also sets the copy's
  rotation, so turning the template in Studio changes nothing: if it is
  carried sideways, fix it in Blender and import again.

Then press **Play**. The Output window should show
`[CampusDeliveryDash] Ready: 6 destinations, 90-second rounds.` and no
`Map problem` lines. A line ending `use a part, or a Model with a
PrimaryPart` usually means a Model has no PrimaryPart; fewer than 6
destinations means a mailbox was ignored or is missing. Re-run T1, T2, T4
and T6 in [TEST-PLAN.md](TEST-PLAN.md) (T15 too if you use streaming),
record the results in [STATUS.md](../STATUS.md), and save the place.

## Where files live

| File | Where |
|---|---|
| Small (a few MB), original `.blend` sources | Can go in Git, in a folder such as `assets/blender/` |
| Larger `.blend` files | Outside Git, for example `~/Documents/AI Studio/Blender/`, with backups |
| `*.blend1` and `*.blend@` (Blender's automatic backups and temporary save files) | Already ignored by `.gitignore` |
| Exported `.fbx` or `.obj` files | Not needed in Git: export again from the `.blend`. A folder named `exports/` is ignored anywhere in the repository. |
| Props imported into Studio | In the place file, outside Git. Back it up. |

This repository is public: anyone can download what you commit. Never
commit an asset you do not have the rights to, and read `git status` before
every commit ([Backups and Git](SETUP.md#backups-and-git)).

## Checklist for each prop

Copy this into the task in `TASK.md` for each prop.

- [ ] Original (or properly licensed), with no real logos, names or brands
- [ ] Agreed scale, clean names, simple materials, low face count
- [ ] Numbered `.blend` saved (`name-v01.blend`) before big agent changes
- [ ] Only the prop exported (the package joined into one object)
- [ ] Place backup saved before importing
- [ ] After import: size, orientation, materials and collisions checked
- [ ] Map props anchored; no path or ramp blocked
- [ ] Map contract kept: names, `DisplayName`, `PrimaryPart` for a Model
- [ ] Ready line shows 6 destinations, with no `Map problem` lines
- [ ] T1, T2, T4 and T6 re-run and recorded in `STATUS.md`
- [ ] `.blend` stored in the right place; nothing committed without rights
