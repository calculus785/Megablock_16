# identity.gd
# Autoload — available globally as Identity
# Tier 1 Config — pure data, no dependencies
#
# Source of truth for character identity generation:
# names, pronouns, sexualities, favourite colours, interests, life arches.
#
# Used by Registry when generating non-bespoke characters.

extends Node

# ─────────────────────────────────────────────────────────────
# NAME POOLS
# Cyberpunk, multicultural, deliberately mixed.
# Keep small for now — expand as needed.
# ─────────────────────────────────────────────────────────────

# Names categorised by pronoun set.
# When generating a character, we pick from the matching pool.
# they/them characters pick from NAMES_NEUTRAL.

const FIRST_NAMES_HE_HIM: Array = [
	"Marcus", "Jerome", "Dylan", "Vance", "Charlie", "Ravi", "Ezra",
	"Theo", "Cyrus", "Idris", "Hugo", "Leon", "Anton", "Jared", "Bran",
	"Soren", "Mateo", "Dmitri", "Callum", "Zane",
]

const FIRST_NAMES_SHE_HER: Array = [
	"Sara", "Mira", "Nadia", "Astrid", "Anya", "Soraya", "Mei",
	"Ines", "Tamsin", "Yuki", "Lin", "Priya", "Celeste", "Vashti",
	"Riona", "Nour", "Elara", "Suki", "Ingrid", "Dani",
]

const FIRST_NAMES_NEUTRAL: Array = [
	"Kai", "Phoenix", "Sage", "River", "Quinn", "Rowan", "Jamie",
	"Skye", "Alex", "Avery", "Blake", "Ren", "Arlo", "Finley", "Reese",
]

const LAST_NAMES: Array = [
	"Vega", "Marsh", "Okafor", "Tanaka", "Banks", "Kowalski",
	"Reyes", "Singh", "Nguyen", "Park", "Volkov",
	"Rourke", "Castellanos", "Osei", "Finch", "Drăgan",
	"Hartwell", "Moreno", "Saito", "Adisa", "Lindqvist",
]

# ─────────────────────────────────────────────────────────────
# PRONOUN SETS
# Each entry: subject, object, possessive, possessive_pronoun, reflexive
# Used by storybook templates: "{they} took {their} drink to {themself}."
# ─────────────────────────────────────────────────────────────

const PRONOUNS: Dictionary = {
	"they/them": {
		"subject": "they", "object": "them", "possessive": "their",
		"possessive_pronoun": "theirs", "reflexive": "themself", "is_plural": true
	},
	"she/her": {
		"subject": "she", "object": "her", "possessive": "her",
		"possessive_pronoun": "hers", "reflexive": "herself", "is_plural": false
	},
	"he/him": {
		"subject": "he", "object": "him", "possessive": "his",
		"possessive_pronoun": "his", "reflexive": "himself", "is_plural": false
	},
}

const PRONOUN_WEIGHTS: Dictionary = {
	"they/them": 20,
	"she/her": 40,
	"he/him": 40,
}

# ─────────────────────────────────────────────────────────────
# SEXUALITIES
# Used in romantic event eligibility checks.
# ─────────────────────────────────────────────────────────────

# ─────────────────────────────────────────────────────────────
# ATTRACTION PREFERENCES
# Who this character is attracted to (by pronoun set).
# Checked during romantic event eligibility.
# "any" means attracted to all pronoun sets.
# "none" means no romantic attraction (asexual equivalent).
# ─────────────────────────────────────────────────────────────

# Weights per pronoun set. Values are { preference_key: weight }.
const PREFERENCE_WEIGHTS_BY_PRONOUNS: Dictionary = {
	"he/him": {
		"she/her":   60,   # most common
		"any":       20,   # attracted to everyone
		"he/him":    12,   # same-pronoun attraction
		"they/them":  5,
		"none":       3,
	},
	"she/her": {
		"he/him":    60,
		"any":       20,
		"she/her":   12,
		"they/them":  5,
		"none":       3,
	},
	"they/them": {
		"any":       45,   # non-binary characters more likely to be pan
		"she/her":   20,
		"he/him":    20,
		"they/them": 10,
		"none":       5,
	},
}

# All valid preference keys (for validation elsewhere)
const ALL_PREFERENCES: Array = ["she/her", "he/him", "they/them", "any", "none"]

# ─────────────────────────────────────────────────────────────
# FAVOURITE COLOURS
# Drives clothing, apartment wallpaper, lighting, UI accent.
# Stored as Godot Color values for easy use later.
# ─────────────────────────────────────────────────────────────

const FAVOURITE_COLOURS: Dictionary = {
	"deep_red":      Color(0.65, 0.15, 0.20),
	"orange":        Color(0.95, 0.55, 0.20),
	"yellow":        Color(0.95, 0.85, 0.30),
	"green":         Color(0.30, 0.65, 0.35),
	"teal":          Color(0.20, 0.65, 0.65),
	"navy":          Color(0.15, 0.25, 0.55),
	"purple":        Color(0.55, 0.30, 0.65),
	"pink":          Color(0.95, 0.55, 0.75),
	"black":         Color(0.10, 0.10, 0.12),
	"white":         Color(0.92, 0.92, 0.92),
	"electric_blue": Color(0.20, 0.60, 0.95),
	"acid_green":    Color(0.55, 0.95, 0.35),
}

