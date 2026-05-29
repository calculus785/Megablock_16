# rooms.gd
# Autoload — available globally as Rooms
# Tier 2 Core — reads Tier 1 (Interactables, Stats)
# Absorbed: AuraManager
#
# Tracks room state: who's in each room, zone/spot occupancy,
# aura ticking for occupied rooms.
# Room IDs follow the format: type_fFLOOR_sSLOT (e.g. bar_f2_s1)

extends Node

# room_id → Dictionary with occupants, zones, interactables, etc.
var _rooms: Dictionary = {}
var _hallway_doors: Dictionary = {}  # room_id → door Node3D
var _room_doors: Dictionary = {}     # room_id → door Node3D


func _ready() -> void:
	print("[Rooms] Loaded. %d rooms registered." % _rooms.size())


# ── OCCUPANCY ────────────────────────────────────────────────

func get_occupants(room_id: String) -> Array:
	if not _rooms.has(room_id):
		return []
	return _rooms[room_id].get("occupants", [])

func add_occupant(room_id: String, char_id: String) -> void:
	if not _rooms.has(room_id):
		return
	var occupants: Array = _rooms[room_id].get("occupants", [])
	if char_id not in occupants:
		occupants.append(char_id)

func remove_occupant(room_id: String, char_id: String) -> void:
	if not _rooms.has(room_id):
		return
	_rooms[room_id].get("occupants", []).erase(char_id)

func get_room_type(room_id: String) -> String:
	if not _rooms.has(room_id):
		return ""
	return _rooms[room_id].get("type", "")

func is_occupied(room_id: String) -> bool:
	return get_occupants(room_id).size() > 0

# Returns all room IDs where a character could go
func get_all_room_ids() -> Array:
	return _rooms.keys()

# Returns all rooms of a given type (e.g. "bar", "apartment")
func get_rooms_by_type(room_type: String) -> Array:
	var result: Array = []
	for room_id in _rooms:
		if _rooms[room_id].get("type", "") == room_type:
			result.append(room_id)
	return result

# ── POSITION LOOKUPS (Phase 3) ───────────────────────────────
# World positions registered by building.gd during setup.

func get_door_spot(room_id: String) -> Vector3:
	if not _rooms.has(room_id):
		return Vector3.ZERO
	return _rooms[room_id].get("door_spot", Vector3.ZERO)

func get_cutout_center(room_id: String) -> Vector3:
	if not _rooms.has(room_id):
		return Vector3.ZERO
	return _rooms[room_id].get("spawn_pos", Vector3.ZERO)

func get_floor_index(room_id: String) -> int:
	if not _rooms.has(room_id):
		return -1
	return _rooms[room_id].get("floor_index", -1)

# ── FLOOR DATA (Phase 3) ─────────────────────────────────────
# Registered by building.gd. Stores elevator + hallway positions per floor.

var _floors: Dictionary = {}   # floor_id → Dictionary

func register_floor(floor_id: String, data: Dictionary) -> void:
	_floors[floor_id] = data

func get_floor_data_by_index(floor_index: int) -> Dictionary:
	for fid in _floors:
		if _floors[fid].get("index", -1) == floor_index:
			return _floors[fid]
	return {}


# ── FULL ROOM DATA GETTER ────────────────────────────────────

func get_room_data(room_id: String) -> Dictionary:
	if not _rooms.has(room_id):
		return {}
	return _rooms[room_id]

func get_spawn_pos(room_id: String) -> Vector3:
	if not _rooms.has(room_id):
		return Vector3.ZERO
	return _rooms[room_id].get("spawn_pos", Vector3.ZERO)

func get_door_pos(room_id: String) -> Vector3:
	if not _rooms.has(room_id):
		return Vector3.ZERO
	return _rooms[room_id].get("door_pos", Vector3.ZERO)


# ── AURA TICKING (stub) ─────────────────────────────────────
# Called on half_hour_ticked. Only ticks occupied rooms.

func tick_auras() -> void:
	for room_id in _rooms:
		if not is_occupied(room_id):
			continue
		# Loop interactables in this room, apply aura_effects to occupants
		# Per-stat cap +5, per-room cap +12, personality sensitivity roll
		# Full implementation in Phase 5
		pass


# ── ROOM REGISTRATION ────────────────────────────────────────
# Called during building setup. Phase 3 populates these.

func register_room(room_id: String, room_data: Dictionary) -> void:
	_rooms[room_id] = room_data

