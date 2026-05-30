# bootstrap.gd
# Attached to main.tscn root node.
# Phase 3: builds the building, spawns characters with visual bodies.

extends Node3D

# Container for character body nodes
var _char_bodies: Dictionary = {}   # char_id → Node3D

# Apartment IDs from the prototype building layout (6 total)
const APARTMENT_IDS: Array = [
	"apartment_f3_s0",
	"apartment_f3_s1",
	"apartment_f3_s2",
	"apartment_f1_s1",
	"apartment_f2_s1",
	"apartment_f4_s0",
	"apartment_f5_s0",
]

const BESPOKE_CONFIGS: Array = [
	{
		"char_name": "Sara Vega",
		"pronouns": "she/her",
		"preference": "she/her",
		"favourite_color": "electric_blue",
		"hair_colour": "unusual",
		"life_arch": "romance",
		"traits": ["FLIRTATIOUS", "CHARMING", "OPTIMISTIC"],
		"hidden_traits": ["JEALOUS_TYPE"],
		"interests": ["music", "nightlife", "fashion"],
		"internal_age": 24.0,
	},
	{
		"char_name": "Marcus Webb",
		"pronouns": "he/him",
		"preference": "any",
		"favourite_color": "black",
		"hair_colour": "dark",
		"life_arch": "crime",
		"traits": ["CRIMINAL_HEART", "MANIPULATIVE", "STUBBORN"],
		"hidden_traits": ["VIOLENT"],
		"interests": ["gambling", "people_watching"],
		"internal_age": 31.0,
	},
	{
		"char_name": "Kai Lindqvist",
		"pronouns": "they/them",
		"preference": "any",
		"favourite_color": "purple",
		"hair_colour": "unusual",
		"life_arch": "wildcard",
		"traits": ["NOSY", "GOSSIP", "FUNNY"],
		"hidden_traits": ["ADDICT_PRONE"],
		"interests": ["gossip", "social_media", "people_watching"],
		"internal_age": 22.0,
	},
	{
		"char_name": "Priya Nair",
		"pronouns": "she/her",
		"preference": "she/her",
		"favourite_color": "deep_green",
		"hair_colour": "dark",
		"life_arch": "neutral",
		"traits": ["BOOKWORM", "MOTIVATED", "RECLUSIVE"],
		"hidden_traits": ["PARANOID"],
		"interests": ["reading", "history", "people_watching"],
		"internal_age": 29.0,
	},
]


func _ready() -> void:
	# Step 1: Build the building (registers all rooms in Rooms autoload)
	_setup_building()

	# Step 2: Spawn characters into their apartments
	_spawn_characters()

	# Step 3: Create visual bodies
	_create_character_bodies()

	print("[Bootstrap] Done. %d characters, %d rooms." % [
		Registry.get_count(),
		Rooms.get_all_room_ids().size(),
	])
	_print_character_summary()


func _setup_building() -> void:
	# Load and instance the building script on a new Node2D
	var building := Node3D.new()
	building.name = "Building"
	building.set_script(load("res://scripts/world/building.gd"))
	add_child(building)  # triggers building._ready() → floors + rooms registered


func _spawn_characters() -> void:
	print("\n[Bootstrap] Spawning characters...")

	# Bespoke characters → first 3 apartments
	for i in BESPOKE_CONFIGS.size():
		var config: Dictionary = BESPOKE_CONFIGS[i].duplicate()
		config["home_room"] = APARTMENT_IDS[i]
		config["current_room"] = APARTMENT_IDS[i]
		config["apartment_id"] = APARTMENT_IDS[i]
		config["stats"] = Stats.get_default_stats()
		Registry.generate_bespoke_character(config)

	# Random characters → remaining apartments
	for i in range(BESPOKE_CONFIGS.size(), APARTMENT_IDS.size()):
		Registry.generate_random_character(APARTMENT_IDS[i])
	# After all characters are spawned:
	var building = get_node_or_null("/root/main/Building")
	if building:
		building.update_apartment_labels()


func _create_character_bodies() -> void:
	# Container node keeps characters grouped in the scene tree
	var container := Node3D.new()
	container.name = "Characters"
	# Add to Building so characters render in world space with floors
	$Building.add_child(container)

	var body_script = load("res://scripts/world/character_body.gd")

	for character in Registry.get_all():
		var body := Node3D.new()
		body.set_script(body_script)
		body.char_data = character
		body.name = "Char_%s" % character.char_id
		container.add_child(body)  # triggers body._ready() → builds visuals + snaps to room

		_char_bodies[character.char_id] = body

		# Register occupant in Rooms autoload
		Rooms.add_occupant(character.current_room, character.char_id)


func _print_character_summary() -> void:
	print("\n── CHARACTER SUMMARY ──────────────────────────")
	for character in Registry.get_all():
		print("  %s | age %.0f | room: %s" % [
			character.get_debug_label(),
			character.internal_age,
			character.current_room,
		])
	print("───────────────────────────────────────────────\n")
