# pathfinder.gd
# Autoload — available globally as Pathfinder
# Tier 3 Systems — reads Rooms, Settings
#
# Two responsibilities:
#   1. Route planning — builds a waypoint array for any room-to-room journey
#   2. Elevator management — owns 2 car nodes, dispatches them, signals boarding/exit
#
# Route waypoint types:
#   exit_room        — leave current room spawn, walk to door
#   walk             — general hallway movement
#   wait_elevator    — stand at shaft, request car, wait for boarding signal
#   ride_elevator    — follow car Y in _process until passenger_exited fires
#   wait_hallway_door — approach hallway door, wait for it to open
#   enter_doorway    — walk through into the doorway gap, notify hallway door to close
#   wait_room_door   — wait for inner room door to open
#   arrive           — walk to spawn position inside the room

extends Node

signal passenger_boarded(car_index: int, char_id: String)
signal passenger_exited(car_index: int, char_id: String)

const CAR_COUNT: int = 2
const CAR_SPEED: float = 9.0        # units per second
const MAX_PASSENGERS: int = 3
const DOOR_OPEN_TIME: float = 3.0   # seconds doors stay open after last boarding

# Per-car state dictionaries. State values: "idle", "moving", "doors_open"
var _cars: Array = []
var _car_height_offset: float = 0.0

# Per-car boarding queues — { floor, dest_floor, requester_id }
var _wait_queues: Array = [[], []]

# Per-car door close timers
var _door_timers: Array = []

# Shaft X world positions — set by building.gd after lobby scene loads
var _shaft_x: Array = [0.0, 0.0]


func register_shaft_positions(left_x: float, right_x: float) -> void:
	_shaft_x[0] = left_x
	_shaft_x[1] = right_x


func _ready() -> void:
	for i in CAR_COUNT:
		_cars.append({
			"floor": 0,
			"state": "idle",
			"node": null,
			"tween": null,
			"passengers": [],
		})
		var timer := Timer.new()
		timer.one_shot = true
		timer.wait_time = DOOR_OPEN_TIME
		timer.timeout.connect(_on_door_timer_expired.bind(i))
		add_child(timer)
		_door_timers.append(timer)
	print("[Pathfinder] Loaded. %d elevator cars." % CAR_COUNT)


# ── ROUTE PLANNING ───────────────────────────────────────────
# Builds the full waypoint array for a room-to-room journey.
# Called by Actions.start_movement() — result stored on CharData.waypoints.

