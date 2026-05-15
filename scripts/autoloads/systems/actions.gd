# actions.gd
# Autoload — available globally as Actions
# Tier 3 Systems — reads Tier 1 + 2
#
# Every action function called by Sim during the ACT stage lives here.
# Functions receive (character, target, args) and return a result string.
#
# Results:
#   DONE           — event complete, move on
#   REPEAT         — fire same event again next tick
#   LOCK_SEQUENCE  — start a multi-beat sequence (Phase 1+)

extends Node

const DONE := "DONE"
const REPEAT := "REPEAT"
const LOCK_SEQUENCE := "LOCK_SEQUENCE"


func _ready() -> void:
	print("[Actions] Loaded.")


# ─────────────────────────────────────────────────────────────
# DISPATCHER
# Sim calls this. We route to the right function by name.
# ─────────────────────────────────────────────────────────────

func call_action(action_name: String, character: CharData, target, args: Dictionary) -> String:
	match action_name:
		"rest":                    return _rest(character, target, args)
		"wander":                  return _wander(character, target, args)
		"think_about":             return _think_about(character, target, args)
		"queue_intent_visit_bar":  return _queue_intent_visit_bar(character, target, args)
		"order_drink":             return _order_drink(character, target, args)
		"daydream":         return _daydream(character, target, args)
		"cry":              return _cry(character, target, args)
		"late_night_stare": return _late_night_stare(character, target, args)
		"pace_hallway":     return _pace_hallway(character, target, args)
		"look_in_mirror":   return _look_in_mirror(character, target, args)
		"nod_in_passing":   return _nod_in_passing(character, target, args)
		"greet":            return _greet(character, target, args)
		"chat":             return _chat(character, target, args)
		"compliment":       return _compliment(character, target, args)
		"insult":           return _insult(character, target, args)
		"sleep":                       return _sleep(character, target, args)
		"argue":                       return _argue(character, target, args)
		"deep_conversation":           return _deep_conversation(character, target, args)
		"queue_intent_visit_library":  return _queue_intent_visit_library(character, target, args)
		"read_book":                   return _read_book(character, target, args)
		"drink_alone":                 return _drink_alone(character, target, args)
		"flirt":                       return _flirt(character, target, args)
		"start_pool_game":  return _start_pool_game(character, target, args)
		"rack_pool_balls":  return _rack_pool_balls(character, target, args)
		"play_pool_round":  return _play_pool_round(character, target, args)
		"pool_victory":     return _pool_victory(character, target, args)
		_:
			push_warning("[Actions] Unknown action: '%s'" % action_name)
			return DONE


# ─────────────────────────────────────────────────────────────
# HELPER — modify a stat safely
# ─────────────────────────────────────────────────────────────

func modify_stat(character: CharData, stat_key: String, delta: float) -> void:
	if not character.stats.has(stat_key):
		return
	character.stats[stat_key] = Stats.clamp_stat(
		stat_key,
		character.stats[stat_key] + delta
	)


# ─────────────────────────────────────────────────────────────
# ACTION IMPLEMENTATIONS
# ─────────────────────────────────────────────────────────────

func _rest(character: CharData, _target, _args: Dictionary) -> String:
	modify_stat(character, "energy", 5.0)
	modify_stat(character, "stress", -3.0)
	modify_stat(character, "boredom", 5.0)
	return DONE


func _wander(character: CharData, target, _args: Dictionary) -> String:
	# target is a room_id string resolved by Context
	if target is String and target != "":
		character.current_room = target
	modify_stat(character, "boredom", -10.0)
	return DONE


func _think_about(character: CharData, _target, _args: Dictionary) -> String:
	# No memories yet — stub applies a small boredom reduction.
	# Full implementation Phase 2 when Memory is built.
	modify_stat(character, "boredom", -5.0)
	return DONE


func _queue_intent_visit_bar(character: CharData, _target, _args: Dictionary) -> String:
	# No intent queue yet — stub reduces boredom (anticipation effect).
	# Full implementation Phase 2.
	modify_stat(character, "boredom", -5.0)
	return DONE


func _order_drink(character: CharData, _target, _args: Dictionary) -> String:
	modify_stat(character, "cash", -5.0)
	modify_stat(character, "stress", -8.0)
	modify_stat(character, "happiness", 5.0)
	# ADDICT_PRONE gets double the addiction climb
	var addiction_delta: float = 5.0 \
		if "ADDICT_PRONE" in character.get_all_active_traits() \
		else 2.0
	modify_stat(character, "addiction", addiction_delta)
	return DONE

func _daydream(character: CharData, _target, _args: Dictionary) -> String:
	modify_stat(character, "boredom", -15.0)
	modify_stat(character, "stress", -5.0)
	return DONE


func _cry(character: CharData, _target, _args: Dictionary) -> String:
	# Stress relief despite everything else getting worse
	modify_stat(character, "stress", -10.0)
	modify_stat(character, "loneliness", 10.0)
	return DONE


func _late_night_stare(character: CharData, _target, _args: Dictionary) -> String:
	modify_stat(character, "stress", -5.0)
	modify_stat(character, "boredom", -5.0)
	return DONE


func _pace_hallway(character: CharData, _target, _args: Dictionary) -> String:
	modify_stat(character, "stress", -8.0)
	modify_stat(character, "energy", -3.0)
	modify_stat(character, "boredom", -5.0)
	return DONE


func _look_in_mirror(character: CharData, _target, _args: Dictionary) -> String:
	modify_stat(character, "stress", -3.0)
	return DONE


func _nod_in_passing(character: CharData, _target, _args: Dictionary) -> String:
	modify_stat(character, "loneliness", -3.0)
	return DONE


