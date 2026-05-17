# force_event.gd
# Debug panel — toggled with F3.
# Pick a character + event from dropdowns, hit Fire to run it immediately.
# Skips eligibility and cooldown checks via Sim.force_fire_event().
# Builds its own UI in _ready() — no manual scene wiring needed.

extends CanvasLayer

var _visible: bool = false

# UI references — built in _ready()
var _panel: Panel
var _char_dropdown: OptionButton
var _event_dropdown: OptionButton
var _fire_button: Button
var _result_label: Label

# Cached lists so dropdown index maps to actual data
var _char_list: Array = []    # Array of CharData
var _event_list: Array = []   # Array of event key strings


func _ready() -> void:
	visible = false
	_build_ui()
	print("[ForceEvent] Ready. F3 to toggle.")


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_force_event_toggle"):
		_visible = not _visible
		visible = _visible
		if _visible:
			_populate_dropdowns()


# ─────────────────────────────────────────────────────────────
# UI CONSTRUCTION
# Built in code so you only need a minimal .tscn (just the root
# CanvasLayer with this script attached). No manual node wiring.
# ─────────────────────────────────────────────────────────────

func _build_ui() -> void:
	# Panel — right side of screen so it doesn't overlap EventInspector (left side)
	_panel = Panel.new()
	_panel.position = Vector2(770, 20)
	_panel.size = Vector2(470, 340)
	add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.position = Vector2(16, 16)
	vbox.size = Vector2(438, 308)
	_panel.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "═══ FORCE EVENT [F3] ═══"
	title.add_theme_font_size_override("font_size", 16)
	vbox.add_child(title)

	# Spacer
	vbox.add_child(_make_spacer(8))

	# Character label + dropdown
	var char_label := Label.new()
	char_label.text = "Character:"
	vbox.add_child(char_label)

	_char_dropdown = OptionButton.new()
	_char_dropdown.custom_minimum_size.y = 32
	vbox.add_child(_char_dropdown)

	# Spacer
	vbox.add_child(_make_spacer(8))

	# Event label + dropdown
	var event_label := Label.new()
	event_label.text = "Event:"
	vbox.add_child(event_label)

	_event_dropdown = OptionButton.new()
	_event_dropdown.custom_minimum_size.y = 32
	vbox.add_child(_event_dropdown)

	# Spacer
	vbox.add_child(_make_spacer(12))

	# Fire button
	_fire_button = Button.new()
	_fire_button.text = "⚡ FIRE EVENT"
	_fire_button.custom_minimum_size.y = 40
	_fire_button.pressed.connect(_on_fire_pressed)
	vbox.add_child(_fire_button)

	# Spacer
	vbox.add_child(_make_spacer(8))

	# Result label — shows what happened after firing
	_result_label = Label.new()
	_result_label.text = ""
	_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_result_label.custom_minimum_size.y = 60
	vbox.add_child(_result_label)


func _make_spacer(height: float) -> Control:
	var spacer := Control.new()
	spacer.custom_minimum_size.y = height
	return spacer


# ─────────────────────────────────────────────────────────────
# DROPDOWN POPULATION
# Refreshes every time the panel opens so new characters / events
# are always reflected.
# ─────────────────────────────────────────────────────────────

func _populate_dropdowns() -> void:
	# Characters
	_char_dropdown.clear()
	_char_list = Registry.get_all()
	for character in _char_list:
		_char_dropdown.add_item(character.get_debug_label())

	# Events — sorted alphabetically for easy scanning
	_event_dropdown.clear()
	_event_list = Events.get_all_event_keys()
	_event_list.sort()
	for event_key in _event_list:
		var event_def: Dictionary = Events.get_event(event_key)
		var trigger: String = event_def.get("trigger_mode", "rolled")
		var suffix: String = " ⚡" if trigger == "auto_fire" else ""
		_event_dropdown.add_item("%s%s" % [event_key, suffix])

	_result_label.text = "Pick a character and event, then hit Fire."


# ─────────────────────────────────────────────────────────────
# FIRE
# ─────────────────────────────────────────────────────────────

func _on_fire_pressed() -> void:
	# Validate selections
	var char_idx: int = _char_dropdown.selected
	var event_idx: int = _event_dropdown.selected

	if char_idx < 0 or char_idx >= _char_list.size():
		_result_label.text = "⚠ No character selected."
		return

	if event_idx < 0 or event_idx >= _event_list.size():
		_result_label.text = "⚠ No event selected."
		return

	var character: CharData = _char_list[char_idx]
	var event_key: String = _event_list[event_idx]

	# Fire through Sim — skips eligibility + cooldown
	var summary: String = Sim.force_fire_event(character, event_key)

	_result_label.text = "✅ %s\n→ %s" % [event_key, summary]
