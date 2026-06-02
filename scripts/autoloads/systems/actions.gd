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
		# ── Universal ────────────────────────────────────
		"rest":                    return _rest(character, target, args)
		"go_home":                 return _go_home(character, target, args)
		"wander":                  return _wander(character, target, args)
		"daydream":                return _daydream(character, target, args)
		"think_about":             return _think_about(character, target, args)
		"brood":                   return _brood(character, target, args)
		"smile_at_memory":         return _smile_at_memory(character, target, args)
		"cry":                     return _cry(character, target, args)
		"pace_hallway":            return _pace_hallway(character, target, args)
		"late_night_stare":        return _late_night_stare(character, target, args)
		"sleep":                   return _sleep(character, target, args)
		"energy_crash":            return _energy_crash(character, target, args)
		# ── Home ─────────────────────────────────────────
		"look_in_mirror":          return _look_in_mirror(character, target, args)
		"lie_in_bed":              return _lie_in_bed(character, target, args)
		"cook_meal":               return _cook_meal(character, target, args)
		# ── Bar ──────────────────────────────────────────
		"queue_intent_visit_bar":  return _queue_intent_visit_bar(character, target, args)
		"order_drink":             return _order_drink(character, target, args)
		"drink_alone":             return _drink_alone(character, target, args)
		"sit_at_bar":              return _sit_at_bar(character, target, args)
		"lean_on_counter":         return _lean_on_counter(character, target, args)
		"nurse_drink":             return _nurse_drink(character, target, args)
		"hang_at_lounge":          return _hang_at_lounge(character, target, args)
		"watch_the_room":          return _watch_the_room(character, target, args)
		# ── Bar — Pool sequence ──────────────────────────
		"start_pool_game":         return _start_pool_game(character, target, args)
		"rack_pool_balls":         return _rack_pool_balls(character, target, args)
		"play_pool_round":         return _play_pool_round(character, target, args)
		"pool_victory":            return _pool_victory(character, target, args)
		# ── Cafe ─────────────────────────────────────────
		"queue_intent_visit_cafe": return _queue_intent_visit_cafe(character, target, args)
		"order_food":              return _order_food(character, target, args)
		"order_coffee":            return _order_coffee(character, target, args)
		"sit_alone_cafe":          return _sit_alone_cafe(character, target, args)
		"share_meal":              return _share_meal(character, target, args)
		# ── Library ──────────────────────────────────────
		"queue_intent_visit_library": return _queue_intent_visit_library(character, target, args)
		"read_book":               return _read_book(character, target, args)
		"browse_shelves":          return _browse_shelves(character, target, args)
		"window_watch":            return _window_watch(character, target, args)
		"study_together":          return _study_together(character, target, args)
		"quiet_moment_together":   return _quiet_moment_together(character, target, args)
		"admire_statue":           return _admire_statue(character, target, args)
		# ── Grocery ──────────────────────────────────────
		"queue_intent_visit_grocery": return _queue_intent_visit_grocery(character, target, args)
		"check_supplies":          return _check_supplies(character, target, args)
		# ── Social (any room with others) ────────────────
		"brief_conversation": return _brief_conversation(character, target, args)
		"sit_at_bar":         return _sit_at_bar(character, target, args)
		"lean_on_counter":    return _lean_on_counter(character, target, args)
		"browse_shelves":     return _browse_shelves(character, target, args)
		"window_watch":       return _window_watch(character, target, args)
		"lie_in_bed":         return _lie_in_bed(character, target, args)
		"check_supplies":     return _check_supplies(character, target, args)
		"hallway_nod":        return _hallway_nod(character, target, args)
		"hallway_chat":       return _hallway_chat(character, target, args)
		"awkward_pass":       return _awkward_pass(character, target, args)
		"hallway_bump":       return _hallway_bump(character, target, args)
		"nod_in_passing":          return _nod_in_passing(character, target, args)
		"greet":                   return _greet(character, target, args)
		"chat":                    return _chat(character, target, args)
		"compliment":              return _compliment(character, target, args)
		"insult":                  return _insult(character, target, args)
		"argue":                   return _argue(character, target, args)
		"deep_conversation":       return _deep_conversation(character, target, args)
		"flirt":                   return _flirt(character, target, args)
		"confront":                return _confront(character, target, args)
		"gossip":                  return _gossip(character, target, args)
		"reminisce_together":      return _reminisce_together(character, target, args)
		"spill_drink":             return _spill_drink(character, target, args)
		"physical_fight":          return _physical_fight(character, target, args)
		"check_fridge":   return _check_fridge(character, target, args)
		"sit_at_desk":    return _sit_at_desk(character, target, args)
		"eat_at_home":    return _eat_at_home(character, target, args)
		"ask_out":                 return _ask_out(character, target, args)
		"apologise":               return _apologise(character, target, args)
		"share_story":             return _share_story(character, target, args)
		"vent_to_friend":          return _vent_to_friend(character, target, args)
		_:
			push_warning("[Actions] Unknown action: '%s'" % action_name)
			return DONE


