# registry.gd
# Autoload — available globally as Registry
# Tier 2 Core — reads Tier 1 (Stats, Traits, Identity)
#
# Owns the master list of all characters in the building.
# Handles generation, lookup, and lifecycle (spawn/archive).
# CharData resource class must exist before generation works.

extends Node

# Master dictionary: char_id → CharData reference
var _characters: Dictionary = {}

# Counter for generating unique IDs
var _next_id: int = 0


func _ready() -> void:
	print("[Registry] Loaded. %d characters registered." % _characters.size())


# ── LOOKUP ───────────────────────────────────────────────────

func get_character(char_id: String):
	return _characters.get(char_id, null)

func get_all() -> Array:
	return _characters.values()

func get_all_ids() -> Array:
	return _characters.keys()

func get_count() -> int:
	return _characters.size()

func has_character(char_id: String) -> bool:
	return _characters.has(char_id)


# ── REGISTRATION ─────────────────────────────────────────────

# Adds a character to the registry. Used by generation and save loading.
func register(character) -> void:
	_characters[character.char_id] = character

# Removes a character from the registry (death, departure).
func unregister(char_id: String) -> void:
	_characters.erase(char_id)

# Generates a unique character ID.
func generate_id() -> String:
	var id: String = "char_%d" % _next_id
	_next_id += 1
	return id


# ── GENERATION (stub) ────────────────────────────────────────
# Full implementation once CharData resource class is built.

func generate_random_character():
	# Will create a CharData, roll identity/stats/traits, register, return
	push_warning("[Registry] generate_random_character() not yet implemented.")
	return null

func generate_bespoke_character(_config: Dictionary):
	# Will create a CharData from a hand-authored config dict
	push_warning("[Registry] generate_bespoke_character() not yet implemented.")
	return null