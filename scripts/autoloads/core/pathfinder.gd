# pathfinder.gd
# Autoload — available globally as Pathfinder
# Plans routes between rooms. Manages 2 elevator cars.
# Car 0 = left shaft, Car 1 = right shaft.
# Max 3 passengers per car. 3-second door timer resets on each boarding.

extends Node

signal passenger_boarded(car_index: int, char_id: String)
signal passenger_exited(car_index: int, char_id: String)

const CAR_COUNT: int = 2
const CAR_SPEED: float = 300.0
const MAX_PASSENGERS: int = 3
const DOOR_OPEN_TIME: float = 3.0

# Per-car state. States: "idle", "moving", "doors_open"
var _cars: Array = []
var _car_texture_height: float = 0.0

# Per-car wait queues: { floor: int, dest_floor: int, requester_id: String }
var _wait_queues: Array = [[], []]

# Per-car door timers
var _door_timers: Array = []

var _shaft_x: Array = [0.0, 0.0]  # [left_shaft_x, right_shaft_x]

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
			"passengers": [],  # { char_id: String, dest_floor: int }
		})
		var timer := Timer.new()
		timer.one_shot = true
		timer.wait_time = DOOR_OPEN_TIME
		timer.timeout.connect(_on_door_timer_expired.bind(i))
		add_child(timer)
		_door_timers.append(timer)
	print("[Pathfinder] Loaded. %d elevator cars." % CAR_COUNT)


# ── ROUTE PLANNING ───────────────────────────────────────────

func plan_route(origin_room: String, dest_room: String) -> Array:
	var origin: Dictionary = Rooms.get_room_data(origin_room)
	var dest: Dictionary = Rooms.get_room_data(dest_room)

	if origin.is_empty() or dest.is_empty():
		push_warning("[Pathfinder] Bad room IDs: %s → %s" % [origin_room, dest_room])
		return []

	var waypoints: Array = []
	var origin_floor: int = origin["floor_index"]
	var dest_floor: int = dest["floor_index"]

	# Exit room
	waypoints.append({
		"pos": origin["door_pos"],
		"type": "exit_room",
		"room_id": origin_room,
	})

	if origin_floor != dest_floor:
		var car_index: int = _pick_elevator(origin["door_pos"].x)
		var wait_key: String = "elevator_left_wait" if car_index == 0 else "elevator_right_wait"

		var origin_fd: Dictionary = Rooms.get_floor_data_by_index(origin_floor)
		var el_wait_pos: Vector2 = origin_fd.get(wait_key, Vector2.ZERO)
		var origin_hallway_y: float = origin_fd.get("hallway_y", el_wait_pos.y)

		# Walk along hallway to elevator waiting spot
		waypoints.append({
			"pos": Vector2(el_wait_pos.x, origin_hallway_y),
			"type": "walk",
		})

		# Wait for elevator
		waypoints.append({
			"pos": Vector2(el_wait_pos.x, origin_hallway_y),
			"type": "wait_elevator",
			"car_index": car_index,
			"from_floor": origin_floor,
			"to_floor": dest_floor,
		})

		# Ride elevator
		var dest_fd: Dictionary = Rooms.get_floor_data_by_index(dest_floor)
		var dest_wait_key: String = "elevator_left_wait" if car_index == 0 else "elevator_right_wait"
		var el_dest_pos: Vector2 = dest_fd.get(dest_wait_key, Vector2.ZERO)
		var dest_hallway_y: float = dest_fd.get("hallway_y", el_dest_pos.y)
		waypoints.append({
			"pos": Vector2(el_dest_pos.x, dest_hallway_y),
			"type": "ride_elevator",
			"car_index": car_index,
			"to_floor": dest_floor,
		})

		# Snap to hallway after exit
		waypoints.append({
			"pos": Vector2(el_dest_pos.x, dest_hallway_y),
			"type": "walk",
		})

		# Walk along hallway to door
		waypoints.append({
			"pos": Vector2(dest["door_pos"].x, dest_hallway_y),
			"type": "walk",
		})

	# Enter room
	waypoints.append({
		"pos": dest["door_pos"],
		"type": "enter_room",
		"room_id": dest_room,
	})

	# Arrive at spawn
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