# ─────────────────────────────────────────────────────────────
# HELPERS
# ─────────────────────────────────────────────────────────────

func modify_stat(character: CharData, stat_key: String, delta: float) -> void:
	if not character.stats.has(stat_key):
		return
	character.stats[stat_key] = Stats.clamp_stat(
		stat_key,
		character.stats[stat_key] + delta
	)

func modify_faction(character: CharData, faction: String, delta: float) -> void:
	var current: float = character.faction_sentiment.get(faction, 50.0)
	character.faction_sentiment[faction] = clampf(current + delta, 0.0, 100.0)
	if Settings.debug_console_logging:
		print("[Actions] 🏛 %s faction %s %+.0f (→%.0f)" % [
			character.char_name, faction, delta,
			character.faction_sentiment[faction]
		])
# ── MOVEMENT — room to room ─────────────────────────────────

func start_movement(character: CharData, dest_room: String) -> void:
	if dest_room == character.current_room:
		return

	var waypoints: Array = Pathfinder.plan_route(character.current_room, dest_room)
	if waypoints.is_empty():
		push_warning("[Actions] No route: %s → %s" % [character.current_room, dest_room])
		return

	character.is_in_transit = true
	character.movement_target_room = dest_room
	character.waypoints = waypoints
	character.waypoint_index = 0

	if Settings.debug_console_logging:
		print("[Actions] %s moving: %s → %s" % [
			character.char_name, character.current_room, dest_room
		])


# ── MOVEMENT — zone spot (inside a room) ────────────────────
# Releases any previously held spot, claims the new one,
# sets zone_target_pos so character_body tweens there.
# Returns true if a spot was claimed, false if zone is full.

func _move_to_zone(character: CharData, zone_name: String) -> bool:
	# Release any spot this character already holds in this room
	Rooms.release_all_spots(character.current_room, character.char_id)

	var spot: Dictionary = Rooms.get_available_spot(character.current_room, zone_name)
	if spot.is_empty():
		if Settings.debug_console_logging:
			print("[Actions] ⛔ %s → %s full in %s" % [
				character.char_name, zone_name, character.current_room
			])
		return false

	Rooms.claim_spot(character.current_room, zone_name, spot["name"], character.char_id)
	character.zone_target_pos = spot["pos"]

	if Settings.debug_console_logging:
		print("[Actions] 📍 %s → %s/%s in %s" % [
			character.char_name, zone_name, spot["name"], character.current_room
		])
	return true


# Move a target character to a zone spot (used by pool sequence etc.)
func _move_target_to_zone(target: CharData, zone_name: String) -> bool:
	if not target is CharData:
		return false
	return _move_to_zone(target, zone_name)


# ── MEMORY HELPERS ───────────────────────────────────────────

func _get_memory_tone(entry: Dictionary) -> String:
	var event_key: String = entry.get("event_key", "")
	var event_def: Dictionary = Events.get_event(event_key)
	if event_def.is_empty():
		return "neutral"
	var outcomes: Dictionary = event_def.get("outcomes", {})
	var stats: Dictionary = outcomes.get("stats", {})
	var happiness: float = stats.get("happiness", 0.0)
	var stress: float = stats.get("stress", 0.0)
	var net: float = happiness - stress
	if net > 0.0:
		return "positive"
	elif net < 0.0:
		return "negative"
	return "neutral"


