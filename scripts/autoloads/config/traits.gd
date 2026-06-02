# traits.gd
# Autoload — available globally as Traits
# Tier 1 Config — pure data, with evolution logic
#
# Single source of truth for every trait in the game.
# To add a new trait: add one entry to TRAITS. That's it.
#
# Definition fields:
#   label              — UI display name
#   weight             — base probability when rolling random traits
#   description        — flavour text for tooltips/UI
#   stat_modifiers     — applied on top of Stats defaults at character creation
#   conflicting_traits — these trait keys cannot appear on the same character
#   flags              — tags Events/Sim will read to gate or weight events
#                        we define them now, implement their logic later

extends Node


const TRAITS: Dictionary = {

# ── PERSONALITY ─────────────────────────────────────────────────────────
"FLIRTATIOUS": {
	"label": "Flirtatious",
    "hideable": true,
	"weight": 10,
	"description": "Naturally drawn to romance and physical connection. Pursues it openly.",
	"stat_modifiers": {"horniness": 20, "attractiveness": 10, "loneliness": -10},
	"conflicting_traits": ["RECLUSIVE", "LONER"],
	"flags": {"pursues_romance": true, "flirts_at_bar": true}
},
"SHORT_TEMPERED": {
	"label": "Short Tempered",
    "hideable": true,
	"weight": 8,
	"description": "Stress builds fast. Slow to forgive. Quick to escalate.",
	"stat_modifiers": {"stress": 20, "happiness": -10},
	"conflicting_traits": ["OPTIMISTIC", "FUNNY"],
	"flags": {"can_start_fights": true, "escalates_arguments": true}
},
"CHARMING": {
	"label": "Charming",
    "hideable": true,
	"weight": 10,
	"description": "People warm to them quickly. Social events tend to go their way.",
	"stat_modifiers": {"global_reputation": 15, "loneliness": -15},
	"conflicting_traits": ["RECLUSIVE", "PARANOID"],
	"flags": {"builds_relationships_faster": true, "social_events_bonus": true}
},
"STUBBORN": {
	"label": "Stubborn",
    "hideable": true,
	"weight": 10,
	"description": "Slow to change their mind about people. Hard to befriend, hard to make an enemy.",
	"stat_modifiers": {"stress": 10},
	"conflicting_traits": [],
	"flags": {"relationship_change_rate_halved": true, "high_patience": true}
},
"OPTIMISTIC": {
	"label": "Optimistic",
    "hideable": true,
	"weight": 10,
	"description": "Finds the bright side. Bounces back from bad events faster than most.",
	"stat_modifiers": {"happiness": 20, "stress": -15},
	"conflicting_traits": ["PESSIMISTIC", "SHORT_TEMPERED", "PARANOID"],
	"flags": {"recovers_mood_faster": true}
},
"PESSIMISTIC": {
	"label": "Pessimistic",
    "hideable": true,
	"weight": 8,
	"description": "Expects the worst. Often right. Bad events hit harder than they should.",
	"stat_modifiers": {"happiness": -20, "stress": 15},
	"conflicting_traits": ["OPTIMISTIC", "FUNNY"],
	"flags": {"bad_events_hit_harder": true}
},
"FUNNY": {
	"label": "Funny",
    "hideable": true,
	"weight": 9,
	"description": "Naturally comic. Lightens the mood wherever they go. Hard to stay mad at.",
	"stat_modifiers": {"happiness": 10, "loneliness": -20},
	"conflicting_traits": ["SHORT_TEMPERED", "PESSIMISTIC"],
	"flags": {"reduces_stress_in_others": true, "popular_at_bar": true}
},
"PARANOID": {
	"label": "Paranoid",
    "hideable": true,
	"weight": 5,
	"description": "Trusts nobody. Sees patterns in everything. Sometimes correct.",
	"stat_modifiers": {"stress": 25, "happiness": -15},
	"conflicting_traits": ["CHARMING", "OPTIMISTIC"],
	"flags": {"suspicious_of_neighbours": true, "notices_criminal_activity": true}
},
"JEALOUS_TYPE": {
	"label": "Jealous Type",
	"weight": 8,
	"hideable": true,
	"description": "Doesn't show it easily. But when a rival appears, something shifts.",
	"stat_modifiers": {"stress": 10},
	"conflicting_traits": ["LONER"],
	"flags": {"jealousy_events_eligible": true, "rivalry_forms_faster": true}
},

# ── SOCIAL ──────────────────────────────────────────────────────────────
"RECLUSIVE": {
	"label": "Reclusive",
    "hideable": true,
	"weight": 7,
	"description": "Prefers their own company. Resists social situations. Needs space.",
	"stat_modifiers": {"loneliness": -30, "happiness": -10},
	"conflicting_traits": ["FLIRTATIOUS", "CHARMING", "GOSSIP", "NOSY"],
	"flags": {"avoids_social_events": true}
},
"GOSSIP": {
	"label": "Gossip",
    "hideable": true,
	"weight": 9,
	"description": "Cannot keep a secret. Spreads news across the building like wildfire.",
	"stat_modifiers": {"loneliness": -10},
	"conflicting_traits": ["RECLUSIVE", "SECRETIVE"],
	"flags": {"spreads_information": true, "involved_in_drama": true}
},
"ROMANTIC": {
	"label": "Romantic",
    "hideable": true,
	"weight": 10,
	"description": "Falls fast, loves hard. Heartbreak is catastrophic. Hopeful every time.",
	"stat_modifiers": {"horniness": 10, "loneliness": 15},
	"conflicting_traits": ["LONER"],
	"flags": {"falls_in_love_faster": true, "heartbreak_hits_harder": true}
},
"LONER": {
	"label": "Loner",
    "hideable": true,
	"weight": 6,
	"description": "Genuinely content alone. Loneliness barely registers. Relationships are optional.",
	"stat_modifiers": {"loneliness": -40, "happiness": 5},
	"conflicting_traits": ["ROMANTIC", "FLIRTATIOUS", "GOSSIP"],
	"flags": {"loneliness_immune": true, "relationship_cap_best_friend": true}
},
"NOSY": {
	"label": "Nosy",
    "hideable": true,
	"weight": 9,
	"description": "Always in someone else's business. Regularly witnesses events they weren't invited to.",
	"stat_modifiers": {"boredom": -20},
	"conflicting_traits": ["RECLUSIVE"],
	"flags": {"witnesses_other_events": true}
},

# ── TIME OF DAY ──────────────────────────────────────────────────────────
"MORNING_PERSON": {
	"label": "Morning Person",
	"weight": 8,
	"hideable": true,
	"description": "Chipper before noon. Baffling to everyone else.",
	"stat_modifiers": {"energy": 15, "happiness": 5},
	"conflicting_traits": ["INSOMNIAC", "NIGHT_OWL"],
	"flags": {"energy_bonus_morning": true, "energy_penalty_night": true}
},
"NIGHT_OWL": {
	"label": "Night Owl",
	"weight": 9,
	"hideable": true,
	"description": "Comes alive after dark. Mornings are survivable. Barely.",
	"stat_modifiers": {"energy": -10},
	"conflicting_traits": ["MORNING_PERSON"],
	"flags": {"active_at_night": true, "energy_bonus_night": true}
},

# ── DARK / CRIMINAL ──────────────────────────────────────────────────────
"CRIMINAL_HEART": {
	"label": "Criminal Heart",
    "hideable": true,
	"weight": 4,
	"description": "Breaking rules comes naturally. The sewers don't scare them. Legitimate work bores them.",
	"stat_modifiers": {"criminal_inclination": 40, "cash": 50},
	"conflicting_traits": ["BY_THE_BOOK"],
	"flags": {"drawn_to_shady_events": true, "can_initiate_crimes": true}
},
"GAMBLER": {
	"label": "Gambler",
    "hideable": true,
	"weight": 6,
	"description": "The casino calls. Wins feel amazing. Losses are immediately chased.",
	"stat_modifiers": {"cash": -50, "boredom": -10},
	"conflicting_traits": [],
	"flags": {"drawn_to_casino": true, "addiction_climbs_at_casino": true}
},
"VIOLENT": {
	"label": "Violent",
    "hideable": true,
	"weight": 3,
	"description": "Physical confrontation is always on the table. Arguments escalate fast.",
	"stat_modifiers": {"stress": 15, "criminal_inclination": 20},
	"conflicting_traits": ["FUNNY", "CHARMING"],
	"flags": {"can_start_fights": true, "escalates_to_violence": true}
},
"MANIPULATIVE": {
	"label": "Manipulative",
    "hideable": true,
	"weight": 4,
	"description": "Uses people. Shapes relationships to serve their own ends. Hard to catch.",
	"stat_modifiers": {"criminal_inclination": 15, "attractiveness": 10},
	"conflicting_traits": [],
	"flags": {"can_manipulate_relationships": true}
},
"ADDICT_PRONE": {
	"label": "Addictive Personality",
    "hideable": true,
	"weight": 5,
	"description": "Anything pleasurable becomes a habit. The bar is dangerous for them.",
	"stat_modifiers": {"addiction": 10, "happiness": 10},
	"conflicting_traits": [],
	"flags": {"addiction_climbs_faster": true}
},
"CORRUPT": {
	"label": "Corrupt",
    "hideable": true,
	"weight": 3,
	"description": "Will take a bribe. Will offer one. The system is just a tool.",
	"stat_modifiers": {"criminal_inclination": 25, "cash": 100},
	"conflicting_traits": ["BY_THE_BOOK"],
	"flags": {"accepts_bribes": true, "abuses_authority": true}
},
"BY_THE_BOOK": {
	"label": "By The Book",
    "hideable": true,
	"weight": 7,
	"description": "Rules exist for a reason. Cuts no corners. Reports infractions.",
	"stat_modifiers": {"stress": 10, "criminal_inclination": -10},
	"conflicting_traits": ["CRIMINAL_HEART", "CORRUPT"],
	"flags": {"reports_crimes": true, "refuses_bribes": true}
},

# ── PRACTICAL / LIFESTYLE ────────────────────────────────────────────────
"MOTIVATED": {
	"label": "Motivated",
    "hideable": true,
	"weight": 10,
	"description": "High energy, high output. Works harder than most. Has plans.",
	"stat_modifiers": {"energy": 20, "stress": -10, "cash": 100},
	"conflicting_traits": ["LAZY"],
	"flags": {"job_performance_bonus": true}
},
"LAZY": {
	"label": "Lazy",
    "hideable": true,
	"weight": 9,
	"description": "Minimum effort. Maximum comfort. Boredom is a constant companion.",
	"stat_modifiers": {"energy": -20, "boredom": 20, "cash": -50},
	"conflicting_traits": ["MOTIVATED"],
	"flags": {"job_performance_penalty": true, "boredom_climbs_faster": true, "low_patience": true}
},
"INSOMNIAC": {
	"label": "Insomniac",
    "hideable": true,
	"weight": 6,
	"description": "Sleep doesn't come easily. Never fully rested. 3am is a normal hour.",
	"stat_modifiers": {"energy": -25},
	"conflicting_traits": [],
	"flags": {"energy_cap_reduced": true, "active_at_night": true}
},
"NEAT_FREAK": {
	"label": "Neat Freak",
    "hideable": true,
	"weight": 7,
	"description": "Their apartment is immaculate. Disorder in others stresses them out.",
	"stat_modifiers": {"stress": -10, "happiness": 10},
	"conflicting_traits": [],
	"flags": {"apartment_always_tidy": true, "stressed_by_mess": true}
},
"FORGETFUL": {
	"label": "Forgetful",
    "hideable": true,
	"weight": 8,
	"description": "Misses appointments. Loses things. Genuinely means well. Mostly.",
	"stat_modifiers": {},
	"conflicting_traits": [],
	"flags": {"occasionally_misses_events": true}
},
"HOMEBODY": {
	"label": "Homebody",
	"weight": 8,
	"hideable": true,
	"description": "Their apartment is their world. Leaving requires motivation.",
	"stat_modifiers": {"stress": -10, "boredom": 15},
	"conflicting_traits": ["NOSY", "GOSSIP"],
	"flags": {"prefers_apartment_events": true, "resists_leaving_home": true}
},
"THRILL_SEEKER": {
	"label": "Thrill Seeker",
	"weight": 6,
	"hideable": true,
	"description": "Boredom is unbearable. Risk is the cure. This does not always end well.",
	"stat_modifiers": {"boredom": -20, "criminal_inclination": 10},
	"conflicting_traits": ["HOMEBODY"],
	"flags": {"drawn_to_risky_events": true, "boredom_drops_faster": true}
},
"GENEROUS": {
	"label": "Generous",
	"weight": 8,
	"hideable": true,
	"description": "Gives freely. Money, time, attention. Sometimes to a fault.",
	"stat_modifiers": {"cash": -50, "global_reputation": 10},
	"conflicting_traits": ["STINGY"],
	"flags": {"gifts_often": true, "relationship_bonus_on_gift": true}
},
"STINGY": {
	"label": "Stingy",
	"weight": 6,
	"hideable": true,
	"description": "Holds on to what's theirs. Every transaction is a negotiation.",
	"stat_modifiers": {"cash": 100},
	"conflicting_traits": ["GENEROUS"],
	"flags": {"rarely_gifts": true, "resists_buying_rounds": true}
},

# ── PHYSICAL / NEEDS ─────────────────────────────────────────────────────
"HYPOCHONDRIAC": {
	"label": "Hypochondriac",
    "hideable": true,
	"weight": 6,
	"description": "Convinced they're always one symptom away from disaster. Frequent clinic visitor.",
	"stat_modifiers": {"stress": 15, "health": 10},
	"conflicting_traits": [],
	"flags": {"visits_clinic_often": true}
},
"BIG_APPETITE": {
	"label": "Big Appetite",
    "hideable": true,
	"weight": 8,
	"description": "Always hungry. Visits the grocery often. Gets cranky when they skip a meal.",
	"stat_modifiers": {"hunger": 20, "health": 5},
	"conflicting_traits": [],
	"flags": {"hunger_climbs_faster": true}
},
"WEAK_BLADDER": {
	"label": "Weak Bladder",
    "hideable": true,
	"weight": 5,
	"description": "The toilet is never far from their mind. Long events are a gamble.",
	"stat_modifiers": {"need_for_toilet": 20},
	"conflicting_traits": [],
	"flags": {"toilet_need_climbs_faster": true}
},
"HIGH_LIBIDO": {
	"label": "High Libido",
    "hideable": true,
	"weight": 7,
	"description": "Horniness is a persistent and motivating force in their life.",
	"stat_modifiers": {"horniness": 30},
	"conflicting_traits": ["LONER"],
	"flags": {"horniness_climbs_faster": true, "pursues_romance": true}
},
"SECRETIVE": {
	"label": "Secretive",
    "hideable": true,
	"weight": 7,
	"description": "Keeps themselves to themselves. Hard to read. Their Storybook has gaps.",
	"stat_modifiers": {"criminal_inclination": 5},
	"conflicting_traits": ["GOSSIP", "NOSY"],
	"flags": {"withholds_information": true}
},
"PREFERS_LIGHT_HAIR": {
	"label": "Prefers Light Hair",
	"weight": 6,
	"hideable": true,
	"description": "A consistent pattern in who catches their eye. They may not even notice it themselves.",
	"stat_modifiers": {},
	"conflicting_traits": ["PREFERS_DARK_HAIR"],
	"flags": {"attraction_bonus_light_hair": true}
},
"PREFERS_DARK_HAIR": {
	"label": "Prefers Dark Hair",
	"weight": 6,
	"hideable": true,
	"description": "Something about it. They couldn't explain it. They wouldn't need to.",
	"stat_modifiers": {},
	"conflicting_traits": ["PREFERS_LIGHT_HAIR"],
	"flags": {"attraction_bonus_dark_hair": true}
},
"PREFERS_UNUSUAL_HAIR": {
	"label": "Prefers Unusual Hair",
	"weight": 4,
	"hideable": true,
	"description": "Dyed, dramatic, or distinctive. Boring hair is a dealbreaker.",
	"stat_modifiers": {},
	"conflicting_traits": [],
	"flags": {"attraction_bonus_unusual_hair": true}
},
"OLDER_PREFERENCE": {
	"label": "Older Preference",
	"weight": 5,
	"hideable": true,
	"description": "Attracted to experience. Older characters have a quiet pull on them.",
	"stat_modifiers": {},
	"conflicting_traits": ["YOUNGER_PREFERENCE"],
	"flags": {"attraction_bonus_older": true}
},
"YOUNGER_PREFERENCE": {
	"label": "Younger Preference",
	"weight": 5,
	"hideable": true,
	"description": "Energy, novelty, potential. They find it magnetic.",
	"stat_modifiers": {},
	"conflicting_traits": ["OLDER_PREFERENCE"],
	"flags": {"attraction_bonus_younger": true}
},

# ── EVOLVED (granted by behaviour, not rolled at generation) ─────────────
"ALCOHOLIC": {
	"label": "Alcoholic",
	"weight": 0,  # weight 0 = never rolled at generation, only granted
	"description": "Their relationship with the bar has crossed a line. Drinking has become coping.",
	"stat_modifiers": {"addiction": 30, "health": -10, "cash": -50},
	"conflicting_traits": [],
	"flags": {"drawn_to_bar": true, "alcohol_cravings": true}
},
"RECOVERING_ALCOHOLIC": {
	"label": "Recovering Alcoholic",
	"weight": 0,
	"description": "Doing the work. The pull is still there, but they're stronger than they were.",
	"stat_modifiers": {"stress": 10, "happiness": 5},
	"conflicting_traits": [],  # can coexist with ALCOHOLIC (suppresses its modifiers)
	"flags": {"suppresses_alcoholic_modifiers": true, "avoids_bar": true}
},
"WELL_READ": {
	"label": "Well Read",
	"weight": 0,
	"description": "Hours in the library have left a mark. They reference things. People notice.",
	"stat_modifiers": { "happiness": 5 },
	"conflicting_traits": [],
	"flags": { "library_events_bonus": true }
},
 
"BRAWLER": {
	"label": "Brawler",
	"weight": 0,
	"description": "Fought enough times that it stopped feeling like a mistake. It's just what happens.",
	"stat_modifiers": { "health": -5, "stress": -10 },
	"conflicting_traits": [],
	"flags": { "can_start_fights": true, "fight_events_bonus": true }
},
 
"REGULAR": {
	"label": "Regular",
	"weight": 0,
	"description": "The bar knows their order before they sit down. They like it that way.",
	"stat_modifiers": { "loneliness": -10 },
	"conflicting_traits": [],
	"flags": { "bar_events_bonus": true, "known_at_bar": true }
},
 
"GOSSIP_EVOLVED": {
	"label": "Chronic Gossip",
	"weight": 0,
	"description": "They can't help it anymore. Every conversation becomes an exchange of secrets.",
	"stat_modifiers": { "loneliness": -5 },
	"conflicting_traits": ["SECRETIVE"],
	"flags": { "gossip_events_bonus": true, "shares_information": true }
},
}


