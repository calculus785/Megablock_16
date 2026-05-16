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
#   cooldown_events:      number of other events that must fire before this can fire again
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
	"cooldown_events": 2,  
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
	"cooldown_events": 3,
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
	"cooldown_events": 2,
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
	"cooldown_events": 8,
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
	"cooldown_events": 0,
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

"DAYDREAM": {
	"scope": "character",
	"trigger_mode": "rolled",
	"base_weight": 10,
	"category": "psychology",
	"magnitude": "minor",
	"cooldown_events": 3,
	"requirements": {
		"stats_above": { "boredom": 20 },
	},
	"weight_modifiers": [
		{ "condition": { "has_state": ["LONELY"] }, "multiply": 1.5 },
		{ "condition": { "has_state": ["CONTENT"] }, "multiply": 1.4 },
		{ "condition": { "stats_above": { "boredom": 50 } }, "multiply": 1.8 },
	],
	"target_resolution": { "type": "self" },
	"call_action": "daydream",
	"outcomes": {
		"stats": { "boredom": -15, "stress": -5 },
	},
	"storybook_templates": [
		"{name} stared at nothing for a while.",
		"{name} drifted somewhere else entirely. Just for a moment.",
		"The room went quiet in {name}'s head.",
	],
},

"CRY": {
	"scope": "character",
	"trigger_mode": "rolled",
	"base_weight": 4,
	"category": "psychology",
	"magnitude": "minor",
	"cooldown_events": 5,
	"requirements": {
		"stats_below": { "happiness": 30 },
	},
	"weight_modifiers": [
		{ "condition": { "has_state": ["MISERABLE"] }, "multiply": 2.5 },
		{ "condition": { "has_feeling": ["GRIEF_FEELING"] }, "multiply": 2.0 },
		{ "condition": { "has_feeling": ["HEARTBROKEN_FEELING"] }, "multiply": 2.0 },
		{ "condition": { "has_state": ["LONELY"] }, "multiply": 1.5 },
	],
	"target_resolution": { "type": "self" },
	"call_action": "cry",
	"outcomes": {
		"stats": { "stress": -10, "loneliness": 10 },
		"feelings": ["GRIEF_FEELING"],
	},
	"storybook_templates": [
		"{name} cried. No particular reason needed.",
		"It came out of nowhere. {name} sat with it.",
		"{name} didn't try to stop it this time.",
	],
},

"LATE_NIGHT_STARE": {
	"scope": "character",
	"trigger_mode": "rolled",
	"base_weight": 6,
	"category": "psychology",
	"magnitude": "minor",
	"cooldown_events": 4,
	"requirements": {
		"time_of_day": ["night"],
		"stats_above": { "stress": 30 },
	},
	"weight_modifiers": [
		{ "condition": { "stats_above": { "stress": 60 } }, "multiply": 2.0 },
		{ "condition": { "has_state": ["LONELY"] }, "multiply": 1.6 },
		{ "condition": { "stats_below": { "happiness": 40 } }, "multiply": 1.5 },
	],
	"target_resolution": { "type": "self" },
	"call_action": "late_night_stare",
	"outcomes": {
		"stats": { "stress": -5, "boredom": -5 },
	},
	"storybook_templates": [
		"{name} sat up and stared at the ceiling.",
		"It was late. {name} wasn't sleeping anyway.",
		"{name} watched the city through the window. Nothing moving.",
	],
},

"PACE_HALLWAY": {
	"scope": "character",
	"trigger_mode": "rolled",
	"base_weight": 7,
	"category": "psychology",
	"magnitude": "minor",
	"cooldown_events": 3,
	"requirements": {
		"stats_above": { "stress": 40 },
		"not_has_persistent_state": ["IN_HOSPITAL", "IN_JAIL"],
	},
	"weight_modifiers": [
		{ "condition": { "has_state": ["ANXIOUS"] }, "multiply": 2.0 },
		{ "condition": { "stats_above": { "stress": 70 } }, "multiply": 2.5 },
	],
	"target_resolution": { "type": "self" },
	"call_action": "pace_hallway",
	"outcomes": {
		"stats": { "stress": -8, "energy": -3, "boredom": -5 },
	},
	"storybook_templates": [
		"{name} paced the hallway until it helped.",
		"{name} walked circuits. Nowhere in particular.",
		"Three lengths of the corridor. Then three more.",
	],
},

