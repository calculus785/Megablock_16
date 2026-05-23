# movement_controller.gd
# Child node of CharacterBody. Tweens parent through waypoints.
# Listens to Pathfinder's passenger_boarded/exited signals for elevator phases.

extends Node

signal movement_completed
signal waypoint_reached(waypoint: Dictionary)

var _waypoints: Array = []
var _current_index: int = 0
var _is_moving: bool = false
var _tween: Tween

enum ElevatorPhase { NONE, WAITING, RIDING }
var _elevator_phase: ElevatorPhase = ElevatorPhase.NONE
var _ride_car_index: int = -1

const BASE_SPEED: float = 200.0


func _ready() -> void:
	Pathfinder.passenger_boarded.connect(_on_passenger_boarded)
	Pathfinder.passenger_exited.connect(_on_passenger_exited)


func _process(_delta: float) -> void:
	if _elevator_phase != ElevatorPhase.RIDING or _ride_car_index < 0:
		return
	var car_node: Node2D = Pathfinder.get_car_node(_ride_car_index)
	var parent := get_parent() as Node2D
	if car_node and parent:
		parent.position.y = car_node.position.y + Pathfinder._car_texture_height / 2.0


func start_movement(waypoints: Array) -> void:
	if waypoints.is_empty():
		movement_completed.emit()
		return
	_waypoints = waypoints
	_current_index = 0
	_is_moving = true
	_elevator_phase = ElevatorPhase.NONE
	_move_to_next()


func stop_movement() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_is_moving = false
	_elevator_phase = ElevatorPhase.NONE
	_ride_car_index = -1
	_waypoints.clear()
	_current_index = 0


func is_moving() -> bool:
	return _is_moving


func _move_to_next() -> void:
	if _current_index >= _waypoints.size():
		_is_moving = false
		movement_completed.emit()
		return

	var wp: Dictionary = _waypoints[_current_index]

	match wp["type"]:
		"wait_elevator": _handle_wait_elevator(wp)
		"ride_elevator": _handle_ride_elevator(wp)
		_: _tween_to(wp["pos"])


func _tween_to(target_pos: Vector2) -> void:
	var parent := get_parent() as Node2D
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
	_current_index += 1
	_move_to_next()


# ── ELEVATOR WAIT ────────────────────────────────────────────

func _handle_wait_elevator(wp: Dictionary) -> void:
	_elevator_phase = ElevatorPhase.WAITING
	_ride_car_index = wp["car_index"]

	var parent := get_parent()
	var char_id: String = parent.char_data.char_id if "char_data" in parent else ""

	# Request with both pickup and destination floor
	Pathfinder.request_elevator(wp["car_index"], wp["from_floor"], wp["to_floor"], char_id)

	if Settings.debug_console_logging:
		var n: String = parent.char_data.char_name if "char_data" in parent else "?"
		print("[Movement] %s waiting for elevator %d at floor %d" % [n, wp["car_index"], wp["from_floor"]])


func _on_passenger_boarded(car_index: int, char_id: String) -> void:
	if _elevator_phase != ElevatorPhase.WAITING:
		return
	var my_id: String = _get_char_id()
	if char_id != my_id:
		return

	# We boarded — advance past wait_elevator to ride_elevator
	_elevator_phase = ElevatorPhase.NONE

	if Settings.debug_console_logging:
		print("[Movement] %s boarded elevator %d" % [_get_char_name(), car_index])

	waypoint_reached.emit(_waypoints[_current_index])
	_current_index += 1
	_move_to_next()


# ── ELEVATOR RIDE ────────────────────────────────────────────

func _handle_ride_elevator(wp: Dictionary) -> void:
	_elevator_phase = ElevatorPhase.RIDING
	_ride_car_index = wp["car_index"]

	# Snap X into car center
	var car_node: Node2D = Pathfinder.get_car_node(_ride_car_index)
	var parent := get_parent() as Node2D
	if car_node and car_node is Sprite2D:
		parent.position.x = car_node.position.x + (car_node as Sprite2D).texture.get_width() / 2.0
	elif car_node:
		parent.position.x = car_node.position.x

	if Settings.debug_console_logging:
		print("[Movement] %s riding elevator %d to floor %d" % [
			_get_char_name(), _ride_car_index, wp["to_floor"]
		])
	# Car movement is managed entirely by Pathfinder's timer system.
	# _process follows car Y. We wait for passenger_exited signal.


func _on_passenger_exited(car_index: int, char_id: String) -> void:
	if _elevator_phase != ElevatorPhase.RIDING:
		return
	var my_id: String = _get_char_id()
	if char_id != my_id:
		return

	_elevator_phase = ElevatorPhase.NONE
	_ride_car_index = -1

	# Snap Y to next waypoint to prevent float
	var next_idx: int = _current_index + 1
	if next_idx < _waypoints.size():
		(get_parent() as Node2D).position.y = _waypoints[next_idx]["pos"].y

	if Settings.debug_console_logging:
		print("[Movement] %s exiting elevator %d" % [_get_char_name(), car_index])

	waypoint_reached.emit(_waypoints[_current_index])
	_current_index += 1
	_move_to_next()


# ── HELPERS ──────────────────────────────────────────────────

func _get_char_id() -> String:
	var parent := get_parent()
	return parent.char_data.char_id if "char_data" in parent else ""


func _get_char_name() -> String:
	var parent := get_parent()
	return parent.char_data.char_name if "char_data" in parent else "?"