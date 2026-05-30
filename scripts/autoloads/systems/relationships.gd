# relationships.gd
# Autoload — available globally as Relationships
# Tier 3 Systems — reads Tier 1 + 2
#
# Pairwise relationship records between characters.
# Records are lazily created on first interaction (no pre-generation).
# Bond is bidirectional. Directional feelings are per-side (a_feels, b_feels).
#
# IMPORTANT: This is the ONLY place relationship data lives.
# No system mirrors or caches relationship state.
# All reads go through Relationships.get_bond() etc.

extends Node

# ─────────────────────────────────────────────────────────────
# STORAGE
# pair_key → record Dictionary
# pair_key = "char_a_id:char_b_id" (lower ID first, always)
# ─────────────────────────────────────────────────────────────

var _records: Dictionary = {}


# ─────────────────────────────────────────────────────────────
# 15-TIER SPECTRUM
# Ordered from lowest to highest. Index = rank for comparisons.
# Romantic tiers (★) require an event-gated transition —
# bond score alone isn't enough to reach them.
# ─────────────────────────────────────────────────────────────

const TIER_ORDER: Array = [
	"MORTAL_ENEMY",       # 0   bond == -100
	"ENEMY",              # 1   -99 to -80
	"RIVAL",              # 2   -79 to -60
	"DISLIKED",           # 3   -59 to -40
	"UNFRIENDLY",         # 4   -39 to -20
	"COOL",               # 5   -19 to -10
	"NEUTRAL",            # 6   -9 to +9
	"ACQUAINTANCE",       # 7   +10 to +19
	"FRIENDLY",           # 8   +20 to +39
	"FRIEND",             # 9   +40 to +59
	"CLOSE_FRIEND",       # 10  +60 to +74
	"BEST_FRIEND",        # 11  +75 to +84
	"ROMANTIC_INTEREST",  # 12  +85 to +94  ★ event-gated
	"PARTNER",            # 13  +95 to +97  ★ event-gated
	"DEEPLY_BONDED",      # 14  +98 to +99
	"MARRIED",            # 15  +100        ★ event-gated
]

# Tiers that require a formalising event to unlock.
# Without the event, bond is capped at the platonic equivalent.
const EVENT_GATED_TIERS: Array = [
	"ROMANTIC_INTEREST", "PARTNER", "MARRIED",
]

# The highest tier reachable without an event gate.
const MAX_PLATONIC_TIER: String = "BEST_FRIEND"
const MAX_PLATONIC_BOND: float = 84.0

# Decay rates per day without interaction.
# Key = minimum tier rank (index in TIER_ORDER), value = daily decay.
# Checked from highest to lowest — first match wins.
const DECAY_RATES: Dictionary = {
	15: 0.0,    # MARRIED: no passive decay
	13: -0.05,  # PARTNER / DEEPLY_BONDED: very slow
	11: -0.08,  # BEST_FRIEND / ROMANTIC_INTEREST: slow
	9:  -0.1,   # FRIEND / CLOSE_FRIEND: normal
	0:  -0.15,  # everything below FRIEND: faster
}

# How many days between decay ticks (decay fires every N days)
const DECAY_INTERVAL_DAYS: int = 10


func _ready() -> void:
	Clock.day_ticked.connect(_on_day_ticked)
	print("[Relationships] Loaded. Listening to Clock.day_ticked.")


# ─────────────────────────────────────────────────────────────
# PAIR KEY + RECORD CREATION
# ─────────────────────────────────────────────────────────────

# Returns the canonical pair key — lower char_id always first.
func _pair_key(id_a: String, id_b: String) -> String:
	if id_a < id_b:
		return "%s:%s" % [id_a, id_b]
	return "%s:%s" % [id_b, id_a]


# Returns which side of the record this character is on.
# true = "a" side (first in pair key), false = "b" side.
func _is_a_side(id_a: String, id_b: String) -> bool:
	return id_a < id_b