"LOOK_IN_MIRROR": {
	"scope": "character",
	"trigger_mode": "rolled",
	"base_weight": 5,
	"category": "psychology",
	"magnitude": "minor",
	"cooldown_events": 6,
	"requirements": {
		"in_home_room": true,
	},
	"weight_modifiers": [
		{ "condition": { "stats_below": { "happiness": 35 } }, "multiply": 1.8 },
		{ "condition": { "has_trait": ["VAIN"] }, "multiply": 2.5 },
		{ "condition": { "has_state": ["CONTENT"] }, "multiply": 1.4 },
	],
	"target_resolution": { "type": "self" },
	"call_action": "look_in_mirror",
	"outcomes": {
		"stats": { "stress": -3 },
	},
	"storybook_templates": [
		"{name} looked in the mirror for a long moment.",
		"{name} caught their own reflection. Looked away first.",
		"The mirror again. {name} wasn't sure what they were looking for.",
	],
},

"NOD_IN_PASSING": {
	"scope": "character",
	"trigger_mode": "rolled",
	"base_weight": 12,
	"category": "social",
	"magnitude": "minor",
	"cooldown_events": 4,
	"requirements": {
		"other_character_in_room": true,
	},
	"weight_modifiers": [
		{ "condition": { "has_trait": ["SHY"] }, "multiply": 1.8 },
		{ "condition": { "has_trait": ["ANTISOCIAL"] }, "multiply": 1.5 },
		{ "condition": { "has_state": ["TIRED"] }, "multiply": 1.4 },
	],
	"target_resolution": { "type": "character", "filter": "same_room", "scope": "same_room" },
	"call_action": "nod_in_passing",
	"outcomes": {
		"stats": { "loneliness": -3 },
	},
	"storybook_templates": [
		"{name} nodded at {target}. {target} nodded back.",
		"{name} and {target} passed each other. Nothing said.",
		"Eye contact. A nod. That was enough.",
	],
},

"GREET": {
	"scope": "character",
	"trigger_mode": "rolled",
	"base_weight": 9,
	"category": "social",
	"magnitude": "minor",
	"cooldown_events": 6,
	"requirements": {
		"other_character_in_room": true,
		"stats_below": { "loneliness": 70 },
	},
	"weight_modifiers": [
		{ "condition": { "has_trait": ["SOCIAL"] }, "multiply": 2.0 },
		{ "condition": { "has_trait": ["CHARMING"] }, "multiply": 1.6 },
		{ "condition": { "has_trait": ["SHY"] }, "multiply": 0.4 },
		{ "condition": { "has_state": ["LONELY"] }, "multiply": 1.8 },
	],
	"target_resolution": { "type": "character", "filter": "same_room", "scope": "same_room" },
	"call_action": "greet",
	"outcomes": {
		"stats": { "loneliness": -8 },
		"target_stats": { "loneliness": -5 },
	},
	"storybook_templates": [
		"{name} said hello to {target}.",
		"{name} introduced themselves to {target}. First time, maybe.",
		"{name} caught {target}'s eye and smiled.",
	],
},

"CHAT": {
	"scope": "character",
	"trigger_mode": "rolled",
	"base_weight": 8,
	"category": "social",
	"magnitude": "minor",
	"cooldown_events": 3,
	"requirements": {
		"other_character_in_room": true,
		"stats_below": { "loneliness": 80 },
	},
	"weight_modifiers": [
		{ "condition": { "has_trait": ["SOCIAL"] }, "multiply": 2.0 },
		{ "condition": { "has_trait": ["GOSSIP"] }, "multiply": 1.5 },
		{ "condition": { "has_trait": ["ANTISOCIAL"] }, "multiply": 0.3 },
		{ "condition": { "has_trait": ["SHY"] }, "multiply": 0.5 },
		{ "condition": { "stats_above": { "loneliness": 50 } }, "multiply": 1.6 },
	],
	"target_resolution": { "type": "character", "filter": "same_room", "scope": "same_room" },
	"call_action": "chat",
	"outcomes": {
		"stats": { "loneliness": -12, "boredom": -10, "stress": -5 },
		"target_stats": { "loneliness": -8, "boredom": -8 },
	},
	"storybook_templates": [
		"{name} chatted with {target} for a while.",
		"{name} and {target} talked. Nothing heavy.",
		"A few minutes with {target}. {name} felt better for it.",
	],
},

