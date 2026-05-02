# interactables.gd
# Autoload — available globally as Interactables
# Tier 1 Config — pure data, no dependencies
#
# Defines every interactable type in the game.
# At runtime, instances are spawned in rooms via Rooms autoload.
# Each instance has a state dictionary (broken, dirty, occupancy, etc.)
# but the type definition (tags, aura, ownership rules) lives here.
#
# Fields:
#   label             — UI display name
#   tags              — used by event requirements (room_has_interactable etc.)
#   interaction_tags  — which actions characters can perform on this
#   ownership         — "building" | "communal" | "personal"
#   material          — drives breaking outcomes ("wood", "glass", "metal", "fabric")
#   two_handed        — true = occupies both held_item slots when held
#   carryable         — false = fixed in place (pool table, bed)
#   aura_effects      — passive stat drift on characters in same room (per-hour)
#                       Empty {} = no aura, room aura ticking skips this
#   aura_personality_match — interest tags that boost the aura for matching chars

extends Node


const INTERACTABLES: Dictionary = {

# ── BAR ──────────────────────────────────────────────────────
"bar_counter": {
	"label": "Bar Counter",
	"tags": ["bar_furniture", "service_point"],
	"interaction_tags": ["order_drink", "lean_against", "pass_drink"],
	"ownership": "building",
	"material": "wood",
	"two_handed": false,
	"carryable": false,
	"aura_effects": {},
	"aura_personality_match": [],
},
"pool_table": {
	"label": "Pool Table",
	"tags": ["bar_furniture", "game", "social_focus"],
	"interaction_tags": ["play_pool", "lean_against", "watch"],
	"ownership": "communal",
	"material": "wood",
	"two_handed": false,
	"carryable": false,
	"aura_effects": { "boredom": -1 },
	"aura_personality_match": ["sports", "card_games"],
},

# ── CAFE ─────────────────────────────────────────────────────
"coffee_machine": {
	"label": "Coffee Machine",
	"tags": ["cafe_equipment", "service_point"],
	"interaction_tags": ["order_coffee", "operate", "clean"],
	"ownership": "building",
	"material": "metal",
	"two_handed": false,
	"carryable": false,
	"aura_effects": {},
	"aura_personality_match": [],
},

# ── LIBRARY ──────────────────────────────────────────────────
"bookshelf": {
	"label": "Bookshelf",
	"tags": ["library_furniture", "knowledge"],
	"interaction_tags": ["browse", "borrow_book", "shelve"],
	"ownership": "building",
	"material": "wood",
	"two_handed": false,
	"carryable": false,
	"aura_effects": { "boredom": -1, "stress": -1 },
	"aura_personality_match": ["books", "history", "philosophy"],
},

# ── COMMON / DECOR ───────────────────────────────────────────
"statue": {
	"label": "Statue",
	"tags": ["decor", "landmark"],
	"interaction_tags": ["admire", "vandalise"],
	"ownership": "building",
	"material": "stone",
	"two_handed": false,
	"carryable": false,
	"aura_effects": { "happiness": 1 },
	"aura_personality_match": ["art", "history"],
},

# ── APARTMENT ────────────────────────────────────────────────
"bed": {
	"label": "Bed",
	"tags": ["apartment_furniture", "rest_point"],
	"interaction_tags": ["sleep", "lie_down"],
	"ownership": "personal",
	"material": "fabric",
	"two_handed": false,
	"carryable": false,
	"aura_effects": {},
	"aura_personality_match": [],
},
"shelf": {
	"label": "Shelf",
	"tags": ["apartment_furniture", "storage"],
	"interaction_tags": ["place_item", "retrieve_item"],
	"ownership": "personal",
	"material": "wood",
	"two_handed": false,
	"carryable": false,
	"aura_effects": {},
	"aura_personality_match": [],
},
"decoration_spot": {
	"label": "Decoration Spot",
	"tags": ["apartment_furniture", "decoratable"],
	"interaction_tags": ["place_decoration", "remove_decoration"],
	"ownership": "personal",
	"material": "wood",
	"two_handed": false,
	"carryable": false,
	"aura_effects": {},
	"aura_personality_match": [],
},

# ── BREAKABLE ITEMS (carryable) ──────────────────────────────
"whisky_glass": {
	"label": "Whisky Glass",
	"tags": ["drinkware", "fragile"],
	"interaction_tags": ["drink_from", "throw", "set_down"],
	"ownership": "communal",
	"material": "glass",
	"two_handed": false,
	"carryable": true,
	"aura_effects": {},
	"aura_personality_match": [],
},
}


func _ready() -> void:
	print("[Interactables] Loaded. %d interactable types defined." % INTERACTABLES.size())


# ─────────────────────────────────────────────────────────────
# HELPERS
# ─────────────────────────────────────────────────────────────

func is_valid(interactable_key: String) -> bool:
	return INTERACTABLES.has(interactable_key)

func get_interactable(interactable_key: String) -> Dictionary:
	return INTERACTABLES.get(interactable_key, {})

func has_tag(interactable_key: String, tag: String) -> bool:
	if not INTERACTABLES.has(interactable_key):
		return false
	return tag in INTERACTABLES[interactable_key]["tags"]

func has_interaction(interactable_key: String, interaction: String) -> bool:
	if not INTERACTABLES.has(interactable_key):
		return false
	return interaction in INTERACTABLES[interactable_key]["interaction_tags"]

# True if this interactable would emit an aura. Rooms uses this to skip
# aura-less items during room ticking — saves loops at scale.
func has_aura(interactable_key: String) -> bool:
	if not INTERACTABLES.has(interactable_key):
		return false
	return not INTERACTABLES[interactable_key]["aura_effects"].is_empty()