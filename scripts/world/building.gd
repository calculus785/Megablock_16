# building.gd
# Instances floor scenes from BuildingData, registers all rooms in Rooms.
# Reads Marker2D positions from each instanced scene — no hardcoded coords.

extends Node3D

var _camera: Camera3D
var _storybook_logs_visible: bool = false


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

		var floor_node: Node3D = scene.instantiate()    # ← was Node2D
		floor_node.name = floor_def["floor_id"]
		floor_node.position = Vector3(0, -BuildingData.get_floor_y(i) / 32.0, 0)

		# Add to tree FIRST — global positions are only valid after this
		add_child(floor_node)

		# Now register each room using Marker2D global positions
		_register_floor_rooms(floor_node, floor_def, type_def, i)

		_register_floor_info(floor_node, floor_def, i)

		_register_doors(floor_node, floor_def, type_def)


func _register_floor_rooms(
	floor_node: Node3D,
	floor_def: Dictionary,
	type_def: Dictionary,
	floor_index: int
) -> void:
	var slots: Array = type_def["slots"]

	for room_entry in floor_def["rooms"]:
		var slot: Dictionary = slots[room_entry["slot"]]

		var door_marker: Marker3D = floor_node.get_node_or_null(slot["door_node"])
		var doorway_marker: Marker3D = floor_node.get_node_or_null(slot.get("doorway_node", ""))

		if door_marker == null:
			push_error("[Building] Missing door marker in %s for room %s" % [
				floor_def["floor_id"], room_entry["room_id"]
			])
			continue

		var hallway_y: float = 0.0
		var lane0 = floor_node.get_node_or_null("HallwayLane0")
		if lane0:
			hallway_y = lane0.global_position.y

		Rooms.register_room(room_entry["room_id"], {
			"type":         room_entry["type"],
			"floor_id":     floor_def["floor_id"],
			"floor_index":  floor_index,
			"occupants":    [],
			# spawn_pos intentionally left as ZERO here —
			# overwritten by _instance_room_scene once room scene is loaded
			"spawn_pos":    Vector3.ZERO,
			"door_pos":     door_marker.global_position,
			"doorway_pos":  doorway_marker.global_position if doorway_marker else door_marker.global_position,
			"hallway_y":    hallway_y,
			"room_size":    slot["room_size"],
		})

		_instance_room_scene(floor_node, slot, room_entry["room_id"])
	

func _register_floor_info(floor_node: Node3D, floor_def: Dictionary, floor_index: int) -> void:
	var lane0 = floor_node.get_node_or_null("HallwayLane0")
	var lane1 = floor_node.get_node_or_null("HallwayLane1")
	var lane2 = floor_node.get_node_or_null("HallwayLane2")
	var el_left = floor_node.get_node_or_null("ElevatorLeftWait")
	var el_right = floor_node.get_node_or_null("ElevatorRightWait")

	# Fallback: if lanes missing, space them manually from lane0
	var l0_pos: Vector3 = lane0.global_position if lane0 else Vector3.ZERO
	var l1_pos: Vector3 = lane1.global_position if lane1 else l0_pos + Vector3(0, 0, 0.35)
	var l2_pos: Vector3 = lane2.global_position if lane2 else l0_pos + Vector3(0, 0, 0.70)

	Rooms.register_floor(floor_def["floor_id"], {
		"index":                floor_index,
		"hallway_y":            l0_pos.y,
		"hallway_lanes":        [l0_pos, l1_pos, l2_pos],
		"elevator_left_wait":   el_left.global_position  if el_left  else Vector3.ZERO,
		"elevator_right_wait":  el_right.global_position if el_right else Vector3.ZERO,
	})


# ─── CAMERA ──────────────────────────────────────────────────

func _setup_camera() -> void:
	_camera = Camera3D.new()
	_camera.name = "BuildingCamera"
	_camera.projection = Camera3D.PROJECTION_PERSPECTIVE

	# Ortho size = half the vertical view in units.
	# 40 shows ~2.5 floors. Zoom changes this value.
	_camera.size = 45.0

	# Position: centered on building, pulled forward on Z
	var mid_floor: int = BuildingData.FLOORS.size() / 2
	var mid_y: float = -BuildingData.get_floor_y(mid_floor) / 32.0 - BuildingData.FLOOR_HEIGHT / 64.0
	_camera.position = Vector3(
		BuildingData.FLOOR_WIDTH / 64.0,  # center X
		mid_y,                             # center Y
		50.0                               # far enough forward to see everything
	)
	# Look straight at the building (default -Z direction is correct)
	_camera.rotation_degrees = Vector3.ZERO

	add_child(_camera)
	_camera.make_current()


