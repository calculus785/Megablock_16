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
		# Sequence advance — before is_actionable check.
		if character.active_sequence != "" and character.sequence_role == "initiator":
			if not _check_and_interrupt(character):
				_advance_sequence(character)
			continue
		if not character.is_actionable():
			continue

		# ── INTENT PROCESSING ───────────────────────────────
		# Tick patience on all intents. Any that hit 0 fire GIVE_UP.
		var expired: Array = Memory.tick_intents(character)
		for expired_key in expired:
			_fire_give_up(character, expired_key)

		# If character still has intents, try to fire the top one.
		# If it can't fire (requirements not met), fall through to normal pipeline.
		if Memory.has_intents(character):
			if _try_fire_intent(character):
				continue

		# ── NORMAL PIPELINE ─────────────────────────────────
		if _run_auto_fire(character):
			continue
		_run_pipeline(character)

func _on_half_hour() -> void:
	# Restore energy for sleeping characters each half-hour tick
	# 8 energy per tick × ~16 ticks in a night = full restore from empty
	for character in Registry.get_all():
		if character.is_sleeping:
			Actions.modify_stat(character, "energy", 8.0)


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

	# other_character_in_room — at least one other character must share the room
	# NOTE: uses Registry directly — Rooms.get_occupants() is a Phase 3 shell.
	# Phase 3: replace this loop with Rooms.get_occupants(character.current_room)
	if reqs.has("other_character_in_room") and reqs["other_character_in_room"]:
		var others_present := false
		for other in Registry.get_all():
			if other.char_id != character.char_id and \
					other.current_room == character.current_room:
				others_present = true
				break
		if not others_present:
			return false
	
	# has_memorable_entries — character must have at least one memorable storybook entry
	if reqs.has("has_memorable_entries") and reqs["has_memorable_entries"]:
		var memorable: Array = Memory.get_memorable_entries(character)
		if memorable.is_empty():
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
	if _target is CharData:
		target_id = _target.char_id

	Memory.write_storybook(character, {
		"event_key":         event_key,
		"summary":           summary,
		"at_tick":           Clock.get_total_days(),
		"target_id":         target_id,
		"magnitude":         event_def.get("magnitude", "minor"),
		"memorable": event_def.get("magnitude", "minor") in ["moderate", "major", "huge"],
		"memory_tags":       [],
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
