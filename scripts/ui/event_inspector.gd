# event_inspector.gd
# Debug overlay — toggled with F2, cycle characters with Tab.
# Phase 0 version: shows stats, traits, feelings, states for selected character.
# Phase 1+ will add eligible events + weights, memory, relationships.
# Attach to an EventInspector scene (CanvasLayer → Panel → VBoxContainer → Label).

extends CanvasLayer

# Whether the overlay is currently visible
var _visible: bool = false

# Index into Registry.get_all() for which character we're inspecting
var _selected_index: int = 0

# The label we write into
@onready var _label: Label = $Panel/ScrollContainer/Label


func _ready() -> void:
	visible = false
	# Auto-refresh when any event fires
	Sim.event_fired.connect(_on_event_fired)
	print("[EventInspector] Ready. F2 to toggle, Tab to cycle characters.")

func _on_event_fired(_char_id: String, _event_key: String, _summary: String) -> void:
	if _visible:
		_refresh()


func _input(event: InputEvent) -> void:
	# F2 toggles the overlay
	if event.is_action_pressed("ui_inspector_toggle"):
		_visible = not _visible
		visible = _visible
		if _visible:
			_refresh()

	# Tab cycles to next character while visible
	if _visible and event.is_action_pressed("ui_focus_next"):
		var all := Registry.get_all()
		if all.size() == 0:
			return
		_selected_index = (_selected_index + 1) % all.size()
		_refresh()


func _refresh() -> void:
	var all := Registry.get_all()
	if all.size() == 0:
		_label.text = "No characters in registry."
		return

	# Clamp index in case characters were removed
	_selected_index = clamp(_selected_index, 0, all.size() - 1)
	var character: CharData = all[_selected_index]

	var lines: PackedStringArray = []

	# ── HEADER ──────────────────────────────────────────────
	lines.append("═══ EVENT INSPECTOR [F2] — Tab: next character ═══")
	lines.append("%s  [%d / %d]" % [
		character.get_debug_label(), _selected_index + 1, all.size()
	])
	lines.append("arch: %s  |  room: %s" % [character.life_arch, character.current_room])
	lines.append("")

	# ── STATS ───────────────────────────────────────────────
	lines.append("── STATS ──────────────────────────────────────")
	var stat_keys: Array = Stats.STATS.keys()
	# Print in two columns for readability
	var i := 0
	while i < stat_keys.size():
		var key_a: String = stat_keys[i]
		var val_a: float = character.stats.get(key_a, 0.0)
		var line: String = "  %-22s %6.1f" % [key_a, val_a]
		if i + 1 < stat_keys.size():
			var key_b: String = stat_keys[i + 1]
			var val_b: float = character.stats.get(key_b, 0.0)
			line += "    %-22s %6.1f" % [key_b, val_b]
		lines.append(line)
		i += 2
	lines.append("")

	# ── TRAITS ──────────────────────────────────────────────
	lines.append("── TRAITS ─────────────────────────────────────")
	if character.traits.size() > 0:
		lines.append("  visible: " + ", ".join(character.traits))
	else:
		lines.append("  visible: (none)")
	if character.hidden_traits.size() > 0:
		lines.append("  hidden:  " + ", ".join(character.hidden_traits))
	lines.append("")

	# ── FEELINGS ────────────────────────────────────────────
	lines.append("── FEELINGS ────────────────────────────────────")
	if character.feelings.size() == 0:
		lines.append("  (none)")
	else:
		for instance in character.feelings:
			var hidden_tag: String = " [hidden]" if instance.get("is_hidden", false) else ""
			var target_tag: String = ""
			if instance.get("target_id") != null:
				var target: CharData = Registry.get_character(instance["target_id"])
				if target:
					target_tag = " → %s" % target.char_name
			lines.append("  %s%s%s  (%.1fh left)" % [
				instance["feeling_key"],
				hidden_tag,
				target_tag,
				instance.get("hours_remaining", 0.0),
			])
			# Show causes
			for cause in instance.get("causes", []):
				lines.append("    ↳ %s" % cause.get("summary", "unknown cause"))
	lines.append("")

	# ── STATES ──────────────────────────────────────────────
	lines.append("── STATES ──────────────────────────────────────")
	if character.states.size() > 0:
		lines.append("  derived:    " + ", ".join(character.states))
	else:
		lines.append("  derived:    (none)")
	if character.persistent_states.size() > 0:
		lines.append("  persistent: " + ", ".join(character.persistent_states))
	else:
		lines.append("  persistent: (none)")
	lines.append("")

	# ── CLOCK ───────────────────────────────────────────────
	lines.append("── CLOCK ───────────────────────────────────────")
	lines.append("  %s  Hour %d  (%s)" % [
		Clock.get_display_string(),
		Clock.current_hour,
		Clock.get_time_of_day(),
	])
	lines.append("  season: %s  intensity: %.1f" % [
		Clock.current_season, Clock.season_intensity
	])

	_label.text = "\n".join(lines)
