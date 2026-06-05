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
"CONVERSE_SEQ": {
	"participants": 2,
	"roles": ["initiator", "responder"],
	"category": "social",
	"type": "pool",

	# ── POOL SEQUENCE CONFIG ────────────────────────────────
	"continue_base_chance": 0.90,
	"continue_decay_per_beat": 0.12,
	"mood_end_bonus": 0.03,
	"mood_continue_bonus": 0.01,
	"escalation_min_beats": 4,
	"escalation_end_chance": 0.65,
	"memorable_mood_threshold": 40,

	# ── OPENING BEAT ────────────────────────────────────────
	# Always fires first. Sets the topic and tone.
	"opening_beat": {
		"call_action": "converse_open",
		"mood_delta": 0,
		"storybook_templates": [
			"{name} started talking to {target} about {topic}.",
			"{name} and {target} got to chatting about {topic}.",
			"It started with {topic}. {name} and {target} had things to say.",
		],
	},

	# ── CONVERSATION BEAT POOL ──────────────────────────────
	# Rolled each tick after the opening. Weights modified by mood,
	# traits, feelings, and relationship.
	"beat_pool": {
		"POSITIVE_CHAT": {
			"base_weight": 15,
			"mood_delta": 8,
			"call_action": "converse_positive_chat",
			"storybook_templates": [
				"{name} said something that made {target} laugh.",
				"The conversation drifted to {topic}. Both seemed to enjoy it.",
				"{name} told {target} about {topic}. {target} was into it.",
				"{target} grinned at something {name} said about {topic}.",
			],
			"continued_templates": [
				"{name} and {target} kept going. {topic} had legs.",
				"They were still on {topic}. Neither wanted to stop.",
			],
			"weight_modifiers": [
				{ "condition": { "mood_above": 10 }, "multiply": 1.5 },
				{ "condition": { "has_trait": ["SOCIAL"] }, "multiply": 1.3 },
				{ "condition": { "has_trait": ["CHARMING"] }, "multiply": 1.3 },
				{ "condition": { "relationship_bond_above": 30 }, "multiply": 1.4 },
			],
		},
		"NEUTRAL_CHAT": {
			"base_weight": 20,
			"mood_delta": 2,
			"call_action": "converse_neutral_chat",
			"storybook_templates": [
				"{name} and {target} talked about {topic}.",
				"The conversation moved to {topic}. Nothing heavy.",
				"{name} mentioned {topic}. {target} nodded along.",
				"They talked about {topic} for a bit.",
			],
			"continued_templates": [
				"Still on {topic}. The conversation was easy.",
				"{name} and {target} kept talking. {topic} again.",
			],
			"weight_modifiers": [
				{ "condition": { "mood_above": -10, "mood_below": 10 }, "multiply": 1.5 },
			],
		},
		"NEGATIVE_CHAT": {
			"base_weight": 8,
			"mood_delta": -8,
			"call_action": "converse_negative_chat",
			"storybook_templates": [
				"{name} brought up {topic}. {target} didn't want to hear it.",
				"The conversation took a turn. {name} wouldn't drop {topic}.",
				"{target} tensed up when {name} mentioned {topic}.",
				"{name} complained about {topic}. The mood shifted.",
			],
			"continued_templates": [
				"{name} kept going about {topic}. {target} was losing patience.",
				"Still on {topic}. Neither was enjoying it anymore.",
			],
			"weight_modifiers": [
				{ "condition": { "mood_below": -10 }, "multiply": 1.8 },
				{ "condition": { "has_trait": ["MEAN"] }, "multiply": 1.5 },
				{ "condition": { "has_trait": ["SHORT_TEMPERED"] }, "multiply": 1.4 },
				{ "condition": { "relationship_bond_below": 0 }, "multiply": 2.0 },
			],
		},
		"FLIRT_BEAT": {
			"base_weight": 4,
			"mood_delta": 7,
			"call_action": "converse_flirt",
			"storybook_templates": [
				"Something {name} said landed differently. {target} noticed.",
				"{name} said something that wasn't quite a compliment. {target} smiled anyway.",
				"The conversation shifted. {name} was flirting. {target} knew it.",
			],
			"continued_templates": [
				"{name} kept at it. {target} wasn't stopping them.",
			],
			"weight_modifiers": [
				{ "condition": { "mood_above": 10 }, "multiply": 2.0 },
				{ "condition": { "has_trait": ["FLIRTATIOUS"] }, "multiply": 3.0 },
				{ "condition": { "has_trait": ["ROMANTIC"] }, "multiply": 1.8 },
				{ "condition": { "has_trait": ["SHY"] }, "multiply": 0.2 },
				{ "condition": { "relationship_bond_above": 20 }, "multiply": 1.5 },
			],
			"requirements": {
				"relationship_bond_above": 5,
			},
		},
		"COMPLIMENT_BEAT": {
			"base_weight": 6,
			"mood_delta": 10,
			"call_action": "converse_compliment",
			"storybook_templates": [
				"{name} paid {target} a genuine compliment.",
				"Something {name} said caught {target} off guard. In a good way.",
				"{name} told {target} something kind. {target} needed to hear it.",
			],
			"continued_templates": [
				"{name} kept being nice. {target} wasn't used to it.",
			],
			"weight_modifiers": [
				{ "condition": { "mood_above": 15 }, "multiply": 1.6 },
				{ "condition": { "has_trait": ["CHARMING"] }, "multiply": 2.0 },
				{ "condition": { "has_trait": ["MEAN"] }, "multiply": 0.3 },
				{ "condition": { "relationship_bond_above": 20 }, "multiply": 1.5 },
			],
		},
		"INSULT_BEAT": {
			"base_weight": 4,
			"mood_delta": -15,
			"call_action": "converse_insult",
			"storybook_templates": [
				"{name} said something cutting to {target}.",
				"That was uncalled for. {name} knew it. Said it anyway.",
				"{target} went quiet after what {name} said.",
			],
			"continued_templates": [
				"{name} kept pushing. Another jab at {target}.",
			],
			"weight_modifiers": [
				{ "condition": { "mood_below": -15 }, "multiply": 2.0 },
				{ "condition": { "has_trait": ["MEAN"] }, "multiply": 2.5 },
				{ "condition": { "has_feeling": "FURIOUS" }, "multiply": 3.0 },
				{ "condition": { "relationship_bond_below": -10 }, "multiply": 2.0 },
			],
		},
		"GOSSIP_BEAT": {
			"base_weight": 6,
			"mood_delta": -3,
			"call_action": "converse_gossip",
			"storybook_templates": [
				"Midway through, {name} brought up what they'd heard about someone.",
				"{name} leaned in. Had something to share with {target}.",
				"The conversation shifted. {name} had gossip.",
			],
			"continued_templates": [
				"{name} had more. The gossip kept flowing.",
			],
			"weight_modifiers": [
				{ "condition": { "has_trait": ["GOSSIP"] }, "multiply": 2.5 },
				{ "condition": { "has_trait": ["SECRETIVE"] }, "multiply": 0.3 },
			],
			"requirements": {
				"has_gossipable_memory": true,
			},
		},
		"SHARE_INTEREST": {
			"base_weight": 7,
			"mood_delta": 6,
			"call_action": "converse_share_interest",
			"storybook_templates": [
				"{name} got excited talking about something they loved.",
				"{name} and {target} found something they both cared about.",
				"The conversation lit up when {name} mentioned a shared interest.",
			],
			"continued_templates": [
				"They were still going. Turns out they both loved it.",
			],
			"weight_modifiers": [
				{ "condition": { "has_trait": ["SOCIAL"] }, "multiply": 1.4 },
				{ "condition": { "mood_above": 5 }, "multiply": 1.3 },
			],
			"requirements": {
				"shares_interest_with_target": true,
			},
		},
		"UNSOLICITED_ADVICE": {
			"base_weight": 5,
			"mood_delta": -5,
			"call_action": "converse_unsolicited_advice",
			"storybook_templates": [
				"{name} offered {target} some advice. {target} didn't ask for it.",
				"Unprompted, {name} told {target} what they should do.",
				"{name} thought they were being helpful. {target} disagreed.",
			],
			"continued_templates": [
				"{name} kept advising. {target} kept not listening.",
			],
			"weight_modifiers": [
				{ "condition": { "has_trait": ["BY_THE_BOOK"] }, "multiply": 2.0 },
				{ "condition": { "has_trait": ["STUBBORN"] }, "multiply": 1.5 },
				{ "condition": { "mood_above": 5 }, "multiply": 1.3 },
			],
		},
		"SHOW_OFF": {
			"base_weight": 4,
			"mood_delta": -4,
			"call_action": "converse_show_off",
			"storybook_templates": [
				"{name} steered the conversation back to themselves.",
				"{name} couldn't help bragging a little.",
				"Somehow every topic circled back to {name}.",
			],
			"continued_templates": [
				"{name} was still going. {target} had stopped listening.",
			],
			"weight_modifiers": [
				{ "condition": { "has_trait": ["NARCISSISTIC"] }, "multiply": 3.0 },
				{ "condition": { "has_trait": ["COMPETITIVE"] }, "multiply": 1.5 },
				{ "condition": { "has_feeling": "COCKY" }, "multiply": 2.0 },
			],
		},
		"DEEP_MOMENT": {
			"base_weight": 3,
			"mood_delta": 15,
			"call_action": "converse_deep_moment",
			"storybook_templates": [
				"Something shifted. {name} said something real to {target}.",
				"The small talk fell away. {name} and {target} were actually talking.",
				"{target} didn't expect {name} to open up like that.",
			],
			"continued_templates": [
				"They stayed in it. Neither wanted to break the moment.",
			],
			"weight_modifiers": [
				{ "condition": { "mood_above": 20 }, "multiply": 2.0 },
				{ "condition": { "has_trait": ["ROMANTIC"] }, "multiply": 1.8 },
				{ "condition": { "relationship_bond_above": 40 }, "multiply": 2.0 },
				{ "condition": { "time_of_day": ["evening", "night"] }, "multiply": 1.5 },
			],
			"requirements": {
				"relationship_bond_above": 20,
			},
		},
		"RUB_WRONG_WAY": {
			"base_weight": 6,
			"mood_delta": -10,
			"call_action": "converse_rub_wrong_way",
			"storybook_templates": [
				"{name} said the wrong thing. Didn't even realise.",
				"Something about what {name} said rubbed {target} the wrong way.",
				"{target} didn't say anything, but {name} could tell.",
			],
			"continued_templates": [
				"It happened again. {name} just kept putting their foot in it.",
			],
			"weight_modifiers": [
				{ "condition": { "has_trait": ["ANTISOCIAL"] }, "multiply": 2.0 },
				{ "condition": { "has_trait": ["OBLIVIOUS"] }, "multiply": 1.8 },
				{ "condition": { "relationship_bond_below": 10 }, "multiply": 1.5 },
			],
		},
	},

	# ── ESCALATION POOL ─────────────────────────────────────
	# Only available after escalation_min_beats. Each has a chance
	# to end the conversation immediately.
	"escalation_pool": {
		"HEATED_ARGUMENT_BEAT": {
			"base_weight": 5,
			"mood_delta": -25,
			"call_action": "converse_heated_argument",
			"ends_conversation_chance": 0.0,
			"storybook_templates": [
				"Voices raised. {name} and {target} weren't chatting anymore.",
				"It escalated. {name} and {target} were properly arguing now.",
				"What started as a conversation turned into something uglier.",
			],
			"weight_modifiers": [
				{ "condition": { "mood_below": -20 }, "multiply": 3.0 },
				{ "condition": { "has_trait": ["SHORT_TEMPERED"] }, "multiply": 2.0 },
				{ "condition": { "has_feeling": "FURIOUS" }, "multiply": 2.5 },
				{ "condition": { "relationship_bond_below": -10 }, "multiply": 2.0 },
			],
		},
		"SPIT_ON": {
			"base_weight": 1,
			"mood_delta": -40,
			"call_action": "converse_spit_on",
			"ends_conversation_chance": 0.65,
			"storybook_templates": [
				"{name} spat at {target}. The conversation was over.",
				"No words left. {name} spat in {target}'s direction.",
			],
			"weight_modifiers": [
				{ "condition": { "mood_below": -30 }, "multiply": 3.0 },
				{ "condition": { "has_feeling": "FURIOUS" }, "multiply": 4.0 },
				{ "condition": { "has_trait": ["VIOLENT"] }, "multiply": 2.0 },
			],
		},
	},

	# ── END POOL ────────────────────────────────────────────
	# Picked when the continue/end roll triggers ending.
	# Weighted by final mood value.
	"end_pool": {
		"NATURAL_GOODBYE": {
			"base_weight": 10,
			"storybook_templates": [
				"{name} and {target} said their goodbyes.",
				"The conversation wound down naturally.",
				"{name} smiled. {target} nodded. That was that.",
			],
			"weight_modifiers": [
				{ "condition": { "mood_above": 5 }, "multiply": 3.0 },
			],
		},
		"GOTTA_RUN": {
			"base_weight": 8,
			"storybook_templates": [
				"{name} had to go. {target} understood.",
				"\"I should get going.\" {name} stood up.",
				"{target} waved {name} off. Places to be.",
			],
			"weight_modifiers": [],
		},
		"AWKWARD_EXIT": {
			"base_weight": 5,
			"storybook_templates": [
				"The conversation hit a wall. {name} excused themselves.",
				"Neither knew what to say next. {name} left.",
				"It fizzled out. {name} found a reason to leave.",
			],
			"weight_modifiers": [
				{ "condition": { "mood_below": 0, "mood_above": -15 }, "multiply": 2.5 },
			],
		},
		"STORMED_OFF": {
			"base_weight": 2,
			"storybook_templates": [
				"{name} walked away mid-sentence. Done.",
				"{name} didn't say goodbye. Just left.",
				"{target} was still talking when {name} turned and walked off.",
			],
			"weight_modifiers": [
				{ "condition": { "mood_below": -20 }, "multiply": 5.0 },
				{ "condition": { "has_trait": ["SHORT_TEMPERED"] }, "multiply": 2.0 },
			],
		},
	},

	# ── SUMMARY TEMPLATES ───────────────────────────────────
	# Written once at the end. Picked by mood bracket.
	"summary_templates": {
		"very_positive": [
			"{name} and {target} had a great conversation.",
			"That was a good talk. {name} and {target} both knew it.",
		],
		"positive": [
			"{name} and {target} had a nice chat.",
			"A pleasant conversation between {name} and {target}.",
		],
		"neutral": [
			"{name} and {target} talked for a while.",
			"A conversation happened. Nothing remarkable.",
		],
		"negative": [
			"{name} and {target} didn't see eye to eye.",
			"The conversation between {name} and {target} was tense.",
		],
		"very_negative": [
			"That conversation went badly. {name} and {target} both knew it.",
			"{name} and {target} should have stopped talking a long time ago.",
		],
		"recovery": [
			"It started rough, but {name} and {target} found common ground.",
			"Things were tense at first. By the end, they were laughing.",
		],
		"soured": [
			"It started well enough. It didn't end that way.",
			"{name} and {target} started friendly. Something changed.",
		],
	},
},
}
const CONVERSATION_TOPICS: Dictionary = {
	"positive": [
		"something funny that happened",
		"a good meal they had recently",
		"their favourite spot in the building",
		"a show they've been watching",
		"weekend plans",
		"a hobby they've picked up",
		"a funny rumour going around",
		"how great the weather's been",
		"a cool thing they saw",
		"someone they admire",
		"a place they want to visit",
		"something they're looking forward to",
	],
	"neutral": [
		"the building",
		"the weather",
		"what they've been up to",
		"the elevator situation",
		"the neighbourhood",
		"the news",
		"nothing in particular",
		"whatever came to mind",
		"the usual",
		"this and that",
		"how busy things have been",
		"who they've seen around lately",
	],
	"negative": [
		"something that's been bothering them",
		"a complaint about the building",
		"someone who annoys them",
		"how tired they are",
		"rent prices",
		"the state of things",
		"how unfair something is",
		"a grudge they can't let go of",
		"something that went wrong",
		"their frustrations",
		"how loud the neighbours are",
		"management's latest decision",
	],
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

func get_conversation_topic(tone: String) -> String:
	var pool: Array = CONVERSATION_TOPICS.get(tone, CONVERSATION_TOPICS["neutral"])
	return pool[randi() % pool.size()]


func get_beat_from_pool(sequence_key: String, beat_key: String) -> Dictionary:
	var seq: Dictionary = SEQUENCES.get(sequence_key, {})
	if seq.get("beat_pool", {}).has(beat_key):
		return seq["beat_pool"][beat_key]
	if seq.get("escalation_pool", {}).has(beat_key):
		return seq["escalation_pool"][beat_key]
	return {}


func get_end_beat(sequence_key: String, end_key: String) -> Dictionary:
	var seq: Dictionary = SEQUENCES.get(sequence_key, {})
	return seq.get("end_pool", {}).get(end_key, {})