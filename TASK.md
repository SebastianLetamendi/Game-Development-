# Current task

## First Studio playtest of the round (milestones 1 to 4)

**Owner:** the human owner, with Claude Code helping through the Studio
MCP connection.

**Why:** the code for milestones 1 to 4 exists and passes every automated
check, but nobody has played it in Roblox Studio yet. Until someone does,
none of those milestones count as done.

### Acceptance criteria

- [ ] The scripts are in a private Baseplate place (any route in
      `docs/SETUP.md`), and a backup copy of the place was saved first.
- [ ] Pressing Play prints `[CampusDeliveryDash] Ready: 6 destinations,
      90-second rounds.` in the Output window, with no red errors.
- [ ] Solo on desktop: start a round, pick up the package, deliver it, see
      the score, and press Play again.
- [ ] Wait out a round without delivering: "Time's up!" appears and Try
      again starts a new round.
- [ ] Every case in `docs/TEST-PLAN.md` was tried and its real result is
      written in `STATUS.md` (pass, fail with what happened, or not tried).
- [ ] Any bug found is listed in `STATUS.md`. Only fix bugs as part of this
      task if they stop a round from being completed.
- [ ] The owner can answer the quiz questions in `docs/CODE-TOUR.md` for
      `RoundLogic.luau` and `RoundService.luau` without looking.

### Out of scope

New features, art, sounds, saved data and publishing. Write ideas down in
`STATUS.md` under "Ideas parked" instead.

### Suggested first prompt for Claude Code

> Read PROJECT-BRIEF.md, TASK.md, STATUS.md and docs/SETUP.md. Then inspect
> the open Studio place and list its top-level objects without changing
> anything. Tell me which install route you recommend and what I need to
> do before you install.

---

## Template for the next task

Copy this block over the task above when the owner picks the next task.

```markdown
## <Short name of the task>

**Why:** <the problem this solves, ideally something a playtester hit>

### Acceptance criteria
- [ ] <something you can see in Studio or in a test>
- [ ] tools/check.sh passes
- [ ] STATUS.md updated with what was actually tested

### Out of scope
<what not to touch>
```