func _greet(character: CharData, target, _args: Dictionary) -> String:
	modify_stat(character, "loneliness", -8.0)
	if target is CharData:
		modify_stat(target, "loneliness", -5.0)
	return DONE


func _chat(character: CharData, target, _args: Dictionary) -> String:
	modify_stat(character, "loneliness", -12.0)
	modify_stat(character, "boredom", -10.0)
	modify_stat(character, "stress", -5.0)
	if target is CharData:
		modify_stat(target, "loneliness", -8.0)
		modify_stat(target, "boredom", -8.0)
	return DONE


func _compliment(character: CharData, target, _args: Dictionary) -> String:
	modify_stat(character, "happiness", 3.0)
	if target is CharData:
		modify_stat(target, "happiness", 8.0)
		modify_stat(target, "stress", -5.0)
	return DONE


func _insult(character: CharData, target, _args: Dictionary) -> String:
	modify_stat(character, "stress", -8.0)
	if target is CharData:
		modify_stat(target, "stress", 15.0)
		modify_stat(target, "happiness", -10.0)
	return DONE

func _sleep(character: CharData, _target, _args: Dictionary) -> String:
	# Sim._try_wake() handles the wake-up check each tick
	# Sim._on_half_hour() restores energy while sleeping
	character.is_sleeping = true
	return DONE


func _argue(character: CharData, target, _args: Dictionary) -> String:
	# Stress spikes for both — arguing makes things worse short term
	modify_stat(character, "stress", 10.0)
	if target is CharData:
		modify_stat(target, "stress", 15.0)
		modify_stat(target, "happiness", -10.0)
	return DONE


func _deep_conversation(character: CharData, target, _args: Dictionary) -> String:
	modify_stat(character, "loneliness", -25.0)
	modify_stat(character, "stress", -10.0)
	if target is CharData:
		modify_stat(target, "loneliness", -20.0)
		modify_stat(target, "stress", -8.0)
	return DONE


func _queue_intent_visit_library(character: CharData, _target, _args: Dictionary) -> String:
	# Stub — same pattern as visit_bar until intent queue is built in Phase 2
	modify_stat(character, "boredom", -5.0)
	return DONE


func _read_book(character: CharData, _target, _args: Dictionary) -> String:
	modify_stat(character, "boredom", -20.0)
	modify_stat(character, "stress", -10.0)
	modify_stat(character, "happiness", 5.0)
	return DONE


func _drink_alone(character: CharData, _target, _args: Dictionary) -> String:
	modify_stat(character, "stress", -5.0)
	modify_stat(character, "loneliness", 8.0)
	modify_stat(character, "cash", -5.0)
	modify_stat(character, "addiction", 2.0)
	return DONE


func _flirt(character: CharData, target, _args: Dictionary) -> String:
	# No attraction check yet — Phase 4 Relationships adds compatibility logic
	# For now: both get a happiness bump, drama emerges from the sim naturally
	modify_stat(character, "happiness", 5.0)
	if target is CharData:
		modify_stat(target, "happiness", 5.0)
	return DONE

# ─────────────────────────────────────────────────────────────
# POOL SEQUENCE
# ─────────────────────────────────────────────────────────────

# Consent check. Rolls against target's traits/stats.
# Returns LOCK_SEQUENCE if accepted, DONE if refused.
func _start_pool_game(character: CharData, target, _args: Dictionary) -> String:
	if not target is CharData:
		return DONE
	if target.active_sequence != "": 
		return DONE
	var accept_chance: float = 50.0
	var target_traits: Array = target.get_all_active_traits()

	if "SOCIAL" in target_traits:      accept_chance += 20.0
	if "ANTISOCIAL" in target_traits:  accept_chance -= 30.0
	if "COMPETITIVE" in target_traits: accept_chance += 15.0
	if "SHY" in target_traits:         accept_chance -= 10.0
	if target.stats.get("boredom", 0.0) > 50.0: accept_chance += 15.0
	if target.stats.get("stress", 0.0) > 60.0:  accept_chance -= 20.0

	accept_chance = clamp(accept_chance, 5.0, 95.0)

	if randf() * 100.0 > accept_chance:
		# Refused — initiator's reaction depends on their traits
		var my_traits: Array = character.get_all_active_traits()
		if "INSECURE" in my_traits or "SHY" in my_traits:
			FeelingDriver.push(character, "HUMILIATED", {
				"event_key": "start_pool_game",
				"at_tick":   Clock.get_total_days(),
				"summary":   "%s said no to pool." % target.char_name,
			})
		elif "COMPETITIVE" in my_traits:
			FeelingDriver.push(character, "FRUSTRATED", {
				"event_key": "start_pool_game",
				"at_tick":   Clock.get_total_days(),
				"summary":   "%s refused a game." % target.char_name,
			})
		else:
			modify_stat(character, "stress", 3.0)

		if Settings.debug_console_logging:
			print("[Sim] 🚫 %s asked %s to play pool — refused." % [
				character.char_name, target.char_name
			])
		return DONE

	return LOCK_SEQUENCE


# Beat 0 — rack balls. Outcomes in beat definition.
func _rack_pool_balls(_character: CharData, _target, _args: Dictionary) -> String:
	return DONE


# Beat 1 — play round. Winner decided by Sim's weighted branch roll.
func _play_pool_round(_character: CharData, _target, _args: Dictionary) -> String:
	return DONE


# Beats 2/3 — victory/loss feelings in beat definition.
func _pool_victory(_character: CharData, _target, _args: Dictionary) -> String:
	return DONE