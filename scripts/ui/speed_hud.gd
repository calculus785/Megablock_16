# speed_hud.gd
# UI overlay — always visible, shows current speed preset.
# Handles speed key input: Space = pause toggle, 1-4 = speed presets.
#
# SETUP:
#   1. Create scene: CanvasLayer root named "SpeedHUD"
#   2. Attach this script
#   3. Save to res://scenes/ui/speed_hud.tscn
#   4. Add as child of main scene (sibling of EventInspector, ForceEvent)
#
# No input map registration needed — uses raw keycodes.

extends CanvasLayer

var _label: Label
var _last_speed_preset: int = 1  # remember last non-paused speed


func _ready() -> void:
	# Must process while game is paused (time_scale = 0)
	process_mode = Node.PROCESS_MODE_ALWAYS

	_label = Label.new()
	_label.position = Vector2(540, 8)
	_label.add_theme_font_size_override("font_size", 18)
	_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.7))
	_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	_label.add_theme_constant_override("shadow_offset_x", 1)
	_label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(_label)
	_update_label()


func _process(_delta: float) -> void:
	_update_label()


func _update_label() -> void:
	_label.text = Settings.SPEED_NAMES[Settings.speed_preset]

	# Color based on speed
	match Settings.speed_preset:
		0:  _label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4, 0.9))  # red = paused
		1:  _label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.5))  # white = normal
		2:  _label.add_theme_color_override("font_color", Color(0.6, 0.9, 1.0, 0.8))  # blue = fast
		3:  _label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3, 0.8))  # gold = turbo
		4:  _label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.8, 0.9))  # pink = ultra


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return

	match event.keycode:
		KEY_SPACE:
			if Settings.speed_preset == 0:
				# Unpause — restore last speed
				Settings.set_speed(_last_speed_preset)
			else:
				# Pause — remember current speed
				_last_speed_preset = Settings.speed_preset
				Settings.set_speed(0)
			get_viewport().set_input_as_handled()
		KEY_1:
			Settings.set_speed(1)
			get_viewport().set_input_as_handled()
		KEY_2:
			Settings.set_speed(2)
			get_viewport().set_input_as_handled()
		KEY_3:
			Settings.set_speed(3)
			get_viewport().set_input_as_handled()
		KEY_4:
			Settings.set_speed(4)
			get_viewport().set_input_as_handled()