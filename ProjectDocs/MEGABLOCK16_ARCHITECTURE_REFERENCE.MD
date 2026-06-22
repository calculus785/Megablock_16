# MegaBlock 16 — Architecture Reference
*Project knowledge document. Reference for all chat sessions.*
*Created: Architecture Planning Meeting, Session 3-4*

---

## What This Document Is

The single source of truth for how the codebase is organised. Covers folder structure, autoload map with load order, resource classes, naming conventions, system relationships, and the simulation pipeline. Every dev session, brainstorm session, and event design session should reference this.

---

## Project Folder Structure

```
megablock16/
├── project.godot
├── .gitignore
│
├── scripts/
│   ├── autoloads/
│   │   ├── config/              # Tier 1 — pure data, no dependencies
│   │   │   ├── settings.gd
│   │   │   ├── stats.gd             # includes movement types
│   │   │   ├── traits.gd            # includes evolution logic
│   │   │   ├── identity.gd
│   │   │   ├── feelings.gd
│   │   │   ├── states.gd
│   │   │   ├── events.gd
│   │   │   ├── sequences.gd
│   │   │   └── interactables.gd
│   │   │
│   │   ├── core/                # Tier 2 — reads Tier 1
│   │   │   ├── clock.gd             # calendar, seasons, signals
│   │   │   ├── registry.gd          # character list, generation
│   │   │   ├── rooms.gd             # occupancy, zones, aura ticking
│   │   │   ├── pathfinder.gd        # routing, elevators, blockages
│   │   │   └── memory.gd            # short/long-term, intent, pruning
│   │   │
│   │   ├── systems/             # Tier 3 — reads Tier 1 + 2
│   │   │   ├── feeling_driver.gd
│   │   │   ├── state_driver.gd
│   │   │   ├── relationships.gd
│   │   │   ├── context.gd
│   │   │   ├── actions.gd
│   │   │   ├── audio.gd             # includes config data
│   │   │   └── camera.gd
│   │   │
│   │   ├── simulation/          # Tier 4 — orchestrator
│   │   │   └── sim.gd
│   │   │
│   │   ├── domain/              # Tier 5 — meta systems
│   │   │   ├── architect.gd         # includes config as @export
│   │   │   ├── mayor.gd
│   │   │   ├── strata.gd
│   │   │   ├── police.gd
│   │   │   ├── factions.gd          # includes config + generator
│   │   │   └── jobs.gd              # includes coverage tables
│   │   │
│   │   └── player/              # Tier 6 — loaded last
│   │       ├── decisions.gd
│   │       └── saves.gd
│   │
│   ├── resources/               # Resource class definitions
│   │   ├── char_data.gd
│   │   ├── robot_data.gd
│   │   ├── ghost_record.gd
│   │   ├── robot_ghost_record.gd
│   │   ├── baby_data.gd
│   │   ├── interactable_data.gd
│   │   ├── relationship_record.gd
│   │   ├── faction.gd
│   │   ├── occasion.gd
│   │   ├── player_decision.gd
│   │   ├── world_state.gd
│   │   └── save_meta.gd
│   │
│   ├── characters/
│   │   ├── character_body.gd
│   │   └── movement_controller.gd
│   │
│   ├── building/
│   │   ├── building.gd
│   │   └── room.gd
│   │
│   ├── ui/
│   │   ├── hud.gd
│   │   ├── news_ticker.gd
│   │   ├── popup.gd
│   │   ├── chronicle.gd
│   │   ├── event_inspector.gd
│   │   ├── force_event.gd
│   │   ├── character_creation.gd
│   │   └── main_menu.gd
│   │
│   └── debug/
│       ├── sim_runner.gd
│       ├── story_reader.gd
│       └── sim_lab.gd
│
├── scenes/
│   ├── building/
│   │   ├── building.tscn
│   │   └── management_floor.tscn
│   │
│   ├── rooms/                   # 3D SubViewport scenes
│   │   ├── apartment_single.tscn
│   │   ├── apartment_couple.tscn
│   │   ├── apartment_family.tscn
│   │   ├── bar.tscn
│   │   ├── cafe.tscn
│   │   ├── library.tscn
│   │   ├── cinema.tscn
│   │   ├── shop.tscn
│   │   ├── police_station.tscn
│   │   └── [future rooms]
│   │
│   ├── characters/
│   │   └── character_body.tscn
│   │
│   ├── interactables/           # 3D interactable scenes
│   │   ├── pool_table.tscn
│   │   ├── bar_counter.tscn
│   │   ├── bookshelf.tscn
│   │   ├── statue.tscn
│   │   └── [more as added]
│   │
│   ├── elevators/
│   │   └── elevator_car.tscn
│   │
│   ├── ui/
│   │   ├── hud.tscn
│   │   ├── popup.tscn
│   │   ├── chronicle.tscn
│   │   ├── character_creation.tscn
│   │   └── main_menu.tscn
│   │
│   └── debug/
│       ├── sim_lab.tscn
│       ├── event_inspector.tscn
│       └── force_event.tscn
│
├── assets/
│   ├── audio/
│   │   ├── sfx/
│   │   ├── ambience/
│   │   ├── music/
│   │   └── stings/
│   ├── sprites/
│   │   ├── characters/
│   │   ├── interactables/
│   │   ├── ui/
│   │   └── badges/
│   └── textures/
│       ├── rooms/
│       └── building/
│
└── data/                        # External data files (if needed)
    ├── name_pools.json
    ├── faction_name_pools.json
    └── movie_catalogue.json
```

