# feelings.gd
# Autoload — available globally as Feelings
# Tier 1 Config — pure data, no dependencies
#
# Defines every temporary feeling a character can experience.
# Feelings are pushed by events — never assigned automatically.
# (That's what States are for.)
#
# Fields:
#   duration_hours    — how long the feeling lasts in in-game hours
#   drift_modifiers   — stat change applied every in-game hour while active
#   conflicting       — these feelings are removed when this one is pushed
#   can_be_hidden     — if true, can be assigned without a UI bubble
#   can_be_targeted   — if true, this feeling can be directed at a specific character

# ─────────────────────────────────────────────────────────────
# RUNTIME FEELING INSTANCE SHAPE
# (Stored on CharData.feelings — populated by FeelingDriver.push)
# ─────────────────────────────────────────────────────────────
# Each active feeling on a character is a Dictionary:
#
#   {
#     "feeling_key":     "FRUSTRATED",
#     "hours_remaining": 2.5,
#     "target_id":       null or char_id (if can_be_targeted),
#     "is_hidden":       false,
#     "causes": [
#       {
#         "event_key": "POOL_GAME_LOSS",
#         "at_tick":   1247,
#         "summary":   "Lost at pool to Sara"
#       },
#       ...
#     ]
#   }
#
# When the same feeling is pushed again while already active:
#   - hours_remaining refreshes to max(remaining, new_duration)
#   - the new cause appends to causes[] (capped at last 4)
#   - causes never expire on their own — they vanish with the feeling
#
# Event/Action code should also write a 'felt' short-term memory
# entry per push, for the wider memory system to use.

extends Node


