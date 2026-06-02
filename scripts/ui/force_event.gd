# force_event.gd
# Debug panel — toggled with F3.
# Pick character + event + optional target, hit Fire.
# Quick tools: modify stats, push feelings, set bonds, teleport.
# Built entirely in code — no manual scene wiring needed.
#
# SETUP:
#   Same as before — CanvasLayer with this script attached.
#   No changes to scene file needed.

extends CanvasLayer

var _visible: bool = false

# ── UI references ────────────────────────────────────────────
var _panel: Panel
var _scroll: ScrollContainer
var _vbox: VBoxContainer

# Event firing
var _char_dropdown: OptionButton
var _event_dropdown: OptionButton
var _target_dropdown: OptionButton
var _fire_button: Button
var _result_label: Label

# Stat modifier
var _stat_dropdown: OptionButton
var _stat_spin: SpinBox
var _stat_apply_btn: Button

# Feeling tools
var _feeling_dropdown: OptionButton
var _feeling_push_btn: Button
var _feeling_remove_btn: Button

# Bond setter
var _bond_char_a: OptionButton
var _bond_char_b: OptionButton
var _bond_spin: SpinBox
var _bond_set_btn: Button

# Teleport
var _room_dropdown: OptionButton
var _teleport_btn: Button

# Event log
var _log_label: Label
var _event_log: Array = []  # last 8 entries

# Data caches
var _char_list: Array = []
var _event_list: Array = []
var _room_list: Array = []


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	print("[ForceEvent] Ready. F3 to toggle.")


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_force_event_toggle"):
		_visible = not _visible
		visible = _visible
		if _visible:
			_populate_all()


# ─────────────────────────────────────────────────────────────
# UI CONSTRUCTION
# ─────────────────────────────────────────────────────────────