---

## Autoload Map (30 Total)

### Tier 1 — Config (9) — Pure data, no dependencies

| Autoload | Purpose | Absorbed |
|---|---|---|
| Settings | Game/display/audio/debug settings. user://settings.cfg. FIRST loaded. | — |
| Stats | 16 stat definitions, defaults, clamps | MovementConfig |
| Traits | Trait defs, modifiers, evolution thresholds + daily check | TraitEvolutionManager |
| Identity | Name pools, pronouns, colours, ages, interests, life arches | — |
| Feelings | Feeling defs, durations, decay rates, hidden flag | — |
| States | Stat-derived state rules, persistent state list | — |
| Events | All event definitions (reqs, weights, call_action, trigger_mode, player_choice, ticker_worthy) | — |
| Sequences | Multi-beat sequence definitions | — |
| Interactables | Interactable definitions (tags, aura, interaction rules) | — |

### Tier 2 — Core (5) — Reads Tier 1

| Autoload | Purpose | Absorbed |
|---|---|---|
| Clock | Heartbeat, calendar, seasons, intensity curve, signals | — |
| Registry | Master character list, generation, ID lookup | — |
| Rooms | Occupant tracking, zone/spot occupancy, aura ticking (occupied rooms only) | AuraManager |
| Pathfinder | Room-to-room routing, elevator dispatch + car state, blockages | ElevatorManager |
| Memory | Short/long-term read/write, intent queue, daily pruning | — |

### Tier 3 — Systems (7) — Reads Tier 1 + 2

| Autoload | Purpose | Absorbed |
|---|---|---|
| FeelingDriver | Push/tick/decay feelings, targeted, hidden | — |
| StateDriver | Evaluate stat-derived states each half-hour | — |
| Relationships | Pairwise records, 15-tier spectrum, decay, directional feelings | — |
| Context | Complex arg resolution for events | — |
| Actions | Action functions called by events, world state changes | — |
| Audio | Positional playback (AudioStreamPlayer2D), ambience, stings | AudioConfig |
| Camera | FREE/FOLLOW/CINEMATIC/OVERVIEW modes, transitions | — |

### Tier 4 — Simulation (1) — Orchestrator

| Autoload | Purpose | Absorbed |
|---|---|---|
| Sim | The 7-stage pipeline. Per-character tick loop. | — |

### Tier 5 — Domain (6) — Meta systems

| Autoload | Purpose | Absorbed |
|---|---|---|
| Architect | Pacing, mood, threads, building events, calendar, occasions, auto-fire gate | ArchitectConfig |
| Mayor | Progression, apartments, rent, eviction, room open/close, holidays | — |
| Strata | Robot pool, elevator maintenance, decoration drones, vacancy fill | — |
| Police | Cases, investigation, arrest, dispatch, detective | — |
| Factions | Create/dissolve, membership, name/badge generator, homeless faction | FactionConfig |
| Jobs | Shift coverage, human/robot assignment, satisfaction, quit | JobConfig |

### Tier 6 — Player (2) — Last loaded

| Autoload | Purpose | Absorbed |
|---|---|---|
| Decisions | Pop-up queue, timer, resolution, management trio voices | — |
| Saves | Save/load, WorldState, versioning, migrations, auto-save | — |

---

## Naming Conventions

**Autoloads:** short, unambiguous, no suffix. Tier structure implies role.
**Resource classes:** PascalCase class (`CharData`), snake_case file (`char_data.gd`).
**Variables:** snake_case. IDs as strings. Booleans prefixed (`is_homeless`).
**Room IDs:** `type_fFLOOR_sSLOT` (e.g. `bar_f2_s2`).
**Vocabulary:** Room → Zone → Spot. Always. Every time.

---

## The Simulation Pipeline