# ─────────────────────────────────────────────────────────────
# EVOLUTION CONFIG
# Counter-based daily check. Behaviour pushes counters,
# crossing a threshold grants/removes a trait.
# Wired up to Clock.day_ticked in Phase 4. Stub for now.
# ─────────────────────────────────────────────────────────────

const EVOLUTION_THRESHOLDS: Dictionary = {
	"ALCOHOLIC": {
		"counter_key": "drinks_at_bar",
		"threshold": 30,
		"requires_trait": "",
		"hidden": false,
		"replaces": "",
	},
	"RECOVERING_ALCOHOLIC": {
		"counter_key": "sober_days",
		"threshold": 20,
		"requires_trait": "ALCOHOLIC",
		"hidden": true,
		"replaces": "",
	},
	"WELL_READ": {
		"counter_key": "books_read",
		"threshold": 15,
		"requires_trait": "",
		"hidden": false,
		"replaces": "",
	},
	"BRAWLER": {
		"counter_key": "fights",
		"threshold": 5,
		"requires_trait": "",
		"hidden": false,
		"replaces": "",
	},
	"GOSSIP_EVOLVED": {
		"counter_key": "gossip_shared",
		"threshold": 20,
		"requires_trait": "",
		"hidden": false,
		"replaces": "",
	},
	"REGULAR": {
		"counter_key": "bar_visits",
		"threshold": 15,
		"requires_trait": "",
		"hidden": false,
		"replaces": "",
	},
}
 