func has_room(room_id: String) -> bool:
	return _rooms.has(room_id)

func register_hallway_door(room_id: String, door_node: Node3D) -> void:
	_hallway_doors[room_id] = door_node

func register_room_door(room_id: String, door_node: Node3D) -> void:
	_room_doors[room_id] = door_node

func get_hallway_door(room_id: String) -> Node3D:
	return _hallway_doors.get(room_id, null)

func get_room_door(room_id: String) -> Node3D:
	return _room_doors.get(room_id, null)

func get_doorway_pos(room_id: String) -> Vector3:
	if not _rooms.has(room_id):
		return Vector3.ZERO
	return _rooms[room_id].get("doorway_pos", Vector3.ZERO)

func set_room_door_wait_pos(room_id: String, pos: Vector3) -> void:
	if _rooms.has(room_id):
		_rooms[room_id]["room_door_wait_pos"] = pos

func set_room_doorway_pos(room_id: String, pos: Vector3) -> void:
	if _rooms.has(room_id):
		_rooms[room_id]["room_doorway_pos"] = pos

func get_room_door_wait_pos(room_id: String) -> Vector3:
	if not _rooms.has(room_id):
		return Vector3.ZERO
	return _rooms[room_id].get("room_door_wait_pos", Vector3.ZERO)

func get_room_doorway_pos(room_id: String) -> Vector3:
	if not _rooms.has(room_id):
		return Vector3.ZERO
	return _rooms[room_id].get("room_doorway_pos", Vector3.ZERO)

func set_spawn_pos(room_id: String, pos: Vector3) -> void:
	if _rooms.has(room_id):
		_rooms[room_id]["spawn_pos"] = pos

func set_zones(room_id: String, zone_data: Array) -> void:
	if _rooms.has(room_id):
		_rooms[room_id]["zones"] = zone_data

func get_zones(room_id: String) -> Array:
	if not _rooms.has(room_id):
		return []
	return _rooms[room_id].get("zones", [])

func get_zone(room_id: String, zone_name: String) -> Dictionary:
	for zone in get_zones(room_id):
		if zone["zone_name"] == zone_name:
			return zone
	return {}

# Returns the first unoccupied spot in a zone, or {} if full
func get_available_spot(room_id: String, zone_name: String) -> Dictionary:
	var zone: Dictionary = get_zone(room_id, zone_name)
	if zone.is_empty():
		return {}
	for spot in zone["spots"]:
		if spot["occupied_by"] == "":
			return spot
	return {}

# Returns any available spot in ANY zone in the room
func get_any_available_spot(room_id: String) -> Dictionary:
	for zone in get_zones(room_id):
		for spot in zone["spots"]:
			if spot["occupied_by"] == "":
				return spot
	return {}

# Claim a spot — sets occupied_by to char_id
func claim_spot(room_id: String, zone_name: String, spot_name: String, char_id: String) -> void:
	var zone: Dictionary = get_zone(room_id, zone_name)
	if zone.is_empty():
		return
	for spot in zone["spots"]:
		if spot["name"] == spot_name:
			spot["occupied_by"] = char_id
			return

# Release a spot — called when character leaves zone or room
func release_spot(room_id: String, char_id: String) -> void:
	for zone in get_zones(room_id):
		for spot in zone["spots"]:
			if spot["occupied_by"] == char_id:
				spot["occupied_by"] = ""
				return

# Release all spots held by a character (safety — called on room exit)
func release_all_spots(room_id: String, char_id: String) -> void:
	for zone in get_zones(room_id):
		for spot in zone["spots"]:
			if spot["occupied_by"] == char_id:
				spot["occupied_by"] = ""

# Check if a specific zone has any free spots
func zone_has_space(room_id: String, zone_name: String) -> bool:
	return not get_available_spot(room_id, zone_name).is_empty()

# Check if character is in a specific zone
func is_in_zone(room_id: String, char_id: String, zone_name: String) -> bool:
	var zone: Dictionary = get_zone(room_id, zone_name)
	if zone.is_empty():
		return false
	for spot in zone["spots"]:
		if spot["occupied_by"] == char_id:
			return true
	return false

# Get zone name a character is currently in
func get_character_zone(room_id: String, char_id: String) -> String:
	for zone in get_zones(room_id):
		for spot in zone["spots"]:
			if spot["occupied_by"] == char_id:
				return zone["zone_name"]
	return ""
