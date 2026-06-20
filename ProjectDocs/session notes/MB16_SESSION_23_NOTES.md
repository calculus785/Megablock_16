# MB16 Session 23 Notes — Base Event Layer Step 1 (Dev Session)

**Date:** 2026-06-18
**Type:** Dev
**Phase:** Post-Phase-4 — Base Event Layer implementation
**Build order step completed:** Step 1 of 6 (tagging + cleanup)
**Build order step next:** Step 2 of 6 (base roll in sim.gd)

---

## What Happened This Session

Implemented Step 1 of the base event layer build order: tagged every
rolled event in events.gd with `base_category` and `fulfills_need`
fields. Walked through all ~55 events category by category with
Alexander, making design decisions along the way. Scope expanded beyond
pure tagging into event deletions, event-to-beat conversions, a
trigger_mode change on GO_HOME, and a full actions.gd cleanup.

**Two files fully rewritten:**
- `events.gd` — base_category/fulfills_need tags added, 10 events
  deleted, GO_HOME converted to auto_fire, SPILL_DRINK removed
- `actions.gd` — dispatcher cleaned (16 dead entries + 6 duplicates
  removed), 7 dead functions removed, 9 functions reorganized into
  SEQUENCE-CALLABLE section, duplicate FeelingDriver.push bug fixed
  in _maybe_push_avoidance, duplicate debug print fixed in _tell_on,
  duplicate guard block fixed in _start_pool_game

**No sim.gd changes this session** — the base layer is tagged but not
yet consumed. Sim still uses the flat event pool. Step 2 (next session)
wires it up.

---

## All events.gd Changes

### base_category Tags Applied (35 rolled events tagged)

**FULFILL_NEED:**
- REST → `"fulfill_need"`, fulfills_need: `"energy"`
- CHECK_FRIDGE → `["fulfill_need", "idle"]`, fulfills_need: `"hunger"`
- EAT_AT_HOME → `"fulfill_need"`, fulfills_need: `"hunger"`
- COOK_MEAL → `"fulfill_need"`, fulfills_need: `"hunger"`
- ORDER_FOOD → `["fulfill_need", "idle"]`, fulfills_need: `"hunger"`
- ORDER_DRINK → `["fulfill_need", "socialize", "idle"]`, fulfills_need: `"stress"`
- ORDER_COFFEE → `["fulfill_need", "idle"]`, fulfills_need: `"energy"`
- LIE_IN_BED → `["fulfill_need", "idle"]`, fulfills_need: `"energy"`
- READ_BOOK → `["idle", "fulfill_need"]`, fulfills_need: `["boredom", "stress"]`
- ADMIRE_STATUE → `["idle", "fulfill_need"]`, fulfills_need: `["boredom", "stress"]`
- DRINK_ALONE → `["fulfill_need", "idle"]`, fulfills_need: `"stress"`

**SOCIALIZE:**
- CONVERSE → `"socialize"`
- FLIRT → `"socialize"` (standalone wink-case kept)
- ASK_OUT → `"socialize"` (future: becomes goal-event)
- APOLOGISE → `"socialize"`
- VENT_TO_FRIEND → `"socialize"`
- TELL_ON → `"socialize"`
- SHARE_MEAL → `"socialize"`
- QUIET_MOMENT_TOGETHER → `"socialize"`
- STUDY_TOGETHER → `"socialize"`
- PLAY_POOL_INVITE → `"socialize"`
- NOD_IN_PASSING → `["socialize", "idle"]`

**VISIT:**
- VISIT_BAR → `"visit"`
- VISIT_CAFE → `"visit"`
- VISIT_LIBRARY → `"visit"`
- VISIT_GROCERY → `"visit"`
- CHECK_SUPPLIES → `["visit", "idle"]`

**INTROSPECT:**
- THINK_ABOUT → `"introspect"`
- BROOD → `"introspect"`
- SMILE_AT_MEMORY → `"introspect"`
- CRY → `"introspect"`