# ─────────────────────────────────────────────────────────────
# INTERESTS
# Gate object/program impressions. Characters only accumulate
# attachment to interactables matching their interests.
# ─────────────────────────────────────────────────────────────

const INTERESTS: Array = [
	"music", "books", "cinema", "fashion", "cooking", "fitness",
	"mechanics", "gambling", "gossip", "art", "history",
	"sports", "social_media", "card_games", "people_watching",
	"nightlife", "tech", "DIY", "philosophy",
]

# ─────────────────────────────────────────────────────────────
# LIFE ARCHES
# Vague genre-suggestive labels. Phase 4+ will use these to
# apply time-phased weight modifiers (e.g. "The Last Chapter"
# weights death and reflection events higher in late game).
# Phase 0 just stores the string.
# ─────────────────────────────────────────────────────────────

const LIFE_ARCHES: Dictionary = {
	"romance": {
		"label": "Romance",
		"description": "Their story is one of love, longing, and connection. Drama follows close behind."
	},
	"drama": {
		"label": "Drama",
		"description": "Conflict finds them. Or they find it. Either way, things rarely stay quiet around them."
	},
	"neutral": {
		"label": "Neutral",
		"description": "Living their life. No grand arc. Sometimes that's enough."
	},
	"wildcard": {
		"label": "Wildcard",
		"description": "Unpredictable. Their weight modifiers swing hard. Nobody — including them — knows what's next."
	},
	"crime": {
		"label": "Crime",
		"description": "Not necessarily a criminal. But the pull is there. Whether they resist it is the story."
	},
}


func _ready() -> void:
	print("[Identity] Loaded. %d names, %d colours, %d interests, %d arches." % [
		FIRST_NAMES_HE_HIM.size() + FIRST_NAMES_SHE_HER.size() + FIRST_NAMES_NEUTRAL.size() + LAST_NAMES.size(),
		FAVOURITE_COLOURS.size(),
		INTERESTS.size(),
		LIFE_ARCHES.size(),
	])


# ─────────────────────────────────────────────────────────────
# NAME GENERATION
# ─────────────────────────────────────────────────────────────

func random_first_name(pronoun_key: String = "they/them") -> String:
	var pool: Array
	match pronoun_key:
		"he/him":  pool = FIRST_NAMES_HE_HIM
		"she/her": pool = FIRST_NAMES_SHE_HER
		_:         pool = FIRST_NAMES_NEUTRAL
	return pool[randi() % pool.size()]


func random_last_name() -> String:
	return LAST_NAMES[randi() % LAST_NAMES.size()]

func random_full_name(pronoun_key: String = "they/them") -> String:
	return "%s %s" % [random_first_name(pronoun_key), random_last_name()]






# ─────────────────────────────────────────────────────────────
# PRONOUNS / SEXUALITY
# ─────────────────────────────────────────────────────────────

func random_pronouns() -> String:
	return _pick_weighted_string(PRONOUN_WEIGHTS)


func get_pronoun_set(pronoun_key: String) -> Dictionary:
	return PRONOUNS.get(pronoun_key, PRONOUNS["they/them"])


func random_preference(pronoun_key: String) -> String:
	var weights: Dictionary = PREFERENCE_WEIGHTS_BY_PRONOUNS.get(
		pronoun_key,
		PREFERENCE_WEIGHTS_BY_PRONOUNS["they/them"]
	)
	return _pick_weighted_string(weights)


# Checks if character A is attracted to character B.
# Used by romantic event eligibility checks.
func is_attracted_to(preference_a: String, pronouns_b: String) -> bool:
	if preference_a == "none":
		return false
	if preference_a == "any":
		return true
	return preference_a == pronouns_b


# ─────────────────────────────────────────────────────────────
# COLOURS / INTERESTS / LIFE ARCH
# ─────────────────────────────────────────────────────────────

func random_favourite_colour() -> String:
	var keys: Array = FAVOURITE_COLOURS.keys()
	return keys[randi() % keys.size()]


func get_colour_value(colour_key: String) -> Color:
	return FAVOURITE_COLOURS.get(colour_key, Color.WHITE)


# Picks between min_count and max_count distinct interests.
func random_interests(min_count: int = 2, max_count: int = 4) -> Array:
	var count: int = randi_range(min_count, max_count)
	var pool: Array = INTERESTS.duplicate()
	pool.shuffle()
	return pool.slice(0, count)


func random_life_arch() -> String:
	var keys: Array = LIFE_ARCHES.keys()
	return keys[randi() % keys.size()]


func get_life_arch(arch_key: String) -> Dictionary:
	return LIFE_ARCHES.get(arch_key, LIFE_ARCHES["neutral"])


# ─────────────────────────────────────────────────────────────
# WEIGHTED PICKER (internal)
# ─────────────────────────────────────────────────────────────

func _pick_weighted_string(weights: Dictionary) -> String:
	var total: int = 0
	for key in weights:
		total += weights[key]

	var roll: int = randi_range(1, total)
	var running: int = 0
	for key in weights:
		running += weights[key]
		if roll <= running:
			return key

	return weights.keys()[0]