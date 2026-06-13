# MB16 Session 10 Notes
Session type: Dev session
Phase: Phase 3 — The Building (Visual Prototype) — COMPLETE
Status: Phase 3 fully wrapped. Phase 4 ready to begin.

---

## What We Did This Session

### Proximity Event Pause/Resume — IMPLEMENTED AND WORKING

Fixed the core issue: `_check_proximity()` fires from `_on_tween_finished`, meaning the tween is already done when the pause is requested. Pausing the tween did nothing.

**Fix:** Added `_proximity_paused` flag to `movement_controller.gd` that gates `_move_to_next()`.

```gdscript
var _proximity_paused: bool = false

func pause_for_proximity(duration: float) -> void:
    if not _is_moving:
        return
    _proximity_paused = true
    if _tween and _tween.is_valid():
        _tween.kill()
    _pause_timer.start(duration)

func _on_pause_finished() -> void:
    _proximity_paused = false
    if _is_moving:
        _move_to_next()

func _move_to_next() -> void:
    if _proximity_paused:   # ← guard at top
        return
    # ... rest unchanged
```

`sim.gd` calls `_pause_character_movement()` for heavy proximity events, finding the character body via `/root/main/Building/Characters` and calling `pause_for_proximity(duration)` on `MovementController`.

Pause durations: HALLWAY_CHAT = 4.0s, BRIEF_CONVERSATION = 6.0s.

---

### BRIEF_CONVERSATION Proximity Event — ADDED

New heavy proximity event. Longer pause than HALLWAY_CHAT, requires loneliness > 40 or happiness > 35, gives more loneliness relief.

```gdscript
"BRIEF_CONVERSATION": {
    proximity_type: "heavy",
    base_weight: 4,
    cooldown_events: 15,
    outcomes: { loneliness: -10, boredom: -5 (both) },
    storybook_templates: [
        "{name} and {target} stopped in the hallway. One of them said something real.",
        "{name} caught {target} on the way out. They talked for a minute — actually talked.",
        "It was just the hallway, but {name} and {target} stayed longer than they meant to.",
    ]
}
```

Dispatcher + `_brief_conversation()` stub added to actions.gd.

---

### Room Door Not Closing — FIXED

**Root cause:** On entry, `wait_room_door` calls `door.request_open()` (occupant_count → 1). But nothing calls `notify_through()` on the room door after the character walks through to `arrive`. So occupant_count stays at 1 forever. On next exit, `request_open()` increments to 2, `exit_room_doorway` calls `notify_through()` → count back to 1, timer never fires.

**Fix:** In `movement_controller.gd _on_tween_finished()`, call `notify_through()` on the room door when the `arrive` waypoint completes:

```gdscript
if wp["type"] == "arrive":
    var room_id: String = wp.get("room_id", "")
    var room_door: Node3D = Rooms.get_room_door(room_id)
    if room_door and room_door.has_method("notify_through"):
        room_door.notify_through()
```

---

### Hallway Backtrack Bug — FIXED

**Root cause:** After `exit_hallway_doorway`, the first walk waypoint targeted `origin["door_pos"]` at a different Z than lane_z, causing visible backtrack toward the room.

**Fix in pathfinder.gd:** Set `exit_hallway_doorway` pos to already use `lane_z`:

```gdscript
var doorway_pos: Vector3 = Rooms.get_doorway_pos(origin_room)
waypoints.append({
    "pos": Vector3(doorway_pos.x, doorway_pos.y, lane_z),
    "type": "exit_hallway_doorway",
    "room_id": origin_room,
})
```

Removed the redundant first walk waypoint from both same-floor and elevator branches. Characters now flow directly from doorway into hallway without backtracking.

---

### Perspective → Orthographic Camera Switch — IMPLEMENTED

`building.gd` now switches projection mode when camera Z crosses `zoom_ortho_threshold` (export var, tweak in Inspector).

```gdscript
@export var zoom_ortho_threshold: float = 80.0
var _is_ortho: bool = false

func _get_ortho_size_from_perspective() -> float:
    var fov_rad: float = deg_to_rad(_camera.fov)
    var half_height: float = _camera.position.z * tan(fov_rad * 0.5)
    var viewport := get_viewport()
    if viewport:
        var aspect: float = float(viewport.size.x) / float(viewport.size.y)
        return half_height * maxf(1.0, aspect * 0.75)
    return half_height * 1.4
```

