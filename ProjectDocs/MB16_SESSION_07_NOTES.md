# MB16 Session 7 Notes
Session type: Dev session
Phase: Phase 3 — The Building (Visual Prototype)
Status: Phase 3 substantially complete. Final items in progress.

---

## What We Did This Session

### Bug Fixes (from Session 6 carry-forward)

**Sleep location bug — FIXED**
- Added `"go_home"` to the `call_action` dispatcher in `actions.gd` (was missing, causing silent fail)
- Added `"in_home_room": true` to SLEEP event requirements
- Lowered ENERGY_CRASH threshold from 10 to 5 (true emergency fallback only)

**GO_HOME not firing reliably — FIXED**
- Lowered `cooldown_events` from 5 to 3
- Added `"boredom_exempt": true` to GO_HOME

**Boredom system rework**
- Replaced `BOREDOM_EXEMPT_PAIRS` dictionary in `sim.gd` with two new per-event fields:
  - `boredom_exempt: true` — never generates boredom (navigation/movement events)
  - `boredom_exempt_traits: [...]` — exempt if character has any listed trait
- `_apply_repetition_boredom()` rewritten to read these fields from the event definition
- Applied across all relevant events in `events.gd`

**Pronoun template bug — FIXED**
- LOOK_IN_MIRROR, SLEEP, ENERGY_CRASH templates updated to use `{they}`, `{their}`, `{were_was}`

**VISIT_LIBRARY missing start_movement — FIXED**
- `_queue_intent_visit_library()` now calls `start_movement()` before queuing intent (mirrors bar/cafe pattern)

---

### Full 2D → 3D Visual Layer Conversion

**Scope:** Every visual file changed. All sim/autoload files untouched.

**Scale:** 1 unit = 32px = 1 grid square

**Files changed:**
- `main.tscn` — Node3D root, WorldEnvironment, DirectionalLight3D
- `building.gd` — Node3D, Camera3D orthographic→perspective, Vector3 positions, BoxMesh elevator cars
- `building_data.gd` — floor type system expanded for specific room scenes
- `FloorApartments.tscn`, `FloorLargeCommon.tscn`, `FloorSmallCommon.tscn`, `FloorLobby.tscn` — Node3D root, Sprite3D (PNG overlay at Z=0), Marker3D nodes
- `character_body.gd` — Node3D + QuadMesh billboard + Label3D
- `movement_controller.gd` — Vector3 tweens, BASE_SPEED = 6.0 units/sec
- `pathfinder.gd` — Vector3 waypoints, Node3D car nodes, CAR_SPEED = 9.0 units/sec
- `rooms.gd` — all position getters return Vector3, new door/zone storage
- `bootstrap.gd` — Node3D character bodies

**Camera:** Perspective, FOV 45, starts at Z=50. Scroll wheel moves Z (zoom). Arrow keys pan.

**Z-depth layers:**
- PNG overlay: Z=0 (flush)
- Characters (hallway): Z=0.5
- Room geometry: Z=0 to -depth (behind overlay)

---

### Room Geometry

Built in editor per room type. All rooms use BoxMesh nodes under `Geometry/` node.

Room sizes (units):
- Large common (bar/cafe/grocery): 24W × 10H × 4.0D
- Small common: 16W × 10H × 3.5D  
- Apartment: 12W × 8H × 3.0D

Room scenes created:
- `room_bar.tscn`
- `room_large_common.tscn` (generic fallback)
- `room_small_common.tscn`
- `room_apartment.tscn`

Room scenes are instanced into floor scenes at `RoomX_Origin` markers by `building.gd _instance_room_scene()`.

**Floor type system:** Each specific room floor type defined in `FLOOR_TYPES` with its own `room_scene` path per slot. Generic `large_common` kept as fallback.

---

### BubbleContainer

Script: `res://scripts/world/bubble_container.gd`
- Shows active feelings as coloured billboard quads above character head
- Positioned at Y=2.8 on character body
- Refreshes by comparing actual feeling keys (not just count)
- Each bubble stores `feeling_key` as metadata for comparison
- `FeelingDriver.get_active_feelings()` added to `feeling_driver.gd`