func _build_ui() -> void:
	_panel = Panel.new()
	_panel.position = Vector2(770, 10)
	_panel.size = Vector2(500, 720)
	add_child(_panel)

	_scroll = ScrollContainer.new()
	_scroll.position = Vector2(8, 8)
	_scroll.size = Vector2(484, 704)
	_panel.add_child(_scroll)

	_vbox = VBoxContainer.new()
	_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_vbox.custom_minimum_size.x = 468
	_scroll.add_child(_vbox)

	# ── TITLE ────────────────────────────────────────────
	_add_label("═══ FORCE EVENT [F3] ═══", 16)
	_add_spacer(6)

	# ── CHARACTER ────────────────────────────────────────
	_add_label("Character:")
	_char_dropdown = _add_dropdown()

	# ── EVENT ────────────────────────────────────────────
	_add_label("Event:")
	_event_dropdown = _add_dropdown()

	# ── TARGET ───────────────────────────────────────────
	_add_label("Target (optional):")
	_target_dropdown = _add_dropdown()

	_add_spacer(8)

	# ── FIRE BUTTON ──────────────────────────────────────
	_fire_button = Button.new()
	_fire_button.text = "⚡ FIRE EVENT"
	_fire_button.custom_minimum_size.y = 36
	_fire_button.pressed.connect(_on_fire_pressed)
	_vbox.add_child(_fire_button)

	_add_spacer(4)

	_result_label = Label.new()
	_result_label.text = ""
	_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_result_label.custom_minimum_size.y = 40
	_vbox.add_child(_result_label)

	_add_spacer(6)
	_add_separator()

	# ── QUICK TOOLS: STAT MODIFIER ───────────────────────
	_add_label("── STAT MODIFIER ──")
	var stat_row := HBoxContainer.new()
	_vbox.add_child(stat_row)

	_stat_dropdown = OptionButton.new()
	_stat_dropdown.custom_minimum_size = Vector2(140, 28)
	stat_row.add_child(_stat_dropdown)

	_stat_spin = SpinBox.new()
	_stat_spin.min_value = -100
	_stat_spin.max_value = 100
	_stat_spin.step = 5
	_stat_spin.value = 10
	_stat_spin.custom_minimum_size = Vector2(90, 28)
	stat_row.add_child(_stat_spin)

	_stat_apply_btn = Button.new()
	_stat_apply_btn.text = "Apply"
	_stat_apply_btn.custom_minimum_size = Vector2(70, 28)
	_stat_apply_btn.pressed.connect(_on_stat_apply)
	stat_row.add_child(_stat_apply_btn)

	_add_spacer(6)
	_add_separator()

	# ── QUICK TOOLS: FEELING ─────────────────────────────
	_add_label("── FEELING ──")
	var feel_row := HBoxContainer.new()
	_vbox.add_child(feel_row)

	_feeling_dropdown = OptionButton.new()
	_feeling_dropdown.custom_minimum_size = Vector2(160, 28)
	feel_row.add_child(_feeling_dropdown)

	_feeling_push_btn = Button.new()
	_feeling_push_btn.text = "Push"
	_feeling_push_btn.custom_minimum_size = Vector2(60, 28)
	_feeling_push_btn.pressed.connect(_on_feeling_push)
	feel_row.add_child(_feeling_push_btn)

	_feeling_remove_btn = Button.new()
	_feeling_remove_btn.text = "Remove"
	_feeling_remove_btn.custom_minimum_size = Vector2(75, 28)
	_feeling_remove_btn.pressed.connect(_on_feeling_remove)
	feel_row.add_child(_feeling_remove_btn)

	_add_spacer(6)
	_add_separator()

	# ── QUICK TOOLS: BOND SETTER ─────────────────────────
	_add_label("── BOND SETTER ──")
	var bond_row1 := HBoxContainer.new()
	_vbox.add_child(bond_row1)

	_bond_char_a = OptionButton.new()
	_bond_char_a.custom_minimum_size = Vector2(170, 28)
	bond_row1.add_child(_bond_char_a)

	var arrow_lbl := Label.new()
	arrow_lbl.text = " ↔ "
	bond_row1.add_child(arrow_lbl)

	_bond_char_b = OptionButton.new()
	_bond_char_b.custom_minimum_size = Vector2(170, 28)
	bond_row1.add_child(_bond_char_b)

	var bond_row2 := HBoxContainer.new()
	_vbox.add_child(bond_row2)

	_bond_spin = SpinBox.new()
	_bond_spin.min_value = -100
	_bond_spin.max_value = 100
	_bond_spin.step = 5
	_bond_spin.value = 50
	_bond_spin.custom_minimum_size = Vector2(100, 28)
	bond_row2.add_child(_bond_spin)

	_bond_set_btn = Button.new()
	_bond_set_btn.text = "Set Bond"
	_bond_set_btn.custom_minimum_size = Vector2(90, 28)
	_bond_set_btn.pressed.connect(_on_bond_set)
	bond_row2.add_child(_bond_set_btn)

	_add_spacer(6)
	_add_separator()

	# ── QUICK TOOLS: TELEPORT ────────────────────────────
	_add_label("── TELEPORT ──")
	var tp_row := HBoxContainer.new()
	_vbox.add_child(tp_row)

	_room_dropdown = OptionButton.new()
	_room_dropdown.custom_minimum_size = Vector2(260, 28)
	tp_row.add_child(_room_dropdown)

	_teleport_btn = Button.new()
	_teleport_btn.text = "Teleport"
	_teleport_btn.custom_minimum_size = Vector2(80, 28)
	_teleport_btn.pressed.connect(_on_teleport)
	tp_row.add_child(_teleport_btn)

	_add_spacer(6)
	_add_separator()

	# ── EVENT LOG ────────────────────────────────────────
	_add_label("── EVENT LOG (last 8) ──")
	_log_label = Label.new()
	_log_label.text = "(empty)"
	_log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_log_label.custom_minimum_size.y = 120
	_log_label.add_theme_font_size_override("font_size", 12)
	_vbox.add_child(_log_label)


# ─────────────────────────────────────────────────────────────
# UI HELPERS
# ─────────────────────────────────────────────────────────────

func _add_label(text: String, size: int = 14) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", size)
	_vbox.add_child(lbl)
	return lbl


func _add_dropdown() -> OptionButton:
	var dd := OptionButton.new()
	dd.custom_minimum_size.y = 28
	_vbox.add_child(dd)
	return dd


func _add_spacer(height: float) -> void:
	var s := Control.new()
	s.custom_minimum_size.y = height
	_vbox.add_child(s)