Size is set **before** switching projection to avoid jump. Switching back to perspective requires no action — FOV was never changed.

---

### New Rooms — COMPLETED

**Room_cafe.tscn:**
- Zone_Counter (3 spots) — ORDER_COFFEE
- Zone_Tables (4 spots, merged from Zone_Table_01/02) — ORDER_FOOD, SIT_ALONE_CAFE, SHARE_MEAL
- Zone_Window (1 spot) — WINDOW_WATCH

**Room_library.tscn:**
- Zone_Shelves (6 spots, merged from Zone_Shelf_0/1/2) — READ_BOOK, BROWSE_SHELVES, STUDY_TOGETHER, QUIET_MOMENT_TOGETHER
- Zone_Statue (1 spot) — ADMIRE_STATUE (new event)

**Room_grocery.tscn:**
- Zone_Aisles (3 spots) — CHECK_SUPPLIES
- Zone_Check_Out (1 spot) — future checkout sequence
- Zone_Queue (2 spots) — future queue sequence

**Note:** Grocery checkout sequence flagged for Phase 5 (inventory system).

---

### New Floor — F05 Library

Added `small_common_library` floor type to building_data.gd. F05 added to FLOORS array:
- `apartment_f5_s0` — Soraya Park (then Nadia Rourke after roster change)
- `library_f5_s1` — library room

Characters on F05 naturally visit the adjacent library. Working well in testing.

---

### New Character — Priya Nair

Added as 4th bespoke character. Apartment: `apartment_f5_s0` (floor 5, next to library).

```gdscript
{
    "char_name": "Priya Nair",
    "pronouns": "she/her",
    "life_arch": "neutral",
    "traits": ["BOOKWORM", "MOTIVATED", "RECLUSIVE"],
    "hidden_traits": ["PARANOID"],
    "interests": ["reading", "history", "people_watching"],
    "internal_age": 29.0,
}
```

---

### New Events Added This Session

**ADMIRE_STATUE** — library, Zone_Statue, happiness +5, stress -5
**VISIT_GROCERY** — triggers travel to grocery, queues CHECK_SUPPLIES intent
**CHECK_FRIDGE** — home, Zone_Fridge, hunger -15
**SIT_AT_DESK** — home, Zone_Desk, boredom -15, stress -5
**EAT_AT_HOME** — home, Zone_Fridge, hunger -40, WELL_FED feeling
**BRIEF_CONVERSATION** — proximity heavy, loneliness relief

---

### Actions.gd Zone Wiring

All cafe, library, and grocery actions now call `_move_to_zone()`:
- `_order_food()` → Zone_Tables
- `_order_coffee()` → Zone_Counter
- `_sit_alone_cafe()` → Zone_Tables
- `_share_meal()` → Zone_Tables (both actor and target)
- `_read_book()` → Zone_Shelves
- `_browse_shelves()` → Zone_Shelves
- `_window_watch()` → Zone_Window
- `_study_together()` → Zone_Shelves (both)
- `_quiet_moment_together()` → Zone_Shelves (both)
- `_admire_statue()` → Zone_Statue
- `_check_supplies()` → Zone_Aisles
- `_check_fridge()` → Zone_Fridge
- `_sit_at_desk()` → Zone_Desk
- `_eat_at_home()` → Zone_Fridge
- `_cook_meal()` → Zone_Fridge

---

### Apartment Zones — ADDED

Room_apartment.tscn now has:
- Zone_Bed (1 spot) — LIE_IN_BED, SLEEP
- Zone_Fridge (1 spot) — CHECK_FRIDGE, EAT_AT_HOME, COOK_MEAL
- Zone_Desk (1 spot) — SIT_AT_DESK

Furniture: Bed mesh, Fridge mesh, Desk mesh (MeshInstance3D placeholder).

---

### Room Label System — IMPLEMENTED

`building.gd` now places a `Label3D` above each room using the origin marker position. Labels stored in `_room_labels` dictionary keyed by room_id.

`update_apartment_labels()` public method called by Bootstrap after character spawn — replaces "APT" with resident's first name in blue.

```gdscript
@export var zoom_ortho_threshold: float = 80.0
var _room_labels: Dictionary = {}

func update_apartment_labels() -> void:
    for character in Registry.get_all():
        var room_id: String = character.home_room
        if _room_labels.has(room_id):
            _room_labels[room_id].text = character.char_name.split(" ")[0]
            _room_labels[room_id].modulate = Color(0.7, 0.9, 1.0, 0.85)
```

