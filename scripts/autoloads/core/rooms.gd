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


# ── ZONE / SPOT (stub) ───────────────────────────────────────
# Room → Zone → Spot hierarchy. Populated when rooms are built in Phase 3.

func get_zones(room_id: String) -> Array:
	if not _rooms.has(room_id):
		return []
	return _rooms[room_id].get("zones", [])

func get_available_spot(room_id: String, zone_id: String) -> String:
	# Returns the first unoccupied spot in a zone, or "" if full
	push_warning("[Rooms] get_available_spot() not yet implemented.")
	return ""


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