const FEELINGS: Dictionary = {

# ── POSITIVE ─────────────────────────────────────────────────────────────
"HAPPY": {
	"label": "Happy",
	"description": "Something good happened. Life feels a bit brighter right now.",
	"duration_hours": 24,
	"drift_modifiers": { "happiness": 3, "stress": -2, "loneliness": -1 },
	"conflicting": ["MISERABLE", "HUMILIATED", "HEARTBROKEN", "GRIEVING"],
	"can_be_hidden": false,
	"can_be_targeted": false,
},
"ELATED": {
	"label": "Elated",
	"description": "Something really good happened. Hard to wipe the smile off.",
	"duration_hours": 24,
	"drift_modifiers": { "happiness": 6, "stress": -4, "loneliness": -3, "boredom": -5 },
	"conflicting": ["MISERABLE", "HUMILIATED", "HEARTBROKEN", "ANXIOUS", "GRIEVING"],
	"can_be_hidden": false,
	"can_be_targeted": false,
},
"AFFECTIONATE": {
	"label": "Affectionate",
	"description": "Warm and open. Drawn toward the people they like.",
	"duration_hours": 24,
	"drift_modifiers": { "horniness": 3, "loneliness": -4, "happiness": 2 },
	"conflicting": ["HUMILIATED", "FURIOUS", "HEARTBROKEN", "DISGUSTED"],
	"can_be_hidden": true,
	"can_be_targeted": true,
},
"FLIRTY": {
	"label": "Flirty",
	"description": "In the mood. Noticing people. Making eye contact a beat too long.",
	"duration_hours": 24,
	"drift_modifiers": { "horniness": 5, "loneliness": -3 },
	"conflicting": ["HEARTBROKEN", "HUMILIATED", "GRIEVING"],
	"can_be_hidden": false,
	"can_be_targeted": false,
},
"CONFIDENT": {
	"label": "Confident",
	"description": "Feeling good about themselves. Walking taller than usual.",
	"duration_hours": 24,
	"drift_modifiers": { "stress": -3, "happiness": 2, "global_reputation": 1 },
	"conflicting": ["HUMILIATED", "ANXIOUS", "PARANOID_FEELING"],
	"can_be_hidden": false,
	"can_be_targeted": false,
},
"INSPIRED": {
	"label": "Inspired",
	"description": "Something sparked something. Energy and motivation are both up.",
	"duration_hours": 24,
	"drift_modifiers": { "energy": 4, "boredom": -6, "happiness": 2 },
	"conflicting": ["EXHAUSTED_FEELING", "MISERABLE"],
	"can_be_hidden": false,
	"can_be_targeted": false,
},
"GRATEFUL": {
	"label": "Grateful",
	"description": "Someone did something for them. Quietly touched by it.",
	"duration_hours": 24,
	"drift_modifiers": { "happiness": 3, "stress": -2, "loneliness": -3 },
	"conflicting": ["FURIOUS", "BITTER"],
	"can_be_hidden": true,
	"can_be_targeted": true,
},
"EXCITED": {
	"label": "Excited",
	"description": "Something is coming. Anticipation is making them restless in a good way.",
	"duration_hours": 24,
	"drift_modifiers": { "energy": 3, "boredom": -8, "happiness": 4 },
	"conflicting": ["MISERABLE", "EXHAUSTED_FEELING", "ANXIOUS"],
	"can_be_hidden": false,
	"can_be_targeted": false,
},
"SATISFIED": {
	"label": "Satisfied",
	"description": "A need was met. Content in the quiet way that doesn't ask for more.",
	"duration_hours": 24,
	"drift_modifiers": { "happiness": 2, "stress": -3, "boredom": -2 },
	"conflicting": ["MISERABLE", "BITTER"],
	"can_be_hidden": false,
	"can_be_targeted": false,
},
"AMOROUS": {
	"label": "Amorous",
	"description": "Deeply romantically charged. Something or someone has got under their skin.",
	"duration_hours": 24,
	"drift_modifiers": { "horniness": 6, "loneliness": -6, "happiness": 3 },
	"conflicting": ["HEARTBROKEN", "HUMILIATED", "FURIOUS"],
	"can_be_hidden": true,
	"can_be_targeted": true,
},

# ── NEGATIVE ─────────────────────────────────────────────────────────────
"MISERABLE": {
	"label": "Miserable",
	"description": "Something knocked them down hard. Not dealing with it well.",
	"duration_hours": 24,
	"drift_modifiers": { "happiness": -5, "stress": 3, "loneliness": 3, "energy": -2 },
	"conflicting": ["HAPPY", "ELATED", "EXCITED", "INSPIRED", "GRATEFUL"],
	"can_be_hidden": false,
	"can_be_targeted": false,
},
"HUMILIATED": {
	"label": "Humiliated",
	"description": "Something embarrassing happened. They can't stop thinking about it.",
	"duration_hours": 24,
	"drift_modifiers": { "happiness": -4, "stress": 5, "global_reputation": -1 },
	"conflicting": ["CONFIDENT", "HAPPY", "ELATED", "AFFECTIONATE", "FLIRTY"],
	"can_be_hidden": true,
	"can_be_targeted": false,
},
"FURIOUS": {
	"label": "Furious",
	"description": "Properly angry. Something or someone has crossed a line.",
	"duration_hours": 24,
	"drift_modifiers": { "stress": 8, "happiness": -5, "criminal_inclination": 2 },
	"conflicting": ["HAPPY", "AFFECTIONATE", "GRATEFUL", "CONTENT_FEELING"],
	"can_be_hidden": false,
	"can_be_targeted": true,
},
"ANXIOUS": {
	"label": "Anxious",
	"description": "Something has them on edge. Hard to relax. Watching the door.",
	"duration_hours": 24,
	"drift_modifiers": { "stress": 5, "happiness": -3, "energy": -2 },
	"conflicting": ["CONFIDENT", "ELATED", "EXCITED"],
	"can_be_hidden": true,
	"can_be_targeted": false,
},
"HEARTBROKEN": {
	"label": "Heartbroken",
	"description": "Romantic loss. The kind that changes how they move through the world for a while.",
	"duration_hours": 24,
	"drift_modifiers": { "happiness": -6, "stress": 4, "loneliness": 6, "horniness": -5 },
	"conflicting": ["HAPPY", "ELATED", "FLIRTY", "AMOROUS", "AFFECTIONATE"],
	"can_be_hidden": false,
	"can_be_targeted": false,
},
"GRIEVING": {
	"label": "Grieving",
	"description": "Someone is gone. The absence is loud.",
	"duration_hours": 32,
	"drift_modifiers": { "happiness": -5, "stress": 3, "loneliness": 5, "energy": -3 },
	"conflicting": ["HAPPY", "ELATED", "EXCITED", "FLIRTY"],
	"can_be_hidden": false,
	"can_be_targeted": false,
},
"BITTER": {
	"label": "Bitter",
	"description": "Resentment sitting just below the surface. Something wasn't fair.",
	"duration_hours": 24,
	"drift_modifiers": { "happiness": -3, "stress": 3, "criminal_inclination": 1 },
	"conflicting": ["GRATEFUL", "HAPPY", "ELATED"],
	"can_be_hidden": true,
	"can_be_targeted": true,
},
"DISGUSTED": {
	"label": "Disgusted",
	"description": "Something turned their stomach. Moral or physical — either way it lingers.",
	"duration_hours": 12,
	"drift_modifiers": { "happiness": -3, "stress": 3 },
	"conflicting": ["AFFECTIONATE", "AMOROUS", "FLIRTY"],
	"can_be_hidden": false,
	"can_be_targeted": true,
},
"PARANOID_FEELING": {
	"label": "Paranoid",
	"description": "Convinced something is wrong. Watching everyone. Trusting nobody.",
	"duration_hours": 24,
	"drift_modifiers": { "stress": 6, "happiness": -4, "loneliness": 3 },
	"conflicting": ["CONFIDENT", "HAPPY", "GRATEFUL"],
	"can_be_hidden": true,
	"can_be_targeted": false,
},

# ── PHYSICAL ─────────────────────────────────────────────────────────────
"EXHAUSTED_FEELING": {
	"label": "Exhausted",
	"description": "Pushed past their limit. Everything is slower and harder.",
	"duration_hours": 10,
	"drift_modifiers": { "energy": -5, "happiness": -2, "stress": 3 },
	"conflicting": ["EXCITED", "INSPIRED", "ELATED"],
	"can_be_hidden": false,
	"can_be_targeted": false,
},
"WELL_FED": {
	"label": "Well Fed",
	"description": "A good meal lands well. Comfortable and settled.",
	"duration_hours": 5,
	"drift_modifiers": { "hunger": -8, "happiness": 2, "stress": -1 },
	"conflicting": [],
	"can_be_hidden": false,
	"can_be_targeted": false,
},
"HUNGOVER": {
	"label": "Hungover",
	"description": "Last night caught up with them. Regretting most of it.",
	"duration_hours": 24,
	"drift_modifiers": { "energy": -5, "stress": 4, "happiness": -4, "health": -2 },
	"conflicting": ["ELATED", "EXCITED", "INSPIRED"],
	"can_be_hidden": false,
	"can_be_targeted": false,
},
"CRAVING": {
	"label": "Craving",
	"description": "The habit is calling. Hard to think about much else right now.",
	"duration_hours": 32,
	"drift_modifiers": { "stress": 5, "happiness": -3, "addiction": 2, "boredom": 3 },
	"conflicting": ["SATISFIED", "CONTENT_FEELING"],
	"can_be_hidden": true,
	"can_be_targeted": false,
},
"RELIEVED": {
	"label": "Relieved",
	"description": "Something they were dreading didn't happen — or something bad resolved.",
	"duration_hours": 24,
	"drift_modifiers": { "stress": -6, "happiness": 3 },
	"conflicting": ["ANXIOUS", "FURIOUS"],
	"can_be_hidden": false,
	"can_be_targeted": false,
},

# ── NEUTRAL ───────────────────────────────────────────────────────────────
"CONTENT_FEELING": {
	"label": "Content",
	"description": "Quietly okay. No complaints. Sometimes that's enough.",
	"duration_hours": 24,
	"drift_modifiers": { "stress": -2, "happiness": 1 },
	"conflicting": ["MISERABLE", "FURIOUS", "ANXIOUS", "HEARTBROKEN"],
	"can_be_hidden": false,
	"can_be_targeted": false,
},

# ── SEQUENCE-ONLY (pushed during multi-beat sequences, not standalone events)
"FRUSTRATED": {
	"label": "Frustrated",
	"description": "Something is in the way. Patience is wearing thin.",
	"duration_hours": 24,
	"drift_modifiers": { "stress": 4, "happiness": -2 },
	"conflicting": ["SATISFIED", "CONTENT_FEELING"],
	"can_be_hidden": true,
	"can_be_targeted": false,
},
"COCKY": {
	"label": "Cocky",
	"description": "On a streak. Starting to believe their own hype.",
	"duration_hours": 24,
	"drift_modifiers": { "happiness": 3, "stress": -2 },
	"conflicting": ["HUMILIATED", "ANXIOUS"],
	"can_be_hidden": false,
	"can_be_targeted": false,
},
"COMPETITIVE": {
	"label": "Competitive",
	"description": "Someone else's success is personal. They need to win.",
	"duration_hours": 24,
	"drift_modifiers": { "stress": 3, "energy": 2 },
	"conflicting": ["CONTENT_FEELING", "SATISFIED"],
	"can_be_hidden": true,
	"can_be_targeted": true,
},
"RECKLESS": {
	"label": "Reckless",
	"description": "Consequences aren't real right now. Something bad is probably coming.",
	"duration_hours": 224,
	"drift_modifiers": { "criminal_inclination": 3, "stress": -2 },
	"conflicting": ["ANXIOUS"],
	"can_be_hidden": false,
	"can_be_targeted": false,
},
"INFATUATED_WITH": {
	"label": "Infatuated",
	"description": "Someone has taken up entirely too much space in their head.",
	"duration_hours": 24,
	"drift_modifiers": { "horniness": 3, "loneliness": -5, "happiness": 2, "stress": 2 },
	"conflicting": ["HEARTBROKEN"],
	"can_be_hidden": true,
	"can_be_targeted": true,  # always targeted at a specific character
},
"NURSING_GRUDGE": {
	"label": "Nursing a Grudge",
	"description": "They haven't forgotten. They're waiting.",
	"duration_hours": 48,
	"drift_modifiers": { "stress": 2, "happiness": -1 },
	"conflicting": ["GRATEFUL", "AFFECTIONATE"],
	"can_be_hidden": true,
	"can_be_targeted": true,  # always targeted at a specific character
},
}


func _ready() -> void:
	print("[Feelings] Loaded. %d feelings defined." % FEELINGS.size())


# ─────────────────────────────────────────────────────────────
# HELPERS
# ─────────────────────────────────────────────────────────────

func is_valid(feeling_key: String) -> bool:
	return FEELINGS.has(feeling_key)

func get_label(feeling_key: String) -> String:
	return FEELINGS[feeling_key]["label"]

func get_duration(feeling_key: String) -> float:
	return FEELINGS[feeling_key]["duration_hours"]

func get_drift_modifiers(feeling_key: String) -> Dictionary:
	return FEELINGS[feeling_key]["drift_modifiers"]

func get_conflicting(feeling_key: String) -> Array:
	return FEELINGS[feeling_key]["conflicting"]

func can_be_hidden(feeling_key: String) -> bool:
	return FEELINGS[feeling_key].get("can_be_hidden", false)

func can_be_targeted(feeling_key: String) -> bool:
	return FEELINGS[feeling_key].get("can_be_targeted", false)