---

### THINK_ABOUT Self-Targeting Bug — FIXED

**Root cause:** Events with `target_resolution: { "type": "self" }` were writing the character's own `char_id` as `target_id` in storybook entries. THINK_ABOUT then picked those entries and resolved the target as the character themselves.

**Fix in sim.gd `_echo()`:**

```gdscript
# Don't write self as target_id
var target_id: String = ""
if _target is CharData and _target.char_id != character.char_id:
    target_id = _target.char_id
```

---

## Phase 3 — Complete ✅

All roadmap test criteria met:
- ✅ Building renders, 6 floors, 14 rooms
- ✅ Characters visible with name labels and colours
- ✅ Elevator dispatch and multi-passenger riding
- ✅ Room entry/exit with opening/closing doors (both room and hallway)
- ✅ Pathfinding routes correctly (no backtrack bug)
- ✅ Zone/spot system: bar, cafe, library, grocery, apartments all wired
- ✅ Proximity events firing and pausing movement for heavy events
- ✅ F2 EventInspector with eligible events + weights + storybook
- ✅ F3 ForceEvent panel
- ✅ Perspective/ortho camera switch on zoom
- ✅ Room labels with resident names

---

## Pending Documentation

**Context template variable guide** — WRITTEN this session. See `MB16_CONTEXT_TEMPLATE_GUIDE.md`.

---

## What's Next — Phase 4: Relationships & Social Drama

### Phase 4 goals
- `Relationships` autoload — pairwise RelationshipRecord, bond/trust/rivalry/familiarity
- 15-tier relationship spectrum from bond score
- Bond decay on day_ticked
- Relationship-gated events (ASK_OUT, relationship-weighted CHAT, DEEP_CONVERSATION already exists)
- Trait evolution wired to Clock.day_ticked
- EventInspector upgraded to show relationship tiers

### Session 11 starting point
Start with `Relationships` autoload design — RelationshipRecord structure and core API before any events. The shell already exists; needs full implementation.

---

## Key File Paths

- `res://scripts/world/movement_controller.gd` — proximity pause, arrive door fix
- `res://scripts/autoloads/core/pathfinder.gd` — hallway backtrack fix
- `res://scripts/autoloads/sim/sim.gd` — _echo self-target fix, _pause_character_movement
- `res://scripts/autoloads/config/events.gd` — 6 new events
- `res://scripts/autoloads/systems/actions.gd` — full zone wiring, 5 new action functions
- `res://scripts/world/building.gd` — room labels, ortho camera switch
- `res://scripts/world/building_data.gd` — F05, small_common_library, small_common_cafe types
- `res://scripts/bootstrap.gd` — Priya Nair, 7th apartment slot
- `res://scenes/rooms/room_cafe.tscn` — Zone_Counter, Zone_Tables, Zone_Window
- `res://scenes/rooms/room_library.tscn` — Zone_Shelves, Zone_Statue
- `res://scenes/rooms/room_grocery.tscn` — Zone_Aisles, Zone_Check_Out, Zone_Queue
- `res://scenes/rooms/room_apartment.tscn` — Zone_Bed, Zone_Fridge, Zone_Desk

---

## Decisions Log Entries

**Proximity pause uses flag gate not tween pause** — `_proximity_paused` blocks `_move_to_next()` entry point. Tween is killed so character stops in place. Timer fires → flag cleared → movement resumes. Pausing the tween directly failed because tween was already finished when pause was requested. Session 10.

**Room door notify_through on arrive** — Room door occupant_count decremented when character reaches SpawnPos (arrive waypoint), not when passing through doorway. Matches real-world behaviour (door closes after you're inside). Session 10.

**exit_hallway_doorway uses lane_z** — Doorway gap waypoint snaps to lane Z immediately, eliminating the visual backtrack to door_pos. Redundant walk waypoint removed from both same-floor and elevator branches. Session 10.

**THINK_ABOUT target exclusion** — Self-referential storybook entries (target_id = own char_id) no longer written. Prevents memory events from resolving the character as their own memory subject. Session 10.

**Grocery checkout flagged for Phase 5** — Zone_Check_Out and Zone_Queue created in room_grocery.tscn but no events yet. Checkout sequence requires inventory system. Session 10.