func _pick_wander_destination(character: CharData) -> String:
	var options: Array = []
	for room_id in Rooms.get_all_room_ids():
		if room_id == character.current_room:
			continue
		var room_type: String = Rooms.get_room_type(room_id)
		if room_type == "lobby":
			continue
		if room_type == "apartment" and room_id != character.home_room:
			continue
		options.append(room_id)
	if options.is_empty():
		return ""
	return options[randi() % options.size()]


# ═════════════════════════════════════════════════════════════
# UNIVERSAL — fire for any character, anywhere
# ═════════════════════════════════════════════════════════════

func _rest(character: CharData, _target, _args: Dictionary) -> String:
	modify_stat(character, "energy", 5.0)
	modify_stat(character, "stress", -3.0)
	modify_stat(character, "boredom", 5.0)
	return DONE


func _go_home(character: CharData, _target, _args: Dictionary) -> String:
	if character.current_room == character.home_room:
		return DONE
	start_movement(character, character.home_room)
	return DONE


func _wander(character: CharData, _target, _args: Dictionary) -> String:
	var dest: String = _pick_wander_destination(character)
	if dest == "":
		return DONE
	start_movement(character, dest)
	return DONE


func _daydream(character: CharData, _target, _args: Dictionary) -> String:
	modify_stat(character, "boredom", -15.0)
	modify_stat(character, "stress", -5.0)
	return DONE


func _think_about(character: CharData, _target, _args: Dictionary) -> String:
	var result = Memory.pick_random_memorable(character)
	if result == null:
		modify_stat(character, "boredom", -5.0)
		return DONE
 
	Memory.recall_entry(character, result["index"])
	var entry: Dictionary = result["entry"]
	var tone: String = _get_memory_tone(entry)
 
	# Check if the memory involves someone we have a relationship with
	var target_id: String = entry.get("target_id", "")
	if target_id != "" and target_id != character.char_id:
		var bond: float = Relationships.get_bond(character.char_id, target_id)
		var rivalry: float = Relationships.get_rivalry(character.char_id, target_id)
		var target_char: CharData = Registry.get_character(target_id)
		var target_name: String = target_char.char_name if target_char else "someone"
 
		# High bond — warm memories
		if bond >= 30.0:
			modify_stat(character, "happiness", 5.0)
			modify_stat(character, "loneliness", -8.0)
			if tone == "positive":
				Relationships.set_directional_feeling(
					character.char_id, target_id, "AFFECTIONATE", 1.0)
				FeelingDriver.push(character, "CONTENT_FEELING", {
					"event_key": "think_about_fondly",
					"at_tick": Clock.get_total_days(),
					"summary": "thinking fondly about %s" % target_name,
				})
			return DONE
 
		# Negative bond — bitter memories
		if bond <= -20.0:
			modify_stat(character, "stress", 5.0)
			modify_stat(character, "happiness", -3.0)
			Relationships.set_directional_feeling(
				character.char_id, target_id, "BITTER", 1.0)
			return DONE
 
		# High rivalry — resentful regardless of bond
		if rivalry >= 20.0:
			modify_stat(character, "stress", 3.0)
			Relationships.set_directional_feeling(
				character.char_id, target_id, "RESENTFUL", 1.0)
			return DONE
 
	# No relationship context — fall back to tone-based response (original logic)
	match tone:
		"positive":
			modify_stat(character, "happiness", 5.0)
			modify_stat(character, "loneliness", -5.0)
		"negative":
			modify_stat(character, "stress", 5.0)
			modify_stat(character, "happiness", -3.0)
		_:
			modify_stat(character, "boredom", -5.0)
	return DONE


func _brood(character: CharData, _target, _args: Dictionary) -> String:
	var result = Memory.pick_random_memorable(character)
	if result:
		Memory.recall_entry(character, result["index"])
	modify_stat(character, "stress", 5.0)
	modify_stat(character, "happiness", -5.0)
	return DONE


