# events.gd
# Autoload — available globally as Events
# Tier 1 Config — pure data, no dependencies
#
# Defines every event in the game.
# Each event is one beat of simulation. Sim reads from here, evaluates
# eligibility, rolls weighted picks, and calls Actions to execute outcomes.
#
# Data shape (full reference in MEGABLOCK16_EVENT_DESIGN_BIBLE.md):
#
#   scope:                "character" | "building"
#   trigger_mode:         "rolled" | "auto_fire"
#   priority:             0-100 (auto_fire only — higher fires first)
#   bypass_architect:     true bypasses Architect approval
#   base_weight:          starting probability
#   requirements:         dict of conditions that must all be true
#   weight_modifiers:     list of {condition, multiply} pairs
#   target_resolution:    {type, filter, scope, exclude_robots}
#   call_action:          name of function in Actions to execute
#   outcomes:             stat/feeling/state/relationship deltas
#   magnitude:            "minor" | "moderate" | "major" | "huge"
#   ticker_worthy:        appears in news ticker if true
#   player_choice:        triggers Decisions popup if actor is player
#   storybook_templates:  array of narrative variants
#   category:             tag for Architect tracking, ticker colour, etc.

extends Node


const EVENTS: Dictionary = {

# ─────────────────────────────────────────────────────────────
# SOLO PLACEHOLDERS — fire for any character, anywhere
# ─────────────────────────────────────────────────────────────

"REST": {
	"scope": "character",
	"trigger_mode": "rolled",
	"base_weight": 12,
	"category": "psychology",
	"magnitude": "minor",
	"requirements": {
		"stats_below": { "energy": 60 },
	},
	"weight_modifiers": [
		{ "condition": { "stats_below": { "energy": 30 } }, "multiply": 2.0 },
		{ "condition": { "has_state": ["TIRED"] }, "multiply": 1.5 },
	],
	"target_resolution": { "type": "self" },
	"call_action": "rest",
	"outcomes": {
		"stats": { "energy": 5, "stress": -3, "boredom": 5 },
	},
	"storybook_templates": [
		"{name} sat down for a moment.",
		"{name} needed a minute.",
	],
},

"WANDER": {
	"scope": "character",
	"trigger_mode": "rolled",
	"base_weight": 8,
	"category": "psychology",
	"magnitude": "minor",
	"requirements": {
		"stats_above": { "boredom": 25 },
		"not_has_persistent_state": ["IN_HOSPITAL", "IN_JAIL", "IN_VR_POD"],
	},
	"weight_modifiers": [
		{ "condition": { "has_state": ["RESTLESS"] }, "multiply": 1.5 },
		{ "condition": { "has_trait": ["NOSY"] }, "multiply": 1.4 },
	],
	"target_resolution": { "type": "room" },
	"call_action": "wander",
	"outcomes": {
		"stats": { "boredom": -10 },
	},
	"storybook_templates": [
		"{name} wandered out of {room}. No destination in mind.",
		"{name} drifted. Nothing in particular pulling them anywhere.",
	],
},

"THINK_ABOUT": {
	"scope": "character",
	"trigger_mode": "rolled",
	"base_weight": 10,
	"category": "psychology",
	"magnitude": "minor",
	"requirements": {
		# Will check memory.long_term.size() > 0 once Memory is built
	},
	"weight_modifiers": [
		{ "condition": { "has_state": ["LONELY"] }, "multiply": 1.6 },
		{ "condition": { "has_state": ["RESTLESS"] }, "multiply": 1.3 },
		{ "condition": { "stats_above": { "grief": 20 } }, "multiply": 2.0 },
	],
	"target_resolution": { "type": "memory" },
	"call_action": "think_about",
	"outcomes": {
		# Resolved by the action — depends on memory tone
	},
	"storybook_templates": [
		"{name} thought about {target}.",
		"{target} crossed {name}'s mind again.",
		"It came back to {name}. {target}. That whole thing.",
	],
},

# ─────────────────────────────────────────────────────────────
# LOCATION-GATED PLACEHOLDERS
# ─────────────────────────────────────────────────────────────

"VISIT_BAR": {
	"scope": "character",
	"trigger_mode": "rolled",
	"base_weight": 6,
	"category": "social",
	"magnitude": "minor",
	"requirements": {
		"not_in_room": ["bar"],
		"not_has_persistent_state": ["BANNED_FROM_BAR", "IN_HOSPITAL", "IN_JAIL"],
	},
	"weight_modifiers": [
		{ "condition": { "stats_above": { "loneliness": 50 } }, "multiply": 1.8 },
		{ "condition": { "stats_above": { "stress": 50 } }, "multiply": 1.5 },
		{ "condition": { "has_trait": ["ALCOHOLIC"] }, "multiply": 2.5 },
		{ "condition": { "has_trait": ["RECOVERING_ALCOHOLIC"] }, "multiply": 0.1 },
	],
	"target_resolution": { "type": "room" },
	"call_action": "queue_intent_visit_bar",
	"outcomes": {
		"stats": { "boredom": -5 },  # anticipation
	},
	"storybook_templates": [
		"{name} headed to the bar.",
		"{name} needed a drink. Or just somewhere to be.",
	],
},

"ORDER_DRINK": {
	"scope": "character",
	"trigger_mode": "rolled",
	"base_weight": 14,
	"category": "social",
	"magnitude": "minor",
	"requirements": {
		"in_room": ["bar"],
		"stats_above": { "cash": 5 },
	},
	"weight_modifiers": [
		{ "condition": { "has_trait": ["ADDICT_PRONE"] }, "multiply": 1.5 },
		{ "condition": { "has_trait": ["ALCOHOLIC"] }, "multiply": 2.5 },
		{ "condition": { "has_trait": ["RECOVERING_ALCOHOLIC"] }, "multiply": 0.05 },
	],
	"target_resolution": { "type": "self" },
	"call_action": "order_drink",
	"outcomes": {
		"stats": { "cash": -5, "stress": -8, "happiness": 5, "addiction": 2 },
	},
	"storybook_templates": [
		"{name} ordered a drink.",
		"{name} sat at the bar. The drink appeared.",
	],
},
}


