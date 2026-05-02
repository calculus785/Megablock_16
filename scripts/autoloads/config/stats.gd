# stats.gd
# Autoload — available globally as Stats
# Tier 1 Config — pure data, no dependencies
#
# Single source of truth for every stat in the game.
# Also defines movement types (speed multipliers + required feelings).
#
# To add a new stat: add one entry to STATS. Nothing else changes.
# To add a new movement type: add one entry to MOVEMENT_TYPES.

extends Node

# ─────────────────────────────────────────────────────────────
# STATS — every gameplay-relevant number on a character
# ─────────────────────────────────────────────────────────────
# Each definition has:
#   default — starting value when a character is created
#   min     — floor (stat can never go below this)
#   max     — ceiling (stat can never go above this)
#   label   — human-readable name for UI

const STATS: Dictionary = {

	# ── CORE WELLBEING ──────────────────────────────────────
	"stress":        { "default": 20, "min": 0, "max": 100, "label": "Stress" },
	"happiness":     { "default": 50, "min": 0, "max": 100, "label": "Happiness" },
	"health":        { "default": 80, "min": 0, "max": 100, "label": "Health" },
	"energy":        { "default": 80, "min": 0, "max": 100, "label": "Energy" },

	# ── NEEDS ───────────────────────────────────────────────
	"hunger":          { "default": 20, "min": 0, "max": 100, "label": "Hunger" },
	"boredom":         { "default": 10, "min": 0, "max": 100, "label": "Boredom" },
	"loneliness":      { "default": 30, "min": 0, "max": 100, "label": "Loneliness" },
	"horniness":       { "default": 20, "min": 0, "max": 100, "label": "Horniness" },
	"need_for_toilet": { "default":  0, "min": 0, "max": 100, "label": "Bladder" },
	"grief":           { "default":  0, "min": 0, "max": 100, "label": "Grief" },

	# ── SOCIAL ──────────────────────────────────────────────
	"global_reputation": { "default": 50, "min": 0, "max": 100, "label": "Reputation" },
	"attractiveness":    { "default": 50, "min": 0, "max": 100, "label": "Attractiveness" },

	# ── PRACTICAL ───────────────────────────────────────────
	"cash": { "default": 200, "min": 0, "max": 999999, "label": "Cash" },

	# ── DARK / HIDDEN ───────────────────────────────────────
	"criminal_inclination": { "default": 5, "min": 0, "max": 100, "label": "Criminal Inclination" },
	"criminal_reputation":  { "default": 0, "min": 0, "max": 100, "label": "Criminal Rep" },
	"addiction":            { "default": 0, "min": 0, "max": 100, "label": "Addiction" },
}


# ─────────────────────────────────────────────────────────────
# MOVEMENT TYPES — how a character moves between waypoints
# ─────────────────────────────────────────────────────────────
# Each definition has:
#   speed_mult    — multiplier on base walk speed
#   requires      — feelings the character must have for this to be available
#                   (empty array = always available)
#   anim_hint     — name MovementController will look up later (Phase 3)

const MOVEMENT_TYPES: Dictionary = {
	"walk":    { "speed_mult": 1.0, "requires": [],                                      "anim_hint": "walk" },
	"run":     { "speed_mult": 2.0, "requires": ["BURSTING", "TERRIFIED", "FURIOUS"],    "anim_hint": "run" },
	"skip":    { "speed_mult": 1.2, "requires": ["ELATED"],                              "anim_hint": "skip" },
	"crawl":   { "speed_mult": 0.3, "requires": [],                                      "anim_hint": "crawl" },
	"sneak":   { "speed_mult": 0.7, "requires": [],                                      "anim_hint": "sneak" },
	"limp":    { "speed_mult": 0.6, "requires": ["INJURED"],                             "anim_hint": "limp" },
	"shuffle": { "speed_mult": 0.5, "requires": [],                                      "anim_hint": "shuffle" },
}


func _ready() -> void:
	print("[Stats] Loaded. %d stats, %d movement types." % [STATS.size(), MOVEMENT_TYPES.size()])


# ─────────────────────────────────────────────────────────────
# STAT HELPERS
# ─────────────────────────────────────────────────────────────

# Returns a fresh stats dictionary with all default values.
# Called when a new character is created.
func get_default_stats() -> Dictionary:
	var result: Dictionary = {}
	for stat_key in STATS:
		result[stat_key] = STATS[stat_key]["default"]
	return result


# Clamps a value so it never goes below min or above max.
# Call this whenever you change a stat.
func clamp_stat(stat_key: String, value: float) -> float:
	var min_val: float = STATS[stat_key]["min"]
	var max_val: float = STATS[stat_key]["max"]
	return clamp(value, min_val, max_val)


# Returns the display name for a stat (used by the UI).
func get_label(stat_key: String) -> String:
	return STATS[stat_key]["label"]


# True if a stat exists. Useful guard before reads/writes.
func has_stat(stat_key: String) -> bool:
	return STATS.has(stat_key)


# ─────────────────────────────────────────────────────────────
# MOVEMENT HELPERS
# ─────────────────────────────────────────────────────────────

# Returns the speed multiplier for a movement type.
# Defaults to 1.0 if the type is unknown.
func get_speed_mult(movement_type: String) -> float:
	if not MOVEMENT_TYPES.has(movement_type):
		return 1.0
	return MOVEMENT_TYPES[movement_type]["speed_mult"]


# True if a character with the given feelings can use this movement type.
# `current_feelings` is an Array of feeling key strings.
func can_use_movement(movement_type: String, current_feelings: Array) -> bool:
	if not MOVEMENT_TYPES.has(movement_type):
		return false
	var requires: Array = MOVEMENT_TYPES[movement_type]["requires"]
	if requires.is_empty():
		return true
	# Need at least one of the required feelings
	for feeling in requires:
		if feeling in current_feelings:
			return true
	return false