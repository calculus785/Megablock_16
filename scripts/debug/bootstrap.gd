# bootstrap.gd
# Attached to main.tscn root node.
# Spawns test characters on startup so Phase 0 is testable.
# Remove or gate behind a debug flag before Phase 1 ships.

extends Node2D

const TEST_ROOMS: Array = [
	"apartment_f1_s1", "apartment_f1_s2", "apartment_f1_s3",
	"apartment_f2_s1", "apartment_f2_s2", "apartment_f2_s3",
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
]


func _ready() -> void:
	print("\n[Bootstrap] Spawning test characters...")

	# Bespoke characters — generate_bespoke_character handles trait modifiers internally
	for i in BESPOKE_CONFIGS.size():
		var config: Dictionary = BESPOKE_CONFIGS[i].duplicate()
		config["home_room"] = TEST_ROOMS[i]
		config["current_room"] = TEST_ROOMS[i]
		config["apartment_id"] = TEST_ROOMS[i]
		config["stats"] = Stats.get_default_stats()
		Registry.generate_bespoke_character(config)

	# Random characters for remaining slots
	for i in range(3, TEST_ROOMS.size()):
		Registry.generate_random_character(TEST_ROOMS[i])

	# Testing: put everyone in the same room so social events fire
	# Remove this when movement is real (Phase 3)
	for character in Registry.get_all():
		character.current_room = "bar_f1_s1"

	print("[Bootstrap] Done. %d characters in registry." % Registry.get_count())
	_print_character_summary()



func _print_character_summary() -> void:
	print("\n── CHARACTER SUMMARY ──────────────────────────")
	for character in Registry.get_all():
		print("  %s | age %.0f | arch: %s" % [
			character.get_debug_label(),
			character.internal_age,
			character.life_arch,
		])
		print("    traits:  %s" % str(character.traits))
		print("    hidden:  %s" % str(character.hidden_traits))
		print("    stress:%.0f  happy:%.0f  energy:%.0f  cash:%.0f" % [
			character.stats.get("stress", 0),
			character.stats.get("happiness", 0),
			character.stats.get("energy", 0),
			character.stats.get("cash", 0),
		])
	print("───────────────────────────────────────────────\n")