# ─────────────────────────────────────────────────────────────
# CATEGORIES
# Used for Architect tracking, news ticker colour, weight modifier
# conditions ("category_above": 5 means 5 events of this category recently).
# ─────────────────────────────────────────────────────────────

const CATEGORIES: Array = [
	"social", "romantic", "violence", "crime", "police", "death",
	"family", "comedy", "work", "building", "management", "gang",
	"homeless", "health", "psychology", "object", "seasonal", "calendar",
]


func _ready() -> void:
	print("[Events] Loaded. %d events, %d categories." % [EVENTS.size(), CATEGORIES.size()])


# ─────────────────────────────────────────────────────────────
# HELPERS
# ─────────────────────────────────────────────────────────────

func get_all_event_keys() -> Array:
	return EVENTS.keys()

func get_event(event_key: String) -> Dictionary:
	return EVENTS.get(event_key, {})

func is_valid(event_key: String) -> bool:
	return EVENTS.has(event_key)

func get_category(event_key: String) -> String:
	return EVENTS[event_key].get("category", "uncategorised")

# Returns events filtered by scope. Sim uses this to split per-character
# events from building-scope events on each tick.
func get_events_by_scope(scope: String) -> Array:
	var result: Array = []
	for key in EVENTS:
		if EVENTS[key].get("scope", "character") == scope:
			result.append(key)
	return result

# Returns events filtered by trigger_mode. Sim splits these between
# the auto-fire pass and the rolled weighted-pick pass.
func get_events_by_trigger(trigger_mode: String) -> Array:
	var result: Array = []
	for key in EVENTS:
		if EVENTS[key].get("trigger_mode", "rolled") == trigger_mode:
			result.append(key)
	return result