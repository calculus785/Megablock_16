# sim.gd
# Autoload — available globally as Sim
# Tier 4 Simulation — reads everything above it
#
# The 7-stage pipeline. Runs every character every tick.
# Stages: ROLL → RESOLVE → FRAME → PLAYER_GATE → ACT → EXECUTE → ECHO
#
# Phase 1 implementation:
#   - Full requirement evaluation
#   - Weighted random roll with modifiers
#   - Event-count cooldowns (cooldown_events field on each event)
#   - Context.resolve_target() for targeting
#   - Actions.call_action() for execution
#   - Stat outcomes applied from event definition
#   - Storybook entry written on each event
#   - Console logging with storybook text
#
# Not yet: intent queue, sequences, player gate, auto-fire pass
# Future: layer location memory cooldowns (not_recent_room) in Phase 3

extends Node

# Emitted after each event fires — EventInspector listens to this
signal event_fired(char_id: String, event_key: String, summary: String)

# Global counter — increments every time any event fires on any character.
# Cooldowns store the _event_counter value when the event becomes available again.
# Speed-independent: a character always does N other things before repeating,
# regardless of sim speed.
var _event_counter: int = 0


func _ready() -> void:
	Clock.tick.connect(_on_tick)
	Clock.half_hour_ticked.connect(_on_half_hour)
	print("[Sim] Loaded. Listening to Clock.tick.")


func _on_tick() -> void:
	for character in Registry.get_all():
		if character.is_sleeping:
			_try_wake(character)
			continue
		# Sequence advance — only the initiator drives the sequence.
		if character.active_sequence != "" and character.sequence_role == "initiator":
			if not _check_and_interrupt(character):
				_advance_sequence(character)
			continue
		# Responders skip — the initiator drives the sequence for both.
		if character.active_sequence != "":
			continue
		if character.is_in_transit:
			# Characters in a hallway room get a limited event check
			if Rooms.is_hallway(character.current_room):
				_run_hallway_check(character)
			continue
		if not character.is_actionable():
			continue
		# ── AVOIDANCE CHECK ─────────────────────────────────
		if _check_and_flee_avoided(character):
			continue
		# ── INTENT PROCESSING ───────────────────────────────
		var expired: Array = Memory.tick_intents(character)
		for expired_key in expired:
			_fire_give_up(character, expired_key)
		if Memory.has_intents(character):
			if _try_fire_intent(character):
				continue
		# ── NORMAL PIPELINE ─────────────────────────────────
		if _run_auto_fire(character):
			continue
		_run_pipeline(character)

func _on_half_hour() -> void:
	for character in Registry.get_all():
		if character.is_sleeping:
			Actions.modify_stat(character, "energy", 8.0)
			Actions.modify_stat(character, "stress", -2.0)
		else:
			Actions.modify_stat(character, "boredom", 3.0)
			Actions.modify_stat(character, "energy", -3.0)
			Actions.modify_stat(character, "stress", 2.0)
			Actions.modify_stat(character, "hunger", 1.0)
			Actions.modify_stat(character, "need_for_toilet", 1)
			Actions.modify_stat(character, "horniness", 0.2)
		if character.is_in_transit:
			continue


func _try_wake(character: CharData) -> void:
	# Wake up if it's morning AND energy is recovered enough to function
	var is_morning: bool = Clock.current_hour >= 7 and Clock.current_hour < 10
	var energy: float = character.stats.get("energy", 0.0)
	if not (is_morning and energy >= 60.0):
		return

	character.is_sleeping = false

	var summary: String = "%s woke up." % character.char_name
	Memory.write_storybook(character, {
		"event_key":         "WAKE",
		"summary":           summary,
		"at_tick":           Clock.get_total_days(),
		"target_id":         "",
		"magnitude":         "minor",
		"memorable":         false,
		"memory_tags":       [],
		"times_recalled":    0,
		"last_recalled_day": 0,
		"pinned_to_story":   false,
	})

	if Settings.debug_console_logging:
		print("[Sim] %s → %s" % [character.char_name, summary])

	event_fired.emit(character.char_id, "WAKE", summary)


# ─────────────────────────────────────────────────────────────
# PIPELINE
# ─────────────────────────────────────────────────────────────

func _run_pipeline(character: CharData) -> void:

	# ── 1. ROLL ─────────────────────────────────────────────
	var eligible: Array = _get_eligible_events(character)
	if eligible.is_empty():
		return

	var event_key: String = _weighted_roll(character, eligible)
	if event_key == "":
		return

	# Check cooldown — skip if this event fired too recently
	if _is_on_cooldown(character, event_key):
		return

	var event_def: Dictionary = Events.get_event(event_key)

	# ── 2. RESOLVE ──────────────────────────────────────────
	var target = Context.resolve_target(character, event_def)

	# ── 3. FRAME ────────────────────────────────────────────
	var frame: Dictionary = Context.build_frame(character, target, event_def)

	# ── 4. PLAYER_GATE ──────────────────────────────────────
	# Skipped — no player character yet. Phase 1+ adds this.

	# ── 5. ACT ──────────────────────────────────────────────
	var action_name: String = event_def.get("call_action", "")
	if action_name == "":
		return

	var result: String = Actions.call_action(action_name, character, target, frame)

	# If the action returned LOCK_SEQUENCE, start the sequence on both participants.
	# The invite event's outcomes/echo still fire — they describe the invitation moment.
	if result == Actions.LOCK_SEQUENCE:
		var seq_key: String = event_def.get("sequence_key", "")
		if seq_key != "" and target is CharData:
			_start_sequence(character, target, seq_key)

	# ── 6. EXECUTE ──────────────────────────────────────────
	_apply_outcomes(character, target, event_def)

	# ── 7. ECHO ─────────────────────────────────────────────
	var summary: String = _echo(character, target, event_key, event_def, frame)

	# Set cooldown AFTER the event fires
	_set_cooldown(character, event_key, event_def)
	_event_counter += 1
	_apply_repetition_boredom(character, event_key)

	# ── LOG ─────────────────────────────────────────────────
	if Settings.debug_console_logging:
		print("[Sim] %s → %s" % [character.char_name, summary])

	event_fired.emit(character.char_id, event_key, summary)

# ─────────────────────────────────────────────────────────────
# FORCE FIRE (debug)
# Runs an event on a character, skipping eligibility + cooldown.
# Called by ForceEvent panel (F3). Returns the storybook summary.
# ─────────────────────────────────────────────────────────────

func force_fire_event(character: CharData, event_key: String) -> String:
	var event_def: Dictionary = Events.get_event(event_key)
	if event_def.is_empty():
		push_warning("[Sim] force_fire_event — unknown event: %s" % event_key)
		return "Unknown event: %s" % event_key

	# RESOLVE
	var target = Context.resolve_target(character, event_def)

	# FRAME
	var frame: Dictionary = Context.build_frame(character, target, event_def)

	# ACT
	var action_name: String = event_def.get("call_action", "")
	if action_name != "":
		var result: String = Actions.call_action(action_name, character, target, frame)
		if result == Actions.LOCK_SEQUENCE:
			var seq_key: String = event_def.get("sequence_key", "")
			if seq_key != "" and target is CharData:
				_start_sequence(character, target, seq_key)

	# EXECUTE
	_apply_outcomes(character, target, event_def)

	# ECHO
	var summary: String = _echo(character, target, event_key, event_def, frame)

	# No cooldown set — forced events are debug, shouldn't block normal firing
	_event_counter += 1

	if Settings.debug_console_logging:
		print("[Sim] 🔧 FORCED → %s → %s" % [character.char_name, summary])

	event_fired.emit(character.char_id, event_key, summary)
	return summary

func force_fire_event_with_target(character: CharData,
		event_key: String, target) -> String:
	var event_def: Dictionary = Events.get_event(event_key)
	if event_def.is_empty():
		push_warning("[Sim] force_fire_event_with_target — unknown event: %s" % event_key)
		return "Unknown event: %s" % event_key
 
	# Skip resolve_target — use the provided target directly
	var frame: Dictionary = Context.build_frame(character, target, event_def)
 
	var action_name: String = event_def.get("call_action", "")
	if action_name != "":
		var result: String = Actions.call_action(action_name, character, target, frame)
		if result == Actions.LOCK_SEQUENCE:
			var seq_key: String = event_def.get("sequence_key", "")
			if seq_key != "" and target is CharData:
				_start_sequence(character, target, seq_key)
 
	_apply_outcomes(character, target, event_def)
	var summary: String = _echo(character, target, event_key, event_def, frame)
	_event_counter += 1
 
	if Settings.debug_console_logging:
		print("[Sim] 🔧 FORCED → %s → %s" % [character.char_name, summary])
 
	event_fired.emit(character.char_id, event_key, summary)
	return summary

# ─────────────────────────────────────────────────────────────
# DEBUG QUERY (used by EventInspector)
# Returns eligible events + final weights for a character.
# Array of { "event_key": String, "weight": float }, sorted by weight desc.
# ─────────────────────────────────────────────────────────────

