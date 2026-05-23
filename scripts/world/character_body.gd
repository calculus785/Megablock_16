# character_body.gd
# Visual representation of one character in the building.
# Polls CharData.is_in_transit and drives MovementController.
# Updates Rooms occupancy on room enter/exit.

extends Node2D

var char_data: CharData

const BODY_WIDTH: float = 24.0
const BODY_HEIGHT: float = 48.0

var _rect: ColorRect
var _label: Label
var _move_ctrl: Node  # MovementController
var _movement_started: bool = false  # tracks whether we've kicked off this transit


func _ready() -> void:
	if char_data == null:
		push_error("[CharBody] No char_data assigned!")
		return
	_build_visuals()
	_setup_movement_controller()
	snap_to_room()


func _process(_delta: float) -> void:
	if char_data == null:
		return

	# Poll: if sim set is_in_transit but we haven't started moving yet, go
	if char_data.is_in_transit and not _movement_started:
		if not char_data.waypoints.is_empty():
			_movement_started = true
			_move_ctrl.start_movement(char_data.waypoints)


# ─── VISUALS ─────────────────────────────────────────────────

func _build_visuals() -> void:
	_rect = ColorRect.new()
	_rect.size = Vector2(BODY_WIDTH, BODY_HEIGHT)
	_rect.position = Vector2(-BODY_WIDTH / 2.0, -BODY_HEIGHT)
	_rect.color = _resolve_color()
	add_child(_rect)

	_label = Label.new()
	_label.text = char_data.char_name.split(" ")[0]
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.position = Vector2(-50, -BODY_HEIGHT - 22)
	_label.size = Vector2(100, 20)
	_label.add_theme_font_size_override("font_size", 12)
	add_child(_label)


# ─── MOVEMENT ────────────────────────────────────────────────

func _setup_movement_controller() -> void:
	var mc_script = load("res://scripts/world/movement_controller.gd")
	_move_ctrl = Node.new()
	_move_ctrl.set_script(mc_script)
	_move_ctrl.name = "MovementController"
	add_child(_move_ctrl)

	_move_ctrl.waypoint_reached.connect(_on_waypoint_reached)
	_move_ctrl.movement_completed.connect(_on_movement_completed)


func _on_waypoint_reached(wp: Dictionary) -> void:
	match wp["type"]:
		"exit_room":
			# Left the room — remove from old room's occupant list
			Rooms.remove_occupant(char_data.current_room, char_data.char_id)
		"enter_room":
			# Arrived at destination door — not inside yet, just at the door
			pass
		"elevator":
			# Teleported to new floor — nothing to update yet
			pass


func _on_movement_completed() -> void:
	# Arrived at destination spawn point
	_movement_started = false
	char_data.is_in_transit = false

	var dest_room: String = char_data.movement_target_room
	char_data.current_room = dest_room
	char_data.movement_target_room = ""
	char_data.waypoints.clear()
	char_data.waypoint_index = 0

	# Register in new room
	Rooms.add_occupant(dest_room, char_data.char_id)

	# Snap to exact position (fixes any float drift)
	snap_to_room()

	if Settings.debug_console_logging:
		print("[CharBody] %s arrived at %s" % [char_data.char_name, dest_room])


func snap_to_room() -> void:
	var center: Vector2 = Rooms.get_spawn_pos(char_data.current_room)
	if center == Vector2.ZERO:
		# Fallback to old key name in case of mixed data
		center = Rooms.get_cutout_center(char_data.current_room)
	if center != Vector2.ZERO:
		position = center


# ─── COLOR ───────────────────────────────────────────────────

const COLOR_MAP: Dictionary = {
	"red": Color.RED,
	"blue": Color.BLUE,
	"electric_blue": Color.DODGER_BLUE,
	"green": Color.GREEN,
	"yellow": Color.YELLOW,
	"orange": Color.ORANGE,
	"purple": Color.PURPLE,
	"pink": Color.HOT_PINK,
	"black": Color.DIM_GRAY,
	"white": Color.WHITE_SMOKE,
	"teal": Color.TEAL,
	"gold": Color.GOLD,
	"cyan": Color.CYAN,
	"magenta": Color.MAGENTA,
	"lime": Color.LIME_GREEN,
	"brown": Color.SADDLE_BROWN,
}

func _resolve_color() -> Color:
	return COLOR_MAP.get(char_data.favourite_color, Color.GRAY)