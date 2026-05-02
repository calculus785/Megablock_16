# states.gd
# Autoload — available globally as States
# Tier 1 Config — pure data, no dependencies
#
# Two things live here:
# 1. STATES — stat-derived labels. Evaluated automatically by StateDriver.
# 2. PERSISTENT_STATES — set/cleared by events, never auto-evaluated.
#
# StateDriver reads STATES every half-hour tick.
# Never add/remove stat-derived states manually — change the stat instead.
# Persistent states ARE set manually via events using Actions.

extends Node


# ─────────────────────────────────────────────────────────────
# STAT-DERIVED STATES
# Each entry watches one stat and fires when it crosses a threshold.
# direction "high" = state activates when stat is HIGH
# direction "low"  = state activates when stat is LOW
# Hysteresis gap between enter/exit prevents flickering.
# ─────────────────────────────────────────────────────────────

const STATES: Dictionary = {

# ── STRESS ───────────────────────────────────────────────────
"TENSE": {
	"stat": "stress", "direction": "high",
	"enter_threshold": 55, "exit_threshold": 40,
	"label": "Tense",
	"description": "On edge. Small things are starting to bother them."
},
"STRESSED_OUT": {
	"stat": "stress", "direction": "high",
	"enter_threshold": 72, "exit_threshold": 55,
	"label": "Stressed Out",
	"description": "Struggling to cope. Prone to snapping at people."
},
"BURNT_OUT": {
	"stat": "stress", "direction": "high",
	"enter_threshold": 88, "exit_threshold": 70,
	"label": "Burnt Out",
	"description": "At breaking point. Anything could set them off."
},
"AT_EASE": {
	"stat": "stress", "direction": "low",
	"enter_threshold": 20, "exit_threshold": 35,
	"label": "At Ease",
	"description": "Relaxed. Taking things in their stride."
},

# ── HAPPINESS ────────────────────────────────────────────────
"CONTENT": {
	"stat": "happiness", "direction": "high",
	"enter_threshold": 68, "exit_threshold": 55,
	"label": "Content",
	"description": "Things are good. Life feels manageable."
},
"ON_TOP_OF_THE_WORLD": {
	"stat": "happiness", "direction": "high",
	"enter_threshold": 85, "exit_threshold": 70,
	"label": "On Top of the World",
	"description": "Genuinely happy. The kind that makes others notice."
},
"UNHAPPY": {
	"stat": "happiness", "direction": "low",
	"enter_threshold": 35, "exit_threshold": 48,
	"label": "Unhappy",
	"description": "Not doing great. Going through the motions."
},
"MISERABLE_STATE": {
	"stat": "happiness", "direction": "low",
	"enter_threshold": 18, "exit_threshold": 30,
	"label": "Miserable",
	"description": "Genuinely unhappy. It shows."
},

# ── ENERGY ───────────────────────────────────────────────────
"WELL_RESTED": {
	"stat": "energy", "direction": "high",
	"enter_threshold": 82, "exit_threshold": 68,
	"label": "Well Rested",
	"description": "Fully recharged. Ready for anything."
},
"TIRED": {
	"stat": "energy", "direction": "low",
	"enter_threshold": 40, "exit_threshold": 55,
	"label": "Tired",
	"description": "Running low. Starting to drag."
},
"EXHAUSTED": {
	"stat": "energy", "direction": "low",
	"enter_threshold": 20, "exit_threshold": 35,
	"label": "Exhausted",
	"description": "Barely functioning. Needs sleep badly."
},
"DELIRIOUS": {
	"stat": "energy", "direction": "low",
	"enter_threshold": 8, "exit_threshold": 18,
	"label": "Delirious",
	"description": "Beyond exhausted. Making bad decisions."
},

# ── HUNGER ───────────────────────────────────────────────────
"PECKISH": {
	"stat": "hunger", "direction": "high",
	"enter_threshold": 45, "exit_threshold": 25,
	"label": "Peckish",
	"description": "Could eat. Not urgent yet."
},
"HUNGRY": {
	"stat": "hunger", "direction": "high",
	"enter_threshold": 65, "exit_threshold": 45,
	"label": "Hungry",
	"description": "Needs food soon. Getting distracted by it."
},
"STARVING": {
	"stat": "hunger", "direction": "high",
	"enter_threshold": 82, "exit_threshold": 65,
	"label": "Starving",
	"description": "Genuinely struggling. Health will start suffering."
},

# ── LONELINESS ───────────────────────────────────────────────
"LONELY": {
	"stat": "loneliness", "direction": "high",
	"enter_threshold": 55, "exit_threshold": 38,
	"label": "Lonely",
	"description": "Craving connection. More likely to seek people out."
},
"DESPERATELY_LONELY": {
	"stat": "loneliness", "direction": "high",
	"enter_threshold": 78, "exit_threshold": 58,
	"label": "Desperately Lonely",
	"description": "Aching for any human contact. Vulnerability is showing."
},
"ISOLATED": {
	"stat": "loneliness", "direction": "high",
	"enter_threshold": 92, "exit_threshold": 75,
	"label": "Isolated",
	"description": "Completely alone. Mental health is suffering."
},

# ── BOREDOM ──────────────────────────────────────────────────
"RESTLESS": {
	"stat": "boredom", "direction": "high",
	"enter_threshold": 55, "exit_threshold": 35,
	"label": "Restless",
	"description": "Needs something to do. Starting to look for it."
},
"CLIMBING_THE_WALLS": {
	"stat": "boredom", "direction": "high",
	"enter_threshold": 75, "exit_threshold": 55,
	"label": "Climbing the Walls",
	"description": "Dangerously bored. Will do something about it — for better or worse."
},
"LOOKING_FOR_TROUBLE": {
	"stat": "boredom", "direction": "high",
	"enter_threshold": 90, "exit_threshold": 72,
	"label": "Looking for Trouble",
	"description": "Boredom has curdled into intent. Something is going to happen."
},

# ── HORNINESS ────────────────────────────────────────────────
"FRISKY": {
	"stat": "horniness", "direction": "high",
	"enter_threshold": 55, "exit_threshold": 35,
	"label": "Frisky",
	"description": "Aware of attraction. More flirtatious than usual."
},
"HORNY": {
	"stat": "horniness", "direction": "high",
	"enter_threshold": 72, "exit_threshold": 50,
	"label": "Horny",
	"description": "Actively seeking connection. Hard to think about much else."
},
"DESPERATE": {
	"stat": "horniness", "direction": "high",
	"enter_threshold": 88, "exit_threshold": 68,
	"label": "Desperate",
	"description": "Will make moves they might regret. Judgment is compromised."
},

# ── BLADDER ──────────────────────────────────────────────────
"NEEDS_THE_TOILET": {
	"stat": "need_for_toilet", "direction": "high",
	"enter_threshold": 55, "exit_threshold": 20,
	"label": "Needs the Toilet",
	"description": "Aware of it. Manageable for now."
},
"BURSTING": {
	"stat": "need_for_toilet", "direction": "high",
	"enter_threshold": 80, "exit_threshold": 55,
	"label": "Bursting",
	"description": "Cannot concentrate on anything else. Urgent."
},
"THIS_IS_AN_EMERGENCY": {
	"stat": "need_for_toilet", "direction": "high",
	"enter_threshold": 95, "exit_threshold": 80,
	"label": "This Is an Emergency",
	"description": "Something bad is about to happen if a toilet is not found immediately."
},

# ── HEALTH ───────────────────────────────────────────────────
"UNDER_THE_WEATHER": {
	"stat": "health", "direction": "low",
	"enter_threshold": 55, "exit_threshold": 68,
	"label": "Under the Weather",
	"description": "Not great. Getting through it."
},
"UNWELL": {
	"stat": "health", "direction": "low",
	"enter_threshold": 35, "exit_threshold": 50,
	"label": "Unwell",
	"description": "Genuinely sick. Needs rest or medical attention."
},
"DANGEROUSLY_ILL": {
	"stat": "health", "direction": "low",
	"enter_threshold": 15, "exit_threshold": 28,
	"label": "Dangerously Ill",
	"description": "Critical. Without help this could be fatal."
},

# ── GRIEF ────────────────────────────────────────────────────
"MILD_GRIEF": {
	"stat": "grief", "direction": "high",
	"enter_threshold": 25, "exit_threshold": 10,
	"label": "Grieving",
	"description": "Something weighs on them. They're carrying it quietly."
},
"GRIEVING_STATE": {
	"stat": "grief", "direction": "high",
	"enter_threshold": 55, "exit_threshold": 35,
	"label": "Deep in Grief",
	"description": "Loss is present in everything they do."
},
"CONSUMED_BY_GRIEF": {
	"stat": "grief", "direction": "high",
	"enter_threshold": 80, "exit_threshold": 60,
	"label": "Consumed by Grief",
	"description": "Barely functional. The world has gone quiet."
},

# ── CASH ─────────────────────────────────────────────────────
"BROKE": {
	"stat": "cash", "direction": "low",
	"enter_threshold": 50, "exit_threshold": 120,
	"label": "Broke",
	"description": "Barely scraping by. Stress is climbing."
},
"DESTITUTE": {
	"stat": "cash", "direction": "low",
	"enter_threshold": 10, "exit_threshold": 50,
	"label": "Destitute",
	"description": "Nothing left. Desperate measures become thinkable."
},
"COMFORTABLE": {
	"stat": "cash", "direction": "high",
	"enter_threshold": 600, "exit_threshold": 400,
	"label": "Comfortable",
	"description": "Financially stable. Not worrying about money."
},
"FLUSH": {
	"stat": "cash", "direction": "high",
	"enter_threshold": 1200, "exit_threshold": 800,
	"label": "Flush",
	"description": "Doing well. Might splash out on something."
},
"RICH": {
	"stat": "cash", "direction": "high",
	"enter_threshold": 2500, "exit_threshold": 1500,
	"label": "Rich",
	"description": "Living large. Money is no object."
},

# ── ADDICTION ────────────────────────────────────────────────
"DEVELOPING_HABIT": {
	"stat": "addiction", "direction": "high",
	"enter_threshold": 30, "exit_threshold": 18,
	"label": "Developing a Habit",
	"description": "Starting to rely on something. Not quite aware of it yet."
},
"ADDICTED": {
	"stat": "addiction", "direction": "high",
	"enter_threshold": 55, "exit_threshold": 35,
	"label": "Addicted",
	"description": "Dependent. Goes out of their way to get a fix."
},
"DEEP_IN_IT": {
	"stat": "addiction", "direction": "high",
	"enter_threshold": 78, "exit_threshold": 58,
	"label": "Deep In It",
	"description": "Addiction is defining their behaviour. Hard to reach."
},

# ── CRIMINAL ─────────────────────────────────────────────────
"SHADY": {
	"stat": "criminal_inclination", "direction": "high",
	"enter_threshold": 45, "exit_threshold": 28,
	"label": "Shady",
	"description": "Willing to bend rules when it suits them."
},
"CRIMINAL_MINDED": {
	"stat": "criminal_inclination", "direction": "high",
	"enter_threshold": 68, "exit_threshold": 48,
	"label": "Criminal Minded",
	"description": "Actively looks for angles. Legitimate options feel like a waste."
},
"KNOWN_CRIMINAL": {
	"stat": "criminal_reputation", "direction": "high",
	"enter_threshold": 50, "exit_threshold": 30,
	"label": "Known Criminal",
	"description": "The building knows what they are. Doors close. Others open."
},
"FEARED": {
	"stat": "criminal_reputation", "direction": "high",
	"enter_threshold": 78, "exit_threshold": 58,
	"label": "Feared",
	"description": "Reputation precedes them. People get out of the way."
},

# ── REPUTATION ───────────────────────────────────────────────
"WELL_REGARDED": {
	"stat": "global_reputation", "direction": "high",
	"enter_threshold": 68, "exit_threshold": 52,
	"label": "Well Regarded",
	"description": "People think well of them. Small advantages everywhere."
},
"BELOVED": {
	"stat": "global_reputation", "direction": "high",
	"enter_threshold": 85, "exit_threshold": 70,
	"label": "Beloved",
	"description": "A building favourite. Strangers nod at them in the corridor."
},
"DISLIKED_STATE": {
	"stat": "global_reputation", "direction": "low",
	"enter_threshold": 35, "exit_threshold": 48,
	"label": "Disliked",
	"description": "People avoid them. Conversations are short."
},
"PARIAH": {
	"stat": "global_reputation", "direction": "low",
	"enter_threshold": 15, "exit_threshold": 28,
	"label": "Pariah",
	"description": "Socially untouchable. Even the bar goes quiet when they walk in."
},
}