func get_eligible_with_weights(character: CharData) -> Array:
	var result: Array = []
	for event_key in Events.get_events_by_trigger("rolled"):
		var event_def: Dictionary = Events.get_event(event_key)
		if not _check_requirements(character, event_def.get("requirements", {})):
			continue
		var weight: float = event_def.get("base_weight", 10.0)
		weight = _apply_weight_modifiers(character, event_def, weight)
		if weight <= 0.0:
			continue
		var on_cd: bool = _is_on_cooldown(character, event_key)
		result.append({
			"event_key": event_key,
			"weight": weight,
			"on_cooldown": on_cd,
		})
	# Sort by weight descending
	result.sort_custom(func(a, b): return a["weight"] > b["weight"])
	return result

# ─────────────────────────────────────────────────────────────
# INTENT PROCESSING
# Tries to fire the top intent as an event. If the event's
# requirements aren't met, leaves the intent in the queue and
# returns false (fall through to normal pipeline).
# ─────────────────────────────────────────────────────────────

func _try_fire_intent(character: CharData) -> bool:
	var intent: Dictionary = Memory.peek_intent(character)
	if intent.is_empty():
		return false

	var event_key: String = intent.get("intent_key", "")
	var event_def: Dictionary = Events.get_event(event_key)

	# Unknown event — pop and discard the bad intent
	if event_def.is_empty():
		Memory.pop_intent(character)
		push_warning("[Sim] Intent had unknown event_key: %s — discarded." % event_key)
		return false

	# Check requirements — if not met, leave intent in queue and skip
	if not _check_requirements(character, event_def.get("requirements", {})):
		return false

	# Requirements met — pop the intent and fire the event
	Memory.pop_intent(character)

	var target = Context.resolve_target(character, event_def)

	# If intent has a specific target_id, try to use that instead
	var intent_target_id: String = intent.get("target_id", "")
	if intent_target_id != "":
		var specific_target: CharData = Registry.get_character(intent_target_id)
		if specific_target:
			target = specific_target

	var frame: Dictionary = Context.build_frame(character, target, event_def)
	var action_name: String = event_def.get("call_action", "")
	if action_name != "":
		var result: String = Actions.call_action(action_name, character, target, frame)
		if result == Actions.LOCK_SEQUENCE:
			var seq_key: String = event_def.get("sequence_key", "")
			if seq_key != "" and target is CharData:
				_start_sequence(character, target, seq_key)

	_apply_outcomes(character, target, event_def)
	var summary: String = _echo(character, target, event_key, event_def, frame)
	_set_cooldown(character, event_key, event_def)
	_event_counter += 1

	if Settings.debug_console_logging:
		print("[Sim] 📋 INTENT → %s → %s" % [character.char_name, summary])

	event_fired.emit(character.char_id, event_key, summary)
	return true


# Fires a GIVE_UP storybook entry when an intent's patience runs out.
func _fire_give_up(character: CharData, expired_key: String) -> void:
	# Trait-modified reaction
	var my_traits: Array = character.get_all_active_traits()
	if "SHORT_TEMPERED" in my_traits:
		FeelingDriver.push(character, "FRUSTRATED", {
			"event_key": "give_up",
			"at_tick": Clock.get_total_days(),
			"summary": "gave up waiting to %s" % expired_key,
		})
	elif "STUBBORN" in my_traits:
		Actions.modify_stat(character, "stress", 8.0)

	Actions.modify_stat(character, "stress", 5.0)

	var summary: String = "%s gave up on %s." % [character.char_name, expired_key]

	Memory.write_storybook(character, {
		"event_key":         "GIVE_UP",
		"summary":           summary,
		"at_tick":           Clock.get_total_days(),
		"target_id":         "",
		"magnitude":         "minor",
		"memorable":         false,
		"memory_tags":       [],
		"times_recalled":    0,
		"last_recalled_day": 0,
		"pinned_to_story":   false,
	})

	if Settings.debug_console_logging:
		print("[Sim] ❌ %s → %s" % [character.char_name, summary])

	event_fired.emit(character.char_id, "GIVE_UP", summary)

# ─────────────────────────────────────────────────────────────
# AVOIDANCE CHECK
# If a character is in the same room as someone they're AVOIDING,
# push a flee intent and skip normal pipeline.
# ─────────────────────────────────────────────────────────────

func _check_and_flee_avoided(character: CharData) -> bool:
	# Guard: room must be a valid non-empty string
	if character.current_room == null or character.current_room == "":
		return false

	# Don't double-push if already fleeing
	for intent in character.intent_queue:
		if intent.has("flee_from"):
			return false

	var room_id: String = character.current_room
	var occupants: Array = Rooms.get_occupants(room_id)

	for feeling in character.feelings:
		if feeling.get("feeling_key", "") != "AVOIDING":
			continue
		var raw_avoid = feeling.get("target_id", null)
		if raw_avoid == null:
			continue
		var avoid_id: String = str(raw_avoid)
		if avoid_id == "" or avoid_id == "null":
			continue
		# Guard: avoid_id must be valid
		if avoid_id == null or avoid_id == "":
			continue
		if avoid_id not in occupants:
			continue

		var avoided: CharData = Registry.get_character(avoid_id)
		if avoided == null or avoided.is_sleeping:
			continue

		# ── Flee! ───────────────────────────────────────────
		var flee_key: String = "GO_HOME"
		if character.current_room == character.home_room:
			flee_key = "WANDER"

		Memory.push_intent(character, {
			"intent_key": flee_key,
			"priority": "high",
			"target_id": "",
			"patience": 5,
			"clearable": false,
			"flee_from": avoid_id,
		})

		var summary: String = "%s saw %s and needed to leave." % [
			character.char_name, avoided.char_name]

		Memory.write_storybook(character, {
			"event_key":         "FLEE_AVOIDED",
			"summary":           summary,
			"at_tick":           Clock.get_total_days(),
			"target_id":         avoid_id,
			"magnitude":         "minor",
			"memorable":         false,
			"memory_tags":       ["avoidance"],
			"times_recalled":    0,
			"last_recalled_day": 0,
			"pinned_to_story":   false,
		})

		if Settings.debug_console_logging:
			print("[Sim] 🚷 %s spotted %s — leaving %s" % [
				character.char_name, avoided.char_name, room_id])

		event_fired.emit(character.char_id, "FLEE_AVOIDED", summary)
		return true

	return false

# ─────────────────────────────────────────────────────────────
# COOLDOWNS
# Reads cooldown_events from the event definition.
# Stores the _event_counter value when the event becomes available again.
# ─────────────────────────────────────────────────────────────

func _is_on_cooldown(character: CharData, event_key: String) -> bool:
	if not character.event_cooldowns.has(event_key):
		return false
	return _event_counter < character.event_cooldowns[event_key]


func _set_cooldown(character: CharData, event_key: String, event_def: Dictionary) -> void:
	var duration: int = event_def.get("cooldown_events", 0)
	if duration > 0:
		# Store the counter value when this event becomes available again
		character.event_cooldowns[event_key] = _event_counter + duration


# ─────────────────────────────────────────────────────────────
# STAGE 1 — ELIGIBILITY
# ─────────────────────────────────────────────────────────────

func _get_eligible_events(character: CharData) -> Array:
	var eligible: Array = []
	for event_key in Events.get_events_by_trigger("rolled"):
		var event_def: Dictionary = Events.get_event(event_key)
		if _check_requirements(character, event_def.get("requirements", {})):
			eligible.append(event_key)
	return eligible

func _get_room_others(character: CharData) -> Array:
	var others: Array = []
	for char_id in Rooms.get_occupants(character.current_room):
		if char_id != character.char_id:
			var other: CharData = Registry.get_character(char_id)
			if other:
				others.append(other)
	return others