func _process(_delta: float) -> void:
	if _camera == null:
		return
	var speed: float = _camera.position.z * 0.03
	if Input.is_action_pressed("ui_left"):  _camera.position.x -= speed
	if Input.is_action_pressed("ui_right"): _camera.position.x += speed
	if Input.is_action_pressed("ui_up"):    _camera.position.y += speed  # 3D Y is up
	if Input.is_action_pressed("ui_down"):  _camera.position.y -= speed


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_camera.position.z = clamp(_camera.position.z * 0.9, 10.0, 150.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_camera.position.z = clamp(_camera.position.z * 1.1, 10.0, 150.0)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F4:
			_storybook_logs_visible = not _storybook_logs_visible
			_set_storybook_visible(_storybook_logs_visible)

# ─── ELEVATOR CARS ───────────────────────────────────────────
# Two elevator sprites, one per shaft. Start at floor 0 (bottom).
# Pathfinder owns the logic, we just create the visuals.

func _setup_elevators() -> void:
	# Load shaft positions from FloorLobby scene
	var shaft_scene: PackedScene = load("res://scenes/world/FloorLobby.tscn")
	if shaft_scene == null:
		push_error("[Building] Can't load FloorLobby.tscn")
		return

	var shaft_node: Node3D = shaft_scene.instantiate()
	add_child(shaft_node)

	var shaft0_x: float = shaft_node.get_node("Spots/Shaft0_Pos").global_position.x
	var shaft2_x: float = shaft_node.get_node("Spots/Shaft2_Pos").global_position.x

	shaft_node.queue_free()

	var floor0_data: Dictionary = Rooms.get_floor_data_by_index(0)
	var initial_y: float = floor0_data.get("hallway_y", 0.0)

	const CAR_W: float = 2.0
	const CAR_H: float = 3.0
	const CAR_D: float = 0.5

	for i in 2:
		var car := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(CAR_W, CAR_H, CAR_D)
		car.mesh = mesh

		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.2, 0.2, 0.25)
		car.material_override = mat

		car.name = "ElevatorCar%d" % i
		var shaft_x: float = shaft0_x if i == 0 else shaft2_x
		car.position = Vector3(shaft_x, initial_y, 0.3)
		add_child(car)

		# height_offset = 0 since car Y is the hallway floor level
		Pathfinder.register_car_node(i, car, 0.0)

	Pathfinder.register_shaft_positions(shaft0_x, shaft2_x)
	print("[Building] 2 elevator cars placed at shafts.")

func _instance_room_scene(floor_node: Node3D, slot: Dictionary, room_id: String) -> void:
	var scene_path: String = slot.get("room_scene", "")
	var origin_path: String = slot.get("origin_node", "")

	if scene_path == "" or origin_path == "":
		return

	var origin_marker: Marker3D = floor_node.get_node_or_null(origin_path)
	if origin_marker == null:
		push_warning("[Building] No origin marker at %s for room %s" % [origin_path, room_id])
		return

	var packed: PackedScene = load(scene_path)
	if packed == null:
		push_error("[Building] Can't load room scene: %s" % scene_path)
		return

	var room_node: Node3D = packed.instantiate()
	room_node.name = room_id + "_Room"
	room_node.position = origin_marker.position
	floor_node.add_child(room_node)

		# Read zones and spots from the room scene
	var zones_node = room_node.get_node_or_null("Zones")
	if zones_node:
		var zone_data: Array = []
		for zone in zones_node.get_children():
			if not zone.name.begins_with("Zone_"):
				continue
			var zone_name: String = zone.name
			var spots: Array = []
			for spot in zone.get_children():
				if not spot.name.begins_with("Spot_"):
					continue
				spots.append({
					"name": spot.name,
					"pos": spot.global_position,
					"occupied_by": "",  # char_id or empty
				})
			zone_data.append({
				"zone_name": zone_name,
				"spots": spots,
			})
		Rooms.set_zones(room_id, zone_data)

	# Override spawn_pos with the room's internal SpawnPos marker
	var spawn_marker = room_node.get_node_or_null("SpawnPos")
	if spawn_marker:
		Rooms.set_spawn_pos(room_id, spawn_marker.global_position)
	else:
		push_warning("[Building] No SpawnPos in room scene for %s — characters will spawn at origin" % room_id)

	# Store room-side door positions
	var door_wait = room_node.get_node_or_null("DoorWaitPos")
	var room_doorway = room_node.get_node_or_null("DoorwayPos")

	if door_wait:
		Rooms.set_room_door_wait_pos(room_id, door_wait.global_position)
	else:
		push_warning("[Building] No DoorWaitPos in room scene for %s" % room_id)

	if room_doorway:
		Rooms.set_room_doorway_pos(room_id, room_doorway.global_position)
	else:
		push_warning("[Building] No DoorwayPos in room scene for %s" % room_id)

func _set_storybook_visible(show: bool) -> void:
	var container = get_node_or_null("Characters")
	if container == null:
		return
	for body in container.get_children():
		if body.has_method("set_storybook_visible"):
			body.set_storybook_visible(show)

func _register_doors(floor_node: Node3D, floor_def: Dictionary, type_def: Dictionary) -> void:
	var slots: Array = type_def["slots"]

	for i in floor_def["rooms"].size():
		var room_id: String = floor_def["rooms"][i]["room_id"]

		# Hallway door — under Doors/Door0, Door1, Door2...
		var hallway_door = floor_node.get_node_or_null("Doors/Door%d" % i)
		if hallway_door:
			Rooms.register_hallway_door(room_id, hallway_door)
		else:
			push_warning("[Building] No hallway door Door%d for room %s" % [i, room_id])

		# Room door — inside the instanced room scene, under Geometry/Door0
		var room_node_name: String = room_id + "_Room"
		var room_node = floor_node.get_node_or_null(room_node_name)
		if room_node:
			var room_door = room_node.get_node_or_null("Geometry/Door0")
			if room_door:
				Rooms.register_room_door(room_id, room_door)