**IDLE:**
- DAYDREAM → `"idle"`
- LOOK_IN_MIRROR → `"idle"`
- LATE_NIGHT_STARE → `"idle"`
- PACE_HALLWAY → `"idle"`
- WANDER → `"idle"`
- SIT_AT_BAR → `"idle"`
- LEAN_ON_COUNTER → `"idle"`
- NURSE_DRINK → `"idle"`
- HANG_AT_LOUNGE → `"idle"`
- WATCH_THE_ROOM → `"idle"`
- SIT_AT_DESK → `"idle"`
- BROWSE_SHELVES → `"idle"`
- WINDOW_WATCH → `"idle"`
- SIT_ALONE_CAFE → `"idle"`

**WORK:** no events yet (future phase)

### No base_category (auto_fire, bypass base roll)
- SLEEP (unchanged, priority 90)
- ENERGY_CRASH (unchanged, priority 95)
- GO_HOME (CHANGED: was rolled, now auto_fire priority 75)

### No base_category (conflict — flagged for reactive redesign)
- MOCK, COLD_SHOULDER, PROVOKE, PHYSICAL_FIGHT, CONFRONT
- Left in events.gd without base_category so they can't enter the
  category pool. Still rollable via current flat pool until Step 2
  lands, then they go dark until reactive trigger is built.

### Events Deleted from events.gd (10 total)
**Folding into CONVERSE_SEQ as beats (future task):**
- GREET, COMPLIMENT, INSULT, ARGUE, SHARE_STORY, REMINISCE_TOGETHER,
  SHARE_SECRET, BETRAY_SECRET, DEEP_CONVERSATION

**Scrapped for Phase 5 redesign:**
- SPILL_DRINK (reintroduce as reaction event tied to inventory)

### GO_HOME Trigger Mode Change
- Was: `trigger_mode: "rolled"`, `base_weight: 5`
- Now: `trigger_mode: "auto_fire"`, `priority: 75`, `base_weight: 0`
- Rationale: GO_HOME is needs-driven/reactive (tired, stressed, social
  battery depleted), not a base-roll choice. Priority 75 sits below
  SLEEP (90) and ENERGY_CRASH (95), intentionally soft enough that a
  drunk/distracted character can miss the window and crash wherever
  they are.

### FLIRT Storybook Templates Updated
- Old templates were conversation-flavored ("flirted with," "charm on")
- New templates are ambient/non-conversation ("winked across the room,"
  "caught their eye and held it a beat too long") to match the standalone
  wink-case role now that most flirting lives in CONVERSE_SEQ

### fulfills_need Array Support Flagged
- READ_BOOK and ADMIRE_STATUE have `fulfills_need: ["boredom", "stress"]`
- The FULFILL_NEED resolver (Step 4) needs to handle array values, not
  just strings — flagged as a build dependency

---

## All actions.gd Changes

### Dispatcher Entries Removed (22 total)
**Dead events (10):** greet, compliment, insult, argue, gossip,
deep_conversation, share_story, reminisce_together, share_secret,
betray_secret

**Dead stubs (5):** brief_conversation, hallway_nod, hallway_chat,
awkward_pass, hallway_bump

**Fully deleted event (1):** spill_drink

**Duplicate entries removed (6):** sit_at_bar, lean_on_counter,
browse_shelves, window_watch, lie_in_bed, check_supplies (each appeared
twice in the dispatcher)

### Functions Removed (7)
- `_chat()` — replaced by CONVERSE_SEQ, not wrapped by any beat
- `_spill_drink()` — event fully deleted
- `_brief_conversation()` — dead stub
- `_hallway_nod()` — dead stub
- `_hallway_chat()` — dead stub
- `_awkward_pass()` — dead stub
- `_hallway_bump()` — dead stub