func _add_separator() -> void:
	var sep := HSeparator.new()
	_vbox.add_child(sep)
	_add_spacer(4)


# ─────────────────────────────────────────────────────────────
# POPULATION
# ─────────────────────────────────────────────────────────────

func _populate_all() -> void:
	_char_list = Registry.get_all()
	_event_list = Events.get_all_event_keys()
	_event_list.sort()
	_room_list = Rooms.get_all_room_ids()
	_room_list.sort()

	# Character dropdowns (main + bond A/B)
	_char_dropdown.clear()
	_bond_char_a.clear()
	_bond_char_b.clear()
	for character in _char_list:
		var label: String = character.char_name
		_char_dropdown.add_item(label)
		_bond_char_a.add_item(label)
		_bond_char_b.add_item(label)
	if _bond_char_b.item_count > 1:
		_bond_char_b.selected = 1

	# Event dropdown
	_event_dropdown.clear()
	for event_key in _event_list:
		var event_def: Dictionary = Events.get_event(event_key)
		var trigger: String = event_def.get("trigger_mode", "rolled")
		var cat: String = event_def.get("category", "")
		var suffix: String = ""
		if trigger == "auto_fire": suffix = " ⚡"
		if trigger == "proximity": suffix = " 🚶"
		_event_dropdown.add_item("%s [%s]%s" % [event_key, cat, suffix])

	# Target dropdown
	_target_dropdown.clear()
	_target_dropdown.add_item("Auto (resolve_target)")
	for character in _char_list:
		_target_dropdown.add_item(character.char_name)

	# Stat dropdown
	_stat_dropdown.clear()
	for stat_key in Stats.STATS.keys():
		_stat_dropdown.add_item(stat_key)

	# Feeling dropdown
	_feeling_dropdown.clear()
	for feeling_key in Feelings.FEELINGS.keys():
		_feeling_dropdown.add_item(feeling_key)

	# Room dropdown
	_room_dropdown.clear()
	for room_id in _room_list:
		_room_dropdown.add_item(room_id)

	_result_label.text = "Ready. Pick and fire."


# ─────────────────────────────────────────────────────────────
# SELECTED CHARACTER HELPER
# ─────────────────────────────────────────────────────────────

func _get_selected_char() -> CharData:
	var idx: int = _char_dropdown.selected
	if idx < 0 or idx >= _char_list.size():
		return null
	return _char_list[idx]


# ─────────────────────────────────────────────────────────────
# FIRE EVENT
# ─────────────────────────────────────────────────────────────

func _on_fire_pressed() -> void:
	var character: CharData = _get_selected_char()
	if not character:
		_result_label.text = "⚠ No character selected."
		return

	var event_idx: int = _event_dropdown.selected
	if event_idx < 0 or event_idx >= _event_list.size():
		_result_label.text = "⚠ No event selected."
		return

	var event_key: String = _event_list[event_idx]

	# Check if a specific target was chosen
	var target_idx: int = _target_dropdown.selected
	var summary: String

	if target_idx <= 0:
		# Auto — use normal resolve_target
		summary = Sim.force_fire_event(character, event_key)
	else:
		# Specific target selected (index 1+ maps to _char_list[index-1])
		var target: CharData = _char_list[target_idx - 1]
		summary = Sim.force_fire_event_with_target(character, event_key, target)

	_result_label.text = "✅ %s\n→ %s" % [event_key, summary]
	_log_event(character.char_name, event_key, summary)


# ─────────────────────────────────────────────────────────────
# STAT MODIFIER
# ─────────────────────────────────────────────────────────────

func _on_stat_apply() -> void:
	var character: CharData = _get_selected_char()
	if not character:
		_result_label.text = "⚠ No character selected."
		return

	var stat_idx: int = _stat_dropdown.selected
	if stat_idx < 0:
		return

	var stat_key: String = Stats.STATS.keys()[stat_idx]
	var delta: float = _stat_spin.value
	var old_val: float = character.stats.get(stat_key, 0.0)
	Actions.modify_stat(character, stat_key, delta)
	var new_val: float = character.stats.get(stat_key, 0.0)

	_result_label.text = "📊 %s %s: %+.0f (%.0f → %.0f)" % [
		character.char_name, stat_key, delta, old_val, new_val
	]