func _check_requirements(character: CharData, reqs: Dictionary) -> bool:
	# stats_above — stat must be >= value
	if reqs.has("stats_above"):
		for stat_key in reqs["stats_above"]:
			if character.stats.get(stat_key, 0.0) < reqs["stats_above"][stat_key]:
				return false

	# stats_below — stat must be <= value
	if reqs.has("stats_below"):
		for stat_key in reqs["stats_below"]:
			if character.stats.get(stat_key, 0.0) > reqs["stats_below"][stat_key]:
				return false

	# has_state
	if reqs.has("has_state"):
		for state_key in reqs["has_state"]:
			if not StateDriver.has_state(character, state_key):
				return false

	# has_persistent_state / not_has_persistent_state
	if reqs.has("has_persistent_state"):
		for state_key in reqs["has_persistent_state"]:
			if not StateDriver.has_persistent_state(character, state_key):
				return false

	if reqs.has("not_has_persistent_state"):
		for state_key in reqs["not_has_persistent_state"]:
			if StateDriver.has_persistent_state(character, state_key):
				return false

	# has_trait / not_has_trait — checks visible + hidden
	if reqs.has("has_trait"):
		for trait_key in reqs["has_trait"]:
			if not trait_key in character.get_all_active_traits():
				return false

	if reqs.has("not_has_trait"):
		for trait_key in reqs["not_has_trait"]:
			if trait_key in character.get_all_active_traits():
				return false

	# in_room / not_in_room
	# Phase 1: room IDs are placeholders (e.g. "apartment_f1_s1")
	# We check the type prefix ("bar", "apartment", "cafe" etc.)
	if reqs.has("in_room"):
		var matched := false
		for room_type in reqs["in_room"]:
			if character.current_room.begins_with(room_type):
				matched = true
				break
		if not matched:
			return false

	if reqs.has("not_in_room"):
		for room_type in reqs["not_in_room"]:
			if character.current_room.begins_with(room_type):
				return false

	# has_feeling / not_has_feeling
	if reqs.has("has_feeling"):
		for feeling_key in reqs["has_feeling"]:
			if not FeelingDriver.has_feeling(character, feeling_key):
				return false

	if reqs.has("not_has_feeling"):
		for feeling_key in reqs["not_has_feeling"]:
			if FeelingDriver.has_feeling(character, feeling_key):
				return false
	# time_of_day — matches Clock.get_time_of_day() against an array of buckets
	# e.g. "time_of_day": ["evening", "night"]
	if reqs.has("time_of_day"):
		if not Clock.get_time_of_day() in reqs["time_of_day"]:
			return false
	
	# in_home_room — character must be in their own apartment
	if reqs.has("in_home_room") and reqs["in_home_room"]:
		if character.current_room != character.home_room:
			return false

	# not_in_home_room — character must NOT be in their apartment
	if reqs.has("not_in_home_room") and reqs["not_in_home_room"]:
		if character.current_room == character.home_room:
			return false

	if reqs.has("other_character_in_room") and reqs["other_character_in_room"]:
		var occupants: Array = Rooms.get_occupants(character.current_room)
		var others_present := false
		for char_id in occupants:
			if char_id != character.char_id:
				others_present = true
				break
		if not others_present:
			return false
	
	# has_memorable_entries — character must have at least one memorable storybook entry
	if reqs.has("has_memorable_entries") and reqs["has_memorable_entries"]:
		var memorable: Array = Memory.get_memorable_entries(character)
		if memorable.is_empty():
			return false



		# in_zone — character must be in a specific zone
	# e.g. "in_zone": "Zone_Counter"
	if reqs.has("in_zone"):
		var zone_name: String = reqs["in_zone"]
		if not Rooms.is_in_zone(character.current_room, character.char_id, zone_name):
			return false

	# zone_has_space — a specific zone must have free spots
	# e.g. "zone_has_space": "Zone_Pool"
	if reqs.has("zone_has_space"):
		var zone_name: String = reqs["zone_has_space"]
		if not Rooms.zone_has_space(character.current_room, zone_name):
			return false

	# room_has_zone — the current room must have this zone at all
	# e.g. "room_has_zone": "Zone_Counter"
	if reqs.has("room_has_zone"):
		var zone_name: String = reqs["room_has_zone"]
		if Rooms.get_zone(character.current_room, zone_name).is_empty():
			return false
	
	# relationship_bond_above — at least one room occupant has bond > value
	if reqs.has("relationship_bond_above"):
		var threshold: float = float(reqs["relationship_bond_above"])
		var found: bool = false
		for other in _get_room_others(character):
			if Relationships.get_bond(character.char_id, other.char_id) > threshold:
				found = true
				break
		if not found:
			return false
 
	# relationship_bond_below — at least one room occupant has bond < value
	if reqs.has("relationship_bond_below"):
		var threshold: float = float(reqs["relationship_bond_below"])
		var found: bool = false
		for other in _get_room_others(character):
			if Relationships.get_bond(character.char_id, other.char_id) < threshold:
				found = true
				break
		if not found:
			return false
 
	# relationship_tier_at_least — at least one room occupant at or above tier
	if reqs.has("relationship_tier_at_least"):
		var min_tier: String = reqs["relationship_tier_at_least"]
		var found: bool = false
		for other in _get_room_others(character):
			if Relationships.tier_at_least(
				Relationships.get_tier(character.char_id, other.char_id), min_tier
			):
				found = true
				break
		if not found:
			return false
 
	# relationship_tier_at_most — at least one room occupant at or below tier
	if reqs.has("relationship_tier_at_most"):
		var max_tier: String = reqs["relationship_tier_at_most"]
		var found: bool = false
		for other in _get_room_others(character):
			if Relationships.tier_at_most(
				Relationships.get_tier(character.char_id, other.char_id), max_tier
			):
				found = true
				break
		if not found:
			return false
 
	# relationship_familiarity_above — at least one room occupant with familiarity > value
	if reqs.has("relationship_familiarity_above"):
		var threshold: float = float(reqs["relationship_familiarity_above"])
		var found: bool = false
		for other in _get_room_others(character):
			if Relationships.get_familiarity(character.char_id, other.char_id) > threshold:
				found = true
				break
		if not found:
			return false
 
	# is_partnered — actor is / isn't in PARTNER+ tier with anyone (building-wide)
	if reqs.has("is_partnered"):
		var wants_partner: bool = reqs["is_partnered"]
		if Relationships.is_partnered(character.char_id) != wants_partner:
			return false
 
	# compatible_sexuality — actor is attracted to at least one room occupant
	if reqs.has("compatible_sexuality") and reqs["compatible_sexuality"]:
		var found: bool = false
		for other in _get_room_others(character):
			if other is RobotData:
				continue
			if Identity.is_attracted_to(character.preference, other.pronouns):
				found = true
				break
		if not found:
			return false
 
	# no_existing_relationship — at least one room occupant has no record yet
	if reqs.has("no_existing_relationship") and reqs["no_existing_relationship"]:
		var found: bool = false
		for other in _get_room_others(character):
			if not Relationships.has_record(character.char_id, other.char_id):
				found = true
				break
		if not found:
			return false

		# faction_sentiment_above — all listed factions must be above threshold
	if reqs.has("faction_sentiment_above"):
		for faction in reqs["faction_sentiment_above"]:
			var threshold: float = float(reqs["faction_sentiment_above"][faction])
			if character.faction_sentiment.get(faction, 50.0) <= threshold:
				return false
 
	# faction_sentiment_below — all listed factions must be below threshold
	if reqs.has("faction_sentiment_below"):
		for faction in reqs["faction_sentiment_below"]:
			var threshold: float = float(reqs["faction_sentiment_below"][faction])
			if character.faction_sentiment.get(faction, 50.0) >= threshold:
				return false
	
	# has_memory_tag — character has at least one storybook entry with this tag
	if reqs.has("has_memory_tag"):
		if not Memory.has_storybook_tag(character, reqs["has_memory_tag"]):
			return false
	return true

# ─────────────────────────────────────────────────────────────
# STAGE 1 — WEIGHTED ROLL
# ─────────────────────────────────────────────────────────────

func _weighted_roll(character: CharData, eligible: Array) -> String:
	var pool: Array = []

	for event_key in eligible:
		var event_def: Dictionary = Events.get_event(event_key)
		var weight: float = event_def.get("base_weight", 10.0)
		weight = _apply_weight_modifiers(character, event_def, weight)
		if weight > 0.0:
			pool.append([event_key, weight])

	if pool.is_empty():
		return ""

	var total: float = 0.0
	for entry in pool:
		total += entry[1]

	var roll: float = randf() * total
	var running: float = 0.0
	for entry in pool:
		running += entry[1]
		if roll <= running:
			return entry[0]

	return pool[0][0]


func _apply_weight_modifiers(character: CharData, event_def: Dictionary, base_weight: float) -> float:
	var weight := base_weight
	for modifier in event_def.get("weight_modifiers", []):
		var condition: Dictionary = modifier.get("condition", {})
		if _check_requirements(character, condition):
			weight *= modifier.get("multiply", 1.0)
	return weight


# ─────────────────────────────────────────────────────────────
# STAGE 6 — EXECUTE OUTCOMES
# ─────────────────────────────────────────────────────────────

