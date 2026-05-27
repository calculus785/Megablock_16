# storybook_display.gd
# Shows last N storybook entries above a character as a Label3D.
# Toggled globally via Sim.storybook_visible (set by key input).

extends Node3D

const MAX_ENTRIES: int = 4
const LINE_LENGTH: int = 40  # characters before wrapping

var _char_data: CharData
var _label: Label3D
var _last_entry_count: int = -1


func setup(char_data: CharData) -> void:
	_char_data = char_data

	_label = Label3D.new()
	_label.font_size = 28
	_label.pixel_size = 0.015
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.modulate = Color(0.9, 0.9, 0.85, 0.92)
	_label.outline_modulate = Color(0.0, 0.0, 0.0, 0.8)
	_label.outline_size = 6
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.position = Vector3(0.0, 0.0, 0.0)
	_label.visible = false
	add_child(_label)


func set_visible_log(show: bool) -> void:
	if _label:
		_label.visible = show
	if show:
		_last_entry_count = -1  # force refresh on show
		_refresh()


func _process(_delta: float) -> void:
	if _label == null or not _label.visible:
		return
	# Only refresh when storybook has changed
	if _char_data == null:
		return
	var count: int = _char_data.storybook.size()
	if count != _last_entry_count:
		_last_entry_count = count
		_refresh()


func _refresh() -> void:
	if _char_data == null or _label == null:
		return

	var entries: Array = _char_data.storybook
	if entries.is_empty():
		_label.text = ""
		return

	# Take last MAX_ENTRIES, most recent at bottom
	var start: int = max(0, entries.size() - MAX_ENTRIES)
	var recent: Array = entries.slice(start, entries.size())

	var lines: Array = []
	for entry in recent:
		var summary: String = entry.get("summary", "")
		# Wrap long lines
		while summary.length() > LINE_LENGTH:
			lines.append(summary.substr(0, LINE_LENGTH))
			summary = summary.substr(LINE_LENGTH)
		if summary.length() > 0:
			lines.append(summary)
		lines.append("")  # blank line between entries

	# Remove trailing blank
	if not lines.is_empty() and lines[-1] == "":
		lines.pop_back()

	_label.text = "\n".join(lines)