func _smile_at_memory(character: CharData, _target, _args: Dictionary) -> String:
	var result = Memory.pick_random_memorable(character)
	if result:
		Memory.recall_entry(character, result["index"])
	modify_stat(character, "happiness", 5.0)
	modify_stat(character, "stress", -3.0)
	return DONE


func _cry(character: CharData, _target, _args: Dictionary) -> String:
	modify_stat(character, "stress", -10.0)
	modify_stat(character, "loneliness", 10.0)
	return DONE


func _pace_hallway(character: CharData, _target, _args: Dictionary) -> String:
	modify_stat(character, "stress", -8.0)
	modify_stat(character, "energy", -3.0)
	modify_stat(character, "boredom", -5.0)
	return DONE


func _late_night_stare(character: CharData, _target, _args: Dictionary) -> String:
	modify_stat(character, "stress", -5.0)
	modify_stat(character, "boredom", -5.0)
	return DONE


func _sleep(character: CharData, _target, _args: Dictionary) -> String:
	_move_to_zone(character, "Zone_Bed")
	character.is_sleeping = true
	return DONE

func _energy_crash(character: CharData, _target, _args: Dictionary) -> String:
	if character.current_room == character.home_room:
		# Home — sleep in bed
		_move_to_zone(character, "Zone_Bed")
		character.is_sleeping = true
		return DONE
 
	# Not home — go home, queue critical sleep intent
	start_movement(character, character.home_room)
	Memory.push_intent(character, {
		"intent_key": "SLEEP",
		"priority": "critical",
		"patience": 99,
		"clearable": false,
	})
	return DONE

# ═════════════════════════════════════════════════════════════
# HOME — apartment events
# ═════════════════════════════════════════════════════════════

func _check_fridge(character: CharData, _target, _args: Dictionary) -> String:
	_move_to_zone(character, "Zone_Fridge")
	return DONE


func _sit_at_desk(character: CharData, _target, _args: Dictionary) -> String:
	_move_to_zone(character, "Zone_Desk")
	return DONE


func _eat_at_home(character: CharData, _target, _args: Dictionary) -> String:
	_move_to_zone(character, "Zone_Fridge")
	return DONE

func _look_in_mirror(character: CharData, _target, _args: Dictionary) -> String:
	modify_stat(character, "stress", -3.0)
	return DONE


func _lie_in_bed(character: CharData, _target, _args: Dictionary) -> String:
	_move_to_zone(character, "Zone_Bed")
	return DONE


func _cook_meal(_character: CharData, _target, _args: Dictionary) -> String:
	return DONE


# ═════════════════════════════════════════════════════════════
# BAR — counter, lounge, pool, drinking
# ═════════════════════════════════════════════════════════════

func _queue_intent_visit_bar(character: CharData, _target, _args: Dictionary) -> String:
	character.trait_progress["bar_visits"] = character.trait_progress.get("bar_visits", 0) + 1
	var bar_rooms: Array = Rooms.get_rooms_by_type("bar")
	if not bar_rooms.is_empty():
		start_movement(character, bar_rooms[0])
	Memory.clear_intents(character)

	var patience: int = 15
	var my_traits: Array = character.get_all_active_traits()
	if "STUBBORN" in my_traits:   patience += 10
	if "LAZY" in my_traits:       patience -= 5
	if "ALCOHOLIC" in my_traits:  patience += 15

	Memory.push_intent(character, {
		"intent_key": "ORDER_DRINK",
		"priority": "normal",
		"target_id": "",
		"patience": patience,
		"clearable": true,
	})
	Memory.push_intent(character, {
		"intent_key": "ORDER_DRINK",
		"priority": "normal",
		"target_id": "",
		"patience": patience + 5,
		"clearable": true,
	})
	modify_stat(character, "boredom", -5.0)
	return DONE


func _order_drink(character: CharData, _target, _args: Dictionary) -> String:
	character.trait_progress["drinks_at_bar"] = character.trait_progress.get("drinks_at_bar", 0) + 1
	_move_to_zone(character, "Zone_Counter")
	Memory.add_active_impression(character, "bar_counter")
	modify_stat(character, "cash", -5.0)
	modify_stat(character, "stress", -8.0)
	modify_stat(character, "happiness", 5.0)
	var addiction_delta: float = 5.0 \
		if "ADDICT_PRONE" in character.get_all_active_traits() \
		else 2.0
	modify_stat(character, "addiction", addiction_delta)
	return DONE