"COMPLIMENT": {
	"scope": "character",
	"trigger_mode": "rolled",
	"base_weight": 5,
	"category": "social",
	"magnitude": "minor",
	"cooldown_events": 8,
	"requirements": {
		"other_character_in_room": true,
		"stats_above": { "happiness": 40 },
	},
	"weight_modifiers": [
		{ "condition": { "has_trait": ["CHARMING"] }, "multiply": 2.0 },
		{ "condition": { "has_trait": ["FLIRTATIOUS"] }, "multiply": 1.8 },
		{ "condition": { "has_state": ["CONTENT"] }, "multiply": 1.5 },
		{ "condition": { "stats_above": { "happiness": 70 } }, "multiply": 1.8 },
	],
	"target_resolution": { "type": "character", "filter": "same_room", "scope": "same_room" },
	"call_action": "compliment",
	"outcomes": {
		"stats": { "happiness": 3 },
		"target_stats": { "happiness": 8, "stress": -5 },
	},
	"storybook_templates": [
		"{name} said something kind to {target}.",
		"{name} told {target} they liked their jacket. Meant it.",
		"{target} didn't expect the compliment. {name} gave it anyway.",
	],
},

"INSULT": {
	"scope": "character",
	"trigger_mode": "rolled",
	"base_weight": 3,
	"category": "social",
	"magnitude": "minor",
	"cooldown_events": 5,
	"requirements": {
		"other_character_in_room": true,
		"stats_above": { "stress": 50 },
	},
	"weight_modifiers": [
		{ "condition": { "has_trait": ["SHORT_TEMPERED"] }, "multiply": 3.0 },
		{ "condition": { "has_trait": ["MEAN"] }, "multiply": 2.5 },
		{ "condition": { "has_state": ["FURIOUS"] }, "multiply": 3.5 },
		{ "condition": { "stats_above": { "stress": 75 } }, "multiply": 2.0 },
	],
	"target_resolution": { "type": "character", "filter": "same_room", "scope": "same_room" },
	"call_action": "insult",
	"outcomes": {
		"stats": { "stress": -8 },
		"target_stats": { "stress": 15, "happiness": -10 },
		"target_feelings": ["UPSET_FEELING"],
	},
	"storybook_templates": [
		"{name} said something cutting to {target}.",
		"{name} didn't hold back. {target} felt it.",
		"The words came out wrong. Or exactly right, depending on who you asked.",
	],
},

"SLEEP": {
	"scope": "character",
	"trigger_mode": "auto_fire",
	"base_weight": 15,
	"category": "psychology",
	"magnitude": "minor",
	"cooldown_events": 0,
	"requirements": {
		"stats_below": { "energy": 40 },
		"time_of_day": ["night", "evening"],
	},
	"weight_modifiers": [
		{ "condition": { "stats_below": { "energy": 20 } }, "multiply": 3.0 },
		{ "condition": { "has_state": ["EXHAUSTED"] }, "multiply": 4.0 },
		{ "condition": { "has_trait": ["NIGHT_OWL"] }, "multiply": 0.3 },
	],
	"target_resolution": { "type": "self" },
	"call_action": "sleep",
	"outcomes": {},
	"storybook_templates": [
		"{name} went to sleep.",
		"{name} couldn't keep their eyes open any longer.",
		"That was enough for one day. {name} slept.",
	],
},

"ENERGY_CRASH": {
	"scope": "character",
	"trigger_mode": "auto_fire",
	"priority": 95,
	"base_weight": 0,
	"category": "health",
	"magnitude": "moderate",
	"cooldown_events": 20,
	"requirements": {
		"stats_below": { "energy": 10 },
	},
	"weight_modifiers": [],
	"target_resolution": { "type": "self" },
	"call_action": "sleep",
	"outcomes": {},
	"storybook_templates": [
		"{name} crashed. Couldn't keep going.",
		"{name}'s body gave out. They slept wherever they were.",
		"That was all {name} had. They were out.",
	],
},

