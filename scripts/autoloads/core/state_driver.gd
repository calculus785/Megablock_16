# state_driver.gd
# Autoload — available globally as StateDriver
# Tier 3 Systems — reads Tier 1 (States, Stats) + Tier 2 (Clock, Registry)
#
# Evaluates stat-derived states on every character each half-hour.
# Never called manually — change the stat and StateDriver catches it.
#
# Two rules per state:
#   enter_threshold — stat must cross this to gain the state
#   exit_threshold  — stat must cross this to lose it (hysteresis gap)
#
# Persistent states (INJURED, BANNED_FROM_BAR etc.) are NEVER touched here.
# Those are set and cleared by Actions only.
#
# Connected to: Clock.half_hour_ticked

extends Node


func _ready() -> void:
	Clock.half_hour_ticked.connect(_on_half_hour)
	print("[StateDriver] Loaded. Listening to Clock.half_hour_ticked.")


func _on_half_hour() -> void:
	var all_characters: Array = Registry.get_all()
	for character in all_characters:
		evaluate_character(character)


# ─────────────────────────────────────────────────────────────
# EVALUATE
# Checks every stat-derived state against a character's current stats.
# Adds missing states, removes expired ones.
# ─────────────────────────────────────────────────────────────

func evaluate_character(character) -> void:
	for state_key in States.STATES:
		var state_def: Dictionary = States.STATES[state_key]
		var stat_key: String = state_def["stat"]
		var direction: String = state_def["direction"]
		var enter_threshold: float = state_def["enter_threshold"]
		var exit_threshold: float = state_def["exit_threshold"]

		# Guard: stat must exist on this character
		if not character.stats.has(stat_key):
			continue

		var stat_value: float = character.stats[stat_key]
		var currently_has: bool = state_key in character.states

		if direction == "high":
			# State activates when stat is HIGH
			if not currently_has and stat_value >= enter_threshold:
				_add_state(character, state_key)
			elif currently_has and stat_value < exit_threshold:
				_remove_state(character, state_key)

		elif direction == "low":
			# State activates when stat is LOW
			if not currently_has and stat_value <= enter_threshold:
				_add_state(character, state_key)
			elif currently_has and stat_value > exit_threshold:
				_remove_state(character, state_key)


# ─────────────────────────────────────────────────────────────
# ADD / REMOVE
# ─────────────────────────────────────────────────────────────

func _add_state(character, state_key: String) -> void:
	if state_key not in character.states:
		character.states.append(state_key)
		if Settings.debug_console_logging:
			print("[StateDriver] %s gained state: %s" % [character.char_name, state_key])


func _remove_state(character, state_key: String) -> void:
	if state_key in character.states:
		character.states.erase(state_key)
		if Settings.debug_console_logging:
			print("[StateDriver] %s lost state: %s" % [character.char_name, state_key])


# ─────────────────────────────────────────────────────────────
# MANUAL PERSISTENT STATE MANAGEMENT
# These are the only functions that should touch persistent_states.
# Called by Actions, never by StateDriver's own evaluation loop.
# ─────────────────────────────────────────────────────────────

func set_persistent_state(character, state_key: String) -> void:
	if not States.is_valid_persistent(state_key):
		push_warning("[StateDriver] Unknown persistent state: %s" % state_key)
		return
	if state_key not in character.persistent_states:
		character.persistent_states.append(state_key)
		if Settings.debug_console_logging:
			print("[StateDriver] %s gained persistent state: %s" % [
				character.char_name, state_key
			])

func clear_persistent_state(character, state_key: String) -> void:
	if state_key in character.persistent_states:
		character.persistent_states.erase(state_key)
		if Settings.debug_console_logging:
			print("[StateDriver] %s cleared persistent state: %s" % [
				character.char_name, state_key
			])

func has_persistent_state(character, state_key: String) -> bool:
	return state_key in character.persistent_states


# ─────────────────────────────────────────────────────────────
# QUERY HELPERS
# Used by Sim and event requirements.
# ─────────────────────────────────────────────────────────────

func has_state(character, state_key: String) -> bool:
	return state_key in character.states

func get_all_states(character) -> Array:
	return character.states.duplicate()

func get_all_persistent_states(character) -> Array:
	return character.persistent_states.duplicate()