---

### StorybookDisplay

Script: `res://scripts/world/storybook_display.gd`
- Shows last 4 storybook entries as Label3D above character
- Positioned at Y=3.5 on character body
- Toggled globally with **F4** key (wired in `building.gd`)
- Only refreshes when storybook entry count changes
- Lines wrap at 40 characters

---

### Three-Lane Hallway System

Each floor scene has three Marker3D nodes at root level (not in Spots):
- `HallwayLane0` — back lane (Z closest to wall)
- `HallwayLane1` — middle lane
- `HallwayLane2` — front lane (Z closest to camera)

`building.gd _register_floor_info()` reads all three and stores them as `hallway_lanes: [Vector3, Vector3, Vector3]` in floor data.

`pathfinder.gd plan_route()` picks a random lane at route start. All hallway waypoints use that lane's Z. Same-floor routes also use lane system.

Old `HallwayLine` marker removed from all floor scenes.

---

### Door System

Script: `res://scripts/world/door.gd`
- Attach to Node3D root with `DoorMesh` child (BoxMesh)
- Export `slide_direction: Vector3` — hallway doors: `(-1,0,0)`, room doors: `(0,0,-1)`
- Export `slide_distance: float` — default 2.5
- `request_open()` — opens door, increments occupant count
- `notify_through()` — decrements count, starts close timer (1.5s) if empty
- `is_open()` — returns true when state == OPEN
- Signals: `door_opened`, `door_closed`

Scene: `res://scenes/world/door.tscn`

**Naming convention:**
- Hallway doors: children of `Doors/` node in floor scene, named `Door0`, `Door1`, `Door2`
- Room doors: child of `Geometry/` in room scene, named `Door0`

`building.gd _register_doors()` discovers doors by index (slot order = door number).
`rooms.gd` stores: `_hallway_doors`, `_room_doors` dictionaries.

**Required markers per room scene:**
- `DoorWaitPos` — inside room, just in front of room door
- `DoorwayPos` — the gap between room door and hallway door
- `SpawnPos` — interior spawn point (replaces floor scene RoomX_Spawn)

**Required markers per floor scene slot:**
- `RoomX_Door` — hallway side door position
- `RoomX_Doorway` — hallway side threshold gap
- `RoomX_Origin` — center-bottom of room cutout (for room scene placement)

**RoomX_Spawn removed from floor scenes.** Spawn now lives inside room scenes.

---

### Waypoint System (full entry/exit sequence)

Exit sequence:
1. `wait_room_door_exit` — walk to DoorWaitPos, room door opens
2. `exit_room_doorway` — walk through DoorwayPos, room door starts closing
3. `wait_hallway_door_exit` — walk to door_pos, hallway door opens
4. `exit_hallway_doorway` — walk through doorway_pos, hallway door starts closing
5. `walk` — hallway lane waypoints

Entry sequence:
1. `walk` — hallway lane waypoints
2. `wait_hallway_door` — approach door_pos, hallway door opens
3. `enter_doorway` — walk through doorway_pos, hallway door starts closing
4. `wait_room_door` — wait at DoorwayPos, room door opens
5. `arrive` — walk to SpawnPos inside room

---

### Zone & Spot System (implemented, not yet tested in-game)

See `MB16_ZONES_SPOTS_PROXIMITY_GUIDE.md` for full reference.

**Structure:**
```
Zones (Node3D)
└── Zone_Counter (Node3D)
    ├── Spot_0 (Marker3D)
    ├── Spot_1 (Marker3D)
    └── Spot_2 (Marker3D)
```

`building.gd _instance_room_scene()` reads zones after `add_child()` and registers via `Rooms.set_zones()`.

New `rooms.gd` functions: `set_zones`, `get_zone`, `get_available_spot`, `get_any_available_spot`, `claim_spot`, `release_spot`, `release_all_spots`, `zone_has_space`, `is_in_zone`, `get_character_zone`.