### Functions Kept, Reorganized (9)
Moved into new SEQUENCE-CALLABLE FUNCTIONS section with comments
explaining why each is kept:
- `_compliment()` — called by `_converse_compliment()` wrapper
- `_insult()` — called by `_converse_insult()` wrapper
- `_gossip()` — called by `_converse_gossip()` wrapper
- `_greet()` — reserved for future CONVERSE_SEQ GREET_BEAT
- `_argue()` — reserved for future CONVERSE_SEQ ARGUE_BEAT
- `_share_story()` — reserved for future CONVERSE_SEQ beat
- `_reminisce_together()` — reserved for future CONVERSE_SEQ beat
- `_share_secret()` — reserved for future CONVERSE_SEQ beat (full logic)
- `_betray_secret()` — reserved for future CONVERSE_SEQ beat (full logic)

### Bug Fixes (3)
1. `_maybe_push_avoidance()` — duplicate `FeelingDriver.push()` call
   removed (was pushing AVOIDING twice with identical data)
2. `_tell_on()` — duplicate debug print at end removed
3. `_start_pool_game()` — duplicate guard block removed (the
   `if not target is CharData` / `if target.active_sequence != ""`
   checks were written twice)

---

## What's Next — Step 2 Build Order

**Step 2: Add base roll to sim.gd** — this is what makes the base layer
actually run. Three code pieces needed:

1. **events.gd** — add `get_events_by_base_category(category)` helper.
   Tiny function, filters EVENTS dict by base_category field, handles
   both string and array values. Should be done first.

2. **sim.gd** — add `_roll_base_category(character)` function. Picks a
   category (FULFILL_NEED / SOCIALIZE / VISIT / INTROSPECT / IDLE)
   weighted by character state. Start with simple weights: equal base,
   boosted by stat thresholds (high hunger → FULFILL_NEED weight up,
   high loneliness → SOCIALIZE weight up, high boredom → VISIT/IDLE
   weight up). Boredom/loneliness boost SOCIALIZE/VISIT, they are NOT
   FULFILL_NEED targets (locked decision from Session 21-22).

3. **sim.gd** — modify `_run_pipeline()` ROLL stage. Current flow:
   `_get_eligible_events()` → `_weighted_roll()` from full pool.
   New flow: `_roll_base_category()` → filter eligible events to
   matching category → `_weighted_roll()` from filtered sub-pool.
   Unresolvable category (empty sub-pool) = skip that tick, don't
   fire. Conflict events (no base_category) stop appearing in the
   rolled pool once this lands — they need the reactive trigger
   system built before they fire again.

**Important for next session:** load sim.gd fresh (it's a big file,
needs full context). The key functions to read are `_run_pipeline()`,
`_get_eligible_events()`, and `_weighted_roll()`. The change is
inserting a category-filter step between eligibility check and
weighted roll — not a rewrite of the pipeline, just a new filter.

**Steps 3-4 can follow in same session if time allows:**
- Step 3: `current_motivation` field on CharData (set/clear only)
- Step 4: FULFILL_NEED resolver (worst stat → matching fulfills_need)

---

## Decisions Made This Session (for Decisions Log)

**INTROSPECT vs IDLE distinction** — INTROSPECT = memory/feeling-driven
internal processing (THINK_ABOUT, BROOD, SMILE_AT_MEMORY, CRY). IDLE =
atmospheric, no memory reference, passing time (DAYDREAM, LOOK_IN_MIRROR,
LATE_NIGHT_STARE, PACE_HALLWAY, etc). Session 23.

**GO_HOME converted to auto_fire** — Needs-driven/reactive, not a
base-roll choice. Priority 75 (below SLEEP 90, ENERGY_CRASH 95),
intentionally soft so characters can miss the window. Session 23.

**10 events deleted from events.gd** — GREET, COMPLIMENT, INSULT, ARGUE,
SHARE_STORY, REMINISCE_TOGETHER, SHARE_SECRET, BETRAY_SECRET,
DEEP_CONVERSATION folding into CONVERSE_SEQ as beats. SPILL_DRINK
scrapped for Phase 5 reaction-event redesign. Action functions kept in
actions.gd — sequences call them. Session 23.