# ─────────────────────────────────────────────────────────────
# FEELING PUSH / REMOVE
# ─────────────────────────────────────────────────────────────

func _on_feeling_push() -> void:
	var character: CharData = _get_selected_char()
	if not character:
		_result_label.text = "⚠ No character selected."
		return

	var feel_idx: int = _feeling_dropdown.selected
	if feel_idx < 0:
		return

	var feeling_key: String = Feelings.FEELINGS.keys()[feel_idx]
	FeelingDriver.push(character, feeling_key, {
		"event_key": "debug_push",
		"at_tick": Clock.get_total_days(),
		"summary": "forced via F3",
	})
	_result_label.text = "💭 Pushed %s on %s" % [feeling_key, character.char_name]


func _on_feeling_remove() -> void:
	var character: CharData = _get_selected_char()
	if not character:
		_result_label.text = "⚠ No character selected."
		return

	var feel_idx: int = _feeling_dropdown.selected
	if feel_idx < 0:
		return

	var feeling_key: String = Feelings.FEELINGS.keys()[feel_idx]
	FeelingDriver.remove(character, feeling_key)
	_result_label.text = "🗑 Removed %s from %s" % [feeling_key, character.char_name]


# ─────────────────────────────────────────────────────────────
# BOND SETTER
# ─────────────────────────────────────────────────────────────

func _on_bond_set() -> void:
	var idx_a: int = _bond_char_a.selected
	var idx_b: int = _bond_char_b.selected
	if idx_a < 0 or idx_b < 0 or idx_a >= _char_list.size() or idx_b >= _char_list.size():
		_result_label.text = "⚠ Select two characters."
		return
	if idx_a == idx_b:
		_result_label.text = "⚠ Can't set bond with self."
		return

	var char_a: CharData = _char_list[idx_a]
	var char_b: CharData = _char_list[idx_b]
	var bond_val: float = _bond_spin.value

	Relationships.set_bond(char_a.char_id, char_b.char_id, bond_val)
	var tier: String = Relationships.get_tier(char_a.char_id, char_b.char_id)

	_result_label.text = "💛 %s ↔ %s → bond %.0f (%s)" % [
		char_a.char_name, char_b.char_name, bond_val, tier
	]


# ─────────────────────────────────────────────────────────────
# TELEPORT
# ─────────────────────────────────────────────────────────────

func _on_teleport() -> void:
	var character: CharData = _get_selected_char()
	if not character:
		_result_label.text = "⚠ No character selected."
		return

	var room_idx: int = _room_dropdown.selected
	if room_idx < 0 or room_idx >= _room_list.size():
		_result_label.text = "⚠ No room selected."
		return

	var dest_room: String = _room_list[room_idx]
	var old_room: String = character.current_room

	# Release spots in old room
	Rooms.release_all_spots(old_room, character.char_id)

	# Update occupancy
	Rooms.remove_occupant(old_room, character.char_id)
	character.current_room = dest_room
	Rooms.add_occupant(dest_room, character.char_id)

	# Stop any active movement
	character.is_in_transit = false
	character.movement_target_room = ""

	# Snap body to new room spawn position
	var spawn_pos: Vector3 = Rooms.get_spawn_pos(dest_room)
	var container = get_node_or_null("/root/main/Building/Characters")
	if container:
		for body in container.get_children():
			if "char_data" in body and body.char_data.char_id == character.char_id:
				body.position = spawn_pos
				# Stop any active movement controller
				var ctrl = body.get_node_or_null("MovementController")
				if ctrl and ctrl.has_method("stop_movement"):
					ctrl.stop_movement()
				break

	_result_label.text = "🚀 %s → %s (from %s)" % [character.char_name, dest_room, old_room]


# ─────────────────────────────────────────────────────────────
# EVENT LOG
# ─────────────────────────────────────────────────────────────

func _log_event(char_name: String, event_key: String, summary: String) -> void:
	var short_summary: String = summary
	if short_summary.length() > 60:
		short_summary = short_summary.substr(0, 57) + "..."

	_event_log.append("%s → %s → %s" % [char_name, event_key, short_summary])

	# Keep last 8
	while _event_log.size() > 8:
		_event_log.pop_front()

	_log_label.text = "\n".join(_event_log)