func _drink_alone(character: CharData, _target, _args: Dictionary) -> String:
	character.trait_progress["drinks_at_bar"] = character.trait_progress.get("drinks_at_bar", 0) + 1
	_move_to_zone(character, "Zone_Counter")
	Memory.add_active_impression(character, "bar_counter")
	modify_stat(character, "stress", -5.0)
	modify_stat(character, "loneliness", 8.0)
	modify_stat(character, "cash", -5.0)
	modify_stat(character, "addiction", 2.0)
	return DONE


func _sit_at_bar(character: CharData, _target, _args: Dictionary) -> String:
	_move_to_zone(character, "Zone_Counter")
	Memory.add_active_impression(character, "bar_counter")
	return DONE


func _lean_on_counter(_character: CharData, _target, _args: Dictionary) -> String:
	# Already at Zone_Counter (in_zone requirement enforces this)
	return DONE


func _nurse_drink(_character: CharData, _target, _args: Dictionary) -> String:
	# Already at Zone_Counter (in_zone requirement enforces this)
	Memory.add_active_impression(_character, "bar_counter")
	return DONE


func _hang_at_lounge(character: CharData, _target, _args: Dictionary) -> String:
	_move_to_zone(character, "Zone_Lounge")
	return DONE


func _watch_the_room(character: CharData, _target, _args: Dictionary) -> String:
	var current_zone: String = Rooms.get_character_zone(character.current_room, character.char_id)
	if current_zone == "":
		# Only try Zone_Lounge if it exists in this room
		if not Rooms.get_zone(character.current_room, "Zone_Lounge").is_empty():
			_move_to_zone(character, "Zone_Lounge")
	return DONE 


# ── BAR — Pool sequence ─────────────────────────────────────

func _start_pool_game(character: CharData, target, _args: Dictionary) -> String:
	if not target is CharData:
		return DONE
	if target.active_sequence != "":
		return DONE
	if target.is_in_transit:     # ← add this
		return DONE
	if character.is_in_transit:  # ← and this
		return DONE
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

	# Both players move to the pool table zone
	_move_to_zone(character, "Zone_Pool")
	_move_target_to_zone(target, "Zone_Pool")
	return LOCK_SEQUENCE


func _rack_pool_balls(character: CharData, target, _args: Dictionary) -> String:
	# Ensure both are at the pool table (safety)
	_move_to_zone(character, "Zone_Pool")
	if target is CharData:
		_move_target_to_zone(target, "Zone_Pool")
	return DONE


func _play_pool_round(character: CharData, target, _args: Dictionary) -> String:
	Memory.add_active_impression(character, "pool_table")
	if target is CharData:
		Memory.add_active_impression(target, "pool_table")
	return DONE


func _pool_victory(_character: CharData, _target, _args: Dictionary) -> String:
	return DONE


# ═════════════════════════════════════════════════════════════
# CAFE
# ═════════════════════════════════════════════════════════════

func _queue_intent_visit_cafe(character: CharData, _target, _args: Dictionary) -> String:
	var cafe_rooms: Array = Rooms.get_rooms_by_type("cafe")
	if not cafe_rooms.is_empty():
		start_movement(character, cafe_rooms[0])
	Memory.clear_intents(character)

	var patience: int = 12
	var my_traits: Array = character.get_all_active_traits()
	if "STUBBORN" in my_traits:     patience += 8
	if "LAZY" in my_traits:         patience -= 5
	if "BIG_APPETITE" in my_traits: patience += 5

	Memory.push_intent(character, {
		"intent_key": "ORDER_FOOD",
		"priority": "normal",
		"target_id": "",
		"patience": patience,
		"clearable": true,
	})
	modify_stat(character, "boredom", -5.0)
	return DONE

func _order_food(character: CharData, _target, _args: Dictionary) -> String:
	_move_to_zone(character, "Zone_Tables")
	return DONE