func _ready() -> void:
	Clock.day_ticked.connect(_on_day_ticked)
	print("[Traits] Loaded. %d traits defined." % TRAITS.size())


# ─────────────────────────────────────────────────────────────
# LOOKUP HELPERS
# ─────────────────────────────────────────────────────────────

func get_all_trait_keys() -> Array:
	return TRAITS.keys()


# Only traits with weight > 0 — i.e. eligible at generation.
func get_rollable_trait_keys() -> Array:
	var result: Array = []
	for key in TRAITS:
		if TRAITS[key]["weight"] > 0:
			result.append(key)
	return result


func get_label(trait_key: String) -> String:
	return TRAITS[trait_key]["label"]


func has_flag(trait_key: String, flag: String) -> bool:
	if not TRAITS.has(trait_key):
		return false
	var flags: Dictionary = TRAITS[trait_key]["flags"]
	return flags.get(flag, false)


# ─────────────────────────────────────────────────────────────
# RANDOM PICKING
# ─────────────────────────────────────────────────────────────

# Picks between min_count and max_count traits.
# Respects conflict rules so no two clashing traits appear together.
# Used for generating non-bespoke characters.
func pick_random_traits(min_count: int = 3, max_count: int = 5) -> Array:
	var count: int = randi_range(min_count, max_count)
	var chosen: Array = []
	var available: Array = get_rollable_trait_keys()

	while chosen.size() < count and available.size() > 0:
		# Build weighted list from whatever's still available
		var weighted_pool: Array = []
		for key in available:
			weighted_pool.append([key, TRAITS[key]["weight"]])

		var pick: String = _pick_weighted(weighted_pool)
		available.erase(pick)

		# Check conflicts against already chosen traits
		var conflicts: Array = TRAITS[pick]["conflicting_traits"]
		var has_conflict: bool = false
		for already_chosen in chosen:
			if already_chosen in conflicts:
				has_conflict = true
				break
			# Also check the inverse — pick conflicts with chosen?
			var chosen_conflicts: Array = TRAITS[already_chosen]["conflicting_traits"]
			if pick in chosen_conflicts:
				has_conflict = true
				break

		if not has_conflict:
			chosen.append(pick)

	return chosen


