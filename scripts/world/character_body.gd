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
var _zone_tween: Tween = null


func _ready() -> void:
	if char_data == null:
		push_error("[CharBody] No char_data assigned!")
		return
	_build_visuals()
	# Movement controller disabled — sim.gd now drives movement via tick-driven engine.
	# _setup_movement_controller()
	snap_to_room()


func _process(_delta: float) -> void:
	if char_data == null:
		return

	# VHS rewind — Sim writes positions, we just read them
	if Sim.is_rewinding:
		position = char_data.movement_sim_pos
		return

	# Sim-driven movement (walking, elevator, etc.)
	if char_data.movement_phase != "":
		position = char_data.movement_sim_pos
		return

	# Zone movement — tween to spot inside the current room
	if char_data.zone_target_pos != Vector3.ZERO:
		_move_to_zone_target()


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

func snap_to_room() -> void:
	var pos: Vector3 = Rooms.get_spawn_pos(char_data.current_room)
	if pos != Vector3.ZERO:
		position = pos
		char_data.movement_sim_pos = pos
		char_data.movement_prev_pos = pos

# Stops all movement and resets the movement-started flag.
# Called by Sim when a character is intercepted for a hallway conversation.
func cancel_movement() -> void:
	_movement_started = false
	if _zone_tween and _zone_tween.is_valid():
		_zone_tween.kill()
	if _move_ctrl:
		_move_ctrl.stop_movement()
	char_data.movement_phase = ""

func _move_to_zone_target() -> void:
	var target: Vector3 = char_data.zone_target_pos

	# Already there — snap and sync
	if position.distance_to(target) < 0.05:
		position = target
		char_data.zone_target_pos = Vector3.ZERO
		char_data.movement_sim_pos = target
		char_data.movement_prev_pos = target
		return

	# Tween already running — don't start another
	if _zone_tween and _zone_tween.is_valid():
		return

	var dist: float = position.distance_to(target)
	var duration: float = maxf(dist / 6.0, 0.1)
	_zone_tween = create_tween()
	_zone_tween.tween_property(self, "position", target, duration)
	_zone_tween.finished.connect(func():
		char_data.zone_target_pos = Vector3.ZERO
		# Sync sim position to where the body actually is
		char_data.movement_sim_pos = position
		char_data.movement_prev_pos = position
	, CONNECT_ONE_SHOT)


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