func _order_coffee(character: CharData, _target, _args: Dictionary) -> String:
	_move_to_zone(character, "Zone_Counter")
	return DONE

func _sit_alone_cafe(character: CharData, _target, _args: Dictionary) -> String:
	_move_to_zone(character, "Zone_Tables")
	return DONE

func _share_meal(character: CharData, target, _args: Dictionary) -> String:
	_move_to_zone(character, "Zone_Tables")
	if target is CharData:
		_move_target_to_zone(target, "Zone_Tables")
	return DONE


# ═════════════════════════════════════════════════════════════
# LIBRARY
# ═════════════════════════════════════════════════════════════

func _queue_intent_visit_library(character: CharData, _target, _args: Dictionary) -> String:
	var library_rooms: Array = Rooms.get_rooms_by_type("library")
	if not library_rooms.is_empty():
		start_movement(character, library_rooms[0])
	Memory.clear_intents(character)

	var patience: int = 12
	var my_traits: Array = character.get_all_active_traits()
	if "STUBBORN" in my_traits:  patience += 8
	if "LAZY" in my_traits:      patience -= 5

	Memory.push_intent(character, {
		"intent_key": "READ_BOOK",
		"priority": "normal",
		"target_id": "",
		"patience": patience,
		"clearable": true,
	})
	modify_stat(character, "boredom", -5.0)
	return DONE


func _read_book(character: CharData, _target, _args: Dictionary) -> String:
	character.trait_progress["books_read"] = character.trait_progress.get("books_read", 0) + 1
	_move_to_zone(character, "Zone_Shelves")
	Memory.add_active_impression(character, "bookshelf")
	modify_stat(character, "boredom", -20.0)
	modify_stat(character, "stress", -10.0)
	modify_stat(character, "happiness", 5.0)
	return DONE

func _admire_statue(character: CharData, _target, _args: Dictionary) -> String:
	_move_to_zone(character, "Zone_Statue")
	Memory.add_active_impression(character, "library_statue")
	modify_stat(character, "happiness", 5.0)
	modify_stat(character, "stress", -5.0)
	modify_stat(character, "boredom", -8.0)
	return DONE

func _browse_shelves(character: CharData, _target, _args: Dictionary) -> String:
	character.trait_progress["books_read"] = character.trait_progress.get("books_read", 0) + 1
	_move_to_zone(character, "Zone_Shelves")
	Memory.add_active_impression(character, "bookshelf")
	return DONE


func _window_watch(character: CharData, _target, _args: Dictionary) -> String:
	_move_to_zone(character, "Zone_Window")
	return DONE

func _study_together(character: CharData, target, _args: Dictionary) -> String:
	_move_to_zone(character, "Zone_Shelves")
	if target is CharData:
		_move_target_to_zone(target, "Zone_Shelves")
	return DONE

func _quiet_moment_together(character: CharData, target, _args: Dictionary) -> String:
	_move_to_zone(character, "Zone_Shelves")
	if target is CharData:
		_move_target_to_zone(target, "Zone_Shelves")
	return DONE
# ═════════════════════════════════════════════════════════════
# GROCERY
# ═════════════════════════════════════════════════════════════

func _queue_intent_visit_grocery(character: CharData, _target, _args: Dictionary) -> String:
	var grocery_rooms: Array = Rooms.get_rooms_by_type("grocery")
	if not grocery_rooms.is_empty():
		start_movement(character, grocery_rooms[0])
	Memory.clear_intents(character)
	Memory.push_intent(character, {
		"intent_key": "CHECK_SUPPLIES",
		"priority": "normal",
		"target_id": "",
		"patience": 10,
		"clearable": true,
	})
	modify_stat(character, "boredom", -5.0)
	return DONE

func _check_supplies(character: CharData, _target, _args: Dictionary) -> String:
	_move_to_zone(character, "Zone_Aisles")
	return DONE


# ═════════════════════════════════════════════════════════════
# SOCIAL — any room with other characters
# ═════════════════════════════════════════════════════════════
func _brief_conversation(_character: CharData, _target, _args: Dictionary) -> String:
	return DONE

func _hallway_nod(_character: CharData, _target, _args: Dictionary) -> String:
	return DONE

