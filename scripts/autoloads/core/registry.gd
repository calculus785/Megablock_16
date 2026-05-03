# registry.gd
# Autoload — available globally as Registry
# Tier 2 Core — reads Tier 1 (Stats, Traits, Identity)
#
# Owns the master list of all characters in the building.
# Handles generation, lookup, and lifecycle (spawn/archive).

extends Node

# Master dictionary: char_id → CharData
var _characters: Dictionary = {}

# Archive: char_id → GhostRecord (deceased)
var _ghosts: Dictionary = {}

# Robots: char_id → RobotData
var _robots: Dictionary = {}

var _next_id: int = 0


func _ready() -> void:
	print("[Registry] Loaded. %d characters registered." % _characters.size())


# ── LOOKUP — Characters ───────────────────────────────────────

func get_character(char_id: String) -> CharData:
	return _characters.get(char_id, null)

func get_all() -> Array:
	return _characters.values()

func get_all_ids() -> Array:
	return _characters.keys()

func get_count() -> int:
	return _characters.size()

func has_character(char_id: String) -> bool:
	return _characters.has(char_id)


# ── LOOKUP — Robots ───────────────────────────────────────────

func get_robot(char_id: String) -> RobotData:
	return _robots.get(char_id, null)

func get_all_robots() -> Array:
	return _robots.values()


# ── LOOKUP — Ghosts ───────────────────────────────────────────

func get_ghost(char_id: String):
	# Returns GhostRecord or RobotGhostRecord, or null
	return _ghosts.get(char_id, null)

func is_deceased(char_id: String) -> bool:
	return _ghosts.has(char_id)


# ── REGISTRATION ─────────────────────────────────────────────

func register(character: CharData) -> void:
	_characters[character.char_id] = character

func unregister(char_id: String) -> void:
	_characters.erase(char_id)

func register_robot(robot: RobotData) -> void:
	_robots[robot.char_id] = robot

func archive_as_ghost(character: CharData, cause: String) -> GhostRecord:
	var ghost := GhostRecord.from_char_data(
		character, cause, Clock.get_total_days()
	)
	_ghosts[character.char_id] = ghost
	unregister(character.char_id)
	return ghost

func generate_id() -> String:
	var id := "char_%d" % _next_id
	_next_id += 1
	return id


# ── GENERATION ───────────────────────────────────────────────

# Generates a fully randomised character and registers them.
# Call this from bootstrap / test spawn / Mayor when filling a vacancy.
func generate_random_character(home_room: String = "") -> CharData:
	var character := CharData.new()

	# ── ID ──────────────────────────────────────────────────
	character.char_id = generate_id()

	# ── PRONOUNS + NAME + PREFERENCE ────────────────────────
	character.pronouns = Identity.random_pronouns()
	character.char_name = Identity.random_full_name(character.pronouns)
	character.preference = Identity.random_preference(character.pronouns)

	# ── IDENTITY ────────────────────────────────────────────
	character.favourite_color = Identity.random_favourite_colour()
	character.hair_colour = _random_hair_colour()
	character.interests.assign(Identity.random_interests(2, 4))
	character.life_arch = Identity.random_life_arch()
	character.birth_month = randi_range(1, 6)
	character.birth_day = randi_range(1, 15)
	character.favorite_genre = _random_genre()
	character.favorite_movie = ""  # generated later when cinema exists

	# ── AGE + LIFE STAGE ────────────────────────────────────
	# NPCs generated between 18-35. Player character is locked at 16.
	character.internal_age = randf_range(18.0, 35.0)
	character.life_stage = _derive_life_stage(character.internal_age)

	# ── STATS ───────────────────────────────────────────────
	character.stats = Stats.get_default_stats()

	# ── TRAITS ──────────────────────────────────────────────
	# Roll 3-5 visible traits
	character.traits.assign(Traits.pick_random_traits(3, 5))

	# Roll 1-2 hidden traits that don't conflict with visible ones
	var hidden_count: int = randi_range(1, 2)
	character.hidden_traits.assign(Traits.pick_hidden_traits(character.traits, hidden_count))

	# Apply all trait modifiers to stats (visible + hidden)
	for trait_key in character.get_all_active_traits():
		character.stats = Traits.apply_trait_modifiers(trait_key, character.stats)

	# ── LOCATION ────────────────────────────────────────────
	if home_room != "":
		character.home_room = home_room
		character.current_room = home_room
		character.apartment_id = home_room

	# ── FACTION SENTIMENT defaults ───────────────────────────
	character.faction_sentiment = {
		"police":     50,
		"management": 50,
		"robots":     50,
		"building":   50,
	}

	# ── REGISTER ────────────────────────────────────────────
	register(character)

	if Settings.debug_console_logging:
		print("[Registry] Generated: %s | %s | arch:%s | traits:%s" % [
			character.char_name,
			character.get_debug_label(),
			character.life_arch,
			str(character.traits),
		])

	return character


# Generates a character from a hand-authored config dictionary.
# Used for bespoke neighbours — config keys mirror CharData field names.
func generate_bespoke_character(config: Dictionary) -> CharData:
	var character := CharData.new()
	character.char_id = generate_id()

	const TYPED_ARRAY_FIELDS: Array = [
		"traits", "hidden_traits", "starter_traits", "interests",
		"faction_memberships", "states", "persistent_states",
		"parent_ids", "child_ids", "sibling_ids",
	]

	for key in config:
		if not key in character:
			continue
		if key in TYPED_ARRAY_FIELDS:
			character.get(key).assign(config[key])
		else:
			character.set(key, config[key])

	if character.char_name == "":
		character.char_name = Identity.random_full_name(character.pronouns)
	if character.stats.is_empty():
		character.stats = Stats.get_default_stats()
	if character.faction_sentiment.is_empty():
		character.faction_sentiment = {
			"police": 50, "management": 50,
			"robots": 50, "building": 50,
		}

	# Apply trait modifiers to stats
	for trait_key in character.get_all_active_traits():
		character.stats = Traits.apply_trait_modifiers(trait_key, character.stats)

	register(character)

	if Settings.debug_console_logging:
		print("[Registry] Bespoke: %s | %s" % [
			character.char_name, character.get_debug_label()
		])

	return character


# ── PRIVATE HELPERS ──────────────────────────────────────────

func _derive_life_stage(age: float) -> String:
	if age < 2.0:   return "Baby"
	if age < 8.0:   return "Child"
	if age < 16.0:  return "Teen"
	if age < 35.0:  return "Adult"
	return "Elderly"

func _random_hair_colour() -> String:
	var options := ["light", "dark", "unusual"]
	# Weight: dark 45%, light 40%, unusual 15%
	var weights := [45, 40, 15]
	var total: int = 0
	for w in weights:
		total += w
	var roll := randi_range(1, total)
	var running: int = 0
	for i in options.size():
		running += weights[i]
		if roll <= running:
			return options[i]
	return "dark"

func _random_genre() -> String:
	var genres := [
		"thriller", "romance", "horror", "comedy", "drama",
		"sci-fi", "action", "documentary", "animation", "mystery"
	]
	return genres[randi() % genres.size()]