```
Every tick (5-8 real seconds), Sim loops every character:

Skip if sleeping
Skip if in transit (except proximity_reactive)
Check intent queue → fire if any
Check auto-fire pool → fire highest priority if Architect approves
If in sequence → advance to next beat
Otherwise → BASE_ROLL → category sub-pool roll →

RESOLVE → FRAME → PLAYER_GATE → ACT → EXECUTE → ECHO → CONTINUE

Periodic:

Half-hour: Clock advances, FeelingDriver decays, StateDriver evaluates, Rooms ticks auras

Daily: Memory prunes, Relationships decays, Traits checks evolution, Architect evaluates mood + calendar, Clock updates season intensity

On room arrival: Sim fires one reactive event
```
---
- total_ticks: int — monotonic, never resets. Added Session 26 for arc
  timestamps and log prefixes (get_total_days() was too coarse — multiple
  arcs open/close within one in-game day).
  
## The Base Event Layer

A filtering step ahead of the normal event roll, not a separate pipeline
stage — resolves same-tick (decide and act in one tick).
---

BASE_ROLL:

Roll a base category (FULFILL_NEED, SOCIALIZE, VISIT, INTROSPECT,

IDLE, WORK), weighted by character state.

Boredom/loneliness boost SOCIALIZE/VISIT weights, never trigger

FULFILL_NEED directly.
If intent_queue already has 3 entries (soft cap), base events

don't fire — character stays on its current behavior.


Category resolver filters events.gd by base_category (+ matching

fulfills_need if category is FULFILL_NEED, comparing severity if

multiple stats are in deficit).
Roll a specific event from that filtered sub-pool — same weighted

roll as before, just on a smaller pool.
Unresolvable category (no valid sub-pool, e.g. SOCIALIZE with no

target and nowhere to visit) → weight 0, doesn't fire that tick.
Specific event proceeds through RESOLVE → FRAME → PLAYER_GATE →

ACT → EXECUTE → ECHO as normal.

**CALLOUT (SOCIALIZE, same-room target):** initiator picks a target,
target rolls accept/decline (base 60 + bond*0.3 − busy_penalty per
queued intent + mood/trait/feeling/energy modifiers, clamped 5–95).
Decline produces minor/no storybook ("too busy to talk"). No target in
room → SOCIALIZE resolves to VISIT instead.

CALLOUT applies to any sequence-locking event with a character target, regardless of trigger path (base-roll or proximity, excludes autofire events).

**current_motivation (CharData field):** `{type, need, plan}` — set when
a base event resolves, cleared when the chain completes or the queue is
flushed. Lets a future storybook helper narrate multi-step chains (e.g.
FULFILL_NEED→hunger→no ingredients→BUY_GROCERIES→MAKE_FOOD) as one story
instead of disconnected log lines.

**Queue priority buffer:** critical/world events bypass the 3-item soft
cap and push regardless (e.g. a lockdown doesn't erase an already-queued
BUY_GROCERIES — it resumes after). Only genuine emergencies (injury,
arrest) flush the queue outright.

## System Communication

```
Clock signals → Sim, FeelingDriver, StateDriver, Rooms, Memory, Relationships, Traits, Architect
Sim calls     → Events, Actions, Context, Memory, Decisions
Actions calls → Memory, Relationships, Rooms, Pathfinder, Factions, Audio
Architect     ← listens to Sim (event fired) + Clock (day_ticked)
              → applies weight mods to Sim's eligible pool
Mayor         ← Clock (rent, progression)
              → Registry (spawn), Rooms (open/close), Strata (decorations)
Police        ← Sim (crime events), Clock (investigation timers)
Audio         ← Camera (room ambience), Actions (sound triggers)
Camera        ← player input, Architect (cinematic triggers)
```

---

## CharData — All Fields

```
IDENTITY:    char_id, char_name, internal_age, life_stage, job,
             apartment_id, pronouns, sexuality, favourite_color,
             interests, life_arch, birth_month, birth_day,
             favorite_genre, favorite_movie

STATS:       stats (Dict), traits (Array), feelings (Array),
             feeling_timers, states, persistent_states,
             event_cooldowns, trait_progress

MEMORY:      short_term_memory (5 categories × 2), intent_queue,
             storybook (memorable, memory_tags, times_recalled,
             last_recalled_day, pinned_to_story)

LOCATION:    current_room, home_room, is_in_transit,
             movement_target_room, waypoints, waypoint_index,
             movement_type, known_blockages, is_sleeping

SEQUENCE:    active_sequence, sequence_beat, sequence_partner_id,
             sequence_role, sequence_context

INVENTORY:   held_items (max 2), carried_items,
             equipped (hat/costume/faction_badge),
             apartment_items, apartment_storage, current_encumbrance

IMPRESSIONS: object_impressions (includes program impressions)

SOCIAL:      faction_sentiment (Dict), faction_memberships (Array), current_motivation (Dict: type, need, plan)

JOB:         job_satisfaction, is_employed, is_homeless

FAMILY:      parent_ids, child_ids, sibling_ids

current_arc_id: int, story_arcs: Array (populated Phase 11, stamped from Phase 4)
```
## ARC TRACKING (added Session 26)