func _hallway_chat(_character: CharData, _target, _args: Dictionary) -> String:
	return DONE

func _awkward_pass(_character: CharData, _target, _args: Dictionary) -> String:
	return DONE

func _hallway_bump(_character: CharData, _target, _args: Dictionary) -> String:
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


func _argue(character: CharData, target, _args: Dictionary) -> String:
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


func _flirt(character: CharData, target, _args: Dictionary) -> String:
	modify_stat(character, "happiness", 5.0)
	if not target is CharData:
		return DONE
 
	modify_stat(target, "happiness", 3.0)
 
	# Roll reciprocate chance: base 50%, +20% if actor has CHARMING,
	# +15% if target has FLIRTATIOUS, -20% if target has bond < 10
	var chance: float = 0.50
	if "CHARMING" in character.get_all_active_traits():
		chance += 0.20
	if "FLIRTATIOUS" in target.get_all_active_traits():
		chance += 0.15
	if "SHY" in target.get_all_active_traits():
		chance -= 0.15
	var bond: float = Relationships.get_bond(character.char_id, target.char_id)
	if bond < 10.0:
		chance -= 0.20
 
	# Check if target is attracted to actor
	if not Identity.is_attracted_to(target.preference, character.pronouns):
		chance = 0.0  # can't reciprocate if not attracted
 
	chance = clampf(chance, 0.05, 0.95)
 
	if randf() < chance:
		# Reciprocated — push FLIRTY directional feeling on target toward actor
		Relationships.set_directional_feeling(
			target.char_id, character.char_id, "FLIRTY", 1.0)
		Relationships.modify_bond(character.char_id, target.char_id, 3.0)
		if Settings.debug_console_logging:
			print("[Actions] 💕 %s flirted with %s → reciprocated!" % [
				character.char_name, target.char_name])
	else:
		# Rejected — mild awkwardness
		modify_stat(character, "stress", 3.0)
		if Settings.debug_console_logging:
			print("[Actions] 💔 %s flirted with %s → not reciprocated" % [
				character.char_name, target.char_name])
 
	return DONE

func _ask_out(character: CharData, target, _args: Dictionary) -> String:
	if not target is CharData:
		return DONE
 
	# Acceptance chance: base 40%
	var chance: float = 0.40
	var bond: float = Relationships.get_bond(character.char_id, target.char_id)
 
	# Bond bonus: +1% per bond point above 60
	chance += (bond - 60.0) * 0.01
 
	# Target has FLIRTY feeling toward actor → big boost
	if Relationships.has_directional_feeling(target.char_id, character.char_id, "FLIRTY"):
		chance += 0.30
 
	# Target has AFFECTIONATE feeling toward actor → moderate boost
	if Relationships.has_directional_feeling(target.char_id, character.char_id, "AFFECTIONATE"):
		chance += 0.15
 
	# Attraction check — if target isn't attracted, auto-reject
	if not Identity.is_attracted_to(target.preference, character.pronouns):
		chance = 0.0
 
	# Target already partnered → very unlikely
	if Relationships.is_partnered(target.char_id):
		chance *= 0.1
 
	chance = clampf(chance, 0.05, 0.95)
 
	if randf() < chance:
		# ACCEPTED — set event-gated tier to ROMANTIC_INTEREST
		Relationships.set_event_gated_tier(
			character.char_id, target.char_id, "ROMANTIC_INTEREST")
		Relationships.modify_bond(character.char_id, target.char_id, 15.0)
		Relationships.modify_trust(character.char_id, target.char_id, 10.0)
 
		# Push feelings on both
		FeelingDriver.push(character, "ELATED", {
			"event_key": "ask_out_accepted",
			"at_tick": Clock.get_total_days(),
			"summary": "%s said yes" % target.char_name,
		})
		FeelingDriver.push(target, "ELATED", {
			"event_key": "ask_out_accepted",
			"at_tick": Clock.get_total_days(),
			"summary": "%s asked, and it felt right" % character.char_name,
		})
 
		# Set directional feelings
		Relationships.set_directional_feeling(
			character.char_id, target.char_id, "INFATUATED", 1.0)
		Relationships.set_directional_feeling(
			target.char_id, character.char_id, "INFATUATED", 1.0)
 
		if Settings.debug_console_logging:
			print("[Actions] 💕💕 %s asked %s out → ACCEPTED! → ROMANTIC_INTEREST" % [
				character.char_name, target.char_name])
	else:
		# REJECTED
		Relationships.modify_bond(character.char_id, target.char_id, -10.0)
		FeelingDriver.push(character, "HEARTBROKEN", {
			"event_key": "ask_out_rejected",
			"at_tick": Clock.get_total_days(),
			"summary": "%s said no" % target.char_name,
		})
		modify_stat(character, "happiness", -15.0)
		modify_stat(character, "stress", 10.0)
 
		if Settings.debug_console_logging:
			print("[Actions] 💔💔 %s asked %s out → REJECTED" % [
				character.char_name, target.char_name])
 
	return DONE

