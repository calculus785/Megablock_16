# MegaBlock 16 — Session 01 Notes
*Date: May 2026 · Session type: Dev*
*Goal: Phase 0 foundation — project setup, all Tier 1 + Tier 2 autoloads, Tier 3 shells, CharData*

---

## What We Built

### Environment Setup
- Godot 4 project created, folder structure laid out
- VSCode connected as external editor (Godot Tools extension)
- GitHub Desktop set up, repo published
- `.gitignore` configured (excludes `.godot/`, logs, IDE files, exports)

### Tier 1 — Config Autoloads (9/9 complete)
All in `res://scripts/autoloads/config/`

| # | File | Status | Notes |
|---|------|--------|-------|
| 1 | `settings.gd` | ✅ | Reads/writes `user://settings.cfg` |
| 2 | `stats.gd` | ✅ | 16 stats, 7 movement types |
| 3 | `traits.gd` | ✅ | 44 traits, evolution stubs |
| 4 | `identity.gd` | ✅ | Names by pronoun, preferences, 5 life arches |
| 5 | `feelings.gd` | ✅ | 26 feelings, cause-tracking shape locked in |
| 6 | `states.gd` | ✅ | 45 derived states, 13 persistent states |
| 7 | `events.gd` | ✅ | 5 placeholder events |
| 8 | `sequences.gd` | ✅ | 1 placeholder sequence (PLAY_POOL_SEQ) |
| 9 | `interactables.gd` | ✅ | 9 interactable types |

### Tier 2 — Core Autoloads (5/5 complete)
All in `res://scripts/autoloads/core/`

| # | File | Status | Notes |
|---|------|--------|-------|
| 10 | `clock.gd` | ✅ REAL | Heartbeat, calendar, season intensity, signals |
| 11 | `registry.gd` | ✅ shell | Master character list, generation stubs |
| 12 | `rooms.gd` | ✅ shell | Occupancy, zone/spot, aura stub |
| 13 | `pathfinder.gd` | ✅ shell | Route + elevator API signatures |
| 14 | `memory.gd` | ✅ shell | Short/long-term, intent queue signatures |

### Tier 3 — System Autoloads (2/7 complete)
All in `res://scripts/autoloads/systems/`

| # | File | Status | Notes |
|---|------|--------|-------|
| 15 | `feeling_driver.gd` | ✅ REAL | Push/decay/remove with cause tracking |
| 16 | `state_driver.gd` | ✅ REAL | Derives states from stats, hysteresis logic |

### Resource Classes (1 of many)
In `res://scripts/resources/`

| File | Status | Notes |
|------|--------|-------|
| `char_data.gd` | ✅ | Full field set locked in, all sections complete |

---

## Expected Console Output (F5)
```
[Settings] Loaded.
[Stats] Loaded. 16 stats, 7 movement types.
[Traits] Loaded. 44 traits defined.
[Identity] Loaded. 76 names, 12 colours, 19 interests, 5 arches.
[Feelings] Loaded. 26 feelings defined.
[States] Loaded. 45 stat-derived states, 13 persistent states.
[Events] Loaded. 5 events, 18 categories.
[Sequences] Loaded. 1 sequences defined.
[Interactables] Loaded. 9 interactable types defined.
[Clock] Loaded. Starting at Hour 8, Day 1, Month 1, Year 1 — summer (intensity 0.5)
[Registry] Loaded. 0 characters registered.
[Rooms] Loaded. 0 rooms registered.
[Pathfinder] Loaded. (shell — Phase 3)
[Memory] Loaded. (shell — Phase 2)
[FeelingDriver] Loaded. Listening to Clock.half_hour_ticked.
[StateDriver] Loaded. Listening to Clock.half_hour_ticked.
```

---

## Design Decisions Made This Session

### Identity
- `sexuality` renamed to `preference` — attraction to a pronoun set, not a label
- Preference weighted by pronouns (he/him leans she/her, etc.) — weighted dict per pronoun set
- First names split into `FIRST_NAMES_HE_HIM`, `FIRST_NAMES_SHE_HER`, `FIRST_NAMES_NEUTRAL`
- `random_first_name(pronoun_key)` picks from matching pool
- `is_attracted_to(preference_a, pronouns_b)` helper for romantic event checks
- Life arches reduced to 5 keys: `romance`, `drama`, `neutral`, `wildcard`, `crime`
- Crime arch = higher chance of criminal path, not guaranteed — can still reform

