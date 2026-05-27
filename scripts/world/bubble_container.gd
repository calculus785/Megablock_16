# bubble_container.gd
# Displays active feelings as coloured quads above a character's head.
# Placeholder — Phase 5 replaces these with icons.

extends Node3D

const BUBBLE_SIZE: float = 0.3
const BUBBLE_GAP: float = 0.35
const MAX_BUBBLES: int = 5

var _char_data: CharData
var _bubbles: Array = []  # active MeshInstance3D nodes

# Feeling category → colour. Expand as more feelings are added.
const FEELING_COLORS: Dictionary = {
	"COCKY":          Color(1.0,  0.85, 0.0),   # gold
	"FRUSTRATED":     Color(1.0,  0.3,  0.1),   # red-orange
	"HUMILIATED":     Color(0.6,  0.2,  0.8),   # purple
	"WELL_FED":       Color(0.3,  0.9,  0.4),   # green
	"CONTENT_FEELING":Color(0.4,  0.8,  1.0),   # sky blue
	"MELANCHOLY_FEELING": Color(0.3, 0.4, 0.7), # muted blue
	"GRIEF_FEELING":  Color(0.2,  0.2,  0.5),   # dark blue
	"HEARTBROKEN_FEELING": Color(0.9, 0.2, 0.4),# pink
	"ANXIOUS":        Color(0.9,  0.7,  0.1),   # yellow
	"RELIEVED":       Color(0.5,  1.0,  0.5),   # light green
	"FURIOUS":        Color(1.0,  0.0,  0.0),   # red
}
const DEFAULT_COLOR: Color = Color(0.7, 0.7, 0.7)  # grey for unknown feelings


func setup(char_data: CharData) -> void:
	_char_data = char_data


func _process(_delta: float) -> void:
	if _char_data == null:
		return
	_refresh()


func _refresh() -> void:
	if _char_data == null:
		return
	var active: Array = FeelingDriver.get_active_feelings(_char_data)
	if active.size() > MAX_BUBBLES:
		active = active.slice(0, MAX_BUBBLES)

	# Compare actual keys, not just count
	var current_keys: Array = []
	for b in _bubbles:
		current_keys.append(b.get_meta("feeling_key", ""))
	if current_keys == active:
		return

	# Clear and rebuild
	for b in _bubbles:
		b.queue_free()
	_bubbles.clear()

	if active.is_empty():
		return

	var total_width: float = active.size() * BUBBLE_GAP
	var start_x: float = -total_width / 2.0 + BUBBLE_GAP / 2.0

	for i in active.size():
		var feeling_key: String = active[i]
		var mesh_inst := MeshInstance3D.new()
		var quad := QuadMesh.new()
		quad.size = Vector2(BUBBLE_SIZE, BUBBLE_SIZE)
		mesh_inst.mesh = quad

		var mat := StandardMaterial3D.new()
		mat.albedo_color = FEELING_COLORS.get(feeling_key, DEFAULT_COLOR)
		mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mesh_inst.material_override = mat
		mesh_inst.position = Vector3(start_x + i * BUBBLE_GAP, 0.0, 0.0)
		mesh_inst.set_meta("feeling_key", feeling_key)  # ← store key for comparison

		add_child(mesh_inst)
		_bubbles.append(mesh_inst)
