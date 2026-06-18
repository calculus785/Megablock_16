Session type: Dev

Phase: Phase 4 — Relationships & Social Drama (extension wave)

Status: Dead code removed, sim stable, ready to design the next major system.
What we built / decided

Claude Code onboarded for the first time (VS Code extension) — used for the full proximity-system dead-code sweep
CONVERSE cooldown_events bumped 5 → 12
Decided to delete HALLWAY_NOD, AWKWARD_HALLWAY_PASS, HALLWAY_BUMP outright rather than fix, after finding a target-resolution bug in all three

What's working (confirmed in sim)

Hallway conversations: characters stop, run full CONVERSE_SEQ, resume journey cleanly (confirmed Kai+Sara, Soren+Sage)
Elevators, pathing, relationship deltas (bond/trust/rivalry/familiarity) all firing correctly
No parse errors, no loops, no ghost floats after sweep

Still broken / not firing reliably

None new this session.

Bugs fixed
BugFileRoot cause → fixCharacters firing hallway events on themselves (e.g. "Sara Vega and Sara Vega passed in the hall")events.gdHALLWAY_NOD/AWKWARD_HALLWAY_PASS/HALLWAY_BUMP kept target_resolution: {type: "self"} from their old proximity-event design after Session 20's conversion to rolled events. Resolved by deleting all three events rather than patching target resolution.
Files modified
FileChangechar_data.gdRemoved 6 loiter/transit fieldsmovement_controller.gdRemoved all proximity functions, vars, and call sitessim.gdRemoved proximity firing/pause/loiter functionsactions.gdRemoved _start_hallway_conversation() + dispatcher entryevents.gdCONVERSE cooldown_events 5→12; removed HALLWAY_NOD, AWKWARD_HALLWAY_PASS, HALLWAY_BUMP

Decisions to log

Cut HALLWAY_NOD/AWKWARD_HALLWAY_PASS/HALLWAY_BUMP rather than fix self-targeting bug — events were low-value flavor text left over from the old proximity system; not worth the upkeep. Session 21.

Doc edits to apply

None this session — no design changes, just cleanup.

Next priorities

Brainstorm session: design the base event layer (CALLOUT/VISIT_/FULFILL_NEED two-tier intent pipeline)
Implement once design locks

Parking lot

None new.