Fields on CharData:

- current_arc_id: int
  -1 = no arc open. Otherwise a sequential int, unique across the whole
  session (assigned from Sim._arc_counter).

- current_arc_data: Dictionary
  The live, in-progress arc. Mirrors current_arc_id deliberately — not
  collapsed into one field, for inspector/logging readability.
  Shape while open:
    {
      "arc_id": int,
      "base_event": String,      # the event_key that opened this arc
      "opened_tick": int,        # Clock.total_ticks at open
      "event_keys": Array,       # every event_key fired during this arc
    }
  Gets "closed_tick": int appended at close, then the whole dict is
  duplicated into story_arcs and current_arc_data resets to {}.

- story_arcs: Array
  Closed arcs only. Each entry is the full dict shape above, including
  closed_tick.

## What an arc is

An arc is the event trail for one base-roll decision, start to finish —
not a relationship/drama arc. Opens when Sim commits a character to a
new motivation (a base category roll that successfully fires an event).
Everything that happens as a downstream consequence of that motivation —
intent queue items, sequence beats, give-ups, auto-fire interrupts —
appends into the same arc's event_keys. Closes when the character is
free to roll a new base motivation.

Dividing line for whether something appends vs. closes-and-opens:
does the original motivation still exist after this happens?
  - Auto-fire interrupt mid-sequence → append (motivation survives,
    character just got knocked off course)
  - FLEE_AVOIDED → close + open new (motivation replaced outright;
    the original goal is abandoned, not delayed)

No consumer logic exists yet. This is plumbing for the Phase 8 log
summarizer and Phase 11 Chronicle generator. Built in Session 26
alongside the related Clock.total_ticks field (see Clock section) and
the [T<tick> A<arc_id>] log format (see Log Format section).

Owning functions (sim.gd): _open_arc(), _close_arc(), _append_arc().
---

## Calendar

```
Tick = 5-8 real seconds    |  Week = 5 days (Day 5 = Restday)
Half-hour = ~18.75 sec     |  Month = 3 weeks = 15 days
Day = 15 real minutes      |  Year = 6 months = 90 days
                           |  Lifespan = 40 years = ~900 real hours

Months numbered 1-6. No names. Display: "Month 3 · Week 2 · Day 4 — Year 47"
Seasons: summer/summer/neutral/winter/winter/neutral (30 days each)
Intensity peaks at day 15 of each season. Weight mod only, never requirement.
```

---

## Relationship Tiers

```
-100          MORTAL_ENEMY     |  +10 to +19    ACQUAINTANCE
-80 to -99    ENEMY            |  +20 to +39    FRIENDLY
-60 to -79    RIVAL            |  +40 to +59    FRIEND
-40 to -59    DISLIKED         |  +60 to +74    CLOSE_FRIEND
-20 to -39    UNFRIENDLY       |  +75 to +84    BEST_FRIEND
-10 to -19    COOL             |  +85 to +94    ROMANTIC_INTEREST ★
-9  to +9     NEUTRAL          |  +95 to +97    PARTNER ★
                               |  +98 to +99    DEEPLY_BONDED
                               |  +100          MARRIED ★
                               |  ★ = event-gated transition
```

---

## Debug Tools

```
F2  EventInspector   Stats, feelings, states, memory, intents, eligible events,
                     relationships, factions. BUILD FIRST.
F3  ForceEvent       Pick character + event, fire. BUILD SECOND.
    SimRunner        Max speed, no rendering, logs to file. Phase 8.
    StoryReader      Prose output, filterable. Phase 8.
    SimLab           Separate scene, hand-crafted characters. Phase 8.
    All tools:       [Copy All] button for debug chat sessions.
```

---

## Life Stages

```
Baby 0-2 (BabyData) | Child 2-8 | Teen 8-16 | Adult 16-35 | Elderly 35-40
Age hidden from player. UI shows stage only. Player starts at 16.
```

---

## Key Design Principles

1. Data-driven. Behaviour in Resources, not hardcoded logic.
2. Event-based. Ticks → events → state change → next events.
3. Single source of truth. CharData is canonical.
4. Handoff pattern. Systems own their domain, hand off at boundaries.
5. TV show mindset. Stories, not chores.
6. Emergence over authoring. Systems produce stories. Don't script them.
7. Room → Zone → Spot. Always.
8. Test small. Small chunks over massive refactors.
9. Profile before optimising. Don't guess what's slow.
10. The building is the character.