# Lazily creates a record if one doesn't exist yet.
func _get_or_create(id_a: String, id_b: String) -> Dictionary:
	var key := _pair_key(id_a, id_b)
	if not _records.has(key):
		_records[key] = {
			"bond": 0.0,
			"trust": 0.0,
			"rivalry": 0.0,
			"familiarity": 0.0,
			"event_gated_tier": "",          # "", "ROMANTIC_INTEREST", "PARTNER", "MARRIED"
			"a_feels": {},                    # directional feelings from A's perspective
			"b_feels": {},                    # directional feelings from B's perspective
			"last_interaction_day": 0,        # day number of last bond/trust change
		}
	return _records[key]


# ─────────────────────────────────────────────────────────────
# BOND — bidirectional, -100 to +100
# ─────────────────────────────────────────────────────────────

func get_bond(id_a: String, id_b: String) -> float:
	var key := _pair_key(id_a, id_b)
	if not _records.has(key):
		return 0.0
	return _records[key]["bond"]


func modify_bond(id_a: String, id_b: String, delta: float) -> void:
	var record := _get_or_create(id_a, id_b)

	# LONER trait cap: bond can't exceed MAX_PLATONIC_BOND (84)
	# unless a 5% override roll succeeds.
	var char_a: CharData = Registry.get_character(id_a)
	var char_b: CharData = Registry.get_character(id_b)
	var loner_cap: bool = false
	if char_a and "LONER" in char_a.get_all_active_traits():
		loner_cap = true
	if char_b and "LONER" in char_b.get_all_active_traits():
		loner_cap = true

	record["bond"] = clampf(record["bond"] + delta, -100.0, 100.0)

	if loner_cap and record["bond"] > MAX_PLATONIC_BOND:
		# 5% chance to break through the cap
		if randf() > 0.05:
			record["bond"] = minf(record["bond"], MAX_PLATONIC_BOND)

	record["last_interaction_day"] = Clock.get_total_days()


func set_bond(id_a: String, id_b: String, value: float) -> void:
	var record := _get_or_create(id_a, id_b)
	record["bond"] = clampf(value, -100.0, 100.0)
	record["last_interaction_day"] = Clock.get_total_days()


# ─────────────────────────────────────────────────────────────
# TRUST — bidirectional, 0 to 100
# ─────────────────────────────────────────────────────────────

func get_trust(id_a: String, id_b: String) -> float:
	var key := _pair_key(id_a, id_b)
	if not _records.has(key):
		return 0.0
	return _records[key]["trust"]


func modify_trust(id_a: String, id_b: String, delta: float) -> void:
	var record := _get_or_create(id_a, id_b)
	record["trust"] = clampf(record["trust"] + delta, 0.0, 100.0)
	record["last_interaction_day"] = Clock.get_total_days()


# ─────────────────────────────────────────────────────────────
# RIVALRY — bidirectional, 0 to 100
# Can coexist with positive bond (frenemies).
# ─────────────────────────────────────────────────────────────

func get_rivalry(id_a: String, id_b: String) -> float:
	var key := _pair_key(id_a, id_b)
	if not _records.has(key):
		return 0.0
	return _records[key]["rivalry"]


func modify_rivalry(id_a: String, id_b: String, delta: float) -> void:
	var record := _get_or_create(id_a, id_b)
	record["rivalry"] = clampf(record["rivalry"] + delta, 0.0, 100.0)


# ─────────────────────────────────────────────────────────────
# FAMILIARITY — bidirectional, 0 to 100, NEVER DECAYS
# ─────────────────────────────────────────────────────────────

func get_familiarity(id_a: String, id_b: String) -> float:
	var key := _pair_key(id_a, id_b)
	if not _records.has(key):
		return 0.0
	return _records[key]["familiarity"]


func modify_familiarity(id_a: String, id_b: String, delta: float) -> void:
	var record := _get_or_create(id_a, id_b)
	# Familiarity only increases — clamp delta to >= 0
	if delta > 0.0:
		record["familiarity"] = clampf(record["familiarity"] + delta, 0.0, 100.0)


# ─────────────────────────────────────────────────────────────
# DIRECTIONAL FEELINGS
# Per-side feelings: attraction, jealousy, parental_bond, etc.
# Stored as { feeling_key: float } on a_feels / b_feels.
# ─────────────────────────────────────────────────────────────