"ARGUE": {
	"scope": "character",
	"trigger_mode": "rolled",
	"base_weight": 4,
	"category": "social",
	"magnitude": "moderate",
	"cooldown_events": 6,
	"requirements": {
		"other_character_in_room": true,
		"stats_above": { "stress": 55 },
	},
	"weight_modifiers": [
		{ "condition": { "has_trait": ["SHORT_TEMPERED"] }, "multiply": 3.0 },
		{ "condition": { "has_trait": ["MEAN"] }, "multiply": 2.0 },
		{ "condition": { "has_state": ["FURIOUS"] }, "multiply": 4.0 },
		{ "condition": { "has_state": ["MISERABLE"] }, "multiply": 2.0 },
		{ "condition": { "stats_above": { "stress": 80 } }, "multiply": 2.5 },
	],
	"target_resolution": { "type": "character", "filter": "same_room", "scope": "same_room" },
	"call_action": "argue",
	"outcomes": {
		"stats": { "stress": 10 },
		"target_stats": { "stress": 15, "happiness": -10 },
		"feelings": ["UPSET_FEELING"],
		"target_feelings": ["UPSET_FEELING"],
	},
	"storybook_templates": [
		"{name} got into it with {target}. Neither backed down.",
		"It started small. By the end {name} and {target} were both red in the face.",
		"{name} said something to {target} that couldn't be unsaid.",
		"The argument had been building for a while. {name} finally let it out.",
	],
},

"DEEP_CONVERSATION": {
	"scope": "character",
	"trigger_mode": "rolled",
	"base_weight": 5,
	"category": "social",
	"magnitude": "moderate",
	"cooldown_events": 20,
	"requirements": {
		"other_character_in_room": true,
		"time_of_day": ["evening", "night"],
		"stats_above": { "happiness": 50 },
	},
	"weight_modifiers": [
		{ "condition": { "has_trait": ["ROMANTIC"] }, "multiply": 1.8 },
		{ "condition": { "has_trait": ["SOCIAL"] }, "multiply": 1.5 },
		{ "condition": { "has_state": ["LONELY"] }, "multiply": 2.0 },
		{ "condition": { "stats_above": { "loneliness": 50 } }, "multiply": 1.8 },
	],
	"target_resolution": { "type": "character", "filter": "same_room", "scope": "same_room", "exclude_robots": true },
	"call_action": "deep_conversation",
	"outcomes": {
		"stats": { "loneliness": -25, "stress": -10 },
		"target_stats": { "loneliness": -20, "stress": -8 },
		"feelings": ["CONTENT_FEELING"],
		"target_feelings": ["CONTENT_FEELING"],
	},
	"storybook_templates": [
		"{name} and {target} talked until the lights dimmed. Something shifted.",
		"It started as small talk. It didn't stay that way.",
		"{name} told {target} something real. {target} listened.",
		"Late night. {name} and {target} were still talking.",
	],
},

"VISIT_LIBRARY": {
	"scope": "character",
	"trigger_mode": "rolled",
	"base_weight": 5,
	"category": "psychology",
	"magnitude": "minor",
	"cooldown_events": 10,
	"requirements": {
		"not_in_room": ["library"],
		"stats_above": { "boredom": 30 },
		"not_has_persistent_state": ["IN_HOSPITAL", "IN_JAIL"],
	},
	"weight_modifiers": [
		{ "condition": { "has_trait": ["HOMEBODY"] }, "multiply": 0.5 },
		{ "condition": { "stats_above": { "boredom": 60 } }, "multiply": 1.8 },
	],
	"target_resolution": { "type": "room" },
	"call_action": "queue_intent_visit_library",
	"outcomes": {
		"stats": { "boredom": -5 },
	},
	"storybook_templates": [
		"{name} headed to the library.",
		"{name} needed somewhere quiet.",
	],
},

"READ_BOOK": {
	"scope": "character",
	"trigger_mode": "rolled",
	"base_weight": 14,
	"category": "psychology",
	"magnitude": "minor",
	"cooldown_events": 2,
	"requirements": {
		"in_room": ["library"],
	},
	"weight_modifiers": [
		{ "condition": { "stats_above": { "boredom": 40 } }, "multiply": 1.8 },
		{ "condition": { "has_state": ["RESTLESS"] }, "multiply": 1.5 },
		{ "condition": { "stats_above": { "stress": 50 } }, "multiply": 1.6 },
	],
	"target_resolution": { "type": "self" },
	"call_action": "read_book",
	"outcomes": {
		"stats": { "boredom": -20, "stress": -10, "happiness": 5 },
	},
	"storybook_templates": [
		"{name} found a book and disappeared into it.",
		"{name} read for hours. The building kept going without them.",
		"The library was quiet. {name} was exactly where they needed to be.",
	],
},

