# events.gd
# Autoload — available globally as Events
# Tier 1 Config — pure data, no dependencies
#
# Defines every event in the game. Sim reads from here, evaluates
# eligibility, rolls weighted picks, and calls Actions to execute outcomes.
#
# Sorted by location: Universal → Home → Bar → Cafe → Library → Grocery → Social
#
# ── BASE EVENT LAYER (Session 22) ────────────────────────────
# Every rolled character-scope event gets a base_category field:
#   "fulfill_need" | "socialize" | "visit" | "introspect" | "idle" | "work"
# Array if multi-category. Omit for auto_fire events and conflict
# events flagged for reactive redesign.
#
# Events with fulfill_need also get a fulfills_need field (string or
# array) naming the stat(s) this event addresses.
#
# ── DELETIONS (Session 22) ───────────────────────────────────
# Removed: GREET, COMPLIMENT, INSULT, ARGUE, SHARE_STORY,
#   REMINISCE_TOGETHER, SHARE_SECRET, BETRAY_SECRET, SPILL_DRINK,
#   DEEP_CONVERSATION
# These are being folded into CONVERSE_SEQ as beats (future task)
# or scrapped for Phase 5 redesign (SPILL_DRINK).
# Their action functions remain in actions.gd — sequences call them.
#
# ── CONFLICT EVENTS (no base_category) ──────────────────────
# MOCK, COLD_SHOULDER, PROVOKE, PHYSICAL_FIGHT, CONFRONT
# Flagged for reactive/auto-fire redesign (relationship-proximity
# trigger, not base-roll). Left in events.gd without base_category
# so they don't enter the category pool.

extends Node


