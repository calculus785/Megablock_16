# char_data.gd
# Resource class — CharData
# The single source of truth for every character in the game.
#
# Created by Registry.generate_random_character() or hand-authored as .tres.
# Read and modified by FeelingDriver, StateDriver, Sim, Actions, Memory,
# Relationships, and the F2 EventInspector.
#
# IMPORTANT: this is the ONLY place character state lives.
# No autoload caches CharData fields. No system mirrors them.
# All reads go through Registry.get_character(char_id) → returns this Resource.
#
# Saving: all @export fields are persisted automatically to .tres / save bundle.

class_name CharData
extends Resource


# ═════════════════════════════════════════════════════════════
# IDENTITY
# Static — set once at character creation, rarely changes.
# ═════════════════════════════════════════════════════════════

@export var char_id: String = ""               # unique, format "char_0"
@export var char_name: String = ""             # display name
@export var internal_age: float = 18.0         # hidden float, drives life_stage
@export var life_stage: String = "Adult"       # Baby / Child / Teen / Adult / Elderly
@export var job: String = ""                   # job ID, "" = unemployed
@export var apartment_id: String = ""          # room_id of their home, "" = homeless

# Pronouns and attraction preference (renamed from "sexuality")
@export var pronouns: String = "they/them"     # key in Identity.PRONOUNS
@export var preference: String = "any"         # key in Identity.ALL_PREFERENCES

# Aesthetic identity — drives clothing, room theming, attraction modifiers
@export var favourite_color: String = "white"  # key in Identity.FAVOURITE_COLOURS
@export var hair_colour: String = "dark"       # "light" / "dark" / "unusual"
@export var interests: Array[String] = []      # subset of Identity.INTERESTS

# Story shape and birth date (used by Architect for life arch modifiers + birthdays)
@export var life_arch: String = "neutral"      # key in Identity.LIFE_ARCHES
@export var birth_month: int = 1               # 1-6
@export var birth_day: int = 1                 # 1-15

# Cinema / culture preferences (rolled at generation)
@export var favorite_genre: String = ""
@export var favorite_movie: String = ""


# ═════════════════════════════════════════════════════════════
# STATS, TRAITS, FEELINGS, STATES
# The dynamic emotional and personality layer.
# ═════════════════════════════════════════════════════════════

# 16 stats keyed by name. Populated from Stats.get_default_stats() at creation.
@export var stats: Dictionary = {}

# Active permanent traits visible to the player in the bio.
@export var traits: Array[String] = []

# Active permanent traits NOT shown to the player. Same mechanical effect.
@export var hidden_traits: Array[String] = []

# Backstory traits — applied once at creation, no ongoing effect.
# Example: "GREW_UP_POOR" might give starting cash penalty + memory hint,
# but doesn't modify event weights forever. Visible in bio.
@export var starter_traits: Array[String] = []

# Active feelings — Array of Dictionaries.
# Shape (see feelings.gd for full reference):
#   { feeling_key, hours_remaining, target_id, is_hidden, causes: [] }
@export var feelings: Array = []

# Stat-derived states (TIRED, HUNGRY, FURIOUS, etc.)
# Auto-managed by StateDriver — never write to this manually.
@export var states: Array[String] = []

# Persistent states (INJURED, IN_JAIL, BANNED_FROM_BAR, etc.)
# Set/cleared by Actions via StateDriver.set_persistent_state().
@export var persistent_states: Array[String] = []

# event_key → tick_when_available — prevents event spam.
@export var event_cooldowns: Dictionary = {}

# Counters used by trait evolution (drinks_at_bar, sober_days, etc.)
@export var trait_progress: Dictionary = {}


# ═════════════════════════════════════════════════════════════
# MEMORY
# Storybook is the long-term log. Memorable entries are flagged.
# ═════════════════════════════════════════════════════════════

# Short-term memory — 5 categories, max 2 entries each.
# Categories: thought, action, interaction, observation, felt
# Entry shape: { subject, tone, context, at_tick }
@export var short_term_memory: Dictionary = {
	"thought": [],
	"action": [],
	"interaction": [],
	"observation": [],
	"felt": [],
}

# Storybook — full log of events that happened to or around this character.
# Entry shape: { event_key, summary, at_tick, target_id, magnitude,
#                memorable, memory_tags, times_recalled, last_recalled_day,
#                pinned_to_story }
@export var storybook: Array = []

# Intent queue — pending actions in priority order.
# Entry shape: { intent_key, priority, target, patience, clearable }
@export var intent_queue: Array = []


# ═════════════════════════════════════════════════════════════
# LOCATION & MOVEMENT
# Where they are, where they're going, how they're getting there.
# ═════════════════════════════════════════════════════════════

@export var current_room: String = ""          # room_id they're in (or transiting from)
@export var home_room: String = ""             # apartment_id, same as apartment_id

