# door.gd
# Attach to a Node3D root of a door scene.
# The door mesh is a child node named "DoorMesh".
# Slides open via tween, tracks occupants, auto-closes when empty.

extends Node3D

@export var slide_direction: Vector3 = Vector3(-1, 0, 0)  # left for hallway, back for room
@export var slide_distance: float = 2.5
@export var slide_speed: float = 0.4  # seconds to open/close

enum State { CLOSED, OPENING, OPEN, CLOSING }
var _state: State = State.CLOSED
var _occupant_count: int = 0
var _tween: Tween
var _close_timer: Timer
var _door_mesh: Node3D
var _closed_pos: Vector3
var _open_pos: Vector3

signal door_opened
signal door_closed


func _ready() -> void:
	_door_mesh = get_node("DoorMesh")
	if _door_mesh == null:
		push_error("[Door] No DoorMesh child found on %s" % name)
		return

	_closed_pos = _door_mesh.position
	_open_pos = _closed_pos + (slide_direction.normalized() * slide_distance)

	_close_timer = Timer.new()
	_close_timer.one_shot = true
	_close_timer.wait_time = 1.5
	_close_timer.timeout.connect(_on_close_timer)
	add_child(_close_timer)


func request_open() -> void:
	_occupant_count += 1

	match _state:
		State.CLOSED:
			_slide_to(_open_pos, State.OPENING, State.OPEN)
		State.CLOSING:
			# Reverse — reopen
			_slide_to(_open_pos, State.OPENING, State.OPEN)
		State.OPEN:
			# Already open — reset close timer
			_close_timer.stop()
		State.OPENING:
			pass  # Already opening, just wait


func notify_through() -> void:
	_occupant_count = max(0, _occupant_count - 1)
	if _occupant_count <= 0:
		_occupant_count = 0
		_close_timer.start()


func is_open() -> bool:
	return _state == State.OPEN


func _slide_to(target: Vector3, during_state: State, end_state: State) -> void:
	if _door_mesh == null:
		return
	_state = during_state

	if _tween and _tween.is_valid():
		_tween.kill()

	_tween = create_tween()
	_tween.tween_property(_door_mesh, "position", target, slide_speed)
	_tween.finished.connect(func():
		_state = end_state
		if end_state == State.OPEN:
			door_opened.emit()
		elif end_state == State.CLOSED:
			door_closed.emit()
	, CONNECT_ONE_SHOT)


func _on_close_timer() -> void:
	if _occupant_count <= 0:
		_slide_to(_closed_pos, State.CLOSING, State.CLOSED)