func _apply_outcomes(character: CharData, target, event_def: Dictionary) -> void:
	var outcomes: Dictionary = event_def.get("outcomes", {})

	if outcomes.has("stats"):
		for stat_key in outcomes["stats"]:
			Actions.modify_stat(character, stat_key, outcomes["stats"][stat_key])

	if outcomes.has("target_stats") and target is CharData:
		for stat_key in outcomes["target_stats"]:
			Actions.modify_stat(target, stat_key, outcomes["target_stats"][stat_key])

	if outcomes.has("feelings"):
		for feeling_key in outcomes["feelings"]:
			FeelingDriver.push(character, feeling_key, {
				"event_key": event_def.get("call_action", "unknown"),
				"at_tick": Clock.get_total_days(),
				"summary": "outcome of %s" % event_def.get("call_action", "event"),
			})

	if outcomes.has("target_feelings") and target is CharData:
		for feeling_key in outcomes["target_feelings"]:
			FeelingDriver.push(target, feeling_key, {
				"event_key": event_def.get("call_action", "unknown"),
				"at_tick": Clock.get_total_days(),
				"summary": "outcome of %s involving %s" % [
					event_def.get("call_action", "event"), character.char_name
				],
			})
	# Relationship deltas (bond, trust, rivalry, familiarity)
	if outcomes.has("relationship") and target is CharData:
		var rel: Dictionary = outcomes["relationship"]
		if rel.has("bond"):
			Relationships.modify_bond(
				character.char_id, target.char_id, float(rel["bond"]))
		if rel.has("trust"):
			Relationships.modify_trust(
				character.char_id, target.char_id, float(rel["trust"]))
		if rel.has("rivalry"):
			Relationships.modify_rivalry(
				character.char_id, target.char_id, float(rel["rivalry"]))
		if rel.has("familiarity"):
			Relationships.modify_familiarity(
				character.char_id, target.char_id, float(rel["familiarity"]))
	
	# Inside _apply_outcomes(), after the Relationships.modify_* calls:
	if outcomes.has("relationship") and target is CharData:
		var rel: Dictionary = outcomes["relationship"]
		# ... existing modify calls ...
		
		# Debug log
		if Settings.debug_console_logging:
			var bond_now: float = Relationships.get_bond(
				character.char_id, target.char_id)
			var tier: String = Relationships.get_tier(
				character.char_id, target.char_id)
			var parts: PackedStringArray = []
			if rel.has("bond"):
				parts.append("bond %+.0f" % rel["bond"])
			if rel.has("trust"):
				parts.append("trust %+.0f" % rel["trust"])
			if rel.has("rivalry"):
				parts.append("rivalry %+.0f" % rel["rivalry"])
			if rel.has("familiarity"):
				parts.append("fam %+.0f" % rel["familiarity"])
			print("[Sim] 💛 %s ↔ %s: %s (→%.0f %s)" % [
				character.char_name, target.char_name,
				", ".join(parts), bond_now, tier
			])


# ─────────────────────────────────────────────────────────────
# STAGE 7 — ECHO
# ─────────────────────────────────────────────────────────────

func _echo(character: CharData, _target, event_key: String,
		event_def: Dictionary, frame: Dictionary) -> String:

	var templates: Array = event_def.get("storybook_templates", [])
	var summary: String

	if templates.is_empty():
		summary = "%s → %s" % [character.char_name, event_key]
	else:
		var template: String = templates[randi() % templates.size()]
		summary = Context.fill_template(template, frame)

	# Target ID for memory lookups
	var target_id: String = ""
	if _target is CharData and _target.char_id != character.char_id:
			target_id = _target.char_id

	Memory.write_storybook(character, {
		"event_key":         event_key,
		"summary":           summary,
		"at_tick":           Clock.get_total_days(),
		"target_id":         target_id,
		"magnitude":         event_def.get("magnitude", "minor"),
		"memorable": event_def.get("magnitude", "minor") in ["moderate", "major", "huge"],
		"memory_tags":       event_def.get("memory_tags", []),
		"times_recalled":    0,
		"last_recalled_day": 0,
		"pinned_to_story":   false,
	})

	# Write short-term memory — auto-maps event category to memory category
	Memory.write_short_term_from_event(character, event_key, event_def, summary, target_id)

	return summary

# ─────────────────────────────────────────────────────────────
# AUTO-FIRE PASS
# Checks priority events before the weighted roll.
# If any eligible auto_fire event is found, fires the highest
# priority one and skips the normal pipeline for this tick.
# Returns true if an auto_fire event fired.
# ─────────────────────────────────────────────────────────────

func _run_auto_fire(character: CharData) -> bool:
	var candidates: Array = []

	for event_key in Events.get_events_by_trigger("auto_fire"):
		if _is_on_cooldown(character, event_key):
			continue
		var event_def: Dictionary = Events.get_event(event_key)
		if _check_requirements(character, event_def.get("requirements", {})):
			candidates.append([event_key, event_def.get("priority", 0)])

	if candidates.is_empty():
		return false

	# Sort by priority descending — highest fires first
	candidates.sort_custom(func(a, b): return a[1] > b[1])

	var event_key: String = candidates[0][0]
	var event_def: Dictionary = Events.get_event(event_key)

	var target = Context.resolve_target(character, event_def)
	var frame: Dictionary = Context.build_frame(character, target, event_def)

	var action_name: String = event_def.get("call_action", "")
	if action_name == "":
		return false

	var _result: String = Actions.call_action(action_name, character, target, frame)
	_apply_outcomes(character, target, event_def)
	
	var summary: String = _echo(character, target, event_key, event_def, frame)

	_set_cooldown(character, event_key, event_def)
	_event_counter += 1

	if Settings.debug_console_logging:
		print("[Sim] ⚡ %s → %s" % [character.char_name, summary])

	event_fired.emit(character.char_id, event_key, summary)
	return true

	# ─────────────────────────────────────────────────────────────
# SEQUENCES
# ─────────────────────────────────────────────────────────────

# Called when an invite action returns LOCK_SEQUENCE.
# Locks both participants into the sequence at beat 0.
func _start_sequence(initiator: CharData, responder: CharData, seq_key: String) -> void:
	if initiator.active_sequence != "" or responder.active_sequence != "":
		push_warning("[Sim] _start_sequence aborted — participant already in sequence.")
		return
	initiator.active_sequence   = seq_key
	initiator.sequence_beat     = 0
	initiator.sequence_role     = "initiator"
	initiator.sequence_partner_id = responder.char_id
	initiator.sequence_context  = {}

	responder.active_sequence   = seq_key
	responder.sequence_beat     = 0
	responder.sequence_role     = "responder"
	responder.sequence_partner_id = initiator.char_id
	responder.sequence_context  = {}

	if Settings.debug_console_logging:
		print("[Sim] 🎱 %s + %s locked into %s" % [
			initiator.char_name, responder.char_name, seq_key
		])


# Called each tick for the initiator of an active sequence.
# Fires the current beat, applies outcomes, writes storybook, advances.
func _advance_sequence(character: CharData) -> void:
	# ── Pool-type sequence dispatch ─────────────────────────
	var _seq_check: Dictionary = Sequences.get_sequence(character.active_sequence)
	if _seq_check.get("type", "") == "pool":
		_advance_pool_sequence(character)
		return
	var seq_key: String  = character.active_sequence
	var beat_id: int     = character.sequence_beat
	var beat: Dictionary = Sequences.get_beat(seq_key, beat_id)

	if beat.is_empty():
		push_warning("[Sim] Sequence %s beat %d not found — force-ending." % [seq_key, beat_id])
		var partner: CharData = Registry.get_character(character.sequence_partner_id)
		_end_sequence(character, partner)
		return

	var partner: CharData = Registry.get_character(character.sequence_partner_id)

	# Determine actor/target for this beat
	# "responder" role flips who acts. "both" uses initiator as actor.
	var actor: CharData  = character
	var other: CharData  = partner
	if beat.get("actor_role", "initiator") == "responder" and partner:
		actor = partner
		other = character

	# Call the beat's action (stub — outcomes are in the beat definition)
	var action_name: String = beat.get("call_action", "")
	if action_name != "":
		Actions.call_action(action_name, actor, other, character.sequence_context)

	# Apply outcomes defined on this beat
	if beat.has("outcomes"):
		_apply_outcomes(actor, other, beat)

	# Write storybook for this beat
	if beat.has("storybook_templates"):
		var frame: Dictionary = {
			"name":   actor.char_name,
			"target": other.char_name if other else "someone",
		}
		var templates: Array  = beat["storybook_templates"]
		var template: String  = templates[randi() % templates.size()]
		var summary: String   = Context.fill_template(template, frame)

		Memory.write_storybook(character, {
			"event_key":         seq_key + "_B" + str(beat_id),
			"summary":           summary,
			"at_tick":           Clock.get_total_days(),
			"target_id":         partner.char_id if partner else null,
			"magnitude":         "minor",
			"memorable":         false,
			"memory_tags":       [],
			"times_recalled":    0,
			"last_recalled_day": 0,
			"pinned_to_story":   false,
		})

		if Settings.debug_console_logging:
			print("[Sim] 🎱 %s (beat %d) → %s" % [seq_key, beat_id, summary])

		event_fired.emit(character.char_id, seq_key, summary)

	# Determine next beat
	var next_beat = "END"

	if beat.has("weighted_outcomes"):
		# Branch beat — roll weighted outcomes, store result in context
		var branch: Dictionary = _roll_sequence_branch(character, beat)
		next_beat = branch.get("next_beat", "END")
		var outcome_key: String = branch.get("outcome_key", "")
		character.sequence_context["outcome_key"] = outcome_key
		if partner:
			partner.sequence_context["outcome_key"] = outcome_key
	else:
		next_beat = beat.get("next_beat", "END")

	# Advance or end — next_beat can be int or "END" string, so convert to compare
	if str(next_beat) == "END":
		_end_sequence(character, partner)
	else:
		var next_id: int = int(next_beat)
		character.sequence_beat = next_id
		if partner:
			partner.sequence_beat = next_id

