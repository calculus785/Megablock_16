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
		# ── Grocery ──────────────────────────────────────
		"check_supplies":          return _check_supplies(character, target, args)
		# ── Social (any room with others) ────────────────
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
	character.is_sleeping = true
	return DONE


# ═════════════════════════════════════════════════════════════
# HOME — apartment events
# ═════════════════════════════════════════════════════════════

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


func _order_food(_character: CharData, _target, _args: Dictionary) -> String:
	return DONE


func _order_coffee(_character: CharData, _target, _args: Dictionary) -> String:
	return DONE


func _sit_alone_cafe(_character: CharData, _target, _args: Dictionary) -> String:
	return DONE


func _share_meal(_character: CharData, _target, _args: Dictionary) -> String:
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
	Memory.add_active_impression(character, "bookshelf")
	modify_stat(character, "boredom", -20.0)
	modify_stat(character, "stress", -10.0)
	modify_stat(character, "happiness", 5.0)
	return DONE


func _browse_shelves(character: CharData, _target, _args: Dictionary) -> String:
	_move_to_zone(character, "Zone_Shelves")
	Memory.add_active_impression(character, "bookshelf")
	return DONE


func _window_watch(character: CharData, _target, _args: Dictionary) -> String:
	_move_to_zone(character, "Zone_Window")
	return DONE


func _study_together(_character: CharData, _target, _args: Dictionary) -> String:
	return DONE


func _quiet_moment_together(_character: CharData, _target, _args: Dictionary) -> String:
	return DONE


# ═════════════════════════════════════════════════════════════
# GROCERY
# ═════════════════════════════════════════════════════════════

func _check_supplies(character: CharData, _target, _args: Dictionary) -> String:
	_move_to_zone(character, "Zone_Aisles")
	return DONE


# ═════════════════════════════════════════════════════════════
# SOCIAL — any room with other characters
# ═════════════════════════════════════════════════════════════

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
	if target is CharData:
		modify_stat(target, "happiness", 5.0)
	return DONE


func _confront(character: CharData, _target, _args: Dictionary) -> String:
	FeelingDriver.remove(character, "FURIOUS")
	return DONE


func _gossip(_character: CharData, _target, _args: Dictionary) -> String:
	return DONE


func _reminisce_together(character: CharData, _target, _args: Dictionary) -> String:
	var result = Memory.pick_random_memorable(character)
	if result:
		Memory.recall_entry(character, result["index"])
	return DONE


func _spill_drink(_character: CharData, _target, _args: Dictionary) -> String:
	return DONE


func _physical_fight(_character: CharData, _target, _args: Dictionary) -> String:
	return DONE
