# MB16 Room & Floor Building Guide

*Rules and checklists for building rooms, floors, hallways, and elevator connections. Every room must follow these requirements for the tick-driven movement system, pathfinding, boundary detection, and spawn logic to work correctly.*

---

## Waypoint Types

Every Marker3D waypoint in the building is tagged with a **type** that tells the sim what happens when a character arrives at it. These are the types:

| Type | Tag | Purpose |
|---|---|---|
| **Entry Spot** | `entry` | Just inside a room near the door. Arrival point, spawn point, and departure point. A character reaching this from outside is officially "in the room." A character walking to this to leave has started their exit. |
| **Room Door** | `room_door` | At the room's door on the room side. Crossing this outbound triggers `remove_occupant(room)` — character enters the doorway. Crossing inbound from doorway triggers `add_occupant(room)`. |
| **Hallway Door** | `hall_door` | At the room's door on the hallway side. Crossing this from the doorway triggers `add_occupant(hallway)`. Crossing inbound from hallway triggers `remove_occupant(hallway)` — character enters the doorway. |
| **Activity Spot** | `spot` | Where characters do things — a couch seat, bar stool, bed, counter position, desk chair. Characters claim these when they arrive and release them when they leave. |
| **Path Node** | `path` | A navigation waypoint with no special behavior. Used to define walkable routes through hallways, large rooms, or around corners. No boundary transitions fire here. |
| **Elevator Entry** | `elev_entry` | Where characters stand to wait for the elevator on each floor. One per floor per elevator shaft. |
| **Elevator Spot** | `elev_spot` | Where characters stand inside the elevator car. |

---

## Zone Boundary Rules

The movement system uses **boundary crossing detection** at tagged waypoints to determine room membership. A character is always in exactly one zone. Zone transitions happen at specific waypoints:

**Exiting a room → hallway:**
1. Character at activity spot or entry spot (zone = room)
2. Walks to entry spot (still zone = room)
3. Reaches room_door → `remove_occupant(room)`, zone = doorway
4. Reaches hall_door → `remove_occupant(doorway)`, `add_occupant(hallway)`, zone = hallway

**Entering a room from hallway:**
1. Character walking in hallway (zone = hallway)
2. Reaches hall_door → `remove_occupant(hallway)`, zone = doorway
3. Reaches room_door → `add_occupant(room)`, zone = room (but still walking)
4. Reaches entry spot → at entry position (may continue to activity spot)
5. Reaches activity spot → claims spot, movement complete

**Doorway is a brief transitional zone** lasting 1–2 ticks. Characters in a doorway are not available for room events in either the room or the hallway. Doorway is its own zone.

---

## Required Waypoints Per Area Type

### Standard Room (apartment, kitchen, bar, gym, etc.)

**Minimum required:**
- 1× entry spot (`entry`)
- 1× room door (`room_door`)
- 1× activity spot (`spot`)

**Connection order:** hall_door ↔ room_door ↔ entry ↔ spot(s)

The entry spot is placed just inside the room, close to the door. It serves three purposes: arrival destination (pathfinding target when heading to this room), spawn point (where characters appear on game start or load), and departure origin (characters walk here first when leaving).

Activity spots can be as many as needed. A small apartment might have 2–3 (bed, desk, couch). A large bar might have 8–10 (stools, tables, dance floor positions). Each spot is a separate Marker3D.

### Hallway (one per floor)

**Minimum required:**
- 1× hall_door per room that connects to this hallway (`hall_door`)
- 2+ path nodes defining the walkable route (`path`)
- 1× elevator entry (`elev_entry`) if the floor has elevator access

Path nodes should be spaced along the hallway so characters follow a natural walking path. Place them at turns, intersections, and at regular intervals along straight stretches. More path nodes = smoother movement through the hallway.

The hallway is a zone. Characters walking between rooms pass through it and are available for proximity events while in it.

### Elevator

**Minimum required:**
- 1× elevator entry per floor it serves (`elev_entry`) — placed in the hallway near the elevator doors
- 1× elevator spot inside the car (`elev_spot`) — where riders stand

The elevator car is a moving zone. Characters inside it have their zone set to the elevator. The car's Y position is sim-computed and advances per tick.

### Shared / Common Rooms (lobby, rooftop, laundry, etc.)

Same rules as standard rooms. If the room has multiple entrances, each entrance needs its own room_door + hall_door pair, and an entry spot near each door. Characters entering from different directions should have distinct paths to the room's activity spots.

---

## Naming Convention

Format: `type_zone_floor_descriptor`