New requirement keys in `sim.gd _check_requirements()`: `in_zone`, `zone_has_space`, `room_has_zone`.

---

### New Events Added

**Zone-specific (events.gd):**
- `SIT_AT_BAR` — requires Zone_Counter in bar
- `LEAN_ON_COUNTER` — requires in Zone_Counter
- `BROWSE_SHELVES` — requires Zone_Shelves in library
- `WINDOW_WATCH` — requires Zone_Window in cafe
- `LIE_IN_BED` — requires Zone_Bed in home room
- `CHECK_SUPPLIES` — requires Zone_Aisles in grocery

**Proximity (events.gd, trigger_mode: "proximity"):**
- `HALLWAY_NOD` — light, always eligible
- `HALLWAY_CHAT` — light, requires happiness > 40
- `AWKWARD_HALLWAY_PASS` — light, requires stress > 40
- `HALLWAY_BUMP` — light, low weight comedy

---

### Proximity System (designed, stub implemented)

`movement_controller.gd` checks for nearby in-transit characters after each `walk` waypoint. Calls `Sim.fire_proximity_event(actor, target)`.

`sim.gd` has new `fire_proximity_event()` and `_get_eligible_proximity_events()` methods. Proximity events use `trigger_mode: "proximity"` — separate from "rolled" and "auto_fire".

`_proximity_fired` array on movement_controller prevents same pair firing twice per journey. Resets on `start_movement()`.

Heavy proximity events (HALLWAY_CHAT) need a pause timer in movement_controller — **not yet implemented**, flagged for next session.

---

## Known Bugs / Pending Fixes

**Heavy proximity event pause** — HALLWAY_CHAT fires but doesn't actually pause character movement. Need a brief timer in `_move_to_next()` that suspends and resumes. Flagged for next session.

**Zone movement** — `_move_to_zone()` in actions.gd claims a spot but doesn't tween character body to spot position yet. Characters logically occupy spots but don't physically walk to them inside the room. Flagged for Phase 4/5.

**Door registration timing** — `_register_doors()` runs after `_register_floor_rooms()` which calls `_instance_room_scene()`. Room nodes exist by the time door registration runs. Confirmed working.

---

## On the Horizon

- Heavy proximity event pause/resume
- Zone physical movement (tween to spot position)
- Aura system (Phase 5)
- Phase 4 — Relationships

---

## Decisions Log Entries

**Room scenes are specific, not generic** — Each room type (bar, cafe, library etc.) gets its own scene file rather than a shared large_common scene. Scenes linked via `FLOOR_TYPES` entries in `building_data.gd`. Generic `large_common` kept as fallback only. Session 7.

**Boredom system moved to event definitions** — `boredom_exempt` and `boredom_exempt_traits` fields live on the event dict, not in a separate lookup in sim.gd. Data-driven, easier to author. Session 7.

**Door naming by slot index** — Hallway doors named `Door0/1/2` (slot order), room doors named `Door0`. Code zips by index. No room IDs in node names. Session 7.

**Spawn positions moved inside room scenes** — `RoomX_Spawn` markers removed from floor scenes. `SpawnPos` marker inside each room scene, registered by `_instance_room_scene()` after add_child. Session 7.

**Proximity events use separate trigger_mode** — `"proximity"` trigger mode keeps them cleanly separated from rolled and auto_fire events. `fire_proximity_event()` on Sim is the entry point, called by movement_controller. Session 7.

---

## Context Template Variable Guide (PENDING)

Still needs to be written. Copy-paste reference for all template variables:
- Pronouns: `{name}`, `{they}`, `{them}`, `{their}`, `{themself}`, `{They}`, `{Them}`, `{Their}`
- Target variants: `{target}`, `{target_they}` etc.
- Conjugations: `{s}`, `{es}`, `{have_has}`, `{are_is}`, `{were_was}`
- Room: `{room}`

Flagged to produce as end-of-session documentation. Still outstanding.