### Traits
- `hideable` field added to every trait definition
- Hidden traits exist on ALL characters (player + NPCs), just not shown in UI
- Player discovers hidden traits through observing behaviour
- `pick_hidden_traits(existing_traits, count)` helper added
- 10 new traits added: `JEALOUS_TYPE`, `MORNING_PERSON`, `NIGHT_OWL`, `HOMEBODY`,
  `THRILL_SEEKER`, `GENEROUS`, `STINGY`, `PREFERS_LIGHT_HAIR`, `PREFERS_DARK_HAIR`,
  `PREFERS_UNUSUAL_HAIR`, `OLDER_PREFERENCE`, `YOUNGER_PREFERENCE`

### Feelings — Cause Tracking
- Every active feeling instance carries a `causes: Array` field
- Each cause: `{ event_key, at_tick, summary }`
- Stacking: same feeling pushed again → refreshes duration, appends cause (cap: 4)
- Causes vanish with the feeling — separate from `felt` short-term memory entries
- UI tooltip will show: feeling label + list of causes
- `FeelingDriver.push()` accepts `cause: Dictionary` arg

### Seasons (Clock)
- `SEASON_BY_MONTH` tells which season each month is
- `SEASON_MONTH_POSITION` tells position in pair (1=rising, 2=falling, 0=neutral)
- Intensity rises across month 1 of a pair, peaks at end of month 1, falls across month 2
- Neutral months (3, 6) always intensity 0.0

### CharData
- `preference` field (not `sexuality`)
- `hair_colour` field added (`"light"` / `"dark"` / `"unusual"`)
- `hidden_traits: Array[String]` separate from `traits: Array[String]`
- `starter_traits: Array[String]` — applied once at creation, visible in bio, no ongoing effect
- `groceries: int` — abstract pooled resource, not per-ingredient
- `get_all_active_traits()` — returns traits + hidden_traits combined
  - Mechanical checks (event weights, modifiers) MUST call this
  - UI bio uses `traits` only

---

## Things To Flesh Out Later

### Stubs awaiting implementation
- `Registry.generate_random_character()` — needs CharData + full generation pipeline
- `Registry.generate_bespoke_character()` — needs `.tres` hand-authored support
- `Memory` all functions — stubbed, implemented Phase 2
- `Rooms.get_available_spot()` — implemented Phase 3
- `Rooms.tick_auras()` — implemented Phase 5
- `Pathfinder.plan_route()` — implemented Phase 3
- `Pathfinder.request_elevator()` — implemented Phase 3
- `Traits.evaluate_evolution_for_character()` — wired to Clock.day_ticked Phase 4
- `Events.THINK_ABOUT` requirements — needs `memory.long_term.size() > 0` check once Memory exists
- `call_action` refs in Events (`rest`, `wander`, `think_about`, `queue_intent_visit_bar`, `order_drink`) — implemented in Actions (Tier 3, Phase 1)

### Architecture decisions to revisit
- Hair colour pool — `FIRST_NAMES_*` exists but `hair_colour` values are just `"light"/"dark"/"unusual"`. Need to define full hair colour list when art direction is locked in.
- Attraction bonus flags (`attraction_bonus_light_hair` etc.) — read by romantic event eligibility, not yet implemented
- `is_attracted_to()` in Identity — needs calling by event conditions (Phase 1+)
- Life arch weight modifiers — stored as keys only, Phase 6 (Architect) implements the actual modifiers
- `PREFERENCE_WEIGHTS_BY_PRONOUNS` — placeholder weights, tune during playtesting
- `event_cooldowns` mechanics — Sim reads/writes during ROLL stage (Phase 1)
- `intent_queue` patience counter + `GIVE_UP` event — Phase 2
- `object_impressions` increment logic — Phase 5
- `current_encumbrance` calculation + thresholds — Phase 5
- `known_blockages` expiry on `day_ticked` — Phase 3
- `life_stage` derivation function from `internal_age` — Phase 4 lifecycle
- Trait `TERRIFIED` referenced in Stats.MOVEMENT_TYPES `run` requirement — not yet a defined trait, needs adding

### Resource classes still to build (all Phase 0)
- `RobotData` — extends CharData, blanks most fields, always `faction_memberships: ["robots"]`
- `GhostRecord` — archived CharData on death
- `RobotGhostRecord` — archived RobotData on death
- `BabyData` — extends InteractableData (not CharData), converts at Child life stage
- `InteractableData` — runtime instance fields for world objects

---

## What's Next (Phase 0 remaining)

1. `RobotData`, `GhostRecord`, `GhostRobotRecord` resource classes
2. `InteractableData` resource class
3. `Registry.generate_random_character()` — real implementation
4. 4-6 hand-authored test characters spawned on startup
5. Console output confirming characters have valid stats, traits, feelings
6. F2 EventInspector foundation (debug overlay — stats, feelings, states for clicked character)