# If a character stopped mid-journey for a hallway conversation,
# resume movement to their saved destination.
func _resume_from_loiter(character: CharData) -> void:
	if not character.is_loitering:
		return
	character.is_loitering = false

	# Release hallway spot
	if character.loiter_hallway_id != "":
		Rooms.release_spot(character.loiter_hallway_id, character.char_id)
		if Settings.debug_console_logging:
			print("[Sim] 🛤️ %s released spot in %s/%s" % [
				character.char_name, character.loiter_hallway_id, character.loiter_lane])
		character.loiter_hallway_id = ""
		character.loiter_lane = ""

	var dest: String = character.loiter_return_room
	character.loiter_return_room = ""

	if dest == "" or dest == character.current_room:
		character.loiter_saved_waypoints = []
		return

	character.is_in_transit = true
	character.movement_target_room = dest

	# Use saved waypoints if available — avoids re-planning from a stale current_room.
	# Saved waypoints capture the journey exactly where it was interrupted.
	var saved: Array = character.loiter_saved_waypoints
	character.loiter_saved_waypoints = []

	if not saved.is_empty():
		_restart_from_saved_waypoints(character)
		if Settings.debug_console_logging:
			print("[Sim] 🚶 %s resuming journey → %s (saved waypoints)" % [
				character.char_name, dest])
	else:
		# Fallback: re-plan from current_room if no waypoints were saved
		Actions.start_movement(character, dest)
		if Settings.debug_console_logging:
			print("[Sim] 🚶 %s resuming journey → %s (re-planned)" % [
				character.char_name, dest])

# Weighted roll for a branch beat (e.g. beat 1 of PLAY_POOL_SEQ).
# Applies outcome-specific weight modifiers from the beat definition.
func _roll_sequence_branch(character: CharData, beat: Dictionary) -> Dictionary:
	var branches: Array   = beat.get("weighted_outcomes", [])
	var modifiers: Array  = beat.get("weight_modifiers", [])

	var pool: Array = []
	for branch in branches:
		var weight: float = float(branch.get("weight", 10))
		# Outcome-specific modifiers — only boost the named outcome_key
		for mod in modifiers:
			if mod.get("outcome") == branch.get("outcome_key", ""):
				var cond: Dictionary = mod.get("condition", {})
				if _check_beat_condition(character, cond):
					weight *= float(mod.get("multiply", 1.0))
		pool.append({ "branch": branch, "weight": weight })

	var total: float  = 0.0
	for entry in pool:
		total += entry["weight"]

	var roll: float    = randf() * total
	var running: float = 0.0
	for entry in pool:
		running += entry["weight"]
		if roll <= running:
			return entry["branch"]

	return pool[0]["branch"]


# Checks conditions used inside beat weight_modifiers.
# Separate from _check_requirements — beat conditions use different keys.
func _check_beat_condition(character: CharData, condition: Dictionary) -> bool:
	if condition.has("actor_has_trait"):
		for trait_key in condition["actor_has_trait"]:
			if not trait_key in character.get_all_active_traits():
				return false
	return true


# Clears all sequence fields on one character.
func _clear_sequence(character: CharData) -> void:
	character.active_sequence    = ""
	character.sequence_beat      = 0
	character.sequence_role      = ""
	character.sequence_partner_id = ""
	character.sequence_context   = {}


# Called when the final beat resolves. Clears both participants.
func _end_sequence(initiator: CharData, partner: CharData) -> void:
	if Settings.debug_console_logging:
		print("[Sim] ✅ %s ended for %s + %s" % [
			initiator.active_sequence,
			initiator.char_name,
			partner.char_name if partner else "unknown"
		])
	_clear_sequence(initiator)
	if partner:
		_clear_sequence(partner)
	# Resume journey if character was stopped in a hallway
	_resume_from_hallway(initiator)
	if partner:
		_resume_from_hallway(partner)

# If a character is in a hallway room after a sequence ends,
# re-plan their journey to the original destination.
func _resume_from_hallway(character: CharData) -> void:
	if not Rooms.is_hallway(character.current_room):
		return
	var dest: String = character.movement_target_room
	if dest == "" or dest == character.current_room:
		return
	# Release any hallway lane spots
	Rooms.release_all_spots(character.current_room, character.char_id)
	if Settings.debug_console_logging:
		print("[Sim] 🚶 %s resuming → %s (re-planned from %s)" % [
			character.char_name, dest, character.current_room])
	Actions.start_movement(character, dest)

# Checks if any interruptible auto_fire event is eligible for a locked character.
# If found: writes "cut short" storybook, clears sequence, fires the interrupt event.
# Returns true if an interrupt fired.
func _check_and_interrupt(character: CharData) -> bool:
	for event_key in Events.get_events_by_trigger("auto_fire"):
		var event_def: Dictionary = Events.get_event(event_key)
		if not event_def.get("can_interrupt_sequences", false):
			continue
		if _is_on_cooldown(character, event_key):
			continue
		if not _check_requirements(character, event_def.get("requirements", {})):
			continue

		# Found an interruptible event — write trace before clearing
		var partner: CharData = Registry.get_character(character.sequence_partner_id)
		var cut_short: String = "%s and %s's game was cut short." % [
			character.char_name,
			partner.char_name if partner else "their partner"
		]
		var trace: Dictionary = {
			"event_key":         "SEQUENCE_INTERRUPTED",
			"summary":           cut_short,
			"at_tick":           Clock.get_total_days(),
			"target_id":         character.sequence_partner_id,
			"magnitude":         "minor",
			"memorable":         false,
			"memory_tags":       [],
			"times_recalled":    0,
			"last_recalled_day": 0,
			"pinned_to_story":   false,
		}
		Memory.write_storybook(character, trace)
		if partner:
			Memory.write_storybook(partner, trace.duplicate())

		# Clear both
		_clear_sequence(character)
		if partner:
			_clear_sequence(partner)

		# Fire the interrupt event normally
		var target = Context.resolve_target(character, event_def)
		var frame: Dictionary = Context.build_frame(character, target, event_def)
		var action_name: String = event_def.get("call_action", "")
		if action_name != "":
			Actions.call_action(action_name, character, target, frame)
		_apply_outcomes(character, target, event_def)
		var summary: String = _echo(character, target, event_key, event_def, frame)
		_set_cooldown(character, event_key, event_def)
		_event_counter += 1

		if Settings.debug_console_logging:
			print("[Sim] ⚡ INTERRUPTED → %s → %s" % [character.char_name, summary])

		event_fired.emit(character.char_id, event_key, summary)
		return true

	return false

# ─────────────────────────────────────────────────────────────
# POOL SEQUENCES (CONVERSE_SEQ etc.)
# Variable-length sequences that roll from a weighted beat pool
# each tick. Mood tracked in sequence_context, resets on end.
# ─────────────────────────────────────────────────────────────