"DRINK_ALONE": {
	"scope": "character",
	"trigger_mode": "rolled",
	"base_weight": 6,
	"category": "psychology",
	"magnitude": "minor",
	"cooldown_events": 4,
	"requirements": {
		"in_room": ["bar"],
		"stats_below": { "happiness": 35 },
	},
	"weight_modifiers": [
		{ "condition": { "has_state": ["MISERABLE"] }, "multiply": 2.5 },
		{ "condition": { "has_state": ["LONELY"] }, "multiply": 2.0 },
		{ "condition": { "has_trait": ["ALCOHOLIC"] }, "multiply": 2.0 },
		{ "condition": { "stats_below": { "happiness": 20 } }, "multiply": 2.0 },
	],
	"target_resolution": { "type": "self" },
	"call_action": "drink_alone",
	"outcomes": {
		"stats": { "stress": -5, "loneliness": 8, "cash": -5, "addiction": 2 },
		"feelings": ["MELANCHOLY_FEELING"],
	},
	"storybook_templates": [
		"{name} drank alone. Nobody sat next to them.",
		"The bar was full. {name} was still alone in it.",
		"{name} nursed their drink and didn't look up.",
		"Another round. {name} wasn't counting.",
	],
},

"FLIRT": {
	"scope": "character",
	"trigger_mode": "rolled",
	"base_weight": 3,
	"category": "romantic",
	"magnitude": "moderate",
	"cooldown_events": 8,
	"requirements": {
		"other_character_in_room": true,
		"stats_above": { "happiness": 55 },
	},
	"weight_modifiers": [
		{ "condition": { "has_trait": ["FLIRTATIOUS"] }, "multiply": 4.0 },
		{ "condition": { "has_trait": ["ROMANTIC"] }, "multiply": 2.0 },
		{ "condition": { "has_trait": ["SHY"] }, "multiply": 0.2 },
		{ "condition": { "stats_above": { "happiness": 75 } }, "multiply": 1.8 },
		{ "condition": { "has_state": ["CONTENT"] }, "multiply": 1.5 },
	],
	"target_resolution": { "type": "character", "filter": "same_room", "scope": "same_room", "exclude_robots": true },
	"call_action": "flirt",
	"outcomes": {
		"stats": { "happiness": 5 },
		"target_stats": { "happiness": 5 },
	},
	"storybook_templates": [
		"{name} flirted with {target}. Subtly, or not.",
		"{name} said something to {target} that wasn't quite a compliment.",
		"{target} caught {name} looking. {name} didn't look away.",
		"{name} turned the charm on. {target} noticed.",
	],
},

"PLAY_POOL_INVITE": {
	"scope": "character",
	"trigger_mode": "rolled",
	"base_weight": 6,
	"category": "social",
	"magnitude": "minor",
	"cooldown_events": 10,
	"sequence_key": "PLAY_POOL_SEQ",
	"requirements": {
		"in_room": ["bar"],
		"other_character_in_room": true,
		"stats_above": { "energy": 30 },
	},
	"weight_modifiers": [
		{ "condition": { "has_trait": ["COMPETITIVE"] },      "multiply": 2.0 },
		{ "condition": { "has_trait": ["SOCIAL"] },           "multiply": 1.5 },
		{ "condition": { "stats_above": { "boredom": 50 } }, "multiply": 1.4 },
	],
	"target_resolution": {
		"type": "character",
		"filter": "same_room",
		"scope": "same_room",
		"exclude_robots": true,
	},
	"call_action": "start_pool_game",
	"outcomes": {
		"stats": { "boredom": -5 },
	},
	"storybook_templates": [
		"{name} challenged {target} to a game of pool.",
		"{name} picked up a cue and nodded at {target}.",
	],
},

