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
#   - Context.resolve_target() for targeting
#   - Actions.call_action() for execution
#   - Stat outcomes applied from event definition
#   - Storybook entry written on each event
#   - Console logging with storybook text
#
# Not yet: intent queue, sequences, player gate, auto-fire pass

extends Node

# Emitted after each event fires — EventInspector listens to this
signal event_fired(char_id: String, event_key: String, summary: String)


func _ready() -> void:
	Clock.tick.connect(_on_tick)
	print("[Sim] Loaded. Listening to Clock.tick.")


func _on_tick() -> void:
	for character in Registry.get_all():
		if not character.is_actionable():
			continue
		_run_pipeline(character)


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

	var _result: String = Actions.call_action(action_name, character, target, frame)

	# ── 6. EXECUTE ──────────────────────────────────────────
	_apply_outcomes(character, target, event_def)

	# ── 7. ECHO ─────────────────────────────────────────────
	var summary: String = _echo(character, target, event_key, event_def, frame)

	# ── LOG ─────────────────────────────────────────────────
	if Settings.debug_console_logging:
		print("[Sim] %s → %s" % [character.char_name, summary])

	event_fired.emit(character.char_id, event_key, summary)


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
# Applies stat deltas and feelings from the event definition.
# Note: stat changes from call_action (Actions) already applied.
# Outcomes here are the event-level deltas on top of that.
# ─────────────────────────────────────────────────────────────

func _apply_outcomes(character: CharData, target, event_def: Dictionary) -> void:
	var outcomes: Dictionary = event_def.get("outcomes", {})

	# Actor stat deltas
	if outcomes.has("stats"):
		for stat_key in outcomes["stats"]:
			Actions.modify_stat(character, stat_key, outcomes["stats"][stat_key])

	# Target stat deltas
	if outcomes.has("target_stats") and target is CharData:
		for stat_key in outcomes["target_stats"]:
			Actions.modify_stat(target, stat_key, outcomes["target_stats"][stat_key])

	# Feelings pushed onto actor
	if outcomes.has("feelings"):
		for feeling_key in outcomes["feelings"]:
			FeelingDriver.push(character, feeling_key, {
				"event_key": event_def.get("call_action", "unknown"),
				"at_tick": Clock.get_total_days(),
				"summary": "outcome of %s" % event_def.get("call_action", "event"),
			})

	# Feelings pushed onto target
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
# Writes a storybook entry. Returns the summary string for logging.
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

	# Write to storybook
	character.storybook.append({
		"event_key":        event_key,
		"summary":          summary,
		"at_tick":          Clock.get_total_days(),
		"target_id":        null,
		"magnitude":        event_def.get("magnitude", "minor"),
		"memorable":        event_def.get("magnitude", "minor") in ["major", "huge"],
		"memory_tags":      [],
		"times_recalled":   0,
		"last_recalled_day": 0,
		"pinned_to_story":  false,
	})

	return summary