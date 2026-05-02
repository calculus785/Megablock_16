# sequences.gd
# Autoload — available globally as Sequences
# Tier 1 Config — pure data, no dependencies
#
# Defines multi-beat locked activities. While a sequence is active,
# all participants are locked: they can't be pulled into other events,
# their intent queue is paused, only sequence beats fire.
#
# Each sequence has:
#   participants     — number of characters locked (usually 2)
#   roles            — names for each participant role
#   beats            — ordered list of beat definitions
#
# Each beat has:
#   beat_id          — int, used for next_beat references
#   description      — comment for designers, never shown to player
#   actor_role       — which participant acts ("initiator", "responder", "both")
#   call_action      — function in Actions to execute
#   outcomes         — stat/feeling deltas for this beat
#   storybook_templates — narrative variants per beat
#   weighted_outcomes — list of branches with weights (optional)
#   weight_modifiers — modify branch weights (optional)
#   next_beat        — next beat_id to advance to, or "END"

extends Node


const SEQUENCES: Dictionary = {

"PLAY_POOL_SEQ": {
	"participants": 2,
	"roles": ["initiator", "responder"],
	"category": "social",
	"venue_required": "bar",
	"interactable_required": "pool_table",

	"beats": [
		{
			"beat_id": 0,
			"description": "Setup — initiator racks the balls",
			"actor_role": "initiator",
			"call_action": "rack_pool_balls",
			"outcomes": { "stats": { "boredom": -5 } },
			"storybook_templates": [
				"{name} racked the balls. {target} chalked a cue.",
				"The pool table was claimed. {name} broke first.",
			],
			"sound": "pool_rack",
			"next_beat": 1,
		},
		{
			"beat_id": 1,
			"description": "Play — weighted roll for winner",
			"actor_role": "both",
			"call_action": "play_pool_round",
			"weighted_outcomes": [
				{ "weight": 50, "outcome_key": "initiator_wins", "next_beat": 2 },
				{ "weight": 50, "outcome_key": "responder_wins", "next_beat": 3 },
			],
			"weight_modifiers": [
				{
					"condition": { "actor_has_trait": ["COMPETITIVE"] },
					"outcome": "initiator_wins",
					"multiply": 1.5,
				},
			],
		},
		{
			"beat_id": 2,
			"description": "Initiator wins — reaction",
			"actor_role": "initiator",
			"call_action": "pool_victory",
			"outcomes": {
				"stats": { "happiness": 20, "boredom": -30 },
				"target_stats": { "happiness": -5 },
				"feelings": ["COCKY"],
				"target_feelings": ["FRUSTRATED"],
				"relationship_delta": { "bond": 5, "rivalry": 3 },
			},
			"storybook_templates": [
				"{name} won. They tried not to look too smug about it.",
				"{target} lost to {name} at pool. Again.",
			],
			"next_beat": "END",
		},
		{
			"beat_id": 3,
			"description": "Responder wins — reaction",
			"actor_role": "responder",
			"call_action": "pool_victory",
			"outcomes": {
				"stats": { "happiness": 20, "boredom": -30 },
				"target_stats": { "happiness": -5 },
				"feelings": ["COCKY"],
				"target_feelings": ["FRUSTRATED"],
				"relationship_delta": { "bond": 5, "rivalry": 3 },
			},
			"storybook_templates": [
				"{name} beat {target} at pool. {target} didn't take it well.",
				"{name} won. {target} put the cue down too hard.",
			],
			"next_beat": "END",
		},
	],
},
}


func _ready() -> void:
	print("[Sequences] Loaded. %d sequences defined." % SEQUENCES.size())


# ─────────────────────────────────────────────────────────────
# HELPERS
# ─────────────────────────────────────────────────────────────

func is_valid(sequence_key: String) -> bool:
	return SEQUENCES.has(sequence_key)

func get_sequence(sequence_key: String) -> Dictionary:
	return SEQUENCES.get(sequence_key, {})

func get_beat(sequence_key: String, beat_id: int) -> Dictionary:
	if not SEQUENCES.has(sequence_key):
		return {}
	for beat in SEQUENCES[sequence_key]["beats"]:
		if beat["beat_id"] == beat_id:
			return beat
	return {}