func plan_route(origin_room: String, dest_room: String) -> Array:
	# Hallway origins skip the "exit room" waypoints — character is already in the corridor
	if origin_room.begins_with("hallway_"):
		return _plan_from_hallway(origin_room, dest_room)

	var origin: Dictionary = Rooms.get_room_data(origin_room)
	var dest: Dictionary = Rooms.get_room_data(dest_room)

	if origin.is_empty() or dest.is_empty():
		push_warning("[Pathfinder] Bad room IDs: %s → %s" % [origin_room, dest_room])
		return []

	var waypoints: Array = []
	var origin_floor: int = origin["floor_index"]
	var dest_floor: int = dest["floor_index"]

	# Pick a random hallway lane — consistent across all hallway waypoints
	var origin_fd_early: Dictionary = Rooms.get_floor_data_by_index(origin_floor)
	var lanes: Array = origin_fd_early.get("hallway_lanes", [
		Vector3(0, 0, 0.3),
		Vector3(0, 0, 0.65),
		Vector3(0, 0, 1.0),
	])
	var chosen_lane: Vector3 = lanes[randi() % lanes.size()]
	var lane_z: float = chosen_lane.z

	# ── EXIT ORIGIN ROOM ─────────────────────────────────────
	# Walk to room door wait position, room door opens
	waypoints.append({
		"pos": Rooms.get_room_door_wait_pos(origin_room),
		"type": "wait_room_door_exit",
		"room_id": origin_room,
	})
	# Walk through room doorway, room door starts closing
	waypoints.append({
		"pos": Rooms.get_room_doorway_pos(origin_room),
		"type": "exit_room_doorway",
		"room_id": origin_room,
	})
	# Walk to hallway door, hallway door opens
	waypoints.append({
		"pos": origin["door_pos"],
		"type": "wait_hallway_door_exit",
		"room_id": origin_room,
	})
	# Walk through hallway doorway, hallway door starts closing
	var doorway_pos: Vector3 = Rooms.get_doorway_pos(origin_room)
	waypoints.append({
		"pos": Vector3(doorway_pos.x, doorway_pos.y, lane_z),
		"type": "exit_hallway_doorway",
		"room_id": origin_room,
	})

	# ── HALLWAY / ELEVATOR ───────────────────────────────────
	if origin_floor != dest_floor:
		var car_index: int = _pick_elevator(origin["door_pos"].x)
		var wait_key: String = "elevator_left_wait" if car_index == 0 else "elevator_right_wait"

		var origin_fd: Dictionary = Rooms.get_floor_data_by_index(origin_floor)
		var el_wait_pos: Vector3 = origin_fd.get(wait_key, Vector3.ZERO)
		var origin_hallway_y: float = origin_fd.get("hallway_y", el_wait_pos.y)

		waypoints.append({
			"pos": Vector3(el_wait_pos.x, origin_hallway_y, lane_z),
			"type": "walk",
		})
		waypoints.append({
			"pos": Vector3(el_wait_pos.x, origin_hallway_y, lane_z),
			"type": "wait_elevator",
			"car_index": car_index,
			"from_floor": origin_floor,
			"to_floor": dest_floor,
		})

		var dest_fd: Dictionary = Rooms.get_floor_data_by_index(dest_floor)
		var dest_wait_key: String = "elevator_left_wait" if car_index == 0 else "elevator_right_wait"
		var el_dest_pos: Vector3 = dest_fd.get(dest_wait_key, Vector3.ZERO)
		var dest_hallway_y: float = dest_fd.get("hallway_y", el_dest_pos.y)

		waypoints.append({
			"pos": Vector3(el_dest_pos.x, dest_hallway_y, lane_z),
			"type": "ride_elevator",
			"car_index": car_index,
			"to_floor": dest_floor,
		})
		waypoints.append({
			"pos": Vector3(el_dest_pos.x, dest_hallway_y, lane_z),
			"type": "walk",
		})
		waypoints.append({
			"pos": Vector3(dest["door_pos"].x, dest_hallway_y, lane_z),
			"type": "walk",
		})
	else:
		var floor_fd: Dictionary = Rooms.get_floor_data_by_index(origin_floor)
		var hallway_y: float = floor_fd.get("hallway_y", origin["door_pos"].y)
		waypoints.append({
			"pos": Vector3(dest["door_pos"].x, hallway_y, lane_z),
			"type": "walk",
		})

	# ── ENTER DESTINATION ROOM ───────────────────────────────
	# Approach hallway door, wait for it to open
	waypoints.append({
		"pos": dest["door_pos"],
		"type": "wait_hallway_door",
		"room_id": dest_room,
	})
	# Walk through hallway doorway, hallway door starts closing
	waypoints.append({
		"pos": Rooms.get_doorway_pos(dest_room),
		"type": "enter_doorway",
		"room_id": dest_room,
	})
	# Wait for room door to open
	waypoints.append({
		"pos": Rooms.get_doorway_pos(dest_room),
		"type": "wait_room_door",
		"room_id": dest_room,
	})
	# Walk to spawn inside the room
	waypoints.append({
		"pos": dest["spawn_pos"],
		"type": "arrive",
		"room_id": dest_room,
	})

	return waypoints