Examples:
- `entry_kitchen_f1` — entry spot for the kitchen on floor 1
- `room_door_kitchen_f1` — kitchen door (room side), floor 1
- `hall_door_kitchen_f1` — kitchen door (hallway side), floor 1
- `spot_kitchen_f1_stool1` — first stool in the kitchen, floor 1
- `spot_kitchen_f1_stool2` — second stool
- `path_hall_f1_01` — first path node in floor 1 hallway
- `path_hall_f1_02` — second path node
- `elev_entry_f1` — elevator entry on floor 1
- `elev_spot_car1` — spot inside elevator car 1
- `entry_apt101_f1` — entry spot for apartment 101
- `spot_apt101_f1_bed` — bed spot in apartment 101
- `spot_apt101_f1_desk` — desk spot in apartment 101

**Rules:**
- All lowercase, underscores only
- Floor is always included (`f1`, `f2`, etc.)
- Descriptors are short and clear
- Numbered suffixes for multiples (`stool1`, `stool2` or `01`, `02`)

---

## Connection Rules

Waypoints must be connected in the pathfinding graph following these rules:

1. **Every activity spot connects to its room's entry spot.** Never directly to a door or hallway.
2. **Entry spot connects to room_door.** This is the only exit path from a room.
3. **Room_door connects to hall_door.** These are always paired — one on each side of a physical door.
4. **Hall_door connects to the hallway path network.** Usually to the nearest path node.
5. **Hallway path nodes connect to each other** forming a walkable chain along the hallway.
6. **Elevator entry connects to the hallway path network** and to the elevator car spot.
7. **No dead ends.** Every waypoint must connect to at least one other waypoint. A character must be able to path from any spot in the building to any other spot.

---

## Metadata Per Waypoint

Each Marker3D waypoint needs the following metadata (stored however Godot metadata/groups/export vars work best — TBD during implementation):

- **type** — one of: `entry`, `room_door`, `hall_door`, `spot`, `path`, `elev_entry`, `elev_spot`
- **zone** — which zone this waypoint belongs to (room ID, hallway ID, elevator ID, or doorway ID)
- **connections** — list of connected waypoint names/references for pathfinding
- **capacity** (spots only) — how many characters can claim this spot at once (default 1, benches/couches might be 2–3)

---

## Building a New Room — Checklist

Use this every time you add a room to the building:

- [ ] Place the room_door Marker3D at the room's door (room side)
- [ ] Place the hall_door Marker3D at the room's door (hallway side)
- [ ] Place the entry spot Marker3D just inside the room near the door
- [ ] Place activity spot Marker3D(s) where characters will do things
- [ ] Name all waypoints following the naming convention
- [ ] Set type metadata on each waypoint
- [ ] Set zone metadata on each waypoint (use the room's ID)
- [ ] Connect: each spot ↔ entry
- [ ] Connect: entry ↔ room_door
- [ ] Connect: room_door ↔ hall_door
- [ ] Connect: hall_door ↔ nearest hallway path node
- [ ] Verify: a character can path from any spot in this room to any spot in any other room
- [ ] Run the validation function to confirm all requirements are met

## Building a New Floor — Checklist

- [ ] Place hallway path nodes defining the walkable route
- [ ] Place elevator entry spot near the elevator doors
- [ ] Connect hallway path nodes to each other in sequence
- [ ] Connect elevator entry to the hallway path network
- [ ] For each room on this floor, follow the room checklist above
- [ ] Verify: a character can path from any room on this floor to the elevator and to any other room on this floor
- [ ] Run the validation function to confirm all requirements are met

---

## Validation Function (runtime check)

A validation function will run at startup (debug builds) and check:

1. Every room has at least: 1 entry spot, 1 room_door, 1 activity spot
2. Every room_door has a matching hall_door (paired)
3. Every hallway has at least 2 path nodes and 1 elevator entry
4. Every waypoint has at least 1 connection (no orphans)
5. Every waypoint has type and zone metadata set
6. Full connectivity: pathfinding can reach every waypoint from every other waypoint
7. Entry spots match registered room IDs in the Rooms system
8. Elevator entries exist for every floor the elevator serves

Validation failures print warnings to the console with the specific waypoint name and what's missing. This catches errors at startup rather than as weird runtime behavior.

---

## Future Considerations

**Multiple entrances.** Some rooms (lobby, large common areas) may have more than one entrance. Each entrance needs its own room_door + hall_door pair. The entry spot nearest each door serves as the arrival point for characters entering from that direction. Pathfinding picks the closest entrance.

**Locked doors.** When door locking is implemented, the lock state lives on the door pair (room_door + hall_door). The sim checks lock state before allowing a character to path through. The waypoint itself doesn't change — the pathfinder just treats it as impassable when locked.

**Room subdivisions.** Large rooms might have distinct areas (bar counter vs dance floor vs seating area). These can be modeled as sub-zones with internal path nodes, or simply as activity spots with position-based proximity checks. No architectural changes needed — it's just more spots with meaningful placement.

**Outdoor areas.** If the building gets a rooftop, courtyard, or street level, these follow the same rules as rooms. They have entry spots, doors (or access points), and activity spots. The hallway equivalent might be a walkway or path.