# Main driver — called every tick for the initiator of a pool sequence.
func _advance_pool_sequence(character: CharData) -> void:
	var seq_key: String = character.active_sequence
	var seq_def: Dictionary = Sequences.get_sequence(seq_key)
	var partner: CharData = Registry.get_character(character.sequence_partner_id)

	if partner == null:
		push_warning("[Sim] Pool sequence %s — partner gone, ending." % seq_key)
		_end_sequence(character, partner)
		return

	var ctx: Dictionary = character.sequence_context
	var beat_count: int = ctx.get("beat_count", 0)

	# ── OPENING BEAT (first tick) ───────────────────────────
	if beat_count == 0:
		_fire_converse_opening(character, partner, seq_key, seq_def)
		return

	# ── CONTINUE / END ROLL ─────────────────────────────────
	var mood: float = ctx.get("mood", 0.0)
	var base_continue: float = seq_def.get("continue_base_chance", 0.90)
	var decay: float = seq_def.get("continue_decay_per_beat", 0.12)
	var mood_end_bonus: float = seq_def.get("mood_end_bonus", 0.03)
	var mood_cont_bonus: float = seq_def.get("mood_continue_bonus", 0.01)

	# Beat count is the primary driver. Mood nudges slightly.
	var continue_chance: float = base_continue - (decay * beat_count)
	if mood < 0.0:
		continue_chance -= absf(mood) * mood_end_bonus
	elif mood > 0.0:
		continue_chance += mood * mood_cont_bonus
	continue_chance = clampf(continue_chance, 0.05, 0.95)

	if randf() > continue_chance:
		_end_pool_sequence(character, partner, seq_key, seq_def)
		return

	# ── ROLL BEAT FROM POOL ─────────────────────────────────
	var beat_key: String = _roll_converse_beat(character, partner, seq_def)
	if beat_key == "":
		# No eligible beats — end the conversation
		_end_pool_sequence(character, partner, seq_key, seq_def)
		return

	# Find the beat definition (could be in beat_pool or escalation_pool)
	var beat_def: Dictionary = Sequences.get_beat_from_pool(seq_key, beat_key)

	# ── FIRE BEAT ACTION ────────────────────────────────────
	var action_name: String = beat_def.get("call_action", "")
	if action_name != "":
		Actions.call_action(action_name, character, partner, ctx)

	# ── UPDATE MOOD ─────────────────────────────────────────
	var mood_delta: float = beat_def.get("mood_delta", 0.0)
	mood = clampf(ctx.get("mood", 0.0) + mood_delta, -100.0, 100.0)
	ctx["mood"] = mood
	ctx["beat_count"] = beat_count + 1

	# Track mood over time for arc detection at summary
	if not ctx.has("mood_history"):
		ctx["mood_history"] = []
	ctx["mood_history"].append(mood)

	# ── STORYBOOK ───────────────────────────────────────────
	var last_beat: String = ctx.get("last_beat_key", "")
	var templates: Array
	if beat_key == last_beat and beat_def.has("continued_templates"):
		templates = beat_def["continued_templates"]
	else:
		templates = beat_def.get("storybook_templates", [])

	if not templates.is_empty():
		var frame: Dictionary = {
			"name": character.char_name,
			"target": partner.char_name,
			"topic": ctx.get("topic", "nothing in particular"),
		}
		var template: String = templates[randi() % templates.size()]
		var summary: String = Context.fill_template(template, frame)

		Memory.write_storybook(character, {
			"event_key":         seq_key + "_" + beat_key,
			"summary":           summary,
			"at_tick":           Clock.get_total_days(),
			"target_id":         partner.char_id,
			"magnitude":         "minor",
			"memorable":         false,
			"memory_tags":       ["conversation"],
			"times_recalled":    0,
			"last_recalled_day": 0,
			"pinned_to_story":   false,
		})

		if Settings.debug_console_logging:
			print("[Sim] 💬 %s (beat %d, mood %.0f) → %s" % [
				seq_key, beat_count, mood, summary])

		event_fired.emit(character.char_id, seq_key, summary)

	ctx["last_beat_key"] = beat_key

	# ── ESCALATION END CHECK ────────────────────────────────
	# Some beats (SPIT_ON etc.) have a chance to end the conversation.
	var end_chance: float = beat_def.get("ends_conversation_chance", 0.0)
	if end_chance > 0.0 and randf() < end_chance:
		if Settings.debug_console_logging:
			print("[Sim] 💬 %s escalation ended conversation" % beat_key)
		_end_pool_sequence(character, partner, seq_key, seq_def)
		return

	# Sync context to partner so both have the same mood/state
	if partner:
		partner.sequence_context = ctx.duplicate(true)


# Fires the first beat — picks a topic and writes the opening line.
func _fire_converse_opening(character: CharData, partner: CharData,
		seq_key: String, seq_def: Dictionary) -> void:
	var ctx: Dictionary = character.sequence_context

	# Pick topic tone based on relationship
	var bond: float = Relationships.get_bond(character.char_id, partner.char_id)
	var tone: String = "neutral"
	if bond > 20:
		tone = ["positive", "neutral", "neutral"][randi() % 3]
	elif bond < -10:
		tone = ["negative", "neutral", "neutral"][randi() % 3]

	var topic: String = Sequences.get_conversation_topic(tone)
	ctx["topic"] = topic
	ctx["mood"] = 0.0
	ctx["beat_count"] = 1
	ctx["last_beat_key"] = ""
	ctx["mood_history"] = [0.0]

	# Fire opening action
	var opening: Dictionary = seq_def.get("opening_beat", {})
	var action_name: String = opening.get("call_action", "")
	if action_name != "":
		Actions.call_action(action_name, character, partner, ctx)

	# Write storybook
	var templates: Array = opening.get("storybook_templates", [])
	if not templates.is_empty():
		var frame: Dictionary = {
			"name": character.char_name,
			"target": partner.char_name,
			"topic": topic,
		}
		var template: String = templates[randi() % templates.size()]
		var summary: String = Context.fill_template(template, frame)

		Memory.write_storybook(character, {
			"event_key":         seq_key + "_OPEN",
			"summary":           summary,
			"at_tick":           Clock.get_total_days(),
			"target_id":         partner.char_id,
			"magnitude":         "minor",
			"memorable":         false,
			"memory_tags":       ["conversation"],
			"times_recalled":    0,
			"last_recalled_day": 0,
			"pinned_to_story":   false,
		})

		if Settings.debug_console_logging:
			print("[Sim] 💬 %s OPEN → %s" % [seq_key, summary])

		event_fired.emit(character.char_id, seq_key, summary)

	# Sync to partner
	if partner:
		partner.sequence_context = ctx.duplicate(true)


# Rolls a beat from the conversation pool. Returns beat_key or "" if none eligible.
func _roll_converse_beat(character: CharData, partner: CharData,
		seq_def: Dictionary) -> String:
	var ctx: Dictionary = character.sequence_context
	var beat_count: int = ctx.get("beat_count", 0)
	var min_escalation: int = seq_def.get("escalation_min_beats", 4)

	var pool: Array = []  # Array of [beat_key, weight]

	# Add conversation beats
	for beat_key in seq_def.get("beat_pool", {}).keys():
		var beat_def: Dictionary = seq_def["beat_pool"][beat_key]
		if not _check_converse_reqs(character, partner, beat_def, ctx):
			continue
		var weight: float = _apply_converse_mods(character, partner, beat_def, ctx)
		if weight > 0.0:
			pool.append([beat_key, weight])

	# Add escalation beats after minimum beat count
	if beat_count >= min_escalation:
		for beat_key in seq_def.get("escalation_pool", {}).keys():
			var beat_def: Dictionary = seq_def["escalation_pool"][beat_key]
			if not _check_converse_reqs(character, partner, beat_def, ctx):
				continue
			var weight: float = _apply_converse_mods(character, partner, beat_def, ctx)
			if weight > 0.0:
				pool.append([beat_key, weight])

	if pool.is_empty():
		return ""

	# Weighted roll
	var total: float = 0.0
	for entry in pool:
		total += entry[1]

	var roll: float = randf() * total
	var running: float = 0.0
	for entry in pool:
		running += entry[1]
		if roll <= running:
			return entry[0]

	return pool[0][0]


# Checks beat-specific requirements (mood, relationship with partner, etc.)
func _check_converse_reqs(character: CharData, partner: CharData,
		beat_def: Dictionary, ctx: Dictionary) -> bool:
	var reqs: Dictionary = beat_def.get("requirements", {})
	if reqs.is_empty():
		return true

	var mood: float = ctx.get("mood", 0.0)

	if reqs.has("mood_above"):
		if mood <= float(reqs["mood_above"]):
			return false
	if reqs.has("mood_below"):
		if mood >= float(reqs["mood_below"]):
			return false

	# Bond with conversation partner (not room occupants)
	if reqs.has("relationship_bond_above"):
		if Relationships.get_bond(character.char_id, partner.char_id) <= float(reqs["relationship_bond_above"]):
			return false
	if reqs.has("relationship_bond_below"):
		if Relationships.get_bond(character.char_id, partner.char_id) >= float(reqs["relationship_bond_below"]):
			return false

	# Gossip — character has something to share with this target
	if reqs.has("has_gossipable_memory") and reqs["has_gossipable_memory"]:
		var entry = Memory.pick_gossipable_entry(character, partner)
		if entry == null:
			return false

	# Shared interests between the two characters
	if reqs.has("shares_interest_with_target") and reqs["shares_interest_with_target"]:
		var found: bool = false
		for interest in character.interests:
			if interest in partner.interests:
				found = true
				break
		if not found:
			return false

	# Standard trait/feeling checks
	if reqs.has("has_trait"):
		for trait_key in reqs["has_trait"]:
			if not trait_key in character.get_all_active_traits():
				return false
	if reqs.has("has_feeling"):
		for feeling_key in reqs["has_feeling"]:
			if not FeelingDriver.has_feeling(character, feeling_key):
				return false

	return true


# Applies weight modifiers for a conversation beat.
# Handles mood, traits, feelings, relationship, time_of_day.
func _apply_converse_mods(character: CharData, partner: CharData,
		beat_def: Dictionary, ctx: Dictionary) -> float:
	var weight: float = beat_def.get("base_weight", 10.0)
	var mood: float = ctx.get("mood", 0.0)

	for modifier in beat_def.get("weight_modifiers", []):
		var cond: Dictionary = modifier.get("condition", {})
		var matched: bool = true

		if cond.has("mood_above"):
			if mood <= float(cond["mood_above"]):
				matched = false
		if cond.has("mood_below"):
			if mood >= float(cond["mood_below"]):
				matched = false
		if cond.has("has_trait"):
			for trait_key in cond["has_trait"]:
				if not trait_key in character.get_all_active_traits():
					matched = false
					break
		if cond.has("has_feeling"):
			if not FeelingDriver.has_feeling(character, cond["has_feeling"]):
				matched = false
		if cond.has("relationship_bond_above"):
			if Relationships.get_bond(character.char_id, partner.char_id) <= float(cond["relationship_bond_above"]):
				matched = false
		if cond.has("relationship_bond_below"):
			if Relationships.get_bond(character.char_id, partner.char_id) >= float(cond["relationship_bond_below"]):
				matched = false
		if cond.has("time_of_day"):
			if not Clock.get_time_of_day() in cond["time_of_day"]:
				matched = false

		if matched:
			weight *= modifier.get("multiply", 1.0)

	return weight


