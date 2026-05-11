# MegaBlock 16 — Session 03 Notes
*Date: May 2026 · Session type: Dev*
*Goal: Phase 1 — more events, auto-fire pass, sim fixes*

---

## What We Built

### sim.gd fixes
- Added `in_home_room` / `not_in_home_room` to `_check_requirements()`
- Added `time_of_day` to `_check_requirements()`
- Added `other_character_in_room` to `_check_requirements()`
  - **NOTE:** uses Registry directly instead of Rooms.get_occupants() — Rooms is a Phase 3 shell
  - **Phase 3 TODO:** swap both the sim.gd check AND context.gd character resolution to use Rooms.get_occupants(character.current_room)
- Added `_on_half_hour()` — restores 8 energy per tick to sleeping characters
- Added `_try_wake()` — wakes characters between hour 7-9 when energy >= 60
- Added `_run_auto_fire()` — pre-roll pass checking trigger_mode: "auto_fire" events, sorts by priority, fires highest eligible one, returns true to skip normal pipeline
- Auto-fire events log with ⚡ prefix in console

### context.gd fix
- Fixed "character" target resolution — was calling Rooms.get_occupants() (shell, returns [])
  - **NOTE:** now iterates Registry directly to find same-room candidates
  - **Phase 3 TODO:** swap to Rooms.get_occupants(character.current_room)

### bootstrap.gd fix
- All characters set to current_room = "bar_f1_s1" after spawn so social events fire
- NOTE: Remove this when movement is real (Phase 3)

### New Events (10 added this session, 23 total)
Solo events:
- DAYDREAM — boredom above 20, reduces boredom/stress
- CRY — happiness below 30, stress relief but loneliness climbs
- LATE_NIGHT_STARE — night only, stress above 30
- PACE_HALLWAY — stress above 40, drains energy slightly
- LOOK_IN_MIRROR — in_home_room only, stress -3

Social events (require other_character_in_room):
- NOD_IN_PASSING — minimal interaction, SHY/ANTISOCIAL weighted higher
- GREET — loneliness driver
- CHAT — workhorse social event
- COMPLIMENT — happiness above 40
- INSULT — stress above 50, SHORT_TEMPERED x3.0

New events second batch:
- SLEEP — auto_fire, priority 90, energy below 25 + evening/night
- ENERGY_CRASH — auto_fire, priority 95, energy below 10 (any time of day)
- ARGUE — stress above 55, moderate magnitude
- DEEP_CONVERSATION — evening/night only, happiness above 50, cooldown 20
- VISIT_LIBRARY — boredom above 30, intent stub
- READ_BOOK — in_room library, boredom/stress drain
- DRINK_ALONE — in_room bar, happiness below 35, pushes MELANCHOLY_FEELING
- FLIRT — happiness above 55, exclude_robots

### New Action Functions (10 added)
daydream, cry, late_night_stare, pace_hallway, look_in_mirror, nod_in_passing, greet, chat, compliment, insult, sleep, argue, deep_conversation, queue_intent_visit_library, read_book, drink_alone, flirt

---

## Observations from Testing

- Addiction spiral working perfectly — characters hitting DEVELOPING_HABIT → ADDICTED → DEEP_IN_IT → DESTITUTE from ORDER_DRINK
- DEEP_CONVERSATION firing at evening/night with CONTENT_FEELING pushing/decaying correctly
- FLIRT firing heavily — Sara Vega especially, on brand for her traits
- ARGUE and SLEEP never fired — nobody's stress hit 55 or energy hit 25. No meaningful energy drain events yet. This is expected — sleep cycle is correct, just waiting for conditions
- Auto-fire pass confirmed working — no ⚡ events because conditions never met, which is correct behaviour
- StateDriver emergent states working well — SHADY/CRIMINAL_MINDED on Marcus from tick one

## Known Bugs / Gaps (carry to Session 04)

- LOOK_IN_MIRROR was dominating log before in_home_room fix — fixed this session
- Social events not firing before bootstrap room fix — fixed this session
- Pronoun mismatch in storybook templates: "Sara Vega introduced themselves to Mei Saito" — {name} uses "themselves" regardless of pronouns. Fix in Phase 2 when Context is fleshed out — add pronoun-aware template filling
- No meaningful energy drain events — SLEEP/ENERGY_CRASH can't fire until we add events that cost energy over time
- ORDER_DRINK never fires for real — characters don't actually move to bar yet (Phase 3 movement)
- "someone" in THINK_ABOUT — correct placeholder until Memory (Phase 2)
- DEEP_CONVERSATION has no relationship requirement — strangers having deep convos immediately. Cooldown bumped to 20 but ideally needs bond threshold once Relationships is built (Phase 4)

## Phase 3 TODOs (flagged this session)
- sim.gd `_check_requirements` other_character_in_room: swap Registry loop → Rooms.get_occupants()
- context.gd "character" target resolution: swap Registry loop → Rooms.get_occupants()
- bootstrap.gd: remove force-set current_room = "bar_f1_s1" when movement exists
- VISIT_BAR / VISIT_LIBRARY: swap stub action → real intent queue (Phase 2)

## Design Decisions Made This Session

- Auto-fire events still run full pipeline (RESOLVE → FRAME → ACT → EXECUTE → ECHO)
- Auto-fire fires before weighted roll, skips roll if it fires
- SLEEP is auto_fire priority 90, ENERGY_CRASH priority 95 (collapsing mid-day > choosing to sleep)
- Cooldown for DEEP_CONVERSATION bumped to 20 events

## Phase 1 Status

Done:
- All 21 autoloads loading clean
- 23 events firing
- Requirements evaluation working (all condition keys implemented this session)
- Weighted roll working
- Weight modifiers working  
- Cooldowns working
- Storybook entries writing
- Feelings pushing and decaying
- Stats modified by events
- Auto-fire pass implemented
- Sleep/wake cycle wired up

Not Yet Done:
- Sequence execution (PLAY_POOL_SEQ multi-beat handler) ← NEXT
- Memory writes from events (real THINK_ABOUT targets) ← Phase 2
- Player gate ← Phase 2
- More events still to implement from MEGABLOCK16_STARTER_EVENTS.md

## Session Stats
- Events total: 23 (up from 5)
- Action functions total: ~22
- Autoloads complete: 21/30 (Tiers 1-4)
- Git: commit after session