# context.gd
# Autoload — available globally as Context
# Tier 3 Systems — reads Tier 1 + 2
#
# Resolves event targets and frames context args for the pipeline.
# Full implementation Phase 1. Shell for now.

extends Node


func _ready() -> void:
	print("[Context] Loaded. (shell — Phase 1)")


# Resolves the target for an event based on target_resolution config.
# Returns a CharData, InteractableData, String (room_id), or null.
func resolve_target(character: CharData, event_def: Dictionary):
	var resolution: Dictionary = event_def.get("target_resolution", {})
	var type: String = resolution.get("type", "none")

	match type:
		"self":
			return character
		"none":
			return null
		"room":
			# Return a random room ID that isn't the character's current room
			var all_rooms := Rooms.get_all_room_ids()
			if all_rooms.is_empty():
				# No real rooms yet — return a placeholder
				return "bar_f1_s1"
			all_rooms.erase(character.current_room)
			if all_rooms.is_empty():
				return null
			return all_rooms[randi() % all_rooms.size()]
		"character":
			# Return a random other character in the same room
			var occupants := Rooms.get_occupants(character.current_room)
			occupants.erase(character.char_id)
			if occupants.is_empty():
				return null
			var target_id: String = occupants[randi() % occupants.size()]
			return Registry.get_character(target_id)
		"memory":
			# No memories yet — return null
			return null
		_:
			return null


# Builds a context dictionary for storybook template filling.
func build_frame(character: CharData, target, event_def: Dictionary) -> Dictionary:
	var frame: Dictionary = {}
	frame["name"] = character.char_name
	frame["room"] = character.current_room
	if target is CharData:
		frame["target"] = target.char_name
	return frame


# Fills a storybook template string with frame values.
# e.g. "{name} wandered out of {room}." → "Sara wandered out of bar_f1_s1."
func fill_template(template: String, frame: Dictionary) -> String:
	var result := template
	for key in frame:
		result = result.replace("{%s}" % key, str(frame[key]))
	return result