# Get feelings FROM id_from's perspective ABOUT id_about.
func get_directional_feelings(id_from: String, id_about: String) -> Dictionary:
	var key := _pair_key(id_from, id_about)
	if not _records.has(key):
		return {}
	var side_key: String = "a_feels" if _is_a_side(id_from, id_about) else "b_feels"
	return _records[key][side_key]


# Set a single directional feeling value.
func set_directional_feeling(id_from: String, id_about: String,
		feeling_key: String, value: float) -> void:
	var record := _get_or_create(id_from, id_about)
	var side_key: String = "a_feels" if _is_a_side(id_from, id_about) else "b_feels"
	record[side_key][feeling_key] = value


# Check if id_from has a specific directional feeling about id_about.
func has_directional_feeling(id_from: String, id_about: String,
		feeling_key: String) -> bool:
	var feels := get_directional_feelings(id_from, id_about)
	return feels.has(feeling_key) and feels[feeling_key] > 0.0


# Remove a directional feeling.
func clear_directional_feeling(id_from: String, id_about: String,
		feeling_key: String) -> void:
	var key := _pair_key(id_from, id_about)
	if not _records.has(key):
		return
	var side_key: String = "a_feels" if _is_a_side(id_from, id_about) else "b_feels"
	_records[key][side_key].erase(feeling_key)


# ─────────────────────────────────────────────────────────────
# EVENT-GATED TIER TRANSITIONS
# Called by Actions when a formalising event succeeds.
# Only allows forward progression (can't gate backwards).
# ─────────────────────────────────────────────────────────────

func set_event_gated_tier(id_a: String, id_b: String, tier: String) -> void:
	if tier not in EVENT_GATED_TIERS:
		push_warning("[Relationships] '%s' is not an event-gated tier." % tier)
		return
	var record := _get_or_create(id_a, id_b)
	var current_rank: int = TIER_ORDER.find(record["event_gated_tier"])
	var new_rank: int = TIER_ORDER.find(tier)
	if new_rank > current_rank:
		record["event_gated_tier"] = tier
		if Settings.debug_console_logging:
			print("[Relationships] Event gate: %s ↔ %s → %s" % [id_a, id_b, tier])


func get_event_gated_tier(id_a: String, id_b: String) -> String:
	var key := _pair_key(id_a, id_b)
	if not _records.has(key):
		return ""
	return _records[key]["event_gated_tier"]


# ─────────────────────────────────────────────────────────────
# TIER CALCULATION
# Maps bond score → tier name, respecting event gates.
# ─────────────────────────────────────────────────────────────

func get_tier(id_a: String, id_b: String) -> String:
	var bond: float = get_bond(id_a, id_b)
	var raw_tier: String = _bond_to_tier(bond)

	# If the raw tier is event-gated, check if it's been unlocked
	if raw_tier in EVENT_GATED_TIERS:
		var gated: String = get_event_gated_tier(id_a, id_b)
		var gated_rank: int = TIER_ORDER.find(gated) if gated != "" else -1
		var raw_rank: int = TIER_ORDER.find(raw_tier)
		if gated_rank < raw_rank:
			# Not unlocked yet — cap at highest platonic tier
			return MAX_PLATONIC_TIER
	return raw_tier


# Pure bond-to-tier mapping (no event gate check).
func _bond_to_tier(bond: float) -> String:
	if bond <= -100.0:  return "MORTAL_ENEMY"
	if bond <= -80.0:   return "ENEMY"
	if bond <= -60.0:   return "RIVAL"
	if bond <= -40.0:   return "DISLIKED"
	if bond <= -20.0:   return "UNFRIENDLY"
	if bond <= -10.0:   return "COOL"
	if bond <= 9.0:     return "NEUTRAL"
	if bond <= 19.0:    return "ACQUAINTANCE"
	if bond <= 39.0:    return "FRIENDLY"
	if bond <= 59.0:    return "FRIEND"
	if bond <= 74.0:    return "CLOSE_FRIEND"
	if bond <= 84.0:    return "BEST_FRIEND"
	if bond <= 94.0:    return "ROMANTIC_INTEREST"
	if bond <= 97.0:    return "PARTNER"
	if bond <= 99.0:    return "DEEPLY_BONDED"
	return "MARRIED"