# Plans a route starting from a hallway corridor.
# Skips room exit waypoints — character is already in the corridor.
# Used when resuming movement after a hallway conversation.
func _plan_from_hallway(origin_hallway: String, dest_room: String) -> Array:
	var dest: Dictionary = Rooms.get_room_data(dest_room)
	if dest.is_empty():
		push_warning("[Pathfinder] Bad dest room: %s" % dest_room)
		return []

	# Parse floor index from hallway_fN
	var origin_floor: int = int(origin_hallway.replace("hallway_f", ""))
	var dest_floor: int = dest["floor_index"]

	var origin_fd: Dictionary = Rooms.get_floor_data_by_index(origin_floor)
	var lanes: Array = origin_fd.get("hallway_lanes", [
		Vector3(0, 0, 0.3), Vector3(0, 0, 0.65), Vector3(0, 0, 1.0)])
	var chosen_lane: Vector3 = lanes[randi() % lanes.size()]
	var lane_z: float = chosen_lane.z

	var waypoints: Array = []

	if origin_floor != dest_floor:
		# Walk to elevator, ride to dest floor
		var car_index: int = _pick_elevator(dest["door_pos"].x)
		var wait_key: String = "elevator_left_wait" if car_index == 0 else "elevator_right_wait"
		var el_wait_pos: Vector3 = origin_fd.get(wait_key, Vector3.ZERO)
		var origin_hallway_y: float = origin_fd.get("hallway_y", el_wait_pos.y)

		waypoints.append({
			"pos": Vector3(el_wait_pos.x, origin_hallway_y, lane_z),
			"type": "walk",
		})
		waypoints.append({
			"pos": Vector3(el_wait_pos.x, origin_hallway_y, lane_z),
			"type": "wait_elevator",
			"car_index": car_index,
			"from_floor": origin_floor,
			"to_floor": dest_floor,
		})

		var dest_fd: Dictionary = Rooms.get_floor_data_by_index(dest_floor)
		var dest_wait_key: String = "elevator_left_wait" if car_index == 0 else "elevator_right_wait"
		var el_dest_pos: Vector3 = dest_fd.get(dest_wait_key, Vector3.ZERO)
		var dest_hallway_y: float = dest_fd.get("hallway_y", el_dest_pos.y)

		waypoints.append({
			"pos": Vector3(el_dest_pos.x, dest_hallway_y, lane_z),
			"type": "ride_elevator",
			"car_index": car_index,
			"to_floor": dest_floor,
		})
		waypoints.append({
			"pos": Vector3(el_dest_pos.x, dest_hallway_y, lane_z),
			"type": "walk",
		})
		waypoints.append({
			"pos": Vector3(dest["door_pos"].x, dest_hallway_y, lane_z),
			"type": "walk",
		})
	else:
		# Same floor — walk directly to dest door
		var hallway_y: float = origin_fd.get("hallway_y", dest["door_pos"].y)
		waypoints.append({
			"pos": Vector3(dest["door_pos"].x, hallway_y, lane_z),
			"type": "walk",
		})

	# Enter destination room — same as regular plan_route
	waypoints.append({
		"pos": dest["door_pos"],
		"type": "wait_hallway_door",
		"room_id": dest_room,
	})
	waypoints.append({
		"pos": Rooms.get_doorway_pos(dest_room),
		"type": "enter_doorway",
		"room_id": dest_room,
	})
	waypoints.append({
		"pos": Rooms.get_doorway_pos(dest_room),
		"type": "wait_room_door",
		"room_id": dest_room,
	})
	waypoints.append({
		"pos": dest["spawn_pos"],
		"type": "arrive",
		"room_id": dest_room,
	})

	return waypoints
	
func can_reach(origin_room: String, dest_room: String) -> bool:
	return not Rooms.get_room_data(origin_room).is_empty() \
		and not Rooms.get_room_data(dest_room).is_empty()


# ── ELEVATOR PICKING ─────────────────────────────────────────
# Returns the index of the closest shaft to the character's X position.

func _pick_elevator(x_pos: float) -> int:
	# If both shafts are basically in the same spot, always use car 0
	if _shaft_x[1] <= _shaft_x[0] + 1.5:
		return 0
	var dist_left: float = abs(x_pos - _shaft_x[0])
	var dist_right: float = abs(x_pos - _shaft_x[1])
	return 0 if dist_left <= dist_right else 1


# ── ELEVATOR REQUESTS ────────────────────────────────────────
# Called by movement_controller when a character reaches their wait_elevator waypoint.
# Adds them to the queue and dispatches the car if it's free.