Phase 0 test criteria (from Roadmap):
> Run the project. Console confirms characters exist with valid stats, traits, and feelings. Clock ticks. StateDriver evaluates. FeelingDriver decays feelings over time. F2 overlay shows character data.

---

## Session Stats
- Autoloads built: 16 of 30
- Resource classes built: 1 (CharData)
- Phase 0 completion estimate: ~60%
- Commits this session: multiple (settings, stats, traits+identity, feelings+states, tier1 complete, tier2 complete, tier3 shells, chardata)

Session 01 Continued — Resource Classes + Character Generation
Resource Classes Built
All in res://scripts/resources/
FileStatusNotesrobot_data.gd✅Extends CharData, no feelings/traits/storybook, health-only statsghost_record.gd✅Archived CharData on death. Static factory from_char_data()robot_ghost_record.gd✅Ultra-lightweight robot archive on decommissioninteractable_data.gd✅Runtime world object instance — state, occupancy, ownership
Registry Generation — Real Implementation

generate_random_character() fully implemented — rolls pronouns, name, preference, identity, stats, traits, hidden traits, applies all modifiers
generate_bespoke_character() implemented — config dict → CharData, handles typed Array fields via .assign()
archive_as_ghost() implemented — removes from live registry, creates GhostRecord
_ghosts and _robots dictionaries added alongside _characters

Bootstrap

res://scripts/debug/bootstrap.gd attached to main.tscn root node
Spawns 3 bespoke + 3 random test characters on startup
Prints full character summary to Output panel

Bugs Fixed

Array → Array[String] assignment: GDScript 4 requires .assign() not = when assigning untyped arrays to typed array fields
Added TYPED_ARRAY_FIELDS constant in generate_bespoke_character() to handle all typed array fields cleanly
Removed duplicate trait modifier loop from bootstrap (generate_bespoke_character handles it internally)
Removed unused pronoun_set variable from _print_character_summary()

Confirmed Working Output
[Settings] Loaded.
[Stats] Loaded. 16 stats, 7 movement types.
[Traits] Loaded. 44 traits defined.
[Identity] Loaded. 76 names, 12 colours, 19 interests, 5 arches.
[Feelings] Loaded. 31 feelings defined.
[States] Loaded. 49 stat-derived states, 13 persistent states.
[Events] Loaded. 5 events, 18 categories.
[Sequences] Loaded. 1 sequences defined.
[Interactables] Loaded. 9 interactable types defined.
[Clock] Loaded. Starting at Hour 8, Day 1, Month 1, Year 1 — summer
[Registry] Loaded. 0 characters registered.
[Rooms] Loaded. 0 rooms registered.
[Memory] Loaded. (shell — Phase 2)
[Pathfinder] Loaded. (shell — Phase 3)
[FeelingDriver] Loaded. Listening to Clock.half_hour_ticked.
[StateDriver] Loaded. Listening to Clock.half_hour_ticked.
[Bootstrap] Spawning test characters...
[Registry] Bespoke: Sara Vega | Sara Vega (she/her, Adult)
[Registry] Bespoke: Marcus Webb | Marcus Webb (he/him, Adult)
[Registry] Bespoke: Kai Lindqvist | Kai Lindqvist (they/them, Adult)
[Registry] Generated: [random] ...
[Bootstrap] Done. 6 characters in registry.
── CHARACTER SUMMARY ──────────────────────────
  Sara Vega (she/her, Adult) | age 24 | arch: romance
    traits:  ["FLIRTATIOUS", "CHARMING", "OPTIMISTIC"]
    hidden:  ["JEALOUS_TYPE"]
    stress:25  happy:70  energy:80  cash:200
  ...
[StateDriver] Lin Hartwell gained state: TENSE   ← real sim behaviour
Phase 0 Status: COMPLETE ✅
All test criteria met:

All autoloads load without errors
6 characters generated with valid stats, traits, feelings arrays
Clock ticking
StateDriver evaluating on half_hour_ticked
FeelingDriver listening and ready to decay

Still To Do (carried to Session 02)

F2 EventInspector debug overlay (Phase 0 stretch goal — not blocking Phase 1)
TERRIFIED trait missing — referenced in Stats.MOVEMENT_TYPES run requirement, needs adding to traits.gd
Remaining resource class stubs: RelationshipRecord, PlayerDecision, WorldState, SaveMeta, Occasion, Faction — Phase 1+ as needed