const EVENTS: Dictionary = {

# ═════════════════════════════════════════════════════════════
# UNIVERSAL — fire for any character, anywhere
# ═════════════════════════════════════════════════════════════

"REST": {
	"scope": "character",
	"trigger_mode": "rolled",
	"base_category": "fulfill_need",
	"fulfills_need": "energy",
	"base_weight": 12,
	"category": "psychology",
	"magnitude": "minor",
	"cooldown_events": 8,
	"requirements": {
		"stats_below": { "energy": 50 },
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
	"base_category": "idle",
	"base_weight": 8,
	"category": "psychology",
	"magnitude": "minor",
	"cooldown_events": 3,
	"boredom_exempt": true,
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

# GO_HOME — converted to auto_fire (Session 22). Needs-driven:
# tired, stressed, social battery depleted. Priority 75 sits below
# SLEEP (90) and ENERGY_CRASH (95), intentionally soft enough that
# drunk/distracted characters can miss the window.
"GO_HOME": {
	"scope": "character",
	"trigger_mode": "auto_fire",
	"priority": 75,
	"base_weight": 0,
	"category": "daily_life",
	"magnitude": "minor",
	"cooldown_events": 8,
	"boredom_exempt": true,
	"requirements": {
		"not_in_home_room": true,
	},
	"weight_modifiers": [
		{ "condition": { "stats_below": { "energy": 40 } }, "multiply": 3.0 },
		{ "condition": { "has_state": ["TIRED"] }, "multiply": 4.0 },
		{ "condition": { "has_state": ["EXHAUSTED"] }, "multiply": 6.0 },
		{ "condition": { "stats_above": { "stress": 70 } }, "multiply": 2.0 },
		{ "condition": { "stats_above": { "boredom": 60 } }, "multiply": 2.5 },
		{ "condition": { "stats_below": { "happiness": 25 } }, "multiply": 2.0 },
	],
	"target_resolution": { "type": "self" },
	"call_action": "go_home",
	"outcomes": {},
	"storybook_templates": [
		"{name} headed home.",
		"{name} decided to call it a day.",
	],
},

"DAYDREAM": {
	"scope": "character",
	"trigger_mode": "rolled",
	"base_category": "idle",
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

"THINK_ABOUT": {
	"scope": "character",
	"trigger_mode": "rolled",
	"base_category": "introspect",
	"base_weight": 10,
	"category": "psychology",
	"magnitude": "minor",
	"cooldown_events": 2,
	"requirements": {
		"has_memorable_entries": true,
	},
	"weight_modifiers": [
		{ "condition": { "has_state": ["LONELY"] }, "multiply": 1.6 },
		{ "condition": { "has_state": ["RESTLESS"] }, "multiply": 1.3 },
		{ "condition": { "stats_above": { "grief": 20 } }, "multiply": 2.0 },
	],
	"target_resolution": { "type": "memory" },
	"call_action": "think_about",
	"outcomes": {},
	"storybook_templates": [
		"{name} thought about {target}.",
		"{target} crossed {name}'s mind again.",
		"It came back to {name}. {target}. That whole thing.",
	],
},

"BROOD": {
	"scope": "character",
	"trigger_mode": "rolled",
	"base_category": "introspect",
	"base_weight": 5,
	"category": "psychology",
	"magnitude": "minor",
	"cooldown_events": 6,
	"requirements": {
		"has_memorable_entries": true,
		"stats_above": { "stress": 40 },
	},
	"weight_modifiers": [
		{ "condition": { "has_state": ["MISERABLE"] }, "multiply": 2.5 },
		{ "condition": { "has_trait": ["PARANOID"] }, "multiply": 2.0 },
		{ "condition": { "has_trait": ["PESSIMISTIC"] }, "multiply": 1.8 },
		{ "condition": { "stats_above": { "stress": 70 } }, "multiply": 2.0 },
	],
	"target_resolution": { "type": "memory" },
	"call_action": "brood",
	"outcomes": {
		"stats": { "stress": 5, "happiness": -5 },
	},
	"storybook_templates": [
		"{name} kept turning it over. What {target} did. What it meant.",
		"It was eating at {name}. The thing with {target}.",
		"{name} couldn't let it go. Not yet.",
	],
},

"SMILE_AT_MEMORY": {
	"scope": "character",
	"trigger_mode": "rolled",
	"base_category": "introspect",
	"base_weight": 4,
	"category": "psychology",
	"magnitude": "minor",
	"cooldown_events": 8,
	"requirements": {
		"has_memorable_entries": true,
		"stats_above": { "happiness": 40 },
	},
	"weight_modifiers": [
		{ "condition": { "has_state": ["CONTENT"] }, "multiply": 2.0 },
		{ "condition": { "has_trait": ["OPTIMISTIC"] }, "multiply": 1.8 },
		{ "condition": { "stats_above": { "happiness": 65 } }, "multiply": 1.5 },
	],
	"target_resolution": { "type": "memory" },
	"call_action": "smile_at_memory",
	"outcomes": {
		"stats": { "happiness": 5, "stress": -3 },
	},
	"storybook_templates": [
		"{name} smiled, thinking about {target}. Just for a second.",
		"Something about {target} came back to {name}. The good kind.",
		"{name} caught {themself} smiling. {target}. That was why.",
	],
},

"CRY": {
	"scope": "character",
	"trigger_mode": "rolled",
	"base_category": "introspect",
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
	"base_category": "idle",
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
	"base_category": "idle",
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

# ── Auto-fire events (no base_category — bypass base roll) ──

"SLEEP": {
	"scope": "character",
	"trigger_mode": "auto_fire",
	"priority": 90,
	"base_weight": 15,
	"category": "psychology",
	"magnitude": "minor",
	"cooldown_events": 0,
	"requirements": {
		"stats_below": { "energy": 40 },
		"time_of_day": ["night", "evening"],
		"in_home_room": true,
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
		"{name} couldn't keep {their} eyes open any longer.",
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
		"stats_below": { "energy": 5 },
	},
	"weight_modifiers": [],
	"target_resolution": { "type": "self" },
	"call_action": "energy_crash",
	"outcomes": {},
	"storybook_templates": [
		"{name} crashed. Couldn't keep going.",
		"{name}'s body gave out. {They} slept wherever they were.",
		"That was all {name} had. {They} {were_was} out.",
	],
},

# ═════════════════════════════════════════════════════════════
# HOME — apartment events
# ═════════════════════════════════════════════════════════════

"CHECK_FRIDGE": {
	"scope": "character",
	"trigger_mode": "rolled",
	"base_category": ["fulfill_need", "idle"],
	"fulfills_need": "hunger",
	"base_weight": 8,
	"category": "daily_life",
	"magnitude": "minor",
	"cooldown_events": 4,
	"requirements": {
		"in_home_room": true,
		"room_has_zone": "Zone_Fridge",
	},
	"weight_modifiers": [
		{ "condition": { "stats_above": { "hunger": 30 } }, "multiply": 2.5 },
		{ "condition": { "has_trait": ["BIG_APPETITE"] }, "multiply": 2.0 },
		{ "condition": { "has_state": ["TIRED"] }, "multiply": 1.4 },
	],
	"target_resolution": { "type": "self" },
	"call_action": "check_fridge",
	"outcomes": {
		"stats": { "hunger": -15, "boredom": -3 },
	},
	"storybook_templates": [
		"{name} stood in front of the open fridge for a moment. Closed it. Opened it again.",
		"{name} found something in the fridge. Good enough.",
		"Not much left. {name} made it work.",
	],
},

"SIT_AT_DESK": {
	"scope": "character",
	"trigger_mode": "rolled",
	"base_category": "idle",
	"base_weight": 6,
	"category": "psychology",
	"magnitude": "minor",
	"cooldown_events": 5,
	"requirements": {
		"in_home_room": true,
		"room_has_zone": "Zone_Desk",
	},
	"weight_modifiers": [
		{ "condition": { "has_trait": ["MOTIVATED"] }, "multiply": 2.5 },
		{ "condition": { "has_trait": ["BOOKWORM"] }, "multiply": 1.8 },
		{ "condition": { "stats_above": { "boredom": 30 } }, "multiply": 1.5 },
		{ "condition": { "has_state": ["RESTLESS"] }, "multiply": 1.8 },
	],
	"target_resolution": { "type": "self" },
	"call_action": "sit_at_desk",
	"outcomes": {
		"stats": { "boredom": -15, "stress": -5, "energy": -3 },
	},
	"storybook_templates": [
		"{name} sat at the desk. Stared at it. Did something, eventually.",
		"{name} opened something up and got to work.",
		"The desk was cluttered. {name} worked around it.",
		"{name} sat down with the intention of being productive. Mostly succeeded.",
	],
},

"EAT_AT_HOME": {
	"scope": "character",
	"trigger_mode": "rolled",
	"base_category": "fulfill_need",
	"fulfills_need": "hunger",
	"base_weight": 7,
	"category": "daily_life",
	"magnitude": "minor",
	"cooldown_events": 3,
	"boredom_exempt_traits": ["BIG_APPETITE"],
	"requirements": {
		"in_home_room": true,
		"room_has_zone": "Zone_Fridge",
		"stats_above": { "hunger": 40 },
	},
	"weight_modifiers": [
		{ "condition": { "stats_above": { "hunger": 65 } }, "multiply": 2.5 },
		{ "condition": { "has_trait": ["BIG_APPETITE"] }, "multiply": 2.0 },
		{ "condition": { "stats_below": { "cash": 15 } }, "multiply": 2.0 },
	],
	"target_resolution": { "type": "self" },
	"call_action": "eat_at_home",
	"outcomes": {
		"stats": { "hunger": -40, "happiness": 5 },
		"feelings": ["WELL_FED"],
	},
	"storybook_templates": [
		"{name} ate at home. Cheaper, quieter.",
		"{name} made something quick. It was fine.",
		"Dinner in. {name} didn't feel like going out.",
	],
},

"LOOK_IN_MIRROR": {
	"scope": "character",
	"trigger_mode": "rolled",
	"base_category": "idle",
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
		"{name} caught {their} own reflection. Looked away first.",
		"The mirror again. {name} wasn't sure what {they} {were_was} looking for.",
	],
},

"LIE_IN_BED": {
	"scope": "character",
	"trigger_mode": "rolled",
	"base_category": ["fulfill_need", "idle"],
	"fulfills_need": "energy",
	"base_weight": 8,
	"category": "psychology",
	"magnitude": "minor",
	"cooldown_events": 3,
	"requirements": {
		"in_home_room": true,
		"room_has_zone": "Zone_Bed",
	},
	"weight_modifiers": [
		{ "condition": { "has_state": ["TIRED"] }, "multiply": 2.5 },
		{ "condition": { "has_state": ["MISERABLE"] }, "multiply": 2.0 },
		{ "condition": { "has_trait": ["LAZY"] }, "multiply": 1.8 },
	],
	"target_resolution": { "type": "self" },
	"call_action": "lie_in_bed",
	"outcomes": {
		"stats": { "energy": 8, "stress": -5, "boredom": 8 },
	},
	"storybook_templates": [
		"{name} lay on the bed and stared at the ceiling.",
		"{name} climbed into bed. Not to sleep. Just to stop.",
		"The bed was the only thing that made sense right now.",
	],
},

"COOK_MEAL": {
	"scope": "character",
	"trigger_mode": "rolled",
	"base_category": "fulfill_need",
	"fulfills_need": "hunger",
	"base_weight": 6,
	"category": "psychology",
	"magnitude": "minor",
	"cooldown_events": 4,
	"requirements": {
		"in_home_room": true,
		"stats_above": { "hunger": 30 },
		"room_has_zone": "Zone_Fridge",
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

# ═════════════════════════════════════════════════════════════
# BAR — travel, counter, lounge, pool
# ═════════════════════════════════════════════════════════════

"VISIT_BAR": {
	"scope": "character",
	"trigger_mode": "rolled",
	"base_category": "visit",
	"base_weight": 6,
	"category": "social",
	"magnitude": "minor",
	"cooldown_events": 8,
	"boredom_exempt": true,
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
		"stats": { "boredom": -5 },
	},
	"storybook_templates": [
		"{name} headed to the bar.",
		"{name} needed a drink. Or just somewhere to be.",
	],
},

# ── Bar — Counter zone events ───────────────────────────────

"SIT_AT_BAR": {
	"scope": "character",
	"trigger_mode": "rolled",
	"base_category": "idle",
	"base_weight": 12,
	"category": "social",
	"magnitude": "minor",
	"cooldown_events": 2,
	"boredom_exempt_traits": ["ALCOHOLIC"],
	"requirements": {
		"in_room": ["bar"],
		"room_has_zone": "Zone_Counter",
		"zone_has_space": "Zone_Counter",
	},
	"weight_modifiers": [
		{ "condition": { "has_trait": ["ALCOHOLIC"] }, "multiply": 2.0 },
		{ "condition": { "stats_above": { "stress": 50 } }, "multiply": 1.5 },
	],
	"target_resolution": { "type": "self" },
	"call_action": "sit_at_bar",
	"outcomes": {
		"stats": { "stress": -5, "loneliness": -3 },
	},
	"storybook_templates": [
		"{name} took a seat at the bar.",
		"{name} claimed a barstool. Elbows on the counter.",
	],
},

"ORDER_DRINK": {
	"scope": "character",
	"trigger_mode": "rolled",
	"base_category": ["fulfill_need", "socialize", "idle"],
	"fulfills_need": "stress",
	"base_weight": 14,
	"category": "social",
	"magnitude": "minor",
	"cooldown_events": 0,
	"boredom_exempt_traits": ["ALCOHOLIC", "ADDICT_PRONE"],
	"requirements": {
		"in_room": ["bar"],
		"room_has_zone": "Zone_Counter",
		"zone_has_space": "Zone_Counter",
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

# DRINK_ALONE — parking lot: fold into ORDER_DRINK with force-roll
# for drink location (counter vs lounge). Keeping as-is for now.
"DRINK_ALONE": {
	"scope": "character",
	"trigger_mode": "rolled",
	"base_category": ["fulfill_need", "idle"],
	"fulfills_need": "stress",
	"base_weight": 6,
	"category": "psychology",
	"magnitude": "minor",
	"cooldown_events": 4,
	"boredom_exempt_traits": ["ALCOHOLIC", "ADDICT_PRONE"],
	"requirements": {
		"in_room": ["bar"],
		"room_has_zone": "Zone_Counter",
		"zone_has_space": "Zone_Counter",
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

"LEAN_ON_COUNTER": {
	"scope": "character",
	"trigger_mode": "rolled",
	"base_category": "idle",
	"base_weight": 6,
	"category": "social",
	"magnitude": "minor",
	"cooldown_events": 5,
	"requirements": {
		"in_room": ["bar", "cafe"],
		"in_zone": "Zone_Counter",
	},
	"weight_modifiers": [
		{ "condition": { "has_state": ["TIRED"] }, "multiply": 2.0 },
	],
	"target_resolution": { "type": "self" },
	"call_action": "lean_on_counter",
	"outcomes": {
		"stats": { "energy": 3, "stress": -3 },
	},
	"storybook_templates": [
		"{name} leaned against the counter and watched the room.",
		"{name} wasn't going anywhere. Not yet.",
	],
},

"NURSE_DRINK": {
	"scope": "character",
	"trigger_mode": "rolled",
	"base_category": "idle",
	"base_weight": 10,
	"category": "social",
	"magnitude": "minor",
	"cooldown_events": 2,
	"requirements": {
		"in_room": ["bar"],
		"in_zone": "Zone_Counter",
	},
	"weight_modifiers": [
		{ "condition": { "has_state": ["TIRED"] }, "multiply": 1.5 },
		{ "condition": { "has_trait": ["ALCOHOLIC"] }, "multiply": 1.8 },
		{ "condition": { "stats_above": { "stress": 40 } }, "multiply": 1.5 },
	],
	"target_resolution": { "type": "self" },
	"call_action": "nurse_drink",
	"outcomes": {
		"stats": { "stress": -3, "boredom": -5 },
	},
	"storybook_templates": [
		"{name} nursed {their} drink. No rush.",
		"The glass was still half full. {name} made it last.",
		"{name} turned the glass slowly. Thinking.",
	],
},

# ── Bar — Lounge zone events ────────────────────────────────

"HANG_AT_LOUNGE": {
	"scope": "character",
	"trigger_mode": "rolled",
	"base_category": "idle",
	"base_weight": 8,
	"category": "social",
	"magnitude": "minor",
	"cooldown_events": 4,
	"requirements": {
		"in_room": ["bar"],
		"room_has_zone": "Zone_Lounge",
		"zone_has_space": "Zone_Lounge",
	},
	"weight_modifiers": [
		{ "condition": { "has_trait": ["SOCIAL"] }, "multiply": 1.5 },
		{ "condition": { "stats_above": { "boredom": 30 } }, "multiply": 1.5 },
		{ "condition": { "has_state": ["CONTENT"] }, "multiply": 1.4 },
	],
	"target_resolution": { "type": "self" },
	"call_action": "hang_at_lounge",
	"outcomes": {
		"stats": { "stress": -5, "boredom": -8, "loneliness": -5 },
	},
	"storybook_templates": [
		"{name} settled into the lounge area. Feet up, guard down.",
		"{name} moved to the lounge. Better view from here.",
		"The bar was loud. The lounge was just right.",
	],
},

"WATCH_THE_ROOM": {
	"scope": "character",
	"trigger_mode": "rolled",
	"base_category": "idle",
	"base_weight": 10,
	"category": "psychology",
	"magnitude": "minor",
	"cooldown_events": 3,
	"requirements": {
		"in_room": ["bar", "cafe"],
	},
	"weight_modifiers": [
		{ "condition": { "has_trait": ["NOSY"] }, "multiply": 1.8 },
		{ "condition": { "has_trait": ["SHY"] }, "multiply": 1.5 },
		{ "condition": { "stats_above": { "boredom": 30 } }, "multiply": 1.5 },
	],
	"target_resolution": { "type": "self" },
	"call_action": "watch_the_room",
	"outcomes": {
		"stats": { "boredom": -8, "loneliness": -3 },
	},
	"storybook_templates": [
		"{name} watched the room. Everyone had somewhere to be.",
		"{name} sat and took it all in. The noise helped.",
		"People came and went. {name} stayed.",
	],
},

# ── Bar — Pool zone events ──────────────────────────────────

"PLAY_POOL_INVITE": {
	"scope": "character",
	"trigger_mode": "rolled",
	"base_category": "socialize",
	"base_weight": 6,
	"category": "social",
	"magnitude": "minor",
	"cooldown_events": 10,
	"boredom_exempt_traits": ["COMPETITIVE", "GAMBLER"],
	"sequence_key": "PLAY_POOL_SEQ",
	"requirements": {
		"in_room": ["bar"],
		"other_character_in_room": true,
		"stats_above": { "energy": 30 },
		"room_has_zone": "Zone_Pool",
		"zone_has_space": "Zone_Pool",
	},
	"weight_modifiers": [
		{ "condition": { "has_trait": ["COMPETITIVE"] }, "multiply": 2.0 },
		{ "condition": { "has_trait": ["SOCIAL"] }, "multiply": 1.5 },
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

# SPILL_DRINK — DELETED Session 22. Reintroduce in Phase 5 as
# reaction event tied to inventory (character holding a drink).

# ═════════════════════════════════════════════════════════════
# CAFE
# ═════════════════════════════════════════════════════════════

"VISIT_CAFE": {
	"scope": "character",
	"trigger_mode": "rolled",
	"base_category": "visit",
	"base_weight": 5,
	"category": "social",
	"magnitude": "minor",
	"cooldown_events": 10,
	"boredom_exempt": true,
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
	"base_category": ["fulfill_need", "idle"],
	"fulfills_need": "hunger",
	"base_weight": 10,
	"category": "social",
	"magnitude": "minor",
	"cooldown_events": 1,
	"boredom_exempt_traits": ["BIG_APPETITE"],
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
	"base_category": ["fulfill_need", "idle"],
	"fulfills_need": "energy",
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
	"base_category": "idle",
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
	"base_category": "socialize",
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
		"relationship": { "bond": 4, "trust": 2, "familiarity": 2 },
	},
	"storybook_templates": [
		"{name} and {target} ate together. The food wasn't the point.",
		"Lunch with {target}. {name} couldn't remember the last time someone sat with them.",
		"{name} and {target} split a meal. Neither said much. Both ate slowly.",
	],
},

"WINDOW_WATCH": {
	"scope": "character",
	"trigger_mode": "rolled",
	"base_category": "idle",
	"base_weight": 6,
	"category": "psychology",
	"magnitude": "minor",
	"cooldown_events": 5,
	"requirements": {
		"in_room": ["cafe"],
		"room_has_zone": "Zone_Window",
		"zone_has_space": "Zone_Window",
	},
	"weight_modifiers": [
		{ "condition": { "has_state": ["LONELY"] }, "multiply": 2.0 },
		{ "condition": { "has_state": ["CONTENT"] }, "multiply": 1.5 },
	],
	"target_resolution": { "type": "self" },
	"call_action": "window_watch",
	"outcomes": {
		"stats": { "stress": -8, "boredom": -10, "loneliness": -3 },
	},
	"storybook_templates": [
		"{name} watched the city from the window. Nothing was happening. Everything was.",
		"The window seat. {name} could sit there for hours.",
	],
},

# ═════════════════════════════════════════════════════════════
# LIBRARY
# ═════════════════════════════════════════════════════════════

"VISIT_LIBRARY": {
	"scope": "character",
	"trigger_mode": "rolled",
	"base_category": "visit",
	"base_weight": 7,
	"category": "psychology",
	"magnitude": "minor",
	"cooldown_events": 10,
	"boredom_exempt": true,
	"requirements": {
		"not_in_room": ["library"],
		"stats_above": { "boredom": 15 },
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
	"base_category": ["idle", "fulfill_need"],
	"fulfills_need": ["boredom", "stress"],
	"base_weight": 14,
	"category": "psychology",
	"magnitude": "minor",
	"cooldown_events": 2,
	"boredom_exempt_traits": ["BOOKWORM", "HOMEBODY"],
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

"BROWSE_SHELVES": {
	"scope": "character",
	"trigger_mode": "rolled",
	"base_category": "idle",
	"base_weight": 10,
	"category": "psychology",
	"magnitude": "minor",
	"cooldown_events": 3,
	"requirements": {
		"in_room": ["library"],
		"room_has_zone": "Zone_Shelves",
		"zone_has_space": "Zone_Shelves",
	},
	"weight_modifiers": [
		{ "condition": { "stats_above": { "boredom": 40 } }, "multiply": 1.8 },
	],
	"target_resolution": { "type": "self" },
	"call_action": "browse_shelves",
	"outcomes": {
		"stats": { "boredom": -15, "stress": -5 },
	},
	"storybook_templates": [
		"{name} ran {their} fingers along the spines. Looking for something.",
		"{name} browsed the shelves. Nothing jumped out. Everything did.",
	],
},

"STUDY_TOGETHER": {
	"scope": "character",
	"trigger_mode": "rolled",
	"base_category": "socialize",
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
		"relationship": { "bond": 3, "trust": 2, "familiarity": 2 },
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
	"base_category": "socialize",
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
		"relationship": { "bond": 2, "trust": 1, "familiarity": 1 },
	},
	"storybook_templates": [
		"{name} and {target} sat near each other. Neither spoke.",
		"They didn't talk. They didn't have to.",
		"{name} and {target} shared the silence. It was easier this way.",
	],
},

"ADMIRE_STATUE": {
	"scope": "character",
	"trigger_mode": "rolled",
	"base_category": ["idle", "fulfill_need"],
	"fulfills_need": ["boredom", "stress"],
	"base_weight": 4,
	"category": "psychology",
	"magnitude": "minor",
	"cooldown_events": 10,
	"requirements": {
		"in_room": ["library"],
		"room_has_zone": "Zone_Statue",
		"zone_has_space": "Zone_Statue",
	},
	"weight_modifiers": [
		{ "condition": { "has_trait": ["ROMANTIC"] }, "multiply": 2.0 },
		{ "condition": { "has_state": ["CONTENT"] }, "multiply": 1.5 },
		{ "condition": { "stats_above": { "boredom": 30 } }, "multiply": 1.5 },
	],
	"target_resolution": { "type": "self" },
	"call_action": "admire_statue",
	"outcomes": {
		"stats": { "happiness": 5, "stress": -5, "boredom": -8 },
	},
	"storybook_templates": [
		"{name} stood in front of the statue for a while. Something about it.",
		"{name} kept coming back to the statue. Couldn't say why.",
		"The statue didn't move. Neither did {name}. Not for a minute.",
	],
},

# ═════════════════════════════════════════════════════════════
# GROCERY
# ═════════════════════════════════════════════════════════════

"VISIT_GROCERY": {
	"scope": "character",
	"trigger_mode": "rolled",
	"base_category": "visit",
	"base_weight": 4,
	"category": "daily_life",
	"magnitude": "minor",
	"cooldown_events": 12,
	"boredom_exempt": true,
	"requirements": {
		"not_in_room": ["grocery"],
		"not_has_persistent_state": ["IN_HOSPITAL", "IN_JAIL"],
	},
	"weight_modifiers": [
		{ "condition": { "stats_above": { "hunger": 50 } }, "multiply": 2.5 },
		{ "condition": { "stats_below": { "cash": 20 } }, "multiply": 0.3 },
		{ "condition": { "has_trait": ["STINGY"] }, "multiply": 1.8 },
	],
	"target_resolution": { "type": "room" },
	"call_action": "queue_intent_visit_grocery",
	"outcomes": {
		"stats": { "boredom": -5 },
	},
	"storybook_templates": [
		"{name} headed to the grocery.",
		"{name} needed supplies. Or an excuse to leave the apartment.",
	],
},

"CHECK_SUPPLIES": {
	"scope": "character",
	"trigger_mode": "rolled",
	"base_category": ["visit", "idle"],
	"base_weight": 5,
	"category": "daily_life",
	"magnitude": "minor",
	"cooldown_events": 15,
	"boredom_exempt": true,
	"requirements": {
		"in_room": ["grocery"],
		"room_has_zone": "Zone_Aisles",
	},
	"weight_modifiers": [
		{ "condition": { "stats_above": { "hunger": 40 } }, "multiply": 2.0 },
	],
	"target_resolution": { "type": "self" },
	"call_action": "check_supplies",
	"outcomes": {
		"stats": { "boredom": -5 },
	},
	"storybook_templates": [
		"{name} checked what was left on the shelves. Not much.",
		"{name} wandered the aisles. Mostly out of habit.",
	],
},

# ═════════════════════════════════════════════════════════════
# SOCIAL — any room with other characters present
# ═════════════════════════════════════════════════════════════

"NOD_IN_PASSING": {
	"scope": "character",
	"trigger_mode": "rolled",
	"base_category": ["socialize", "idle"],
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
		"relationship": { "familiarity": 1 },
	},
	"storybook_templates": [
		"{name} nodded at {target}. {target} nodded back.",
		"{name} and {target} passed each other. Nothing said.",
		"Eye contact. A nod. That was enough.",
	],
},

# GREET — DELETED Session 22. Folding into CONVERSE_SEQ as a beat.
# Action function _greet() stays in actions.gd for sequence use.

"CONVERSE": {
	"scope": "character",
	"trigger_mode": "rolled",
	"base_category": "socialize",
	"base_weight": 8,
	"category": "social",
	"magnitude": "minor",
	"cooldown_events": 12,
	"allow_hallway": true,
	"requirements": {
		"other_character_in_room": true,
	},
	"weight_modifiers": [
		{ "condition": { "has_trait": ["SOCIAL"] }, "multiply": 2.0 },
		{ "condition": { "has_trait": ["GOSSIP"] }, "multiply": 1.5 },
		{ "condition": { "has_trait": ["ANTISOCIAL"] }, "multiply": 0.3 },
		{ "condition": { "has_trait": ["SHY"] }, "multiply": 0.5 },
		{ "condition": { "stats_above": { "loneliness": 50 } }, "multiply": 1.6 },
	],
	"target_resolution": { "type": "character", "filter": "same_room", "scope": "same_room", "exclude_robots": true },
	"call_action": "start_conversation",
	"sequence_key": "CONVERSE_SEQ",
	"outcomes": {},
	"storybook_templates": [
		"{name} and {target} started talking.",
		"{name} struck up a conversation with {target}.",
	],
},

# COMPLIMENT — DELETED Session 22. Now a callable func / CONVERSE_SEQ beat only.
# INSULT — DELETED Session 22. Now a callable func / CONVERSE_SEQ beat only.
# ARGUE — DELETED Session 22. Now a callable func / CONVERSE_SEQ beat only.

# FLIRT — standalone kept for non-conversation flirting (the "wink" case).
# Primary flirting path is FLIRT_BEAT inside CONVERSE_SEQ.
"FLIRT": {
	"scope": "character",
	"trigger_mode": "rolled",
	"base_category": "socialize",
	"base_weight": 3,
	"category": "romantic",
	"magnitude": "moderate",
	"cooldown_events": 8,
	"requirements": {
		"other_character_in_room": true,
		"stats_above": { "happiness": 55 },
		"compatible_sexuality": true,
		"relationship_bond_above": 20,
	},
	"weight_modifiers": [
		{ "condition": { "has_trait": ["FLIRTATIOUS"] }, "multiply": 4.0 },
		{ "condition": { "has_trait": ["ROMANTIC"] }, "multiply": 2.0 },
		{ "condition": { "has_trait": ["HIGH_LIBIDO"] }, "multiply": 1.5 },
		{ "condition": { "has_trait": ["SHY"] }, "multiply": 0.2 },
		{ "condition": { "stats_above": { "happiness": 75 } }, "multiply": 1.8 },
		{ "condition": { "has_state": ["CONTENT"] }, "multiply": 1.5 },
	],
	"target_resolution": { "type": "character", "filter": "same_room", "scope": "same_room", "exclude_robots": true },
	"call_action": "flirt",
	"outcomes": {
		"stats": { "happiness": 5 },
		"target_stats": { "happiness": 3 },
		"relationship": { "bond": 5, "familiarity": 2 },
	},
	"storybook_templates": [
		"{name} winked at {target} across the room.",
		"{name} caught {target}'s eye and held it a beat too long.",
		"{target} looked up. {name} was already smiling.",
		"{name} found a reason to stand a little closer to {target}.",
	],
},

# ── Conflict events — no base_category ──────────────────────
# These don't enter the base-roll pool. Flagged for reactive/
# auto-fire redesign: relationship-proximity trigger (enemy
# enters room → chance to fire). Kept in events.gd so they
# can still be force-fired via F3 and so their data shape is
# preserved for the redesign.

"CONFRONT": {
	"scope": "character",
	"trigger_mode": "rolled",
	# no base_category — reactive redesign planned
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
		"relationship": { "bond": -3, "trust": 2, "rivalry": 2 },
	},
	"storybook_templates": [
		"{name} cornered {target}. There was something that needed saying.",
		"{name} finally said what they'd been holding in.",
		"{target} could see it coming. {name} didn't soften it.",
	],
},

"PHYSICAL_FIGHT": {
	"scope": "character",
	"trigger_mode": "rolled",
	# no base_category — reactive redesign planned
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
		"relationship": { "bond": -15, "trust": -10, "rivalry": 10 },
	},
	"storybook_templates": [
		"{name} hit {target}. The room went quiet.",
		"It happened fast. {name} and {target}. Blood on the floor.",
		"Someone was always going to throw the first punch. {name} did.",
	],
},

"ASK_OUT": {
	"scope": "character",
	"trigger_mode": "rolled",
	"base_category": "socialize",
	"base_weight": 2,
	"category": "romantic",
	"magnitude": "major",
	"cooldown_events": 30,
	"requirements": {
		"other_character_in_room": true,
		"compatible_sexuality": true,
		"relationship_bond_above": 60,
		"relationship_tier_at_least": "CLOSE_FRIEND",
	},
	"weight_modifiers": [
		{ "condition": { "has_trait": ["ROMANTIC"] }, "multiply": 3.0 },
		{ "condition": { "has_trait": ["FLIRTATIOUS"] }, "multiply": 2.0 },
		{ "condition": { "has_trait": ["SHY"] }, "multiply": 0.3 },
		{ "condition": { "stats_above": { "happiness": 70 } }, "multiply": 2.0 },
	],
	"target_resolution": { "type": "character", "filter": "highest_affection", "scope": "same_room", "exclude_robots": true },
	"call_action": "ask_out",
	"outcomes": {},
	"storybook_templates": [
		"{name} asked {target} out. The {room} held its breath.",
		"It had been building for days. {name} finally said it out loud.",
		"{name} did it. {They} actually asked.",
	],
},

"APOLOGISE": {
	"scope": "character",
	"trigger_mode": "rolled",
	"base_category": "socialize",
	"base_weight": 3,
	"category": "social",
	"magnitude": "moderate",
	"cooldown_events": 20,
	"requirements": {
		"other_character_in_room": true,
		"relationship_bond_below": 30,
		"relationship_bond_above": -40,
	},
	"weight_modifiers": [
		{ "condition": { "has_trait": ["STUBBORN"] }, "multiply": 0.2 },
		{ "condition": { "has_trait": ["CHARMING"] }, "multiply": 1.5 },
		{ "condition": { "stats_above": { "stress": 50 } }, "multiply": 1.8 },
		{ "condition": { "has_feeling": ["UPSET_FEELING"] }, "multiply": 2.0 },
	],
	"target_resolution": { "type": "character", "filter": "lowest_affection", "scope": "same_room", "exclude_robots": true },
	"call_action": "apologise",
	"outcomes": {
		"stats": { "stress": -8 },
	},
	"storybook_templates": [
		"{name} apologised to {target}. It took more than {they} expected.",
		"It took {name} a while to say it. {target} waited.",
		"{name} said sorry. Whether {target} believed it was another thing.",
	],
},

# SHARE_STORY — DELETED Session 22. Folding into CONVERSE_SEQ as a beat.
# REMINISCE_TOGETHER — DELETED Session 22. Folding into CONVERSE_SEQ as a beat.

"VENT_TO_FRIEND": {
	"scope": "character",
	"trigger_mode": "rolled",
	"base_category": "socialize",
	"base_weight": 4,
	"category": "social",
	"magnitude": "moderate",
	"cooldown_events": 15,
	"requirements": {
		"other_character_in_room": true,
		"stats_above": { "stress": 45 },
		"relationship_tier_at_least": "FRIEND",
	},
	"weight_modifiers": [
		{ "condition": { "has_trait": ["SOCIAL"] }, "multiply": 1.5 },
		{ "condition": { "has_trait": ["SECRETIVE"] }, "multiply": 0.2 },
		{ "condition": { "stats_above": { "stress": 70 } }, "multiply": 2.5 },
		{ "condition": { "has_state": ["MISERABLE"] }, "multiply": 2.0 },
	],
	"target_resolution": { "type": "character", "filter": "highest_affection", "scope": "same_room", "exclude_robots": true },
	"call_action": "vent_to_friend",
	"outcomes": {
		"stats": { "stress": -15, "loneliness": -10 },
		"target_stats": { "stress": 5 },
		"feelings": ["RELIEVED"],
		"relationship": { "bond": 3, "trust": 5 },
	},
	"storybook_templates": [
		"{name} needed to talk. {target} let them.",
		"{name} unloaded on {target}. Not everything, but enough.",
		"It wasn't pretty, but {target} heard it. That was enough for {name}.",
		"{name} vented. {target} didn't try to fix it. Just listened.",
	],
},

# ═════════════════════════════════════════════════════════════
# RIVALRY & CONFLICT — no base_category (reactive redesign)
# ═════════════════════════════════════════════════════════════

# SHARE_SECRET — DELETED Session 22. Folding into CONVERSE_SEQ as a beat.
# BETRAY_SECRET — DELETED Session 22. Folding into CONVERSE_SEQ as a beat.

"MOCK": {
	"scope": "character",
	"trigger_mode": "rolled",
	# no base_category — reactive redesign planned
	"base_weight": 2,
	"category": "social",
	"magnitude": "moderate",
	"cooldown_events": 12,
	"requirements": {
		"other_character_in_room": true,
		"stats_above": { "stress": 15 },
		"not_in_home_room": true,
	},
	"weight_modifiers": [
		{ "condition": { "has_trait": ["MEAN"] }, "multiply": 3.0 },
		{ "condition": { "has_trait": ["FUNNY"] }, "multiply": 2.0 },
		{ "condition": { "has_trait": ["SHORT_TEMPERED"] }, "multiply": 2.0 },
		{ "condition": { "has_state": ["FURIOUS"] }, "multiply": 2.5 },
		{ "condition": { "stats_above": { "stress": 70 } }, "multiply": 2.0 },
	],
	"target_resolution": { "type": "character", "filter": "lowest_affection", "scope": "same_room" },
	"call_action": "mock",
	"outcomes": {
		"stats": { "stress": -5, "happiness": 3 },
		"target_stats": { "stress": 10, "happiness": -8 },
		"target_feelings": ["HUMILIATED"],
		"relationship": { "bond": -4, "trust": -5, "rivalry": 5 },
	},
	"storybook_templates": [
		"{name} made fun of {target}. Everyone heard.",
		"{name} got a laugh at {target}'s expense. The room noticed.",
		"It was meant to be funny. {target} wasn't laughing.",
		"{name} said something about {target} loud enough for everyone.",
	],
},

"COLD_SHOULDER": {
	"scope": "character",
	"trigger_mode": "rolled",
	# no base_category — reactive redesign planned
	"base_weight": 3,
	"category": "social",
	"magnitude": "minor",
	"cooldown_events": 8,
	"requirements": {
		"other_character_in_room": true,
		"relationship_bond_below": 0,
	},
	"weight_modifiers": [
		{ "condition": { "has_trait": ["STUBBORN"] }, "multiply": 2.0 },
		{ "condition": { "has_trait": ["MEAN"] }, "multiply": 1.5 },
		{ "condition": { "stats_above": { "stress": 50 } }, "multiply": 1.5 },
		{ "condition": { "stats_above": { "stress": 75 } }, "multiply": 2.0 },
	],
	"target_resolution": { "type": "character", "filter": "lowest_affection", "scope": "same_room" },
	"call_action": "cold_shoulder",
	"outcomes": {
		"target_stats": { "loneliness": 8, "happiness": -5 },
		"relationship": { "bond": -3, "rivalry": 2 },
	},
	"storybook_templates": [
		"{target} tried to say hello. {name} looked right through {them}.",
		"{name} pretended {target} wasn't there. {target} noticed.",
		"The silence was deliberate. {target} felt it.",
		"{name} turned away when {target} approached. Not subtle.",
	],
},

"PROVOKE": {
	"scope": "character",
	"trigger_mode": "rolled",
	# no base_category — reactive redesign planned
	"base_weight": 2,
	"category": "social",
	"magnitude": "moderate",
	"cooldown_events": 15,
	"requirements": {
		"other_character_in_room": true,
		"stats_above": { "stress": 30 },
	},
	"weight_modifiers": [
		{ "condition": { "has_trait": ["MEAN"] }, "multiply": 3.0 },
		{ "condition": { "has_trait": ["VIOLENT"] }, "multiply": 2.5 },
		{ "condition": { "has_trait": ["SHORT_TEMPERED"] }, "multiply": 2.0 },
		{ "condition": { "has_state": ["FURIOUS"] }, "multiply": 3.0 },
		{ "condition": { "stats_above": { "stress": 80 } }, "multiply": 2.0 },
	],
	"target_resolution": { "type": "character", "filter": "lowest_affection", "scope": "same_room" },
	"call_action": "provoke",
	"outcomes": {
		"stats": { "stress": -5 },
		"target_stats": { "stress": 15, "happiness": -8 },
		"target_feelings": ["FURIOUS"],
		"relationship": { "bond": -5, "trust": -3, "rivalry": 6 },
	},
	"storybook_templates": [
		"{name} pushed {target}'s buttons. Knew exactly which ones.",
		"{name} wanted a reaction from {target}. {They} got one.",
		"It wasn't an accident. {name} knew what {they} {were_was} doing.",
		"{name} kept at it until {target} couldn't ignore it.",
	],
},

"TELL_ON": {
	"scope": "character",
	"trigger_mode": "rolled",
	"base_category": "socialize",
	"base_weight": 2,
	"category": "social",
	"magnitude": "moderate",
	"cooldown_events": 20,
	"requirements": {
		"other_character_in_room": true,
		"has_memory_tag": "betrayal_info",
	},
	"weight_modifiers": [
		{ "condition": { "has_trait": ["GOSSIP"] }, "multiply": 2.0 },
		{ "condition": { "has_trait": ["SOCIAL"] }, "multiply": 1.5 },
		{ "condition": { "has_trait": ["BY_THE_BOOK"] }, "multiply": 2.0 },
		{ "condition": { "has_trait": ["MEAN"] }, "multiply": 0.4 },
		{ "condition": { "has_trait": ["SECRETIVE"] }, "multiply": 0.3 },
	],
	"target_resolution": { "type": "character", "filter": "same_room", "scope": "same_room", "exclude_robots": true },
	"call_action": "tell_on",
	"outcomes": {
		"stats": { "stress": -5 },
	},
	"storybook_templates": [
		"{name} decided someone needed to know the truth.",
		"{name} couldn't keep it to themselves. Not this.",
		"There was something {name} had to say. It couldn't wait.",
	],
},
}
# ─────────────────────────────────────────────────────────────
# CATEGORIES
# ─────────────────────────────────────────────────────────────

const CATEGORIES: Array = [
	"social", "romantic", "violence", "crime", "police", "death",
	"family", "comedy", "work", "building", "management", "gang",
	"homeless", "health", "psychology", "object", "seasonal", "calendar",
	"daily_life",
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

func get_events_by_scope(scope: String) -> Array:
	var result: Array = []
	for key in EVENTS:
		if EVENTS[key].get("scope", "character") == scope:
			result.append(key)
	return result

func get_events_by_trigger(trigger_mode: String) -> Array:
	var result: Array = []
	for key in EVENTS:
		if EVENTS[key].get("trigger_mode", "rolled") == trigger_mode:
			result.append(key)
	return result