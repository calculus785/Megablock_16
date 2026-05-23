# building.gd
# Instances floor scenes from BuildingData, registers all rooms in Rooms.
# Reads Marker2D positions from each instanced scene — no hardcoded coords.

extends Node2D

var _camera: Camera2D


func _ready() -> void:
	_build_floors()
	_setup_camera()
	_setup_elevators()
	print("[Building] %d floors built. %d rooms registered." % [
		BuildingData.FLOORS.size(),
		Rooms.get_all_room_ids().size(),
	])


# ─── FLOOR INSTANCING ────────────────────────────────────────

func _build_floors() -> void:
	for i in BuildingData.FLOORS.size():
		var floor_def: Dictionary = BuildingData.FLOORS[i]
		var type_def: Dictionary = BuildingData.FLOOR_TYPES[floor_def["floor_type"]]

		# Load and instance the PackedScene
		var scene: PackedScene = load(type_def["scene_path"])
		if scene == null:
			push_error("[Building] Can't load scene: %s" % type_def["scene_path"])
			continue

		var floor_node: Node2D = scene.instantiate()
		floor_node.name = floor_def["floor_id"]
		floor_node.position = Vector2(0, BuildingData.get_floor_y(i))

		# Add to tree FIRST — global positions are only valid after this
		add_child(floor_node)

		# Now register each room using Marker2D global positions
		_register_floor_rooms(floor_node, floor_def, type_def, i)

		_register_floor_info(floor_node, floor_def, i)


func _register_floor_rooms(
	floor_node: Node2D,
	floor_def: Dictionary,
	type_def: Dictionary,
	floor_index: int
) -> void:
	var slots: Array = type_def["slots"]

	for room_entry in floor_def["rooms"]:
		var slot: Dictionary = slots[room_entry["slot"]]

		# Read world positions directly from the Marker2D nodes
		var spawn_marker: Marker2D = floor_node.get_node(slot["spawn_node"])
		var door_marker: Marker2D = floor_node.get_node(slot["door_node"])

		if spawn_marker == null or door_marker == null:
			push_error("[Building] Missing marker in %s for room %s" % [
				floor_def["floor_id"], room_entry["room_id"]
			])
			continue

		# Also read elevator + hallway markers if present
		var hallway_y: float = 0.0
		var hallway_marker = floor_node.get_node_or_null("HallwayLine")
		if hallway_marker:
			hallway_y = hallway_marker.global_position.y

		Rooms.register_room(room_entry["room_id"], {
			"type": room_entry["type"],
			"floor_id": floor_def["floor_id"],
			"floor_index": floor_index,
			"occupants": [],
			"spawn_pos": spawn_marker.global_position,
			"door_pos": door_marker.global_position,
			"hallway_y": hallway_y,
			"room_size": slot["room_size"],
		})

func _register_floor_info(floor_node: Node2D, floor_def: Dictionary, floor_index: int) -> void:
	var hallway = floor_node.get_node_or_null("HallwayLine")
	var el_left = floor_node.get_node_or_null("ElevatorLeftWait")
	var el_right = floor_node.get_node_or_null("ElevatorRightWait")

	Rooms.register_floor(floor_def["floor_id"], {
		"index": floor_index,
		"hallway_y": hallway.global_position.y if hallway else 0.0,
		"elevator_left_wait": el_left.global_position if el_left else Vector2.ZERO,
		"elevator_right_wait": el_right.global_position if el_right else Vector2.ZERO,
	})


# ─── CAMERA ──────────────────────────────────────────────────

func _setup_camera() -> void:
	_camera = Camera2D.new()
	_camera.name = "BuildingCamera"

	var mid_floor: int = BuildingData.FLOORS.size() / 2
	var mid_y := BuildingData.get_floor_y(mid_floor) + BuildingData.FLOOR_HEIGHT / 2.0
	_camera.position = Vector2(BuildingData.FLOOR_WIDTH / 2.0, mid_y)
	_camera.zoom = Vector2(0.5, 0.5)

	add_child(_camera)
	_camera.make_current()


func _process(_delta: float) -> void:
	if _camera == null:
		return
	var speed := 12.0 / _camera.zoom.x
	if Input.is_action_pressed("ui_left"):  _camera.position.x -= speed
	if Input.is_action_pressed("ui_right"): _camera.position.x += speed
	if Input.is_action_pressed("ui_up"):    _camera.position.y -= speed
	if Input.is_action_pressed("ui_down"):  _camera.position.y += speed


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_camera.zoom = (_camera.zoom * 1.1).clamp(Vector2(0.15, 0.15), Vector2(3.0, 3.0))
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_camera.zoom = (_camera.zoom * 0.9).clamp(Vector2(0.15, 0.15), Vector2(3.0, 3.0))

# ─── ELEVATOR CARS ───────────────────────────────────────────
# Two elevator sprites, one per shaft. Start at floor 0 (bottom).
# Pathfinder owns the logic, we just create the visuals.

func _setup_elevators() -> void:
	var car_texture: Texture2D = load("res://assets/textures/floors/elevator_car.png")
	if car_texture == null:
		push_error("[Building] Can't load elevator_car.png")
		return

	# Load shaft position scene
	var shaft_scene: PackedScene = load("res://scenes/world/FloorLobby.tscn")
	if shaft_scene == null:
		push_error("[Building] Can't load FloorLobby.tscn")
		return

	var shaft_node: Node2D = shaft_scene.instantiate()
	add_child(shaft_node)  # add to tree so global_position resolves

	var shaft0_x: float = shaft_node.get_node("Shaft0_Pos").global_position.x
	var shaft2_x: float = shaft_node.get_node("Shaft2_Pos").global_position.x

	# Remove shaft node — we only needed the positions
	shaft_node.queue_free()

	var tex_h: float = car_texture.get_height()
	var tex_w: float = car_texture.get_width()
	var floor0_data: Dictionary = Rooms.get_floor_data_by_index(0)
	var initial_y: float = floor0_data.get("hallway_y", 0.0) - tex_h

	# Car 0 — left shaft
	var car0 := Sprite2D.new()
	car0.texture = car_texture
	car0.centered = false
	car0.name = "ElevatorCar0"
	car0.position = Vector2(shaft0_x - tex_w / 2.0, initial_y)
	add_child(car0)
	Pathfinder.register_car_node(0, car0, tex_h)

	# Car 1 — right shaft
	var car1 := Sprite2D.new()
	car1.texture = car_texture
	car1.centered = false
	car1.name = "ElevatorCar1"
	car1.position = Vector2(shaft2_x - tex_w / 2.0, initial_y)
	add_child(car1)
	Pathfinder.register_car_node(1, car1, tex_h)

	# Store shaft X positions for Pathfinder car tweening
	Pathfinder.register_shaft_positions(shaft0_x, shaft2_x)

	print("[Building] 2 elevator cars placed at shafts.")
