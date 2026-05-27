# movement_controller.gd
# Child node of CharacterBody. Drives the parent Node3D through a waypoint array.
#
# Waypoint handling:
#   Standard waypoints (walk, exit_room, enter_room, arrive) → tween to pos
#   wait_elevator   → request car, suspend until passenger_boarded signal
#   ride_elevator   → follow car Y in _process until passenger_exited signal
#   wait_hallway_door → request door open, suspend until door_opened signal
#   enter_doorway   → tween through, notify hallway door to start close timer
#   wait_room_door  → request inner door open, suspend until door_opened signal
#
# Movement completes when the final waypoint is reached — emits movement_completed.

extends Node

signal movement_completed
signal waypoint_reached(waypoint: Dictionary)

var _waypoints: Array = []
var _current_index: int = 0
var _is_moving: bool = false
var _tween: Tween

# Elevator state
enum ElevatorPhase { NONE, WAITING, RIDING }
var _elevator_phase: ElevatorPhase = ElevatorPhase.NONE
var _ride_car_index: int = -1

# Door state — set before tweening to door position,
# checked in _on_tween_finished to decide whether to wait or continue
var _pending_door: Node3D = null
var _pending_door_is_hallway: bool = false

const BASE_SPEED: float = 6.0  # units per second


func _ready() -> void:
	Pathfinder.passenger_boarded.connect(_on_passenger_boarded)
	Pathfinder.passenger_exited.connect(_on_passenger_exited)


func _process(_delta: float) -> void:
	# While riding an elevator, follow the car's Y every frame
	if _elevator_phase != ElevatorPhase.RIDING or _ride_car_index < 0:
		return
	var car_node: Node3D = Pathfinder.get_car_node(_ride_car_index)
	var parent := get_parent() as Node3D
	if car_node and parent:
		parent.position.y = car_node.position.y


# ── PUBLIC ───────────────────────────────────────────────────

func start_movement(waypoints: Array) -> void:
	if waypoints.is_empty():
		movement_completed.emit()
		return
	_waypoints = waypoints
	_current_index = 0
	_is_moving = true
	_elevator_phase = ElevatorPhase.NONE
	_pending_door = null
	_move_to_next()


func stop_movement() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_is_moving = false
	_elevator_phase = ElevatorPhase.NONE
	_ride_car_index = -1
	_pending_door = null
	_waypoints.clear()
	_current_index = 0


func is_moving() -> bool:
	return _is_moving


# ── CORE STEP ────────────────────────────────────────────────
# Called after each waypoint completes. Reads the next waypoint type
# and routes to the correct handler.


func _move_to_next() -> void:
	if _current_index >= _waypoints.size():
		_is_moving = false
		movement_completed.emit()
		return

	var wp: Dictionary = _waypoints[_current_index]

	match wp["type"]:
		"wait_elevator":         _handle_wait_elevator(wp)
		"ride_elevator":         _handle_ride_elevator(wp)
		"wait_hallway_door":     _handle_door_wait(wp, true)
		"wait_room_door":        _handle_door_wait(wp, false)
		"enter_doorway":         _handle_enter_doorway(wp)
		"wait_room_door_exit":   _handle_door_wait_exit(wp, false)
		"wait_hallway_door_exit":_handle_door_wait_exit(wp, true)
		"exit_room_doorway":     _handle_exit_doorway(wp, false)
		"exit_hallway_doorway":  _handle_exit_doorway(wp, true)
		_:                       _tween_to(wp["pos"])

# ── TWEENING ─────────────────────────────────────────────────

func _tween_to(target_pos: Vector3) -> void:
	var parent := get_parent() as Node3D
	var distance: float = parent.position.distance_to(target_pos)
	var duration: float = maxf(distance / BASE_SPEED, 0.05)

	if _tween and _tween.is_valid():
		_tween.kill()

	_tween = create_tween()
	_tween.tween_property(parent, "position", target_pos, duration)
	_tween.finished.connect(_on_tween_finished, CONNECT_ONE_SHOT)


func _on_tween_finished() -> void:
	var wp: Dictionary = _waypoints[_current_index]
	waypoint_reached.emit(wp)

	# If we just arrived at a door waypoint, handle open/wait logic
	if _pending_door != null:
		var door = _pending_door
		_pending_door = null

		door.request_open()

		if door.is_open():
			# Door was already open — walk through immediately
			_current_index += 1
			_move_to_next()
		else:
			# Door is opening — wait for the signal before continuing
			door.door_opened.connect(func():
				_current_index += 1
				_move_to_next()
			, CONNECT_ONE_SHOT)
		return

	# Standard waypoint — just advance
	_current_index += 1
	_move_to_next()


# ── ELEVATOR WAIT ────────────────────────────────────────────
# Requests the car and suspends movement. Resumes in _on_passenger_boarded.

func _handle_wait_elevator(wp: Dictionary) -> void:
	_elevator_phase = ElevatorPhase.WAITING
	_ride_car_index = wp["car_index"]

	var parent := get_parent()
	var char_id: String = parent.char_data.char_id if "char_data" in parent else ""

	Pathfinder.request_elevator(wp["car_index"], wp["from_floor"], wp["to_floor"], char_id)

	if Settings.debug_console_logging:
		var n: String = parent.char_data.char_name if "char_data" in parent else "?"
		print("[Movement] %s waiting for elevator %d at floor %d" % [n, wp["car_index"], wp["from_floor"]])


