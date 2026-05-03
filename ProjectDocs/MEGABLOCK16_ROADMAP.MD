# MegaBlock 16 — Development Roadmap
*Living document. Semi-permanent — avoid changes unless necessary.*
*Created: Architecture Planning Meeting, Session 3-4*
*Codename: MegaBlock 16 (final title TBD)*

---

## How To Read This Document

Each phase has a clear goal, a list of what ships, what it depends on, and an estimated session count. A "session" is one afternoon of focused work (3-5 hours). Estimates are conservative — some sessions will be faster, some will need a second pass.

Phases are sequential. Don't skip ahead. Each phase produces something testable before moving on.

**Total estimated sessions to "show someone" build: ~50-65**
**Total estimated sessions to early access: ~90-120**

---

## Phase 0 — Clean Slate
**Goal:** Empty Godot project with the entire data backbone wired up. Nothing visible. Everything compiles and runs.
**Estimated sessions: 4-6**

**What ships:**
- New Godot 4 project, folder structure (see Architecture Reference doc), .gitignore, first commit
- CharData resource class with ALL fields locked in the architecture meeting
- RobotData subclass (lightweight CharData for robot workers)
- GhostRecord and RobotGhostRecord resource classes
- BabyData resource class (InteractableData subclass)
- All Tier 1 config autoloads with starter data:
  - Settings (first in load order, reads user://settings.cfg)
  - Stats (all 16 stats with defaults, clamp ranges, movement type definitions)
  - Traits (all traits, modifier definitions, evolution thresholds + daily evolution check)
  - Identity (name pools, pronouns, colour, age, interest generation)
  - Feelings (all feelings, durations, decay rates, hidden flag support)
  - States (all stat-derived states, evaluation rules, persistent states list)
  - Events (structure only, ~5 placeholder events)
  - Sequences (structure only)
  - Interactables (starter definitions)
- Tier 2 core autoloads (empty shells with correct API signatures):
  - Clock (heartbeat, calendar, season intensity curve, day/hour/tick signals)
  - Registry (master character list, generation, lookup by ID)
  - Rooms (occupant tracking, zone/spot data, aura ticking stub)
  - Pathfinder (route API signatures, elevator dispatch stub)
  - Memory (read/write API signatures)
- Tier 3 system autoloads (shells):
  - FeelingDriver (push/tick/decay, targeted feelings, hidden feelings)
  - StateDriver (evaluate stat-derived states on half-hour tick)
- 4-6 hand-crafted test characters generated on startup
- Console output confirming all autoloads loaded, characters generated, clock ticking
- EventInspector foundation (F2 debug overlay — stats, feelings, states for selected character)

**Test criteria:** Run the project. Console confirms characters exist with valid stats, traits, and feelings. Clock ticks. StateDriver evaluates. FeelingDriver decays feelings over time. F2 overlay shows character data.

**Depends on:** Nothing. This is day one.

---

## Phase 1 — The Simulation Brain
**Goal:** Events fire. Characters do things. The 7-stage pipeline works end to end in the console.
**Estimated sessions: 5-7**

**What ships:**
- Events autoload populated with ~20-30 starter events:
  - Solo events (think, wander, rest, eat, idle)
  - Social events (greet, chat, argue, compliment, insult)
  - Room events (visit_bar, visit_library, go_home)
  - Sleep/wake cycle events
- Sequences autoload with 2-3 starter sequences (pool game, conversation, argument)
- Sim autoload — the full 7-stage pipeline:
  - ROLL (weighted random from eligible pool)
  - RESOLVE (target resolution with filter keys)
  - FRAME (context arg resolution — declarative + Context)
  - ACT (Actions.call_action)
  - EXECUTE (stat changes, storybook writes)
  - ECHO (short-term memory, relationship delta)
  - CONTINUE (DONE / REPEAT / LOCK_SEQUENCE)
- Actions autoload (starter action functions)
- Context autoload (starter resolution functions)
- ForceEvent panel (F3 — pick character + event, fire immediately)
- EventInspector upgraded (show eligible events + weights, last 5 events fired)
- Storybook entries writing to CharData
- Console output showing event flow in readable format

**Test criteria:** Characters autonomously cycle through events. Storybook fills up. Stats drift. Feelings emerge from events. Sequences lock characters and play through beats. ForceEvent can trigger any event on any character. All visible in F2 overlay.

**Depends on:** Phase 0.

---

## Phase 2 — Memory & Intent
**Goal:** Characters remember, plan ahead, and build habits. The simulation starts feeling alive in the logs.
**Estimated sessions: 3-4**

**What ships:**
- Memory autoload:
  - Short-term memory (5 categories × 2 entries, oldest dropped)
  - Long-term memory (memorable flag on storybook entries, memory_tags, times_recalled)
  - Daily pruning of non-memorable storybook entries
- Intent queue on CharData:
  - Checked before ROLL each tick
  - Priority ordering (critical → high → normal → low)
  - Patience counter, GIVE_UP event on expiry
  - Clearable vs non-clearable intents
- Pipeline integration:
  - Intents fire before weighted roll
  - ECHO stage writes short-term memory
  - REPEAT tracks consecutive count, pushes feelings at thresholds
- Events that read memory:
  - THINK_ABOUT targeting long-term memories
  - Relationship deltas from memory tone (fond vs resentful recall)
- Object impressions system (on CharData, gated by character interests)
- Program impressions (room schedule familiarity, same dictionary as object impressions)

**Test criteria:** Characters form memories. Think_about surfaces old events. Intent queue drives planned behaviour. Characters give up when patience runs out. Object impressions accumulate for characters with matching interests. F2 overlay shows memory contents and intent queue.

**Depends on:** Phase 1.

---

## Phase 3 — The Building (Visual Prototype)
**Goal:** You can see the building, the rooms, and coloured shapes walking around. The invisible sim becomes visible.
**Estimated sessions: 6-8**

**What ships:**
- Building scene (main scene, 2D cross-section layout):
  - 3+ floors visible
  - Room slots rendered as panels
  - Elevator shafts connecting floors
- Room scenes (3D SubViewport per room):
  - Basic 3D block geometry (walls, floor, ceiling — no detail yet)
  - Zone nodes with Spot positions pre-authored
  - Doors (visual indicator of room entry/exit)
  - Starter rooms: cafe, library, bar, 6 apartments
- Rooms autoload populated with real layout data (occupants, zone/spot occupancy, aura ticking for occupied rooms only)
- RoomCatalogue and BuildingBlueprint data populated
- CharacterBody scene (Node2D, billboard):
  - Coloured rectangle placeholder (unique colour per character)
  - NameLabel
  - BubbleContainer (feeling icons placeholder)
  - Hand nodes (Left/Right attachment points)
- Pathfinder autoload (full implementation):
  - Room-to-room routing
  - Knowledge-limited pathfinding
  - Blockage discovery on arrival
  - known_blockages on CharData
  - Elevator dispatch and car movement
  - 2 elevator cars with state (idle/moving/doors_open)
  - Lobby waiting zones per floor
- MovementController (node on CharacterBody):
  - Reads waypoints, advances position
  - Movement type speed multipliers (from Stats autoload)
  - Three-lane hallway system (back/middle/front)
- Proximity-reactive events (hallway encounters during transit)
- 6 characters spawned and visible in their apartments on game start
- Camera autoload with basic controls (pan, zoom, FREE mode)

**Test criteria:** Building renders. Characters visible in rooms. Characters walk to elevator, ride between floors, enter rooms. Pathfinding routes correctly. Elevator dispatches and carries passengers. F2 overlay works on clicked characters. Events fire with room context driving eligibility.

**Note:** First phase with 3D work in Godot. Budget extra time for learning SubViewport workflows.

**Depends on:** Phases 0-2.

---

## Phase 4 — Relationships & Social Drama
**Goal:** Characters form opinions of each other. Bonds grow and decay. Social events have real weight.
**Estimated sessions: 4-5**

**What ships:**
- Relationships autoload:
  - Pairwise RelationshipRecord storage (indexed by character ID for O(1) lookup)
  - Bond, trust, rivalry, familiarity fields
  - Directional feelings (a_feels, b_feels — attraction, jealousy, parental_bond, filial_bond)
  - 15-tier spectrum calculation from bond score
  - Bond decay on day_ticked (configurable rates per tier)
  - Familiarity never decays
  - API: get, modify, get_tier, get_all_above_tier, get_all_below_tier
- Romantic tier event gates (ASK_OUT, ASK_TO_GO_STEADY, PROPOSE)
- Trait soft-locks (LONER caps at BEST_FRIEND, 5% override)
- Sexuality compatibility checks for romantic tiers
- ~15 new relationship-driven events
- Trait evolution (daily check inside Traits autoload):
  - trait_progress counter incremented by actions
  - Threshold crossed → trait granted or modified
  - Coexisting traits (ALCOHOLIC + RECOVERING_ALCOHOLIC)
- Targeted feelings integration
- Faction sentiment field on CharData (institutional factions only for now)
- EventInspector upgraded: show relationship tiers and directional feelings

**Test criteria:** Characters form bonds over time. Tiers progress. Romantic chains fire with event gates. Gossip spreads. Grief propagates on death. Trait evolution triggers. F2 shows relationship data.

**Depends on:** Phase 3.

---

## Phase 5 — World Objects & Inventory
**Goal:** The world has stuff in it. Characters pick things up, break things, decorate apartments.
**Estimated sessions: 3-4**

**What ships:**
- InteractableData resource class (full field set)
- Starter interactables per room (bar counter, pool table, bookshelves, statue, coffee machine, beds, shelves, decoration spots)
- Interactable scenes (3D placeholder geometry)
- Inventory system on CharData (held_items, carried_items, equipped, apartment_items, apartment_storage, encumbrance)
- Aura ticking in Rooms autoload (occupied rooms only, skip empty aura_effects, per-stat and per-room caps, personality sensitivity roll)
- Breaking system (Actions: break_item, material-based results)
- Ownership system (building/communal/personal, transfers on theft)
- ~10 new interactable events (use, admire, steal, break, gift, decorate)
- Gifting system (personality match scoring, relationship deltas)

**Test criteria:** Characters interact with objects. Items appear in hands. Apartments decorated. Theft and breaking work. Auras affect characters. Encumbrance works.

**Depends on:** Phase 4.

---

## Phase 6 — The Architect & Calendar
**Goal:** The simulation has rhythm. Quiet periods, chaotic bursts, seasons, birthdays. The building breathes.
**Estimated sessions: 4-5**

**What ships:**
- Architect autoload (includes all tunable config as @export vars):
  - Rolling event log, daily prune
  - Building mood evaluation (quiet/normal/chaotic)
  - Global weight multipliers by mood
  - Character selection for boosted major events (pool-first, weighted pick, player character x1.5)
  - Story thread tracking (open/close/cap at 5-7)
  - Building event scheduling (own cooldown)
  - Death clustering suppression (NATURAL/ILLNESS only)
  - Emotion loop breaker
  - Upcoming occasions list (holidays, festivals, gatherings)
  - Auto-fire event gate (approves/suppresses based on mood)
- Auto-fire pipeline step (between intent check and weighted roll)
- trigger_mode ("auto_fire" | "rolled") and priority (0-100) fields on Events
- Calendar in Clock:
  - Numbered months (1-6), 5-day weeks, 3-week months
  - Season cycle: summer/summer/neutral/winter/winter/neutral
  - Season intensity curve (0 → peak → 0 over 30 days)
  - Birthday tracking and firing
- Season weight modifiers on events (mods not requirements — fire in winter still possible)
- ~5 building events (power outage, elevator breakdown, festival)
- Holiday/festival system (global weight mod packages, Architect-applied)
- Room schedule system (recurring programs in RoomCatalogue)
- Birthday event (age-up + WISH_HAPPY_BIRTHDAY)

**Test criteria:** Building mood shifts. Major events cluster then quiet down. Threads open/close. Seasons cycle. Birthdays fire. Building events on Architect cooldown. Auto-fire events trigger when conditions met and Architect approves.

**Depends on:** Phase 5.

---

## Phase 7 — Factions, Police & Management
**Goal:** The building has power structures. Gangs form, cops investigate, the Mayor runs things.
**Estimated sessions: 5-7**

**What ships:**
- Factions autoload (includes config data, name/badge generator pools):
  - Faction resource class
  - Gang formation events (criminal stat gates)
  - Procedural name + badge generator
  - Homeless faction (auto-managed, single collective, auto-entry/exit, own name pool)
  - Faction sentiment shifts from witnessed events
  - Gang member cap (4-6, tunable)
- Police autoload:
  - Case filing (witness-based only)
  - Investigation, evidence threshold, arrest, jail timer
  - Robot vs human dispatch (humans first, robots backup)
  - Detective role (unique events)
  - Police-as-witness rules (robots: always process; humans: roll with CORRUPT/BY_THE_BOOK)
  - Max human officers cap
- Mayor autoload:
  - Building progression / move-in schedule
  - Apartment assignment and inheritance (partner → child → highest bond → vacant)
  - Rent collection (monthly calendar event)
  - Eviction → homelessness flow
  - Room open/close
  - Holiday decoration dispatch
  - Procedural holiday naming (3 generated options, player picks)
- Strata autoload:
  - Robot pool and deployment
  - Elevator maintenance dispatch
  - Decoration drone deployment
  - Robot vacancy fill (immediate)
- Jobs autoload (includes coverage tables):
  - Shift coverage per room (required/robot_only/human_preferred)
  - Human vs robot assignment
  - Job satisfaction on CharData
  - QUIT_JOB event
  - Vending machine fallback
- Management floor (physical space with animated robots, status screens)
- Homeless system (sleep spots, survival events, path back to employment)
- ~20 new events

**Test criteria:** Gangs form with unique names/badges. Crimes reported, investigated, resolved. Shifts work. Eviction → homelessness → recovery path. Management floor animates. Faction sentiment shifts.

**Depends on:** Phase 6.

---

## Phase 8 — Scale & Stress Test
**Goal:** Go from 6 to 10 to 25 characters. Find what breaks. Fix it.
**Estimated sessions: 3-4**

**What ships:**
- SimRunner (main game at max speed, rendering disabled, full pathfinding/transit, log to user://logs/)
- StoryReader (prose output, filterable by character/event/day)
- Copy-pasteable debug output panel ([Copy All] on all debug tools)
- SimLab scene (controlled environment, hand-crafted characters)
- Scale testing: 10 → 25 characters
- Performance fixes
- Building layout expanded for 25 residents

**Test criteria:** 25 characters stable for 100+ in-game days. No crashes, leaks, or sub-30fps. SimRunner completes. Save file under 5MB.

**Depends on:** Phase 7.

---

## Phase 9 — Player Character & UI
**Goal:** The player is IN the building. Pop-ups work. The HUD tells the story.
**Estimated sessions: 5-7**

**What ships:**
- Character creation screen (name, pronouns, colour, 3 traits, life arch, age 16, watcher mode option — permanent, explicit warning)
- Decisions autoload (queue, timer, resolution, PlayerDecision resource, pop-up UI non-modal, "Choose for me" option)
- PLAYER_GATE pipeline step in Sim
- First-run pop-up tutorial + preference selection (pause all / pause major / timer all / disabled)
- Pop-up settings (per-source toggle, timer duration slider)
- Management trio personalities (Mayor: formal, Architect: cryptic, Jobs: transactional)
- Player death flow (grace period → announcement → 2-day gap → new character creation)
- News ticker (bottom/top adjustable, colour-coded, ticker_worthy flag, fade timing)
- HUD (clock, speed controls, story threads, character info panel)
- Camera autoload finalised (FREE/FOLLOW/CINEMATIC/OVERVIEW, smooth transitions, Escape to FREE)

**Test criteria:** Player creates character, enters building. Pop-ups fire correctly with trio personalities. Death triggers full transfer. News ticker works. Camera modes functional.

**Depends on:** Phase 8.

---

## Phase 10 — Save System
**Goal:** Player can leave and come back.
**Estimated sessions: 2-3**

**What ships:**
- Saves autoload (save/load/list/delete/auto_save, WorldState resource, SaveMeta resource, restore_from methods on all managers)
- Per-character .tres files, ghost record saving
- Pre-save cleanup (prune storybooks, trim logs)
- Save versioning with migrations
- Auto-save daily at 04:00 (3 rotating slots), manual save (5 slots)

**Test criteria:** Save 25 characters. Close. Load. Everything restored. Under 5MB.

**Depends on:** Phase 9.

---

## Phase 11 — The Chronicle
**Goal:** The player's story curation tool. The feature that makes this game worth talking about.
**Estimated sessions: 3-5**

**What ships:**
- Chronicle UI (browse storybooks, pin to named timelines, "Life" master view, filter by character/event/day)
- Pinned entries exempt from pruning
- "times_recalled" flavour text
- Improved storybook templates (narrative tone)
- 40-year rolling cap, 50 memorable entry soft cap
- Story thread click-through to multi-POV Chronicle view

**Test criteria:** Pin entries, name timelines. Life view works. Pinned entries survive pruning. Storybook reads as narrative.

**Depends on:** Phase 10.

---

## Phase 11.5 — Scenario Design Toolkit
**Goal:** Build specialised Claude chat workflows for rapid content creation.
**Estimated sessions: 2-3 (setup), then ongoing**

**What ships:**
- **Event Design Chat** — dedicated Claude Project:
  - Upload: current Events data, Sequences, Actions list, architecture docs
  - Workflow: describe a scenario in plain English → Claude breaks it into events, actions, weight mods, requirements, storybook templates → checks for duplication → outputs copy-pasteable event definitions
- **Storybook Template Chat** — dedicated Claude Project:
  - Input: event ID + context
  - Output: 3-5 storybook text variants, literary tone, template variables filled
- **Balance Review Chat** — dedicated Claude Project:
  - Input: SimRunner logs or StoryReader output (pasted)
  - Output: event frequency analysis, stuck characters, dead weight mods, Architect config tuning suggestions
- Custom instructions document for each chat type
- Example session transcripts

**Why this exists:** Game content will dwarf the codebase. Efficient content pipelines mean 20 events per session instead of 3. These chats are design tools.

**Test criteria:** Describe a scenario, receive event definitions, paste into project, scenario works in-game within one session.

**Depends on:** Phases 0-7 (working event system needed).

---

## Phase 12 — Demo Polish ("Show Someone" Build)
**Goal:** 4-5 floors, 10 characters, enough events and rooms to be interesting for 30 minutes.
**Estimated sessions: 4-6**

**What ships:**
- Building: 4-5 floors, bar, cafe, library, cinema, shop, 10 apartments, management floor, 2 elevators + stairs
- 10 bespoke characters with distinct personalities
- 50+ total events
- Cinema (weekly film rotation, placeholder data)
- Shop (vending machine, no worker)
- Art pass (better placeholders — distinct silhouettes, colours, room theming)
- Audio pass (positional AudioStreamPlayer2D, room ambience, 1-2 music tracks)
- Bug fixing, balance pass (Architect config, event weights, decay rates)
- Main menu, title screen

**Test criteria:** A new player can start, create a character, watch stories emerge, curate in the Chronicle, save, return. Understands the game in 5 minutes. Wants to keep watching.

**Depends on:** All previous phases.

---

## Beyond Demo — Early Access Roadmap (High Level)

Intentionally vague. Designed properly after demo proves the concept.

**Phase 13 — Art & Animation:** Character sprites, face expressions, animation states, body types, room art.

**Phase 14 — Full Room Set:** Hospital, school, gym, park, rooftop, pawn shop, church. Zone/spot layouts, interactables, schedules, room events.

**Phase 15 — Life Stages & Reproduction:** Pregnancy chain, BabyData → CharData, parenting events (settle, comfort, diaper, show off, panic), family tracking, orphan system, school room, apartment model changes.

**Phase 16 — Scale to 45:** Full building, 45 character stress test, performance pass, .tres → .res.

**Phase 17 — Advanced Systems:** Faction wars, cliques, leaving gangs, court/judge/prison, full hiring/firing, store revenue, phone system.

**Phase 18 — Early Access Launch Prep:** 25+ characters, full gangs, building finalised, 100+ events, balance pass, distribution prep.

---

## Autoload Reference (30 Total)

### Tier 1 — Config (9)
Settings, Stats, Traits, Identity, Feelings, States, Events, Sequences, Interactables

### Tier 2 — Core (5)
Clock, Registry, Rooms, Pathfinder, Memory

### Tier 3 — Systems (7)
FeelingDriver, StateDriver, Relationships, Context, Actions, Audio, Camera

### Tier 4 — Simulation (1)
Sim

### Tier 5 — Domain (6)
Architect, Mayor, Strata, Police, Factions, Jobs

### Tier 6 — Player (2)
Decisions, Saves

---

## Key Design Principles (For Every Session)

1. **Data-driven.** Behaviour in Resources, not hardcoded logic.
2. **Event-based.** Ticks → events → state change → next events.
3. **Single source of truth.** CharData is canonical.
4. **Handoff pattern.** Systems own their domain, hand off at boundaries.
5. **TV show mindset.** Stories, not chores. Drama, not spreadsheets.
6. **Emergence over authoring.** Systems produce stories. Don't script them.
7. **Room → Zone → Spot.** Always. Every time.
8. **Test small.** Small testable chunks over massive refactors.
9. **Profile before optimising.** Don't guess what's slow.
10. **The building is the character.** Not any one person. The whole thing.