# Ends a pool sequence: picks end beat, writes summary, applies final deltas.
func _end_pool_sequence(character: CharData, partner: CharData,
		seq_key: String, seq_def: Dictionary) -> void:
	var ctx: Dictionary = character.sequence_context
	var mood: float = ctx.get("mood", 0.0)
	var beat_count: int = ctx.get("beat_count", 1)

	# ── PICK END BEAT ───────────────────────────────────────
	var end_key: String = _roll_converse_end(character, seq_def.get("end_pool", {}), mood)
	var end_def: Dictionary = seq_def.get("end_pool", {}).get(end_key, {})

	# Write end beat storybook
	var end_templates: Array = end_def.get("storybook_templates", [])
	if not end_templates.is_empty():
		var frame: Dictionary = {
			"name": character.char_name,
			"target": partner.char_name if partner else "someone",
			"topic": ctx.get("topic", "nothing"),
		}
		var template: String = end_templates[randi() % end_templates.size()]
		var summary: String = Context.fill_template(template, frame)

		Memory.write_storybook(character, {
			"event_key":         seq_key + "_END_" + end_key,
			"summary":           summary,
			"at_tick":           Clock.get_total_days(),
			"target_id":         partner.char_id if partner else "",
			"magnitude":         "minor",
			"memorable":         false,
			"memory_tags":       ["conversation"],
			"times_recalled":    0,
			"last_recalled_day": 0,
			"pinned_to_story":   false,
		})

		if Settings.debug_console_logging:
			print("[Sim] 💬 %s END (%s, mood %.0f) → %s" % [
				seq_key, end_key, mood, summary])

		event_fired.emit(character.char_id, seq_key, summary)

	# ── WRITE SUMMARY ───────────────────────────────────────
	_write_converse_summary(character, partner, seq_key, seq_def)

	# ── FINAL RELATIONSHIP DELTAS ───────────────────────────
	if partner:
		# Mood maps loosely to bond: +100 mood ≈ +15 bond, -100 ≈ -15
		var bond_delta: float = mood * 0.15
		var fam_delta: float = 2.0 + mini(beat_count, 6) * 0.5
		Relationships.modify_bond(character.char_id, partner.char_id, bond_delta)
		Relationships.modify_familiarity(character.char_id, partner.char_id, fam_delta)

		if mood > 20.0:
			Relationships.modify_trust(character.char_id, partner.char_id, 3.0)
		elif mood < -20.0:
			Relationships.modify_trust(character.char_id, partner.char_id, -3.0)
			Relationships.modify_rivalry(character.char_id, partner.char_id, 2.0)

		if Settings.debug_console_logging:
			print("[Sim] 💬 %s ↔ %s: convo done (mood %.0f, bond %+.1f, fam +%.1f)" % [
				character.char_name, partner.char_name, mood, bond_delta, fam_delta])

	# ── STAT EFFECTS ────────────────────────────────────────
	# Base loneliness/boredom reduction scales with length (capped)
	var capped_beats: int = mini(beat_count, 6)
	Actions.modify_stat(character, "loneliness", -4.0 * capped_beats)
	Actions.modify_stat(character, "boredom", -2.0 * capped_beats)
	if partner:
		Actions.modify_stat(partner, "loneliness", -3.0 * capped_beats)
		Actions.modify_stat(partner, "boredom", -2.0 * capped_beats)

	# Mood-dependent: good chats reduce stress, bad ones add it
	if mood > 10.0:
		Actions.modify_stat(character, "stress", -5.0)
		Actions.modify_stat(character, "happiness", 5.0)
		if partner:
			Actions.modify_stat(partner, "stress", -4.0)
			Actions.modify_stat(partner, "happiness", 4.0)
	elif mood < -10.0:
		Actions.modify_stat(character, "stress", 8.0)
		Actions.modify_stat(character, "happiness", -5.0)
		if partner:
			Actions.modify_stat(partner, "stress", 6.0)
			Actions.modify_stat(partner, "happiness", -4.0)

	_end_sequence(character, partner)


# Rolls from the end pool, weighted by mood.
func _roll_converse_end(character: CharData, end_pool: Dictionary, mood: float) -> String:
	var pool: Array = []

	for end_key in end_pool.keys():
		var end_def: Dictionary = end_pool[end_key]
		var weight: float = end_def.get("base_weight", 10.0)

		for modifier in end_def.get("weight_modifiers", []):
			var cond: Dictionary = modifier.get("condition", {})
			var matched: bool = true

			if cond.has("mood_above"):
				if mood <= float(cond["mood_above"]):
					matched = false
			if cond.has("mood_below"):
				if mood >= float(cond["mood_below"]):
					matched = false
			if cond.has("has_trait"):
				for trait_key in cond["has_trait"]:
					if not trait_key in character.get_all_active_traits():
						matched = false
						break

			if matched:
				weight *= modifier.get("multiply", 1.0)

		if weight > 0.0:
			pool.append([end_key, weight])

	if pool.is_empty():
		return "NATURAL_GOODBYE"

	var total: float = 0.0
	for entry in pool:
		total += entry[1]

	var roll: float = randf() * total
	var running: float = 0.0
	for entry in pool:
		running += entry[1]
		if roll <= running:
			return entry[0]

	return pool[0][0]


# Writes the conversation summary. Detects the arc (positive, soured, recovery, etc.)
# and picks a matching template. Only flagged memorable if mood crossed the threshold.
func _write_converse_summary(character: CharData, partner: CharData,
		seq_key: String, seq_def: Dictionary) -> void:
	var ctx: Dictionary = character.sequence_context
	var mood: float = ctx.get("mood", 0.0)
	var mood_history: Array = ctx.get("mood_history", [])
	var threshold: float = seq_def.get("memorable_mood_threshold", 40.0)

	# Detect the arc
	var arc: String = _detect_converse_arc(mood, mood_history)

	var summary_pool: Dictionary = seq_def.get("summary_templates", {})
	var templates: Array = summary_pool.get(arc,
		summary_pool.get("neutral", ["{name} and {target} talked."]))
	if templates.is_empty():
		templates = ["{name} and {target} talked."]

	var frame: Dictionary = {
		"name": character.char_name,
		"target": partner.char_name if partner else "someone",
		"topic": ctx.get("topic", "nothing"),
	}
	var template: String = templates[randi() % templates.size()]
	var summary: String = Context.fill_template(template, frame)

	var is_memorable: bool = absf(mood) >= threshold

	# Write on both characters
	var entry: Dictionary = {
		"event_key":         seq_key + "_SUMMARY",
		"summary":           summary,
		"at_tick":           Clock.get_total_days(),
		"target_id":         partner.char_id if partner else "",
		"magnitude":         "moderate" if is_memorable else "minor",
		"memorable":         is_memorable,
		"memory_tags":       ["conversation", "summary"],
		"times_recalled":    0,
		"last_recalled_day": 0,
		"pinned_to_story":   false,
	}

	Memory.write_storybook(character, entry)
	if partner:
		var partner_entry: Dictionary = entry.duplicate()
		partner_entry["target_id"] = character.char_id
		Memory.write_storybook(partner, partner_entry)

	if Settings.debug_console_logging:
		print("[Sim] 💬 SUMMARY (%s, mood %.0f%s) → %s" % [
			arc, mood, " ⭐" if is_memorable else "", summary])


# Figures out the conversation arc from mood history.
func _detect_converse_arc(final_mood: float, mood_history: Array) -> String:
	if mood_history.size() < 2:
		if final_mood > 20.0: return "positive"
		if final_mood < -20.0: return "negative"
		return "neutral"

	# Check early mood vs final mood for arc detection
	var early_index: int = mini(2, mood_history.size() - 1)
	var early_mood: float = mood_history[early_index]

	if early_mood < -10.0 and final_mood > 10.0:
		return "recovery"
	if early_mood > 10.0 and final_mood < -10.0:
		return "soured"

	if final_mood > 30.0: return "very_positive"
	if final_mood > 10.0: return "positive"
	if final_mood < -30.0: return "very_negative"
	if final_mood < -10.0: return "negative"
	return "neutral"

# ─────────────────────────────────────────────────────────────
# REPETITION BOREDOM
# If the same event appears in the last 4 storybook entries,
# add boredom. Traits like GAMBLER/ALCOHOLIC are exempt for
# their preferred activities.
# ─────────────────────────────────────────────────────────────