# Compare two tier names. Returns true if tier_a >= tier_b.
func tier_at_least(tier_a: String, tier_b: String) -> bool:
	return TIER_ORDER.find(tier_a) >= TIER_ORDER.find(tier_b)


# Compare two tier names. Returns true if tier_a <= tier_b.
func tier_at_most(tier_a: String, tier_b: String) -> bool:
	return TIER_ORDER.find(tier_a) <= TIER_ORDER.find(tier_b)


# ─────────────────────────────────────────────────────────────
# QUERY HELPERS
# ─────────────────────────────────────────────────────────────

# Returns all char_ids that have a relationship with this character
# at or above a given tier. Sorted by bond descending.
func get_all_above_tier(char_id: String, min_tier: String) -> Array:
	var result: Array = []
	for key in _records:
		var ids: PackedStringArray = key.split(":")
		var other_id: String = ""
		if ids[0] == char_id:
			other_id = ids[1]
		elif ids[1] == char_id:
			other_id = ids[0]
		else:
			continue
		if tier_at_least(get_tier(char_id, other_id), min_tier):
			result.append({"char_id": other_id, "bond": _records[key]["bond"]})
	result.sort_custom(func(a, b): return a["bond"] > b["bond"])
	return result


# Returns all char_ids that have a relationship at or below a given tier.
func get_all_below_tier(char_id: String, max_tier: String) -> Array:
	var result: Array = []
	for key in _records:
		var ids: PackedStringArray = key.split(":")
		var other_id: String = ""
		if ids[0] == char_id:
			other_id = ids[1]
		elif ids[1] == char_id:
			other_id = ids[0]
		else:
			continue
		if tier_at_most(get_tier(char_id, other_id), max_tier):
			result.append({"char_id": other_id, "bond": _records[key]["bond"]})
	result.sort_custom(func(a, b): return a["bond"] > b["bond"])
	return result


# Returns all relationships for a character. Array of { char_id, bond, tier }.
func get_all_for_character(char_id: String) -> Array:
	var result: Array = []
	for key in _records:
		var ids: PackedStringArray = key.split(":")
		var other_id: String = ""
		if ids[0] == char_id:
			other_id = ids[1]
		elif ids[1] == char_id:
			other_id = ids[0]
		else:
			continue
		result.append({
			"char_id": other_id,
			"bond": _records[key]["bond"],
			"trust": _records[key]["trust"],
			"rivalry": _records[key]["rivalry"],
			"familiarity": _records[key]["familiarity"],
			"tier": get_tier(char_id, other_id),
		})
	result.sort_custom(func(a, b): return a["bond"] > b["bond"])
	return result


# Returns true if this character is in PARTNER tier or above with anyone.
func is_partnered(char_id: String) -> bool:
	for key in _records:
		var ids: PackedStringArray = key.split(":")
		var other_id: String = ""
		if ids[0] == char_id:
			other_id = ids[1]
		elif ids[1] == char_id:
			other_id = ids[0]
		else:
			continue
		var tier: String = get_tier(char_id, other_id)
		if tier_at_least(tier, "PARTNER"):
			return true
	return false


# Returns true if a record exists (even if bond is 0).
func has_record(id_a: String, id_b: String) -> bool:
	return _records.has(_pair_key(id_a, id_b))


# ─────────────────────────────────────────────────────────────
# SEEDING (used by bootstrap for starting relationships)
# ─────────────────────────────────────────────────────────────

func seed_relationship(id_a: String, id_b: String, values: Dictionary) -> void:
	var record := _get_or_create(id_a, id_b)
	if values.has("bond"):
		record["bond"] = clampf(values["bond"], -100.0, 100.0)
	if values.has("trust"):
		record["trust"] = clampf(values["trust"], 0.0, 100.0)
	if values.has("rivalry"):
		record["rivalry"] = clampf(values["rivalry"], 0.0, 100.0)
	if values.has("familiarity"):
		record["familiarity"] = clampf(values["familiarity"], 0.0, 100.0)
	if values.has("event_gated_tier"):
		record["event_gated_tier"] = values["event_gated_tier"]
	record["last_interaction_day"] = Clock.get_total_days()
	if Settings.debug_console_logging:
		print("[Relationships] Seeded: %s ↔ %s → bond %.0f, tier %s" % [
			id_a, id_b, record["bond"], get_tier(id_a, id_b)
		])


