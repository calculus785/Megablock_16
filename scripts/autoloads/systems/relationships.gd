# relationships.gd
# Autoload — available globally as Relationships
# Tier 3 Systems — reads Tier 1 + 2
#
# Pairwise relationship records between characters.
# Full implementation in Phase 4.
# Shell provides correct API so event conditions can call us without errors.

extends Node

# pair_key → RelationshipRecord
# pair_key = "char_a_id:char_b_id" (always lower ID first for consistency)
var _records: Dictionary = {}


func _ready() -> void:
	print("[Relationships] Loaded. (shell — Phase 4)")


# Returns the pair key — always alphabetically sorted so A:B == B:A
func _pair_key(id_a: String, id_b: String) -> String:
	if id_a < id_b:
		return "%s:%s" % [id_a, id_b]
	return "%s:%s" % [id_b, id_a]


# Returns bond score (-100 to 100). 0 if no record exists.
func get_bond(id_a: String, id_b: String) -> float:
	var key := _pair_key(id_a, id_b)
	if not _records.has(key):
		return 0.0
	return _records[key].get("bond", 0.0)

func get_familiarity(id_a: String, id_b: String) -> float:
	var key := _pair_key(id_a, id_b)
	if not _records.has(key):
		return 0.0
	return _records[key].get("familiarity", 0.0)

func get_tier(id_a: String, id_b: String) -> String:
	# Full tier calculation in Phase 4. Stub returns NEUTRAL for now.
	return "NEUTRAL"

func modify_bond(id_a: String, id_b: String, delta: float) -> void:
	push_warning("[Relationships] modify_bond() not yet implemented.")

func has_record(id_a: String, id_b: String) -> bool:
	return _records.has(_pair_key(id_a, id_b))