func _pick_elevator(x_pos: float) -> int:
	if _shaft_x[1] <= _shaft_x[0] + 50.0:
		return 0
	var dist_left: float = abs(x_pos - _shaft_x[0])
	var dist_right: float = abs(x_pos - _shaft_x[1])
	return 0 if dist_left <= dist_right else 1


# ── ELEVATOR REQUESTS ────────────────────────────────────────

func request_elevator(car_index: int, pickup_floor: int, dest_floor: int, requester_id: String) -> void:
	var car: Dictionary = _cars[car_index]
	var req := { "floor": pickup_floor, "dest_floor": dest_floor, "requester_id": requester_id }

	# Doors already open at our floor — add to queue and try boarding
	if car["state"] == "doors_open" and car["floor"] == pickup_floor:
		_wait_queues[car_index].append(req)
		_try_board_waiters(car_index)
		return

	# Idle and already at our floor — open doors
	if car["state"] == "idle" and car["floor"] == pickup_floor:
		_wait_queues[car_index].append(req)
		_open_doors_and_process(car_index)
		return

	# Otherwise queue and dispatch if idle
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
	var node: Node2D = car["node"]
	if node == null:
		push_error("[Pathfinder] Car %d has no visual node!" % car_index)
		return

	# Already at target — process immediately
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

	# 1. Let passengers exit at this floor
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

	# 2. Try boarding waiters at this floor
	var boarded: bool = _try_board_waiters(car_index)

	# 3. Decide what to do next
	if car["passengers"].is_empty():
		# No passengers — check for waiters elsewhere
		_door_timers[car_index].stop()
		if _wait_queues[car_index].is_empty():
			car["state"] = "idle"
		else:
			car["state"] = "idle"
			_dispatch_to_nearest_waiter(car_index)
	elif not boarded and not _has_waiters_at_floor(car_index, current_floor):
		# Has passengers, nobody new boarding, nobody else waiting here
		# Move immediately to next destination
		_close_doors_and_move(car_index)
	# If someone boarded, the timer is already running from _try_board_waiters


func _try_board_waiters(car_index: int) -> bool:
	var car: Dictionary = _cars[car_index]
	var current_floor: int = car["floor"]
	var available: int = MAX_PASSENGERS - car["passengers"].size()
	if available <= 0:
		# Full — close doors and go
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
		# Reset door timer — give others 3 seconds to arrive
		_door_timers[car_index].stop()
		_door_timers[car_index].start(DOOR_OPEN_TIME)

	# Check if now full
	if car["passengers"].size() >= MAX_PASSENGERS:
		_close_doors_and_move(car_index)

	return boarded_any


func _on_door_timer_expired(car_index: int) -> void:
	var car: Dictionary = _cars[car_index]
	if car["passengers"].is_empty():
		# Timer expired but nobody aboard — go idle
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

func _get_car_y_for_floor(_car_index: int, floor_index: int) -> float:
	var floor_data: Dictionary = Rooms.get_floor_data_by_index(floor_index)
	if floor_data.is_empty():
		push_warning("[Pathfinder] No floor data for index %d" % floor_index)
		var node = _cars[_car_index]["node"]
		return node.position.y if node else 0.0
	return floor_data.get("hallway_y", 0.0) - _car_texture_height


# ── ACCESSORS ────────────────────────────────────────────────

func get_car_node(car_index: int) -> Node2D:
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


func register_car_node(car_index: int, node: Node2D, texture_height: float) -> void:
	if car_index < 0 or car_index >= _cars.size():
		return
	_cars[car_index]["node"] = node
	_car_texture_height = texture_height


func debug_elevator_state() -> void:
	for i in CAR_COUNT:
		var c = _cars[i]
		print("[Pathfinder] Car %d: floor=%d state=%s passengers=%d queue=%d" % [
			i, c["floor"], c["state"], c["passengers"].size(), _wait_queues[i].size()
		])