# Weighted random picker — used internally and by other configs.
func _pick_weighted(options: Array) -> String:
	var total_weight: int = 0
	for option in options:
		total_weight += option[1]

	if total_weight <= 0:
		return options[0][0]

	var roll: int = randi_range(1, total_weight)
	var running_total: int = 0
	for option in options:
		running_total += option[1]
		if roll <= running_total:
			return option[0]

	return options[0][0]

# Picks 1-2 hidden traits for any character (player or NPC).
# Only pulls from traits marked hideable: true.
func pick_hidden_traits(existing_traits: Array, count: int = 1) -> Array:
	var hideable: Array = []
	for key in TRAITS:
		if TRAITS[key].get("hideable", false) and TRAITS[key]["weight"] > 0:
			# Don't pick traits that conflict with already-assigned traits
			var conflicts: Array = TRAITS[key]["conflicting_traits"]
			var ok: bool = true
			for existing in existing_traits:
				if existing in conflicts or key in TRAITS.get(existing, {}).get("conflicting_traits", []):
					ok = false
					break
			if ok:
				hideable.append(key)

	hideable.shuffle()
	return hideable.slice(0, min(count, hideable.size()))

# ─────────────────────────────────────────────────────────────
# APPLYING TRAITS TO STATS
# ─────────────────────────────────────────────────────────────

