# pathfinder.gd
# Autoload — available globally as Pathfinder
# Tier 2 Core — reads Tier 1 (Stats for movement types)
# Absorbed: ElevatorManager
#
# Plans routes between rooms, manages elevator dispatch.
# Knowledge-limited: characters discover blockages on arrival.
# Full implementation in Phase 3 when the building exists.

extends Node


func _ready() -> void:
	print("[Pathfinder] Loaded. (shell — Phase 3)")


# ── ROUTING ──────────────────────────────────────────────────

# Returns an array of waypoints from origin to destination.
# Each waypoint is a Dictionary with position and type info.
func plan_route(origin_room: String, dest_room: String, _known_blockages: Array = []) -> Array:
	push_warning("[Pathfinder] plan_route() not yet implemented.")
	return []

# True if a route exists between two rooms (ignoring blockages).
func can_reach(origin_room: String, dest_room: String) -> bool:
	push_warning("[Pathfinder] can_reach() not yet implemented.")
	return true


# ── ELEVATOR DISPATCH (stub) ─────────────────────────────────
# Manages 2 physical elevator cars with state: idle/moving/doors_open/broken

func request_elevator(floor: int) -> void:
	push_warning("[Pathfinder] request_elevator() not yet implemented.")

func get_elevator_state(car_index: int) -> String:
	return "idle"

func get_elevator_floor(car_index: int) -> int:
	return 1


# ── BLOCKAGES (stub) ─────────────────────────────────────────

func report_blockage(_room_id: String, _blockage_type: String) -> void:
	pass

func clear_blockage(_room_id: String) -> void:
	pass