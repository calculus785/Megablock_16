# context.gd
# Autoload — available globally as Context
# Tier 3 Systems — reads Tier 1 + 2
#
# Resolves event targets and frames context args for the pipeline.
# Two jobs:
#   1. resolve_target() — picks who/what the event acts on
#   2. build_frame()    — builds the dictionary of template variables
#   3. fill_template()  — replaces {placeholders} with frame values
#
# Template variables available after build_frame():
#
#   ACTOR:    {name}, {they}, {them}, {their}, {theirs}, {themself}
#             Capitalised: {They}, {Them}, {Their}, {Theirs}, {Themself}
#             Verb helpers: {s}, {es}, {have_has}, {are_is}, {were_was}
#
#   TARGET:   {target}, {target_they}, {target_them}, {target_their},
#             {target_theirs}, {target_themself}
#             Capitalised: {Target_they}, {Target_them}, etc.
#             Verb helpers: {target_s}, {target_es},
#             {target_have_has}, {target_are_is}, {target_were_was}
#
#   LOCATION: {room}  (pretty name like "the bar", not "bar_f1_s1")
#
# Verb helpers handle they/them plurality:
#   "{name} sit{s} down"        → "Sara sits down" (she/her)
#                                → "Kai sit down"   (they/them)
#   "{name} watch{es} the door" → "Marcus watches the door" (he/him)
#   "{They} {are_is} tired"     → "She is tired" / "They are tired"

extends Node

# ─────────────────────────────────────────────────────────────
# ROOM DISPLAY NAMES
# Maps the type prefix of a room ID to a readable string.
# Room IDs look like "bar_f1_s1" — we split on "_f" to get the type.
# ─────────────────────────────────────────────────────────────

const ROOM_DISPLAY_NAMES: Dictionary = {
	"bar":              "the bar",
	"cafe":             "the café",
	"library":          "the library",
	"cinema":           "the cinema",
	"shop":             "the shop",
	"gym":              "the gym",
	"laundry":          "the laundry",
	"rooftop":          "the rooftop",
	"lobby":            "the lobby",
	"hallway":          "the hallway",
	"police_station":   "the police station",
	"apartment":        "their apartment",
	"management":       "the management floor",
}


func _ready() -> void:
	print("[Context] Loaded. %d room display names." % ROOM_DISPLAY_NAMES.size())


# ─────────────────────────────────────────────────────────────
# TARGET RESOLUTION (unchanged from Phase 1 shell)
# ─────────────────────────────────────────────────────────────

func resolve_target(character: CharData, event_def: Dictionary):
	var resolution: Dictionary = event_def.get("target_resolution", {})
	var type: String = resolution.get("type", "none")

	match type:
		"self":
			return character
		"none":
			return null
		"room":
			var all_rooms := Rooms.get_all_room_ids()
			if all_rooms.is_empty():
				return "bar_f1_s1"
			all_rooms.erase(character.current_room)
			if all_rooms.is_empty():
				return null
			return all_rooms[randi() % all_rooms.size()]
		"character":
			# NOTE: uses Registry directly — Rooms.get_occupants() is a Phase 3 shell.
			# Phase 3: replace this with Rooms.get_occupants(character.current_room)
			var candidates: Array = []
			for other in Registry.get_all():
				if other.char_id != character.char_id and \
						other.current_room == character.current_room:
					candidates.append(other)
			if candidates.is_empty():
				return null
			return candidates[randi() % candidates.size()]
		"memory":
			# Pick a random memorable storybook entry and return the target character.
			# If the memory has no target, or the target is gone, return null
			# (template will use "someone" fallback).
			var result = Memory.pick_random_memorable(character)
			if result == null:
				return null
			var entry: Dictionary = result["entry"]
			var target_id: String = entry.get("target_id", "")
			if target_id != "":
				var remembered: CharData = Registry.get_character(target_id)
				if remembered:
					return remembered
			return null
		_:
			return null


# ─────────────────────────────────────────────────────────────
# FRAME BUILDING
# ─────────────────────────────────────────────────────────────

func build_frame(character: CharData, target, _event_def: Dictionary) -> Dictionary:
	var frame: Dictionary = {}

	# ── ACTOR ────────────────────────────────────────────────
	frame["name"] = character.char_name
	_add_pronoun_vars(frame, character.pronouns, "")

	# ── TARGET ───────────────────────────────────────────────
	if target is CharData:
		frame["target"] = target.char_name
		_add_pronoun_vars(frame, target.pronouns, "target_")
	else:
		frame["target"] = "someone"
		# Default to they/them for unknown targets
		_add_pronoun_vars(frame, "they/them", "target_")

	# ── LOCATION ─────────────────────────────────────────────
	frame["room"] = _pretty_room(character.current_room)

	return frame


# ─────────────────────────────────────────────────────────────
# TEMPLATE FILLING (unchanged logic, just the same replace loop)
# ─────────────────────────────────────────────────────────────

func fill_template(template: String, frame: Dictionary) -> String:
	var result := template
	for key in frame:
		result = result.replace("{%s}" % key, str(frame[key]))
	return result


# ─────────────────────────────────────────────────────────────
# PRONOUN INJECTION
# Adds lowercase + capitalised pronoun vars to the frame dict.
# prefix "" = actor vars ({they}, {them}, etc.)
# prefix "target_" = target vars ({target_they}, {target_them}, etc.)
# ─────────────────────────────────────────────────────────────

func _add_pronoun_vars(frame: Dictionary, pronoun_key: String, prefix: String) -> void:
	var pset: Dictionary = Identity.get_pronoun_set(pronoun_key)
	var is_plural: bool = pset.get("is_plural", true)

	# Core pronouns — lowercase
	frame[prefix + "they"]     = pset["subject"]
	frame[prefix + "them"]     = pset["object"]
	frame[prefix + "their"]    = pset["possessive"]
	frame[prefix + "theirs"]   = pset["possessive_pronoun"]
	frame[prefix + "themself"] = pset["reflexive"]

	# Core pronouns — capitalised (for sentence starts)
	frame[prefix + "They"]     = pset["subject"].capitalize()
	frame[prefix + "Them"]     = pset["object"].capitalize()
	frame[prefix + "Their"]    = pset["possessive"].capitalize()
	frame[prefix + "Theirs"]   = pset["possessive_pronoun"].capitalize()
	frame[prefix + "Themself"] = pset["reflexive"].capitalize()

	# Verb conjugation helpers
	# they sit / she sits — {s} is "" for plural, "s" for singular
	frame[prefix + "s"]  = "" if is_plural else "s"
	frame[prefix + "es"] = "" if is_plural else "es"

	# they have / she has
	frame[prefix + "have_has"] = "have" if is_plural else "has"
	# they are / she is
	frame[prefix + "are_is"]   = "are" if is_plural else "is"
	# they were / she was
	frame[prefix + "were_was"] = "were" if is_plural else "was"


# ─────────────────────────────────────────────────────────────
# ROOM DISPLAY NAME
# Extracts the type prefix from a room ID and returns a pretty name.
# "bar_f1_s1" → "the bar",  "apartment_f2_s3" → "their apartment"
# Falls back to the raw ID if no mapping exists.
# ─────────────────────────────────────────────────────────────

func _pretty_room(room_id: String) -> String:
	# Room IDs use format: type_fFLOOR_sSLOT
	# Split on "_f" to isolate the type prefix
	var f_index: int = room_id.find("_f")
	var room_type: String
	if f_index > 0:
		room_type = room_id.substr(0, f_index)
	else:
		room_type = room_id

	return ROOM_DISPLAY_NAMES.get(room_type, room_id)