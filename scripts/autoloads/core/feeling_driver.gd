# feeling_driver.gd
# Autoload — available globally as FeelingDriver
# Tier 3 Systems — reads Tier 1 (Feelings) + Tier 2 (Clock)
#
# Manages the lifecycle of feelings on characters:
#   push    — add or stack a feeling with a cause
#   decay   — tick hours_remaining on every half-hour
#   remove  — expire or forcibly clear a feeling
#
# Feelings are stored on CharData.feelings as an Array of Dictionaries.
# See feelings.gd for the full runtime instance shape.
#
# Connected to: Clock.half_hour_ticked

extends Node

# How many causes we keep per feeling instance (oldest dropped first)
const MAX_CAUSES: int = 4

# In-game hours per real half-hour tick.
# 24 hours / (2 half-hours per hour * 24 hours per day) = 0.5 per tick
const HOURS_PER_HALF_HOUR_TICK: float = 0.5


func _ready() -> void:
	# Connect to Clock's half-hour signal.
	# _on_half_hour will be called every time it fires.
	Clock.half_hour_ticked.connect(_on_half_hour)
	print("[FeelingDriver] Loaded. Listening to Clock.half_hour_ticked.")


func _on_half_hour() -> void:
	# Decay all feelings on all characters.
	# Skipped until Registry has characters and CharData exists.
	var all_characters: Array = Registry.get_all()
	for character in all_characters:
		_decay_feelings(character)


# ─────────────────────────────────────────────────────────────
# PUSH
# Call this from Actions when an event generates a feeling.
#
# character   — CharData instance
# feeling_key — must exist in Feelings.FEELINGS
# cause       — Dictionary: { event_key, at_tick, summary }
#               Pass {} if no cause to attach (rare)
# target_id   — char_id string if targeted, null if global
# force_hidden — true = hidden regardless of feeling definition
# ─────────────────────────────────────────────────────────────

func push(character, feeling_key: String, cause: Dictionary = {},
		target_id = null, force_hidden: bool = false) -> void:

	if not Feelings.is_valid(feeling_key):
		push_warning("[FeelingDriver] Unknown feeling key: %s" % feeling_key)
		return

	# Remove conflicting feelings first
	var conflicts: Array = Feelings.get_conflicting(feeling_key)
	for conflict_key in conflicts:
		remove(character, conflict_key)

	# Check if this feeling is already active
	var existing: Dictionary = _find_feeling(character, feeling_key, target_id)

	if not existing.is_empty():
		# Already active — refresh duration and append cause
		var new_duration: float = Feelings.get_duration(feeling_key)
		existing["hours_remaining"] = maxf(existing["hours_remaining"], new_duration)
		if not cause.is_empty():
			existing["causes"].append(cause)
			# Cap causes at MAX_CAUSES — drop the oldest
			if existing["causes"].size() > MAX_CAUSES:
				existing["causes"] = existing["causes"].slice(
					existing["causes"].size() - MAX_CAUSES
				)
	else:
		# New feeling — build the instance and append to character
		var is_hidden: bool = force_hidden or Feelings.can_be_hidden(feeling_key)
		var instance: Dictionary = {
			"feeling_key":     feeling_key,
			"hours_remaining": Feelings.get_duration(feeling_key),
			"target_id":       target_id,
			"is_hidden":       is_hidden,
			"causes":          [cause] if not cause.is_empty() else [],
		}
		character.feelings.append(instance)

	if Settings.debug_console_logging:
		var summary: String = cause.get("summary", "no cause")
		print("[FeelingDriver] %s → %s (%s)" % [character.char_name, feeling_key, summary])


# ─────────────────────────────────────────────────────────────
# DECAY
# Called on each half-hour tick. Reduces hours_remaining.
# Removes feelings that have expired.
# ─────────────────────────────────────────────────────────────

func _decay_feelings(character) -> void:
	# Iterate backwards so we can safely remove while iterating
	var i: int = character.feelings.size() - 1
	while i >= 0:
		var instance: Dictionary = character.feelings[i]
		instance["hours_remaining"] -= HOURS_PER_HALF_HOUR_TICK
		if instance["hours_remaining"] <= 0.0:
			character.feelings.remove_at(i)
			if Settings.debug_console_logging:
				print("[FeelingDriver] %s lost feeling: %s" % [
					character.char_name, instance["feeling_key"]
				])
		i -= 1


# ─────────────────────────────────────────────────────────────
# REMOVE
# Force-clear a specific feeling (used when conflicts push it out,
# or events explicitly clear a feeling — e.g. SLEEP clears EXHAUSTED).
# ─────────────────────────────────────────────────────────────

func remove(character, feeling_key: String, target_id = null) -> void:
	var i: int = character.feelings.size() - 1
	while i >= 0:
		var instance: Dictionary = character.feelings[i]
		var key_matches: bool = instance["feeling_key"] == feeling_key
		var target_matches: bool = target_id == null or instance["target_id"] == target_id
		if key_matches and target_matches:
			character.feelings.remove_at(i)
		i -= 1


# ─────────────────────────────────────────────────────────────
# QUERY HELPERS
# Used by Sim, event requirements, and EventInspector.
# ─────────────────────────────────────────────────────────────

# True if character currently has this feeling (optionally at a specific target)
func has_feeling(character, feeling_key: String, target_id = null) -> bool:
	return not _find_feeling(character, feeling_key, target_id).is_empty()

# Returns all active feeling keys as a flat Array of strings.
# Used by event requirements: has_feeling, not_has_feeling.
func get_active_keys(character) -> Array:
	var result: Array = []
	for instance in character.feelings:
		result.append(instance["feeling_key"])
	return result

# Returns the full instance dictionary for a feeling, or {}.
# Used by EventInspector to build the tooltip with causes.
func get_instance(character, feeling_key: String, target_id = null) -> Dictionary:
	return _find_feeling(character, feeling_key, target_id)

# Returns all feeling instances for the UI panel.
func get_all_instances(character) -> Array:
	return character.feelings


# ─────────────────────────────────────────────────────────────
# INTERNAL
# ─────────────────────────────────────────────────────────────

func _find_feeling(character, feeling_key: String, target_id = null) -> Dictionary:
	for instance in character.feelings:
		if instance["feeling_key"] != feeling_key:
			continue
		# If target_id specified, must match
		if target_id != null and instance["target_id"] != target_id:
			continue
		return instance
	return {}

func get_active_feelings(character: CharData) -> Array:
	var result: Array = []
	for instance in character.feelings:
		result.append(instance["feeling_key"])
	return result