func _apply_repetition_boredom(character: CharData, event_key: String) -> void:
	var event_def: Dictionary = Events.get_event(event_key)

	# Always-exempt events (navigation, one-offs) — never generate boredom
	if event_def.get("boredom_exempt", false):
		return

	# Trait-conditional exemptions — exempt if character has any listed trait
	var exempt_traits: Array = event_def.get("boredom_exempt_traits", [])
	for trait_key in exempt_traits:
		if trait_key in character.get_all_active_traits():
			return

	var recent: Array = character.storybook.slice(
		max(0, character.storybook.size() - 4),
		character.storybook.size()
	)
	var repeat_count: int = 0
	for entry in recent:
		if entry.get("event_key", "") == event_key:
			repeat_count += 1

	if repeat_count >= 2:
		var boredom_delta: float = 5.0 * repeat_count
		Actions.modify_stat(character, "boredom", boredom_delta)
		if Settings.debug_console_logging:
			print("[Sim] 😒 %s bored of %s (+%.0f boredom)" % [
				character.char_name, event_key, boredom_delta
			])

# ─────────────────────────────────────────────────────────────
# PROXIMITY EVENTS
# Fired by movement_controller when two in-transit characters
# pass each other in a hallway. Light events don't interrupt,
# heavy events pause both briefly.
# ─────────────────────────────────────────────────────────────

# ─────────────────────────────────────────────────────────────
# HALLWAY EVENTS
# Characters passing through a hallway get a limited event check.
# Only events with allow_hallway: true can fire.
# ─────────────────────────────────────────────────────────────

func _run_hallway_check(character: CharData) -> void:
	# Don't fire events while physically inside an elevator car
	if character.is_riding_elevator:
		return
	var eligible: Array = _get_eligible_hallway_events(character)
	if eligible.is_empty():
		return

	var event_key: String = _weighted_roll(character, eligible)
	if event_key == "" or _is_on_cooldown(character, event_key):
		return

	var event_def: Dictionary = Events.get_event(event_key)
	var target = Context.resolve_target(character, event_def)
	var frame: Dictionary = Context.build_frame(character, target, event_def)

	var action_name: String = event_def.get("call_action", "")
	if action_name == "":
		return

	var result: String = Actions.call_action(action_name, character, target, frame)

	if result == Actions.LOCK_SEQUENCE:
		var seq_key: String = event_def.get("sequence_key", "")
		if seq_key != "" and target is CharData:
			if target.movement_target_room == "":
				return
			_set_cooldown(character, event_key, event_def)  # ← add this
			_set_cooldown(target, event_key, event_def)     # ← and this
			var pos_a: Vector3 = character.zone_target_pos
			var pos_b: Vector3 = target.zone_target_pos
			_stop_character_movement(character)
			_stop_character_movement(target)
			character.zone_target_pos = pos_a
			target.zone_target_pos = pos_b
			_start_sequence(character, target, seq_key)
	return

	_apply_outcomes(character, target, event_def)
	var summary: String = _echo(character, target, event_key, event_def, frame)
	_set_cooldown(character, event_key, event_def)
	_event_counter += 1

	if Settings.debug_console_logging:
		print("[Sim] 🚶 HALLWAY → %s + %s → %s" % [
			character.char_name,
			target.char_name if target is CharData else "",
			summary])

	event_fired.emit(character.char_id, event_key, summary)


func _get_eligible_hallway_events(character: CharData) -> Array:
	# Only fire if character has a real destination to return to
	if character.movement_target_room == "":
		return []
	var eligible: Array = []
	for event_key in Events.get_events_by_trigger("rolled"):
		var event_def: Dictionary = Events.get_event(event_key)
		if not event_def.get("allow_hallway", false):
			continue
		if _check_requirements(character, event_def.get("requirements", {})):
			eligible.append(event_key)
	return eligible


# Stops a character's movement and marks them as no longer in transit.
# Preserves movement_target_room so we can re-plan on sequence end.
func _stop_character_movement(character: CharData) -> void:
	if not character.is_in_transit:
		return
	character.is_in_transit = false
	var container = get_node_or_null("/root/main/Building/Characters")
	if container == null:
		return
	for body in container.get_children():
		if "char_data" in body and body.char_data.char_id == character.char_id:
			if body.has_method("cancel_movement"):
				body.cancel_movement()
			return

func fire_proximity_event(actor: CharData, target: CharData) -> void:
	var eligible: Array = _get_eligible_proximity_events(actor, target)
	if eligible.is_empty():
		return

	var event_key: String = _weighted_roll(actor, eligible)
	if event_key == "":
		return

	if _is_on_cooldown(actor, event_key):
		return

	var event_def: Dictionary = Events.get_event(event_key)
	var frame: Dictionary = Context.build_frame(actor, target, event_def)

	var action_name: String = event_def.get("call_action", "")
	if action_name != "":
		var result: String = Actions.call_action(action_name, actor, target, frame)
		if result == Actions.LOCK_SEQUENCE:
			var seq_key: String = event_def.get("sequence_key", "")
			if seq_key != "" and target is CharData:
				# Save waypoints BEFORE stop_movement() clears them
				_save_loiter_waypoints(actor)
				_save_loiter_waypoints(target)
				_start_sequence(actor, target, seq_key)
				if actor.zone_target_pos != Vector3.ZERO:
					_tween_character_to_spot(actor, actor.zone_target_pos)
					actor.zone_target_pos = Vector3.ZERO
				if target.zone_target_pos != Vector3.ZERO:
					_tween_character_to_spot(target, target.zone_target_pos)
					target.zone_target_pos = Vector3.ZERO
			return

	_apply_outcomes(actor, target, event_def)
	var summary: String = _echo(actor, target, event_key, event_def, frame)
	_set_cooldown(actor, event_key, event_def)
	_event_counter += 1

	# ── PROXIMITY PAUSE for heavy events ────────────────────
	if event_def.get("proximity_type", "light") == "heavy":
		var pause_duration: float = 4.0 if event_key == "HALLWAY_CHAT" else 6.0
		_pause_character_movement(actor, pause_duration)
		_pause_character_movement(target, pause_duration)

	if Settings.debug_console_logging:
		print("[Sim] 🚶 PROXIMITY → %s + %s → %s" % [
			actor.char_name, target.char_name, summary
		])

	event_fired.emit(actor.char_id, event_key, summary)


func _pause_character_movement(character: CharData, duration: float) -> void:
	# Find the character's body node and call pause_for_proximity on its movement controller
	var container = get_node_or_null("/root/main/Building/Characters")
	if container == null:
		return
	for body in container.get_children():
		if "char_data" in body and body.char_data.char_id == character.char_id:
			var ctrl = body.get_node_or_null("MovementController")
			if ctrl and ctrl.has_method("pause_for_proximity"):
				ctrl.pause_for_proximity(duration)
			return

# Cancels a character's movement and tweens them to a spot position.
# Used after locking into a hallway conversation sequence.
func _tween_character_to_spot(character: CharData, target_pos: Vector3) -> void:
	var container = get_node_or_null("/root/main/Building/Characters")
	if container == null:
		return
	for body in container.get_children():
		if "char_data" in body and body.char_data.char_id == character.char_id:
			var ctrl = body.get_node_or_null("MovementController")
			if ctrl and ctrl.has_method("cancel_and_tween_to"):
				ctrl.cancel_and_tween_to(target_pos)
			elif ctrl and ctrl.has_method("stop_movement"):
				ctrl.stop_movement()
			return

func _get_eligible_proximity_events(actor: CharData, _target: CharData) -> Array:
	var eligible: Array = []
	for event_key in Events.get_events_by_trigger("proximity"):
		var event_def: Dictionary = Events.get_event(event_key)
		if _check_requirements(actor, event_def.get("requirements", {})):
			eligible.append(event_key)
	return eligible

# Saves the movement controller's remaining waypoints to CharData
# before the controller is stopped for a loiter.
func _save_loiter_waypoints(character: CharData) -> void:
	var container = get_node_or_null("/root/main/Building/Characters")
	if container == null:
		return
	for body in container.get_children():
		if "char_data" in body and body.char_data.char_id == character.char_id:
			var ctrl = body.get_node_or_null("MovementController")
			if ctrl and ctrl.has_method("get_remaining_waypoints"):
				character.loiter_saved_waypoints = ctrl.get_remaining_waypoints()
			return


# Restarts movement using saved waypoints rather than re-planning from current_room.
func _restart_from_saved_waypoints(character: CharData) -> void:
	var container = get_node_or_null("/root/main/Building/Characters")
	if container == null:
		return
	for body in container.get_children():
		if "char_data" in body and body.char_data.char_id == character.char_id:
			var ctrl = body.get_node_or_null("MovementController")
			if ctrl:
				ctrl.start_movement(character.loiter_saved_waypoints)
			return