func _on_passenger_boarded(car_index: int, char_id: String) -> void:
	if _elevator_phase != ElevatorPhase.WAITING:
		return
	if char_id != _get_char_id():
		return

	_elevator_phase = ElevatorPhase.NONE

	if Settings.debug_console_logging:
		print("[Movement] %s boarded elevator %d" % [_get_char_name(), car_index])

	# Advance past the wait_elevator waypoint into ride_elevator
	waypoint_reached.emit(_waypoints[_current_index])
	_current_index += 1
	_move_to_next()


# ── ELEVATOR RIDE ────────────────────────────────────────────
# Snaps X to car center. _process() follows Y until passenger_exited fires.

func _handle_ride_elevator(wp: Dictionary) -> void:
	_elevator_phase = ElevatorPhase.RIDING
	_ride_car_index = wp["car_index"]

	var car_node: Node3D = Pathfinder.get_car_node(_ride_car_index)
	var parent := get_parent() as Node3D
	if car_node and parent:
		parent.position.x = car_node.position.x

	if Settings.debug_console_logging:
		print("[Movement] %s riding elevator %d to floor %d" % [
			_get_char_name(), _ride_car_index, wp["to_floor"]
		])


func _on_passenger_exited(car_index: int, char_id: String) -> void:
	if _elevator_phase != ElevatorPhase.RIDING:
		return
	if char_id != _get_char_id():
		return

	_elevator_phase = ElevatorPhase.NONE
	_ride_car_index = -1

	# Snap Y to the next waypoint to prevent float drift after exit
	var next_idx: int = _current_index + 1
	if next_idx < _waypoints.size():
		(get_parent() as Node3D).position.y = _waypoints[next_idx]["pos"].y

	if Settings.debug_console_logging:
		print("[Movement] %s exiting elevator %d" % [_get_char_name(), car_index])

	waypoint_reached.emit(_waypoints[_current_index])
	_current_index += 1
	_move_to_next()


# ── DOOR WAIT ────────────────────────────────────────────────
# Tweens to the door position, then _on_tween_finished checks _pending_door.
# is_hallway=true reads hallway door, false reads room door.

func _handle_door_wait(wp: Dictionary, is_hallway: bool) -> void:
	var room_id: String = wp.get("room_id", "")

	if is_hallway:
		_pending_door = Rooms.get_hallway_door(room_id)
	else:
		_pending_door = Rooms.get_room_door(room_id)

	if _pending_door == null:
		# No door registered for this room — skip through as if it's open
		_tween_to(wp["pos"])
		return

	_pending_door_is_hallway = is_hallway
	_tween_to(wp["pos"])


# ── ENTER DOORWAY ────────────────────────────────────────────
# Character is physically walking through the doorway gap.
# Notify the hallway door to begin its close timer.

func _handle_enter_doorway(wp: Dictionary) -> void:
	var room_id: String = wp.get("room_id", "")
	var hallway_door: Node3D = Rooms.get_hallway_door(room_id)

	if hallway_door and hallway_door.has_method("notify_through"):
		hallway_door.notify_through()

	# Continue tweening to the doorway marker position
	_tween_to(wp["pos"])

# ── EXIT DOOR WAIT ───────────────────────────────────────────
# Same logic as _handle_door_wait but reads the correct door
# for the exit direction. is_hallway=true reads hallway door,
# false reads room door.

func _handle_door_wait_exit(wp: Dictionary, is_hallway: bool) -> void:
	var room_id: String = wp.get("room_id", "")

	if is_hallway:
		_pending_door = Rooms.get_hallway_door(room_id)
	else:
		_pending_door = Rooms.get_room_door(room_id)

	if _pending_door == null:
		# No door — walk straight through
		_tween_to(wp["pos"])
		return

	_pending_door_is_hallway = is_hallway
	_tween_to(wp["pos"])


# ── EXIT DOORWAY ─────────────────────────────────────────────
# Character is physically walking through the doorway on the way OUT.
# Notify the appropriate door to start its close timer.
# is_hallway=true notifies hallway door, false notifies room door.

func _handle_exit_doorway(wp: Dictionary, is_hallway: bool) -> void:
	var room_id: String = wp.get("room_id", "")

	if is_hallway:
		var hallway_door: Node3D = Rooms.get_hallway_door(room_id)
		if hallway_door and hallway_door.has_method("notify_through"):
			hallway_door.notify_through()
	else:
		var room_door: Node3D = Rooms.get_room_door(room_id)
		if room_door and room_door.has_method("notify_through"):
			room_door.notify_through()

	_tween_to(wp["pos"])


# ── HELPERS ──────────────────────────────────────────────────

func _get_char_id() -> String:
	var parent := get_parent()
	return parent.char_data.char_id if "char_data" in parent else ""


func _get_char_name() -> String:
	var parent := get_parent()
	return parent.char_data.char_name if "char_data" in parent else "?"