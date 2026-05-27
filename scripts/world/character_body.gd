# character_body.gd
# Visual representation of one character in the building.
# Polls CharData.is_in_transit and drives MovementController.
# Updates Rooms occupancy on room enter/exit.

extends Node3D

var char_data: CharData

var _mesh: MeshInstance3D
var _label: Label3D
var _move_ctrl: Node  # MovementController
var _movement_started: bool = false
var _bubble_container: Node3D
var _storybook_display: Node3D


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
	if char_data.is_in_transit and not _movement_started:
		if not char_data.waypoints.is_empty():
			_movement_started = true
			_move_ctrl.start_movement(char_data.waypoints)


# ─── VISUALS ─────────────────────────────────────────────────

func _build_visuals() -> void:
	_mesh = MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(1.0, 2.0)  # 1 unit wide, 2 units tall
	_mesh.mesh = quad

	var mat := StandardMaterial3D.new()
	mat.albedo_color = _resolve_color()
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mesh.material_override = mat

	# Offset up so feet sit at node origin
	_mesh.position.y = 1.0
	add_child(_mesh)

	_label = Label3D.new()
	_label.text = char_data.char_name.split(" ")[0]  # first name only
	_label.font_size = 48
	_label.pixel_size = 0.02
	_label.position.y = 2.2  # above head
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.modulate = Color.WHITE
	add_child(_label)

	var bubble_script = load("res://scripts/world/bubble_container.gd")
	_bubble_container = Node3D.new()
	_bubble_container.set_script(bubble_script)
	_bubble_container.position.y = 2.8  # above the name label
	_bubble_container.name = "BubbleContainer"
	add_child(_bubble_container)
	_bubble_container.setup(char_data)

	var sb_script = load("res://scripts/world/storybook_display.gd")
	_storybook_display = Node3D.new()
	_storybook_display.set_script(sb_script)
	_storybook_display.position.y = 3.5  # above bubbles
	_storybook_display.name = "StorybookDisplay"
	add_child(_storybook_display)
	_storybook_display.setup(char_data)

# Add this function:
func set_storybook_visible(show: bool) -> void:
	if _storybook_display:
		_storybook_display.set_visible_log(show)


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
			Rooms.remove_occupant(char_data.current_room, char_data.char_id)
		"enter_room":
			pass
		"elevator":
			pass


func _on_movement_completed() -> void:
	_movement_started = false
	char_data.is_in_transit = false

	var dest_room: String = char_data.movement_target_room
	char_data.current_room = dest_room
	char_data.movement_target_room = ""
	char_data.waypoints.clear()
	char_data.waypoint_index = 0

	Rooms.add_occupant(dest_room, char_data.char_id)
	snap_to_room()

	if Settings.debug_console_logging:
		print("[CharBody] %s arrived at %s" % [char_data.char_name, dest_room])


func snap_to_room() -> void:
	var pos: Vector3 = Rooms.get_spawn_pos(char_data.current_room)
	if pos != Vector3.ZERO:
		position = pos


# ─── COLOR ───────────────────────────────────────────────────

const COLOR_MAP: Dictionary = {
	"red":          Color.RED,
	"blue":         Color.BLUE,
	"electric_blue":Color.DODGER_BLUE,
	"green":        Color.GREEN,
	"yellow":       Color.YELLOW,
	"orange":       Color.ORANGE,
	"purple":       Color.PURPLE,
	"pink":         Color.HOT_PINK,
	"black":        Color.DIM_GRAY,
	"white":        Color.WHITE_SMOKE,
	"teal":         Color.TEAL,
	"gold":         Color.GOLD,
	"cyan":         Color.CYAN,
	"magenta":      Color.MAGENTA,
	"lime":         Color.LIME_GREEN,
	"brown":        Color.SADDLE_BROWN,
}

func _resolve_color() -> Color:
	return COLOR_MAP.get(char_data.favourite_color, Color.GRAY)