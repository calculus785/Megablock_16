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

Session 21 — Brainstorm
Designed the base event layer: a filtering step before the normal event
roll, not a new pipeline stage. Character rolls a base category
(FULFILL_NEED, SOCIALIZE, VISIT, INTROSPECT, IDLE, WORK; FULFILL_GOAL
parked for later) based on current state, then immediately rolls a
specific event from that category's sub-pool and runs it through the
existing pipeline same-tick (Option C — no delay).

Tagging approach: events.gd entries get a base_category field (array if
multi-category, e.g. VISIT_BAR can serve fulfill_need/socialize/visit).
No hardcoded category->event lists — stays data-driven.

FULFILL_NEED: finds worst deficit stat, rolls from events tagged with
matching fulfills_need. Boredom/loneliness are NOT fulfill_need targets —
they're weight boosters on SOCIALIZE/VISIT categories instead. Severity
comparison decides which need wins if multiple are bad (e.g. starving
beats merely bored).

SOCIALIZE: same-room target gets a CALLOUT with accept/decline roll
(equation: base 60 + bond*0.3 + busy_penalty per queued intent +
mood_modifier + trait_modifier + feeling_modifier + energy_modifier,
clamped 5-95). No target in room -> resolves to VISIT instead.

Intent queue: soft cap of 3. At cap, base events don't push (character
stays busy) and CALLOUT auto-declines with a storybook-ready reason
("too busy"). Critical/world events bypass the cap and push anyway —
acts as a high-priority buffer, so e.g. a lockdown doesn't erase Bill's
queued BUY_GROCERIES, it resumes after. Emergency events (injury, arrest)
flush the queue entirely first.

Context carrier: new CharData field current_motivation
({type, need, plan}), set when a base event resolves, cleared when the
chain completes or flushes. Storybook helper (future work) will read this
to narrate chains like the hotdog example. Lives on CharData, not memory
— it's transient mid-chain state, not something worth recalling.

Walked the full example: Bill rolls FULFILL_NEED -> hunger -> MAKE_FOOD ->
no ingredients -> pushes BUY_GROCERIES + MAKE_FOOD intents -> mid-transit
CALLOUT from Jess -> accepts (queue not full) -> CONVERSE_SEQ -> Jess
invites to a movie -> Bill declines (queue non-empty boosts decline) ->
resumes -> buys groceries -> goes home -> makes food. Confirmed the
mechanics support this without new pipeline stages.

Build order locked: tag events -> base roll in sim.gd (simple version) ->
current_motivation field -> FULFILL_NEED resolver -> queue cap/bypass ->
CALLOUT accept/decline. Six steps, each independently testable.

Decided: implementation is dev sessions, not Claude Code. This is
architectural/emergent work needing step-by-step testing, not a
mechanical sweep.

No code written. No files modified. Decision-only session.