func request_elevator(car_index: int, pickup_floor: int, dest_floor: int, requester_id: String) -> void:
	var car: Dictionary = _cars[car_index]
	var req := { "floor": pickup_floor, "dest_floor": dest_floor, "requester_id": requester_id }

	# Doors already open at this floor — try boarding immediately
	if car["state"] == "doors_open" and car["floor"] == pickup_floor:
		_wait_queues[car_index].append(req)
		_try_board_waiters(car_index)
		return

	# Car idle and already here — open doors
	if car["state"] == "idle" and car["floor"] == pickup_floor:
		_wait_queues[car_index].append(req)
		_open_doors_and_process(car_index)
		return

	# Car elsewhere — queue and dispatch if idle
	_wait_queues[car_index].append(req)
	if car["state"] == "idle":
		_dispatch_to_nearest_waiter(car_index)


# ── CAR DISPATCH ─────────────────────────────────────────────

func _dispatch_to_nearest_waiter(car_index: int) -> void:
	if _wait_queues[car_index].is_empty():
		return
	var car: Dictionary = _cars[car_index]
	var closest_floor: int = -1
	var min_dist: int = 999
	for req in _wait_queues[car_index]:
		var d: int = absi(req["floor"] - car["floor"])
		if d < min_dist:
			min_dist = d
			closest_floor = req["floor"]
	if closest_floor >= 0:
		_dispatch_car(car_index, closest_floor)


func _dispatch_car(car_index: int, target_floor: int) -> void:
	var car: Dictionary = _cars[car_index]
	var node: Node3D = car["node"]
	if node == null:
		push_error("[Pathfinder] Car %d has no visual node!" % car_index)
		return

	# Already there — process arrivals immediately without tweening
	if car["floor"] == target_floor:
		_on_car_arrived(car_index, target_floor)
		return

	car["state"] = "moving"
	var target_y: float = _get_car_y_for_floor(car_index, target_floor)
	var distance: float = abs(node.position.y - target_y)
	var duration: float = maxf(distance / CAR_SPEED, 0.1)

	if car["tween"] and car["tween"].is_valid():
		car["tween"].kill()

	var tween: Tween = node.create_tween()
	tween.tween_property(node, "position:y", target_y, duration)
	tween.finished.connect(
		func(): _on_car_arrived(car_index, target_floor),
		CONNECT_ONE_SHOT
	)
	car["tween"] = tween

	if Settings.debug_console_logging:
		print("[Pathfinder] 🛗 Car %d dispatched: floor %d → %d (%d passengers)" % [
			car_index, car["floor"], target_floor, car["passengers"].size()
		])


# ── CAR ARRIVAL + DOOR MANAGEMENT ────────────────────────────

func _on_car_arrived(car_index: int, floor_index: int) -> void:
	var car: Dictionary = _cars[car_index]
	car["floor"] = floor_index
	if Settings.debug_console_logging:
		print("[Pathfinder] 🛗 Car %d arrived at floor %d" % [car_index, floor_index])
	_open_doors_and_process(car_index)


func _open_doors_and_process(car_index: int) -> void:
	var car: Dictionary = _cars[car_index]
	car["state"] = "doors_open"
	var current_floor: int = car["floor"]

	# First let any passengers off at this floor
	var remaining: Array = []
	for p in car["passengers"]:
		if p["dest_floor"] == current_floor:
			if Settings.debug_console_logging:
				print("[Pathfinder] 🛗 %s exiting car %d at floor %d" % [
					p["char_id"], car_index, current_floor
				])
			passenger_exited.emit(car_index, p["char_id"])
		else:
			remaining.append(p)
	car["passengers"] = remaining

	# Then try to board anyone waiting at this floor
	var boarded: bool = _try_board_waiters(car_index)

	if car["passengers"].is_empty():
		# Nobody aboard — check for other waiters elsewhere, otherwise idle
		_door_timers[car_index].stop()
		if _wait_queues[car_index].is_empty():
			car["state"] = "idle"
		else:
			car["state"] = "idle"
			_dispatch_to_nearest_waiter(car_index)
	elif not boarded and not _has_waiters_at_floor(car_index, current_floor):
		# Has passengers but nobody new boarding — move immediately
		_close_doors_and_move(car_index)
	# If someone boarded, the door timer is already running from _try_board_waiters


