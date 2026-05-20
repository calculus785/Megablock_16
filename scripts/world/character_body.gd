# character_body.gd
# Visual representation of one character in the building.
# Colored rectangle + name label. Anchored at feet (position = feet).
# Reads CharData for color/name. snap_to_room() places them in their room.

extends Node2D

var char_data: CharData

const BODY_WIDTH: float = 24.0
const BODY_HEIGHT: float = 48.0

var _rect: ColorRect
var _label: Label


func _ready() -> void:
	if char_data == null:
		push_error("[CharBody] No char_data assigned!")
		return
	_build_visuals()
	snap_to_room()


func _build_visuals() -> void:
	# Colored rectangle — offset so position = feet
	_rect = ColorRect.new()
	_rect.size = Vector2(BODY_WIDTH, BODY_HEIGHT)
	_rect.position = Vector2(-BODY_WIDTH / 2.0, -BODY_HEIGHT)
	_rect.color = _resolve_color()
	add_child(_rect)

	# Name label — centered above head
	_label = Label.new()
	_label.text = char_data.char_name.split(" ")[0]
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.position = Vector2(-50, -BODY_HEIGHT - 22)
	_label.size = Vector2(100, 20)
	_label.add_theme_font_size_override("font_size", 12)
	add_child(_label)


# ─── POSITIONING ─────────────────────────────────────────────

func snap_to_room() -> void:
	var room_id: String = char_data.current_room
	var center: Vector2 = Rooms.get_cutout_center(room_id)
	if center == Vector2.ZERO:
		push_warning("[CharBody] No cutout_center for room: %s" % room_id)
		return
	position = center


# ─── COLOR MAPPING ───────────────────────────────────────────

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