# ─────────────────────────────────────────────────────────────
# PERSISTENT STATES
# Set and cleared by events via Actions — never auto-evaluated.
# Listed here so the codebase has a single registry of valid keys.
# ─────────────────────────────────────────────────────────────

const PERSISTENT_STATES: Array = [
	"INJURED",          # health events, accidents
	"PREGNANT",         # reproduction chain
	"IN_HOSPITAL",      # admitted — most events suspended
	"IN_JAIL",          # arrested — movement locked
	"ON_PAROLE",        # released — some restrictions remain
	"BANNED_FROM_BAR",  # set by bar owner / police event
	"EMPLOYED",         # has an active job
	"UNEMPLOYED",       # between jobs
	"HOMELESS",         # no apartment, faction-assigned
	"IN_VR_POD",        # inside a VR pod — cannot interact with others
	"TRAUMATISED",      # witnessed violent death — set by grief propagation
	"UNDER_INVESTIGATION", # police opened a case
	"WANTED",           # arrest warrant issued
]


func _ready() -> void:
	print("[States] Loaded. %d stat-derived states, %d persistent states." % [
		STATES.size(), PERSISTENT_STATES.size()
	])


# ─────────────────────────────────────────────────────────────
# HELPERS
# ─────────────────────────────────────────────────────────────

func get_label(state_key: String) -> String:
	if STATES.has(state_key):
		return STATES[state_key]["label"]
	return state_key  # fallback for persistent states

func get_states_for_stat(stat_key: String) -> Array:
	# Returns only the states watching a given stat.
	# StateDriver uses this to skip irrelevant checks.
	var result: Array = []
	for key in STATES:
		if STATES[key]["stat"] == stat_key:
			result.append(key)
	return result

func is_valid_persistent(state_key: String) -> bool:
	return state_key in PERSISTENT_STATES

func is_valid_derived(state_key: String) -> bool:
	return STATES.has(state_key)