"SPILL_DRINK": {
	"scope": "character",
	"trigger_mode": "rolled",
	"base_weight": 1,
	"category": "comedy",
	"magnitude": "minor",
	"cooldown_events": 25,
	"requirements": {
		"in_room": ["bar", "cafe"],
		"other_character_in_room": true,
	},
	"weight_modifiers": [
		{ "condition": { "has_trait": ["FORGETFUL"] }, "multiply": 3.0 },
		{ "condition": { "has_trait": ["RECKLESS"] }, "multiply": 2.0 },
		{ "condition": { "stats_below": { "energy": 30 } }, "multiply": 1.5 },
	],
	"target_resolution": { "type": "character", "filter": "same_room", "scope": "same_room" },
	"call_action": "spill_drink",
	"outcomes": {
		"stats": { "happiness": -3 },
		"feelings": ["HUMILIATED"],
	},
	"storybook_templates": [
		"{name} knocked their drink over. The whole place noticed.",
		"It went everywhere. {name} pretended it didn't.",
		"{name} spilled it. Right in front of {target}.",
	],
},

"PHYSICAL_FIGHT": {
	"scope": "character",
	"trigger_mode": "rolled",
	"base_weight": 1,
	"category": "violence",
	"magnitude": "major",
	"cooldown_events": 30,
	"requirements": {
		"other_character_in_room": true,
		"stats_above": { "stress": 75 },
	},
	"weight_modifiers": [
		{ "condition": { "has_feeling": ["FURIOUS"] }, "multiply": 3.0 },
		{ "condition": { "has_trait": ["VIOLENT"] }, "multiply": 4.0 },
		{ "condition": { "has_trait": ["SHORT_TEMPERED"] }, "multiply": 2.5 },
		{ "condition": { "stats_above": { "stress": 90 } }, "multiply": 2.0 },
	],
	"target_resolution": { "type": "character", "filter": "same_room", "scope": "same_room" },
	"call_action": "physical_fight",
	"outcomes": {
		"stats": { "stress": 25, "happiness": -10, "health": -10 },
		"target_stats": { "stress": 25, "happiness": -10, "health": -12 },
		"feelings": ["COCKY"],
		"target_feelings": ["HUMILIATED", "FURIOUS"],
	},
	"storybook_templates": [
		"{name} hit {target}. The room went quiet.",
		"It happened fast. {name} and {target}. Blood on the floor.",
		"Someone was always going to throw the first punch. {name} did.",
	],
},

"CONFRONT": {
	"scope": "character",
	"trigger_mode": "rolled",
	"base_weight": 3,
	"category": "social",
	"magnitude": "moderate",
	"cooldown_events": 15,
	"requirements": {
		"other_character_in_room": true,
		"stats_above": { "stress": 65 },
	},
	"weight_modifiers": [
		{ "condition": { "has_feeling": ["FURIOUS"] }, "multiply": 2.5 },
		{ "condition": { "has_trait": ["STUBBORN"] }, "multiply": 1.8 },
		{ "condition": { "has_trait": ["BY_THE_BOOK"] }, "multiply": 1.5 },
	],
	"target_resolution": { "type": "character", "filter": "same_room", "scope": "same_room" },
	"call_action": "confront",
	"outcomes": {
		"stats": { "stress": -8 },
		"target_stats": { "stress": 12, "happiness": -5 },
		"feelings": ["RELIEVED"],
		"target_feelings": ["ANXIOUS"],
	},
	"storybook_templates": [
		"{name} cornered {target}. There was something that needed saying.",
		"{name} finally said what they'd been holding in.",
		"{target} could see it coming. {name} didn't soften it.",
	],
},

"GOSSIP": {
	"scope": "character",
	"trigger_mode": "rolled",
	"base_weight": 4,
	"category": "social",
	"magnitude": "minor",
	"cooldown_events": 8,
	"requirements": {
		"other_character_in_room": true,
	},
	"weight_modifiers": [
		{ "condition": { "has_trait": ["GOSSIP"] }, "multiply": 4.0 },
		{ "condition": { "has_trait": ["NOSY"] }, "multiply": 2.0 },
		{ "condition": { "has_trait": ["SECRETIVE"] }, "multiply": 0.3 },
	],
	"target_resolution": { "type": "character", "filter": "same_room", "scope": "same_room" },
	"call_action": "gossip",
	"outcomes": {
		"stats": { "boredom": -8 },
		"target_stats": { "boredom": -5 },
	},
	"storybook_templates": [
		"{name} leaned in and told {target} something they probably shouldn't have.",
		"{name} had heard a thing. {target} got the full version.",
		"{name} kept their voice low. {target} listened.",
	],
},

