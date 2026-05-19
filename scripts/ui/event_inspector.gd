# event_inspector.gd
# Debug overlay — toggled with F2, cycle characters with Tab.
# Shows stats, traits, feelings, states, eligible events + weights,
# short-term memory, intent queue, and last 5 storybook entries.

extends CanvasLayer

var _visible: bool = false
var _selected_index: int = 0

@onready var _label: Label = $Panel/ScrollContainer/Label


func _ready() -> void:
	visible = false
	Sim.event_fired.connect(_on_event_fired)
	print("[EventInspector] Ready. F2 to toggle, Tab to cycle characters.")


func _on_event_fired(_char_id: String, _event_key: String, _summary: String) -> void:
	if _visible:
		_refresh()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_inspector_toggle"):
		_visible = not _visible
		visible = _visible
		if _visible:
			_refresh()

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
	var i := 0
	while i < stat_keys.size():
		var key_a: String = stat_keys[i]
		var val_a: float = character.stats.get(key_a, 0.0)
		var line: String = "  %-22s %6.1f" % [key_a, val_a]
		if i + 1 < stat_keys.size():
			var key_b: String = stat_keys[i + 1]
			var val_b: float = character.stats.get(key_b, 0.0)
			line += "   %-22s %6.1f" % [key_b, val_b]
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

	# ── INTENT QUEUE ────────────────────────────────────────
	lines.append("── INTENT QUEUE ────────────────────────────────")
	if character.intent_queue.is_empty():
		lines.append("  (empty)")
	else:
		for intent in character.intent_queue:
			var clearable_tag: String = "" if intent.get("clearable", true) else " [fixed]"
			lines.append("  %-20s  prio:%s  patience:%d%s" % [
				intent.get("intent_key", "?"),
				intent.get("priority", "normal"),
				intent.get("patience", 0),
				clearable_tag,
			])
	lines.append("")

	# ── SHORT-TERM MEMORY ───────────────────────────────────
	lines.append("── SHORT-TERM MEMORY ───────────────────────────")
	var has_any_memory: bool = false
	for category in character.short_term_memory:
		var entries: Array = character.short_term_memory[category]
		if entries.is_empty():
			continue
		has_any_memory = true
		for entry in entries:
			var tone_tag: String = entry.get("tone", "neutral")[0].to_upper()
			lines.append("  [%s] %s: %s" % [
				tone_tag,
				category,
				entry.get("summary", "?"),
			])
	if not has_any_memory:
		lines.append("  (empty)")
	lines.append("")

	# ── OBJECT IMPRESSIONS ──────────────────────────────────
	lines.append("── IMPRESSIONS ─────────────────────────────────")
	if character.object_impressions.is_empty():
		lines.append("  (none)")
	else:
		var sorted_keys: Array = character.object_impressions.keys()
		sorted_keys.sort()
		for obj_key in sorted_keys:
			var score: int = character.object_impressions[obj_key]
			var tier: String = Interactables.get_impression_tier(score)
			lines.append("  %-20s %4d  (%s)" % [obj_key, score, tier])
	lines.append("")

	# ── ELIGIBLE EVENTS + WEIGHTS ───────────────────────────
	lines.append("── ELIGIBLE EVENTS ─────────────────────────────")
	var eligible: Array = Sim.get_eligible_with_weights(character)
	if eligible.is_empty():
		lines.append("  (none eligible)")
	else:
		var total_weight: float = 0.0
		for entry in eligible:
			if not entry["on_cooldown"]:
				total_weight += entry["weight"]

		for entry in eligible:
			var cd_tag: String = " [CD]" if entry["on_cooldown"] else ""
			var pct: String = ""
			if not entry["on_cooldown"] and total_weight > 0.0:
				pct = "  %4.1f%%" % (entry["weight"] / total_weight * 100.0)
			lines.append("  %-24s %6.1f%s%s" % [
				entry["event_key"], entry["weight"], pct, cd_tag
			])
	lines.append("")

	# ── LAST 5 STORYBOOK ENTRIES ────────────────────────────
	lines.append("── LAST 5 EVENTS ───────────────────────────────")
	var book: Array = character.storybook
	if book.is_empty():
		lines.append("  (no events yet)")
	else:
		var start_idx: int = max(0, book.size() - 5)
		for idx in range(start_idx, book.size()):
			var entry: Dictionary = book[idx]
			var mag: String = entry.get("magnitude", "minor")[0].to_upper()
			lines.append("  [%s] %s" % [mag, entry.get("summary", "?")])
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