# Applies a trait's stat_modifiers to a stats dictionary in-place.
# Call during character generation after setting defaults.
func apply_trait_modifiers(trait_key: String, stats: Dictionary) -> Dictionary:
	if not TRAITS.has(trait_key):
		return stats
	var modifiers: Dictionary = TRAITS[trait_key]["stat_modifiers"]
	for stat_key in modifiers:
		if stats.has(stat_key):
			var new_value: float = stats[stat_key] + modifiers[stat_key]
			stats[stat_key] = Stats.clamp_stat(stat_key, new_value)
	return stats


# ─────────────────────────────────────────────────────────────
# DAILY EVOLUTION CHECK
# Wired up to Clock.day_ticked in Phase 4. For now this is a stub.
# Each character has a `trait_progress` dictionary tracking counters
# (drinks_at_bar, sober_days, etc.). When a counter crosses a threshold,
# the matching trait is granted.
# ─────────────────────────────────────────────────────────────

func _on_day_ticked() -> void:
	for character in Registry.get_all():
		if character is RobotData:
			continue
		evaluate_evolution_for_character(character)
 
		# Sober days tracker — increment if ALCOHOLIC but didn't drink today
		if "ALCOHOLIC" in character.get_all_active_traits():
			# Check storybook for a drink event in the last day
			var drank: bool = false
			for entry in character.storybook:
				if entry.get("event_key", "") in ["ORDER_DRINK", "DRINK_ALONE"] and \
						entry.get("at_tick", 0) >= Clock.get_total_days() - 1:
					drank = true
					break
			if not drank:
				character.trait_progress["sober_days"] = \
					character.trait_progress.get("sober_days", 0) + 1
			else:
				character.trait_progress["sober_days"] = 0
 
 