"VISIT_CAFE": {
	"scope": "character",
	"trigger_mode": "rolled",
	"base_weight": 5,
	"category": "social",
	"magnitude": "minor",
	"cooldown_events": 10,
	"requirements": {
		"not_in_room": ["cafe"],
		"not_has_persistent_state": ["IN_HOSPITAL", "IN_JAIL"],
	},
	"weight_modifiers": [
		{ "condition": { "stats_above": { "hunger": 40 } }, "multiply": 1.8 },
		{ "condition": { "stats_above": { "loneliness": 40 } }, "multiply": 1.5 },
		{ "condition": { "stats_above": { "boredom": 40 } }, "multiply": 1.3 },
	],
	"target_resolution": { "type": "room" },
	"call_action": "queue_intent_visit_cafe",
	"outcomes": {
		"stats": { "boredom": -5 },
	},
	"storybook_templates": [
		"{name} headed to the cafe.",
		"{name} needed something warm. And somewhere to sit.",
	],
},

"ORDER_FOOD": {
	"scope": "character",
	"trigger_mode": "rolled",
	"base_weight": 10,
	"category": "social",
	"magnitude": "minor",
	"cooldown_events": 1,
	"requirements": {
		"in_room": ["cafe"],
		"stats_above": { "cash": 8, "hunger": 20 },
	},
	"weight_modifiers": [
		{ "condition": { "stats_above": { "hunger": 60 } }, "multiply": 2.5 },
		{ "condition": { "has_trait": ["BIG_APPETITE"] }, "multiply": 2.0 },
	],
	"target_resolution": { "type": "self" },
	"call_action": "order_food",
	"outcomes": {
		"stats": { "cash": -8, "hunger": -40, "happiness": 5 },
		"feelings": ["WELL_FED"],
	},
	"storybook_templates": [
		"{name} ordered something. It was warm and that was enough.",
		"{name} ate. Not gourmet, but it didn't need to be.",
	],
},

"ORDER_COFFEE": {
	"scope": "character",
	"trigger_mode": "rolled",
	"base_weight": 8,
	"category": "social",
	"magnitude": "minor",
	"cooldown_events": 2,
	"requirements": {
		"in_room": ["cafe"],
		"stats_above": { "cash": 3 },
	},
	"weight_modifiers": [
		{ "condition": { "stats_below": { "energy": 50 } }, "multiply": 1.8 },
		{ "condition": { "has_state": ["TIRED"] }, "multiply": 2.0 },
	],
	"target_resolution": { "type": "self" },
	"call_action": "order_coffee",
	"outcomes": {
		"stats": { "cash": -3, "energy": 10, "stress": -3, "boredom": -5 },
	},
	"storybook_templates": [
		"{name} got a coffee. The day could begin now.",
		"{name} wrapped their hands around the cup. Warmer.",
	],
},

"SIT_ALONE_CAFE": {
	"scope": "character",
	"trigger_mode": "rolled",
	"base_weight": 5,
	"category": "social",
	"magnitude": "minor",
	"cooldown_events": 4,
	"requirements": {
		"in_room": ["cafe"],
	},
	"weight_modifiers": [
		{ "condition": { "has_trait": ["RECLUSIVE"] }, "multiply": 2.0 },
		{ "condition": { "has_trait": ["SHY"] }, "multiply": 1.6 },
		{ "condition": { "stats_above": { "boredom": 40 } }, "multiply": 1.5 },
	],
	"target_resolution": { "type": "self" },
	"call_action": "sit_alone_cafe",
	"outcomes": {
		"stats": { "boredom": -10, "loneliness": -3, "stress": -5 },
	},
	"storybook_templates": [
		"{name} sat in the corner and watched the cafe move around them.",
		"{name} didn't want to talk. Just wanted to be near people.",
		"A coffee, a window seat, an hour. {name} took the long way through it.",
	],
},

