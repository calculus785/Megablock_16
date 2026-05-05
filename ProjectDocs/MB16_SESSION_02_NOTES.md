# MegaBlock 16 - Session 02 Notes

Session type: Dev
Goal: Complete Phase 0 stretch goals, begin Phase 1 - events firing

## What We Built

### Phase 0 Completion
- F2 EventInspector - CanvasLayer overlay, Tab cycles characters, shows stats/traits/feelings/states/clock
  - Scene: res://scenes/debug/event_inspector.tscn
  - Script: res://scripts/ui/event_inspector.gd
  - Auto-refreshes on Sim.event_fired signal
  - Input action ui_inspector_toggle registered to F2
  - Restructured to ScrollContainer so full content is readable

### Tier 3 Remaining System Autoloads (4 more)
All in res://scripts/autoloads/systems/

- relationships.gd - shell, pairwise records, get_bond/familiarity/tier stubs, Phase 4
- context.gd - partial, resolve_target, build_frame, fill_template, target fallback "someone" until Memory
- audio.gd - stub, play_sfx/ambience/sting, Phase 3
- camera.gd - stub, set_mode/follow/pan_to, Phase 3

### Actions (Tier 3)
- res://scripts/autoloads/systems/actions.gd
- Dispatcher pattern - call_action(name, character, target, args) routes by name
- Implemented: rest, wander, think_about, queue_intent_visit_bar, order_drink
- modify_stat() helper - all stat changes go through this
- ADDICT_PRONE doubles addiction climb in order_drink

### Sim (Tier 4)
- res://scripts/autoloads/simulation/sim.gd
- Full 7-stage pipeline: ROLL > RESOLVE > FRAME > PLAYER_GATE > ACT > EXECUTE > ECHO
- Connected to Clock.tick
- Event eligibility: full requirements evaluation
- Weighted roll with modifier application
- Event-count cooldowns (cooldown_events field on event definitions)
- _apply_outcomes() - stat deltas + feelings from event definition
- _echo() - storybook entry written per event, template filled via Context
- event_fired signal emitted - EventInspector listens

### Cooldown System
- Decision locked: cooldown_events field on each event in events.gd, not hardcoded in Sim
- _event_counter - global int, increments every time any event fires on any character
- Speed-independent: character does N other events before repeating regardless of sim speed
- Current values: REST=2, WANDER=3, THINK_ABOUT=2, VISIT_BAR=8, ORDER_DRINK=0

### Bugs Fixed
- {target} not filling in THINK_ABOUT templates - fixed fallback to "someone" in Context.build_frame()
- EventInspector not auto-refreshing - connected to Sim.event_fired signal

## Known Gaps (carry to Session 03)

- ORDER_DRINK never fires - wander/visit_bar stubs dont actually move characters
  in_room: bar requirement never matches. Fix when movement lands in Phase 3.
- "someone" everywhere in THINK_ABOUT - correct behaviour. Real targets come from Memory (Phase 2).
- Debug output overwhelming - 6 chars x every tick = flood. Need per-character filter.
- Autoload load order - Sim loads before Relationships/Context/Actions. Must fix by reordering
  in Project Settings so order is: FeelingDriver, StateDriver, Relationships, Context, Audio, Camera, Actions, Sim

## Design Decisions Made This Session

### Cooldowns
- Architecture: cooldown_events field on each event definition, no hardcoded dict in Sim
- Reads event_def.get("cooldown_events", 0) - zero means no cooldown
- Future expansion Phase 3: layer not_recent_room requirement for location plausibility
- Future expansion Phase 3: track last_visited_rooms history on CharData

### EventInspector
- Phase 0 version: stats, traits, feelings (with causes), states, clock
- Phase 1+ additions planned: eligible events + weights, storybook tail, relationships

## Things To Flesh Out Later (accumulated)

- Traits.evaluate_evolution_for_character() - wire to Clock.day_ticked Phase 4
- Memory all functions - Phase 2
- Rooms.get_available_spot() / tick_auras() - Phase 3/5
- Pathfinder.plan_route() / request_elevator() - Phase 3
- Relationships.modify_bond() - Phase 4
- THINK_ABOUT memory requirement - once Memory built
- ORDER_DRINK actually firing - once movement works Phase 3
- Life arch weight modifiers - Phase 6 Architect
- TERRIFIED trait missing - referenced in Stats.MOVEMENT_TYPES run requirement
- BabyData resource class - Phase 5/15
- RelationshipRecord, PlayerDecision, WorldState, SaveMeta, Occasion, Faction resource classes
- Cooldown v2: layer location memory + intent-based cooldowns Phase 3
- Per-character debug filter or N-tick summary mode for Sim output

## Phase 1 Status

Done:
- Tier 3 complete (all 7 system autoloads registered)
- Sim pipeline running - events fire every tick
- Requirements evaluation working
- Weighted roll working
- Weight modifiers working
- Cooldowns working (event-count based)
- Storybook entries writing
- Feelings pushed from outcomes
- Stats modified by events

Not Yet Done:
- Auto-fire pass (priority events that bypass weighted roll)
- Sequence execution (PLAY_POOL_SEQ multi-beat handler)
- Player gate (when player character exists)
- Memory writes from events (real THINK_ABOUT targets)
- More starter events from MEGABLOCK16_STARTER_EVENTS.md

## Session Stats
- Autoloads built total: 21 of 30 (Tiers 1-4 complete)
- Resource classes: CharData, RobotData, GhostRecord, RobotGhostRecord, InteractableData
- Events firing: yes, pipeline working end to end
- Git: pushed and up to date after session