# ─────────────────────────────────────────────────────────────
# BOND DECAY — connected to Clock.day_ticked
# ─────────────────────────────────────────────────────────────

func _on_day_ticked() -> void:
	# Only decay every DECAY_INTERVAL_DAYS days
	if Clock.get_total_days() % DECAY_INTERVAL_DAYS != 0:
		return

	for key in _records:
		var record: Dictionary = _records[key]
		var days_since: int = Clock.get_total_days() - record["last_interaction_day"]
		if days_since < DECAY_INTERVAL_DAYS:
			continue  # interacted recently, no decay

		# Find decay rate based on tier rank
		var tier_rank: int = TIER_ORDER.find(_bond_to_tier(record["bond"]))
		var decay: float = -0.15  # default fallback

		# Check from highest threshold downward
		var thresholds: Array = DECAY_RATES.keys()
		thresholds.sort()
		thresholds.reverse()
		for threshold in thresholds:
			if tier_rank >= threshold:
				decay = DECAY_RATES[threshold]
				break

		if decay != 0.0:
			# Decay bond toward 0 (not past it — don't make strangers into enemies)
			var old_bond: float = record["bond"]
			if old_bond > 0.0:
				record["bond"] = maxf(0.0, old_bond + decay)
			elif old_bond < 0.0:
				record["bond"] = minf(0.0, old_bond - decay)  # decay toward 0
		# Familiarity NEVER decays — intentionally skipped


# ─────────────────────────────────────────────────────────────
# GRIEF PROPAGATION
# Called when a character dies. Pushes grief feelings based on
# bond strength. Death events come in a later phase but the
# grief logic is ready now.
# ─────────────────────────────────────────────────────────────

func propagate_grief(deceased_id: String) -> void:
	for key in _records:
		var ids: PackedStringArray = key.split(":")
		var other_id: String = ""
		if ids[0] == deceased_id:
			other_id = ids[1]
		elif ids[1] == deceased_id:
			other_id = ids[0]
		else:
			continue

		var bond: float = _records[key]["bond"]
		var other: CharData = Registry.get_character(other_id)
		if not other or other is RobotData:
			continue

		if bond >= 70.0:
			FeelingDriver.push(other, "GRIEVING", {
				"event_key": "death_grief",
				"at_tick": Clock.get_total_days(),
				"summary": "deeply grieving %s" % deceased_id,
			})
		elif bond >= 50.0:
			FeelingDriver.push(other, "GRIEVING", {
				"event_key": "death_grief",
				"at_tick": Clock.get_total_days(),
				"summary": "grieving %s" % deceased_id,
			})
		elif bond >= 30.0:
			FeelingDriver.push(other, "MISERABLE", {
				"event_key": "death_sadness",
				"at_tick": Clock.get_total_days(),
				"summary": "saddened by %s's death" % deceased_id,
			})


# ─────────────────────────────────────────────────────────────
# DEBUG
# ─────────────────────────────────────────────────────────────

func get_record_count() -> int:
	return _records.size()


# Returns a debug-friendly summary for EventInspector.
func get_debug_lines(char_id: String) -> Array:
	var lines: Array = []
	var rels := get_all_for_character(char_id)
	if rels.is_empty():
		lines.append("  (no relationships)")
		return lines
	for rel in rels:
		var other: CharData = Registry.get_character(rel["char_id"])
		var name: String = other.char_name if other else rel["char_id"]
		lines.append("  %-16s  bond:%+.0f  trust:%.0f  riv:%.0f  fam:%.0f  [%s]" % [
			name, rel["bond"], rel["trust"], rel["rivalry"],
			rel["familiarity"], rel["tier"]
		])
		# Show directional feelings if any
		var d_feels := get_directional_feelings(char_id, rel["char_id"])
		if not d_feels.is_empty():
			var feel_str: String = ", ".join(d_feels.keys())
			lines.append("    → feels: %s" % feel_str)
	return lines