**Conflict events get no base_category** — MOCK, COLD_SHOULDER, PROVOKE,
PHYSICAL_FIGHT, CONFRONT flagged for reactive/auto-fire redesign
(relationship-proximity trigger). Not deleted, just excluded from the
base-roll pool. Session 23.

**VISIT events are travel steps, not need-fulfillment** — fulfills_need
tag belongs only on the event that actually applies the stat delta
(ORDER_DRINK, not VISIT_BAR). Travel/intent events get pure category
tags. Session 23.

**fulfills_need supports arrays** — READ_BOOK and ADMIRE_STATUE address
both boredom and stress. FULFILL_NEED resolver (Step 4) must handle
array values. Session 23.

**COMPLIMENT/INSULT as generic callable beat functions** — Usable as
branching options at arbitrary sequence beats (PLAY_POOL_SEQ, future
sequences), not just CONVERSE_SEQ. Design decision, implementation
deferred. Session 23.

**No 7th base category for conflict or romance** — ASK_OUT stays in
SOCIALIZE with strict requirements doing the gating. Conflict events
bypass the base roll entirely via reactive triggers. Adding a category
has cost (every consumer grows a branch). Session 23.

---

## Parking Lot (new items from this session)

**For Roadmap / Phase 5:**
- SPILL_DRINK reintroduce as reaction event tied to inventory (character
  physically holding a drink)
- DRINK_ALONE fold into ORDER_DRINK with force-roll for drink location
  (counter vs lounge) once inventory exists
- Inventory system: CHECK_FRIDGE + EAT_AT_HOME become supply-consuming;
  add GET_SNACK event (rolls check fridge/cupboard); snack = 1 supply,
  cook meal = more; fridge and cupboard as food supply containers
- Characters physically hold drinks once inventory exists, then decide
  where to drink
- Phase 5 shop rework: decoration/gift/smoke stores added to VISIT pool
  or as FULFILL_NEED boredom targets

**For CONVERSE_SEQ expansion (future dev session):**
- Fold GREET, SHARE_STORY, REMINISCE_TOGETHER, SHARE_SECRET,
  BETRAY_SECRET into CONVERSE_SEQ as new beats
- Event requirements (bond-50 gate on SHARE_SECRET etc.) become
  beat-eligibility conditions inside sequences.gd
- COMPLIMENT/INSULT as generic callable beat functions usable across
  any sequence (PLAY_POOL_SEQ branching: "jess is winning, bill can
  insult, compliment, or continue playing")

**For conflict event redesign (future dev session):**
- Reactive/auto-fire trigger for MOCK, COLD_SHOULDER, PROVOKE,
  PHYSICAL_FIGHT, CONFRONT — relationship-proximity trigger (enemy
  enters room → chance to fire), the CALLOUT system's evil twin
- Once Step 2 lands, these events go dark in the rolled pool (no
  base_category = never selected). Reactive trigger needed before
  they fire again.

**For base event layer tuning:**
- Generic VISIT_ event refactor — revisit once Step 2 is live and the
  VISIT sub-pool's actual behavior is visible. Don't refactor blind.
- ASK_OUT becomes a goal-event once the goal system exists
- ENERGY_CRASH storybook needs room-aware templates once GO_HOME is
  softened ("fell asleep at the bar" vs generic "body gave out")

---

## Files Changed This Session

| File | Change |
|---|---|
| events.gd | Full rewrite: base_category + fulfills_need on 35 events, 10 events deleted, GO_HOME → auto_fire, SPILL_DRINK removed, FLIRT templates updated |
| actions.gd | Full rewrite: dispatcher cleaned (22 entries removed), 7 dead functions removed, 9 functions reorganized, 3 bug fixes |

## Files NOT Changed (but need updates from this session's decisions)

| File | Needed Update |
|---|---|
| CLAUDE.md | New Current Sprint block (below) |
| Decisions Log | 7 new entries (listed above) |
| Event Design Bible | Note about deleted events, beat-conversion plan |
| Roadmap | Phase 5 parking lot items |
| Architecture Reference | GO_HOME now auto_fire in tick loop description |