@export var is_in_transit: bool = false        # walking between rooms
@export var movement_target_room: String = ""  # destination room_id
@export var waypoints: Array = []              # path nodes from Pathfinder
@export var waypoint_index: int = 0            # current waypoint progress
@export var movement_type: String = "walk"     # key in Stats.MOVEMENT_TYPES

# Blockages this character knows about. Other floors may have unknown blockages.
# Format: { room_id: expiry_tick }
@export var known_blockages: Dictionary = {}

@export var is_sleeping: bool = false

@export var zone_target_pos: Vector3 = Vector3.ZERO


# ═════════════════════════════════════════════════════════════
# SEQUENCE STATE
# When this character is locked in a multi-beat sequence (pool game, etc.)
# ═════════════════════════════════════════════════════════════

@export var active_sequence: String = ""        # sequence_key, "" = not in sequence
@export var sequence_beat: int = 0              # current beat_id
@export var sequence_partner_id: String = ""    # other participant's char_id
@export var sequence_role: String = ""          # "initiator" / "responder" / etc.
@export var sequence_context: Dictionary = {}   # arbitrary scratchpad for the sequence


# ═════════════════════════════════════════════════════════════
# INVENTORY
# What they're holding, carrying, wearing, and storing at home.
# ═════════════════════════════════════════════════════════════

# Visible in hands. Max 2. Two-handed items occupy both slots.
# Each entry: { item_id, slot } or "" for empty slot.
@export var held_items: Array = ["", ""]

# Backpack — hidden until retrieved.
@export var carried_items: Array = []

# Equipped slots — visible on sprite, not in hands.
@export var equipped: Dictionary = {
	"hat": "",
	"costume": "",
	"faction_badge": "",
}

# Items placed in their apartment. Limited by apartment spot count.
@export var apartment_items: Array = []

# Buffer for food, decoration, etc. — stored in apartment but not placed.
@export var apartment_storage: Array = []

# Abstract pooled groceries (decision: not tracked by ingredient).
@export var groceries: int = 0

# 0 = empty, low = normal, high = full, capped = over-encumbered (speed penalty).
@export var current_encumbrance: int = 0


# ═════════════════════════════════════════════════════════════
# IMPRESSIONS
# How attached this character is to specific objects and programs.
# Higher = more emotional weight. Drives admire, defend, mourn-loss events.
# ═════════════════════════════════════════════════════════════

# object_id OR program_room_id → impression_score (0-100)
# Programs use the pattern "program_<room_id>" (e.g. "program_bar_f2_s1").
@export var object_impressions: Dictionary = {}


# ═════════════════════════════════════════════════════════════
# SOCIAL & FACTION
# Relationships are stored elsewhere (Relationships autoload, by char_id pair).
# Faction sentiment lives here because it's per-character.
# ═════════════════════════════════════════════════════════════

# faction_id → sentiment_score (-100 to 100)
# Institutional factions: police, management, robots, building.
@export var faction_sentiment: Dictionary = {}

# faction_id strings — "police", "homeless", "<gang_name>", etc.
@export var faction_memberships: Array[String] = []


# ═════════════════════════════════════════════════════════════
# JOB & STATUS FLAGS
# ═════════════════════════════════════════════════════════════

@export var job_satisfaction: int = 50         # 0-100, drops when forced to work
@export var is_employed: bool = false
@export var is_homeless: bool = false


# ═════════════════════════════════════════════════════════════
# FAMILY
# Stored as char_id arrays. Lookup goes through Registry.
# ═════════════════════════════════════════════════════════════

@export var parent_ids: Array[String] = []
@export var child_ids: Array[String] = []
@export var sibling_ids: Array[String] = []


# ═════════════════════════════════════════════════════════════
# CONVENIENCE METHODS
# Light helpers — anything heavier belongs in an autoload.
# ═════════════════════════════════════════════════════════════

# Returns the display name with pronouns for debug output.
func get_debug_label() -> String:
	return "%s (%s, %s)" % [char_name, pronouns, life_stage]


# True if this character can act this tick.
# Used by Sim to skip locked or unconscious characters.
func is_actionable() -> bool:
	if is_sleeping:
		return false
	if is_in_transit:
		return false
	if active_sequence != "":
		return false
	if "IN_HOSPITAL" in persistent_states:
		return false
	if "IN_JAIL" in persistent_states:
		return false
	if "IN_VR_POD" in persistent_states:
		return false
	return true


# Returns ALL active traits (visible + hidden) for mechanical effect lookup.
# Use this anywhere event eligibility or weight modifiers check traits.
# Use `traits` directly only when displaying to the player.
func get_all_active_traits() -> Array:
	var combined: Array = []
	combined.append_array(traits)
	combined.append_array(hidden_traits)
	return combined