func evaluate_evolution_for_character(character) -> void:
	for trait_key in EVOLUTION_THRESHOLDS:
		var config: Dictionary = EVOLUTION_THRESHOLDS[trait_key]
		var counter_key: String = config["counter_key"]
		var threshold: int = config["threshold"]
		var requires: String = config.get("requires_trait", "")
		var is_hidden: bool = config.get("hidden", false)
		var replaces: String = config.get("replaces", "")
 
		# Already has this trait — skip
		if trait_key in character.traits or trait_key in character.hidden_traits:
			continue
 
		# Trait doesn't exist in TRAITS dict — skip safely
		if not TRAITS.has(trait_key):
			push_warning("[Traits] Evolution target '%s' not in TRAITS dict." % trait_key)
			continue
 
		# Check prerequisite trait
		if requires != "" and requires not in character.get_all_active_traits():
			continue
 
		# Check counter threshold
		var current_value: int = character.trait_progress.get(counter_key, 0)
		if current_value < threshold:
			continue
 
		# Grant the trait
		if is_hidden:
			character.hidden_traits.append(trait_key)
		else:
			character.traits.append(trait_key)
 
		# Handle replacement (removes old trait)
		if replaces != "":
			character.traits.erase(replaces)
			character.hidden_traits.erase(replaces)
 
		# Apply the trait's stat modifiers
		character.stats = apply_trait_modifiers(trait_key, character.stats)
 
		if Settings.debug_console_logging:
			print("[Traits] 🌱 %s evolved: %s (%s = %d)" % [
				character.char_name, trait_key, counter_key, current_value
			])