func _try_board_waiters(car_index: int) -> bool:
	var car: Dictionary = _cars[car_index]
	var current_floor: int = car["floor"]
	var available: int = MAX_PASSENGERS - car["passengers"].size()
	if available <= 0:
		_close_doors_and_move(car_index)
		return false

	var boarded_any: bool = false
	var remaining_queue: Array = []

	for req in _wait_queues[car_index]:
		if req["floor"] == current_floor and available > 0:
			car["passengers"].append({
				"char_id": req["requester_id"],
				"dest_floor": req["dest_floor"],
			})
			if Settings.debug_console_logging:
				print("[Pathfinder] 🛗 %s boarded car %d (→ floor %d)" % [
					req["requester_id"], car_index, req["dest_floor"]
				])
			passenger_boarded.emit(car_index, req["requester_id"])
			available -= 1
			boarded_any = true
		else:
			remaining_queue.append(req)

	_wait_queues[car_index] = remaining_queue

	if boarded_any:
		# Reset the door timer — give any stragglers time to board
		_door_timers[car_index].stop()
		_door_timers[car_index].start(DOOR_OPEN_TIME)

	# Full car — close and go immediately
	if car["passengers"].size() >= MAX_PASSENGERS:
		_close_doors_and_move(car_index)

	return boarded_any


func _on_door_timer_expired(car_index: int) -> void:
	var car: Dictionary = _cars[car_index]
	if car["passengers"].is_empty():
		# Timer fired but nobody boarded — go idle and check for other waiters
		car["state"] = "idle"
		if not _wait_queues[car_index].is_empty():
			_dispatch_to_nearest_waiter(car_index)
		return
	_close_doors_and_move(car_index)


func _close_doors_and_move(car_index: int) -> void:
	_door_timers[car_index].stop()
	var next_floor: int = _get_next_dest_floor(car_index)
	if next_floor < 0:
		_cars[car_index]["state"] = "idle"
		return
	_dispatch_car(car_index, next_floor)


# Returns the closest destination floor among current passengers
func _get_next_dest_floor(car_index: int) -> int:
	var car: Dictionary = _cars[car_index]
	var closest: int = -1
	var min_dist: float = INF
	for p in car["passengers"]:
		var d: float = abs(float(p["dest_floor"] - car["floor"]))
		if d < min_dist:
			min_dist = d
			closest = p["dest_floor"]
	return closest


func _has_waiters_at_floor(car_index: int, floor_index: int) -> bool:
	for req in _wait_queues[car_index]:
		if req["floor"] == floor_index:
			return true
	return false


# ── CAR POSITION ─────────────────────────────────────────────
# Returns the world Y the car should sit at for a given floor.
# Car Y = hallway Y — characters stand at car Y directly.

func _get_car_y_for_floor(_car_index: int, floor_index: int) -> float:
	var floor_data: Dictionary = Rooms.get_floor_data_by_index(floor_index)
	if floor_data.is_empty():
		push_warning("[Pathfinder] No floor data for index %d" % floor_index)
		var node = _cars[_car_index]["node"]
		return node.position.y if node else 0.0
	return floor_data.get("hallway_y", 0.0)


# ── ACCESSORS ────────────────────────────────────────────────

func get_car_node(car_index: int) -> Node3D:
	if car_index < 0 or car_index >= _cars.size():
		return null
	return _cars[car_index].get("node", null)


func get_car_state(car_index: int) -> String:
	if car_index < 0 or car_index >= _cars.size():
		return "idle"
	return _cars[car_index].get("state", "idle")


func get_car_floor(car_index: int) -> int:
	if car_index < 0 or car_index >= _cars.size():
		return 0
	return _cars[car_index].get("floor", 0)


func get_passenger_count(car_index: int) -> int:
	if car_index < 0 or car_index >= _cars.size():
		return 0
	return _cars[car_index]["passengers"].size()


func register_car_node(car_index: int, node: Node3D, height_offset: float) -> void:
	if car_index < 0 or car_index >= _cars.size():
		return
	_cars[car_index]["node"] = node
	_car_height_offset = height_offset


func debug_elevator_state() -> void:
	for i in CAR_COUNT:
		var c = _cars[i]
		print("[Pathfinder] Car %d: floor=%d state=%s passengers=%d queue=%d" % [
			i, c["floor"], c["state"], c["passengers"].size(), _wait_queues[i].size()
		])