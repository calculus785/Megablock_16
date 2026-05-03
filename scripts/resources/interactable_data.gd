# interactable_data.gd
# Resource class — InteractableData
# Runtime instance of an interactable object placed in a room.
# Type definition (tags, aura, interactions) lives in Interactables autoload.
# This resource tracks: where it is, what state it's in, who owns/uses it.

class_name InteractableData
extends Resource

# ── IDENTITY ─────────────────────────────────────────────────
@export var instance_id: String = ""       # unique, e.g. "pool_table_bar_f2_s1_0"
@export var interactable_key: String = ""  # key in Interactables.INTERACTABLES

# ── LOCATION ─────────────────────────────────────────────────
@export var current_room: String = ""      # room_id
@export var spot_id: String = ""           # spot within room zone

# ── OWNERSHIP ────────────────────────────────────────────────
# "building" / "communal" / "personal" — matches Interactables config default.
# Changes on theft (personal items only).
@export var ownership: String = "communal"
@export var owner_id: String = ""          # char_id if personal, "" otherwise

# ── STATE ────────────────────────────────────────────────────
@export var is_broken: bool = false
@export var is_dirty: bool = false

# Who is currently using this interactable (one user at a time for most items).
@export var is_occupied: bool = false
@export var occupied_by: String = ""       # char_id or ""

# Arbitrary state tags for unusual conditions.
# e.g. ["SPILLED", "ON_FIRE", "FULL_DIAPER"]
@export var state_tags: Array[String] = []


# ── HELPERS ──────────────────────────────────────────────────

# Pull the type definition from the config autoload.
func get_definition() -> Dictionary:
	return Interactables.get_interactable(interactable_key)

func get_label() -> String:
	return get_definition().get("label", interactable_key)

func has_tag(tag: String) -> bool:
	return Interactables.has_tag(interactable_key, tag)

func has_interaction(interaction: String) -> bool:
	if is_broken and interaction != "repair":
		return false
	return Interactables.has_interaction(interactable_key, interaction)

func has_aura() -> bool:
	return not is_broken and Interactables.has_aura(interactable_key)

func is_available() -> bool:
	return not is_broken and not is_occupied

func occupy(char_id: String) -> void:
	is_occupied = true
	occupied_by = char_id

func vacate() -> void:
	is_occupied = false
	occupied_by = ""

func break_it() -> void:
	is_broken = true
	vacate()

func get_debug_label() -> String:
	var status: String = "OK"
	if is_broken:
		status = "BROKEN"
	elif is_occupied:
		status = "IN USE by %s" % occupied_by
	return "%s [%s — %s]" % [get_label(), current_room, status]