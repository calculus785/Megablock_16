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
var _proximity_fired: Array = []
var _proximity_paused: bool = false

# Elevator state
enum ElevatorPhase { NONE, WAITING, RIDING }
var _elevator_phase: ElevatorPhase = ElevatorPhase.NONE
var _ride_car_index: int = -1

# Door state — set before tweening to door position,
# checked in _on_tween_finished to decide whether to wait or continue
var _pending_door: Node3D = null
var _pending_door_is_hallway: bool = false

const BASE_SPEED: float = 6.0  # units per second


var _pause_timer: Timer = null

func _ready() -> void:
	Pathfinder.passenger_boarded.connect(_on_passenger_boarded)
	Pathfinder.passenger_exited.connect(_on_passenger_exited)
	# Proximity pause timer
	_pause_timer = Timer.new()
	_pause_timer.one_shot = true
	_pause_timer.timeout.connect(_on_pause_finished)
	add_child(_pause_timer)



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
	_proximity_fired.clear()
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

# Stops all movement and tweens the character body to a target position.
# Used when a character is intercepted mid-journey for a hallway conversation.
func cancel_and_tween_to(target_pos: Vector3) -> void:
	stop_movement()
	var parent := get_parent() as Node3D
	if parent == null:
		return
	var distance: float = parent.position.distance_to(target_pos)
	var duration: float = maxf(distance / BASE_SPEED, 0.05)
	if _tween and _tween.is_valid():
		_tween.kill()
	_is_moving = true
	_tween = create_tween()
	_tween.tween_property(parent, "position", target_pos, duration)
	_tween.finished.connect(func(): _is_moving = false, CONNECT_ONE_SHOT)

func is_moving() -> bool:
	return _is_moving


# ── CORE STEP ────────────────────────────────────────────────
# Called after each waypoint completes. Reads the next waypoint type
# and routes to the correct handler.


func _move_to_next() -> void:
	if _proximity_paused:
		return
	if _current_index >= _waypoints.size():
		_is_moving = false
		movement_completed.emit()
		return
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

func pause_for_proximity(duration: float) -> void:
	if not _is_moving:
		return
	_proximity_paused = true
	# Kill any active tween so character stops in place
	if _tween and _tween.is_valid():
		_tween.kill()
	_pause_timer.start(duration)


func _on_pause_finished() -> void:
	_proximity_paused = false
	if _is_moving:
		_move_to_next()

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
	if wp["type"] == "walk":
		_check_proximity()
		# If proximity locked us into a sequence, don't advance to next waypoint
		var _p := get_parent()
		if "char_data" in _p and (_p.char_data.is_loitering or _p.char_data.active_sequence != ""):
			_is_moving = false
			return

	if wp["type"] == "arrive":
		var room_id: String = wp.get("room_id", "")
		var room_door: Node3D = Rooms.get_room_door(room_id)
		if room_door and room_door.has_method("notify_through"):
			room_door.notify_through()

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
	# Guard: don't board if character was intercepted for a hallway conversation
	var parent := get_parent()
	if "char_data" in parent:
		var cd = parent.char_data
		if cd.is_loitering or cd.active_sequence != "":
			_elevator_phase = ElevatorPhase.NONE
			_is_moving = false
			_waypoints.clear()
			_current_index = 0
			if Settings.debug_console_logging:
				print("[Movement] %s skipped elevator — in conversation" % _get_char_name())
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

	var parent := get_parent()
	if "char_data" in parent:
		parent.char_data.is_riding_elevator = true

	# Snap X to car center so _process() Y-follow tracks correctly
	var car_node: Node3D = Pathfinder.get_car_node(_ride_car_index)
	var parent_node := parent as Node3D
	if car_node and parent_node:
		parent_node.position.x = car_node.position.x

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

	var parent := get_parent()
	if "char_data" in parent:
		parent.char_data.is_riding_elevator = false
	# Snap Y to the next waypoint to prevent float drift after exit
	var next_idx: int = _current_index + 1
	if next_idx < _waypoints.size():
		(get_parent() as Node3D).position.y = _waypoints[next_idx]["pos"].y

	if Settings.debug_console_logging:
		print("[Movement] %s exiting elevator %d" % [_get_char_name(), car_index])

	waypoint_reached.emit(_waypoints[_current_index])
	_current_index += 1
	_move_to_next()

const PROXIMITY_RANGE: float = 3.0  # units — how close two characters need to be

func _check_proximity() -> void:
	var parent := get_parent()
	if not "char_data" in parent:
		return
	var my_data: CharData = parent.char_data
	var my_pos: Vector3 = parent.global_position

	# Tag which floor we're physically on so hallway spot selection is correct
	if _current_index < _waypoints.size():
		var wp_y: float = _waypoints[_current_index].get("pos", Vector3.ZERO).y
		my_data.transit_floor_index = Rooms.get_floor_index_by_y(wp_y)
	
	for other_body in _get_nearby_character_bodies():
		if not "char_data" in other_body:
			continue
		if other_body.char_data.char_id == my_data.char_id:
			continue
		if not other_body.char_data.is_in_transit:
			continue

		var dist: float = my_pos.distance_to(other_body.global_position)
		if dist > PROXIMITY_RANGE:
			continue

		# Same floor check
		var my_floor: int = Rooms.get_floor_index(my_data.current_room)
		var other_floor: int = Rooms.get_floor_index(other_body.char_data.current_room)
		if my_floor != other_floor:
			continue

		# Don't fire twice for the same pair in the same journey
		var pair_key: String = _make_pair_key(my_data.char_id, other_body.char_data.char_id)
		if pair_key in _proximity_fired:
			continue
		_proximity_fired.append(pair_key)

		# Fire the proximity event via Sim
		Sim.fire_proximity_event(my_data, other_body.char_data)

# Returns the waypoints not yet processed — from the next step onwards.
# Called just before stop_movement() to save journey state for loiter resume.
func get_remaining_waypoints() -> Array:
	# _current_index points to the walk waypoint that just completed (triggered proximity).
	# The next waypoint is _current_index + 1.
	var next_index: int = _current_index + 1
	if next_index >= _waypoints.size():
		return []
	return _waypoints.slice(next_index)

func _get_nearby_character_bodies() -> Array:
	# Walk up to the Characters container and check siblings
	var container = get_parent().get_parent()
	if container == null:
		return []
	return container.get_children()


func _make_pair_key(id_a: String, id_b: String) -> String:
	if id_a < id_b:
		return id_a + ":" + id_b
	return id_b + ":" + id_a


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