func _apologise(character: CharData, target, _args: Dictionary) -> String:
	if not target is CharData:
		return DONE
 
	modify_stat(character, "stress", -8.0)
 
	# Acceptance chance: base 50%, modified by bond
	var bond: float = Relationships.get_bond(character.char_id, target.char_id)
	var chance: float = 0.50
 
	# Bond modifier: easier to forgive near zero, harder deep negative
	chance += bond * 0.01  # e.g. bond -30 → -0.30, bond +10 → +0.10
 
	# Traits
	if "STUBBORN" in target.get_all_active_traits():
		chance -= 0.20
	if "FORGIVING" in target.get_all_active_traits():
		chance += 0.25
 
	chance = clampf(chance, 0.15, 0.90)
 
	if randf() < chance:
		# Accepted
		Relationships.modify_bond(character.char_id, target.char_id, 12.0)
		Relationships.modify_rivalry(character.char_id, target.char_id, -5.0)
		Relationships.modify_trust(character.char_id, target.char_id, 3.0)
		FeelingDriver.push(target, "CONTENT_FEELING", {
			"event_key": "apology_accepted",
			"at_tick": Clock.get_total_days(),
			"summary": "%s apologised, and meant it" % character.char_name,
		})
		# Clear grudge-type directional feelings
		Relationships.clear_directional_feeling(
			target.char_id, character.char_id, "BITTER")
		Relationships.clear_directional_feeling(
			target.char_id, character.char_id, "RESENTFUL")
 
		if Settings.debug_console_logging:
			print("[Actions] 🤝 %s apologised to %s → accepted" % [
				character.char_name, target.char_name])
	else:
		# Rejected
		Relationships.modify_bond(character.char_id, target.char_id, -5.0)
		FeelingDriver.push(character, "UPSET_FEELING", {
			"event_key": "apology_rejected",
			"at_tick": Clock.get_total_days(),
			"summary": "%s didn't accept the apology" % target.char_name,
		})
 
		if Settings.debug_console_logging:
			print("[Actions] ❌ %s apologised to %s → rejected" % [
				character.char_name, target.char_name])
 
	return DONE

func _share_story(_character: CharData, _target, _args: Dictionary) -> String:
	return DONE

func _vent_to_friend(character: CharData, target, _args: Dictionary) -> String:
	if target is CharData:
		# Venting builds trust — you showed vulnerability
		Relationships.modify_trust(character.char_id, target.char_id, 3.0)
	return DONE

func _confront(character: CharData, _target, _args: Dictionary) -> String:
	FeelingDriver.remove(character, "FURIOUS")
	return DONE


func _gossip(character: CharData, _target, _args: Dictionary) -> String:
	character.trait_progress["gossip_shared"] = character.trait_progress.get("gossip_shared", 0) + 1
	return DONE


func _reminisce_together(character: CharData, _target, _args: Dictionary) -> String:
	var result = Memory.pick_random_memorable(character)
	if result:
		Memory.recall_entry(character, result["index"])
	return DONE


func _spill_drink(_character: CharData, _target, _args: Dictionary) -> String:
	return DONE


func _physical_fight(character: CharData, _target, _args: Dictionary) -> String:
	character.trait_progress["fights"] = character.trait_progress.get("fights", 0) + 1
	return DONE
