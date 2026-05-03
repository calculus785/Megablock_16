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