"SHARE_MEAL": {
	"scope": "character",
	"trigger_mode": "rolled",
	"base_weight": 5,
	"category": "social",
	"magnitude": "minor",
	"cooldown_events": 12,
	"requirements": {
		"in_room": ["cafe"],
		"other_character_in_room": true,
		"stats_above": { "cash": 6 },
	},
	"weight_modifiers": [
		{ "condition": { "has_trait": ["SOCIAL"] }, "multiply": 1.8 },
		{ "condition": { "has_trait": ["GENEROUS"] }, "multiply": 2.0 },
		{ "condition": { "stats_above": { "hunger": 40 } }, "multiply": 1.6 },
	],
	"target_resolution": { "type": "character", "filter": "same_room", "scope": "same_room", "exclude_robots": true },
	"call_action": "share_meal",
	"outcomes": {
		"stats": { "hunger": -30, "cash": -6, "loneliness": -15 },
		"target_stats": { "hunger": -30, "loneliness": -15 },
		"feelings": ["WELL_FED"],
		"target_feelings": ["WELL_FED"],
	},
	"storybook_templates": [
		"{name} and {target} ate together. The food wasn't the point.",
		"Lunch with {target}. {name} couldn't remember the last time someone sat with them.",
		"{name} and {target} split a meal. Neither said much. Both ate slowly.",
	],
},

"COOK_MEAL": {
	"scope": "character",
	"trigger_mode": "rolled",
	"base_weight": 6,
	"category": "psychology",
	"magnitude": "minor",
	"cooldown_events": 4,
	"requirements": {
		"in_home_room": true,
		"stats_above": { "hunger": 30 },
	},
	"weight_modifiers": [
		{ "condition": { "has_trait": ["BIG_APPETITE"] }, "multiply": 1.8 },
		{ "condition": { "has_trait": ["STINGY"] }, "multiply": 1.5 },
		{ "condition": { "stats_below": { "cash": 30 } }, "multiply": 1.6 },
	],
	"target_resolution": { "type": "self" },
	"call_action": "cook_meal",
	"outcomes": {
		"stats": { "hunger": -50, "cash": -3, "happiness": 8, "boredom": -5 },
		"feelings": ["WELL_FED", "SATISFIED"],
	},
	"storybook_templates": [
		"{name} cooked for themselves. It wasn't bad.",
		"{name} made something in the kitchen. The whole floor could smell it.",
		"Dinner alone. {name} took their time with it.",
	],
},

"STUDY_TOGETHER": {
	"scope": "character",
	"trigger_mode": "rolled",
	"base_weight": 6,
	"category": "psychology",
	"magnitude": "minor",
	"cooldown_events": 5,
	"requirements": {
		"in_room": ["library"],
		"other_character_in_room": true,
	},
	"weight_modifiers": [
		{ "condition": { "stats_above": { "boredom": 40 } }, "multiply": 1.5 },
		{ "condition": { "has_trait": ["MOTIVATED"] }, "multiply": 1.8 },
	],
	"target_resolution": { "type": "character", "filter": "same_room", "scope": "same_room", "exclude_robots": true },
	"call_action": "study_together",
	"outcomes": {
		"stats": { "boredom": -15, "loneliness": -8, "stress": -3 },
		"target_stats": { "boredom": -15, "loneliness": -8, "stress": -3 },
	},
	"storybook_templates": [
		"{name} and {target} studied together. Someone turned a page too loudly.",
		"They sat across from each other, books open, occasionally looking up.",
		"{name} and {target} worked in parallel. Neither needed to talk much.",
	],
},

"QUIET_MOMENT_TOGETHER": {
	"scope": "character",
	"trigger_mode": "rolled",
	"base_weight": 3,
	"category": "psychology",
	"magnitude": "minor",
	"cooldown_events": 15,
	"requirements": {
		"in_room": ["library"],
		"other_character_in_room": true,
	},
	"weight_modifiers": [
		{ "condition": { "has_state": ["CONTENT"] }, "multiply": 2.0 },
		{ "condition": { "stats_above": { "loneliness": 40 } }, "multiply": 1.5 },
	],
	"target_resolution": { "type": "character", "filter": "same_room", "scope": "same_room", "exclude_robots": true },
	"call_action": "quiet_moment_together",
	"outcomes": {
		"stats": { "loneliness": -12, "stress": -5 },
		"target_stats": { "loneliness": -12, "stress": -5 },
	},
	"storybook_templates": [
		"{name} and {target} sat near each other. Neither spoke.",
		"They didn't talk. They didn't have to.",
		"{name} and {target} shared the silence. It was easier this way.",
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
