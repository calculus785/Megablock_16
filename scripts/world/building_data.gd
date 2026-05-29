# building_data.gd
# Pure layout data. No pixel coordinates — positions come from Marker2D
# nodes placed visually in each floor scene.

class_name BuildingData

const FLOOR_WIDTH: int = 2048
const FLOOR_HEIGHT: int = 512



# ─── FLOOR TYPE DEFINITIONS ──────────────────────────────────
# scene_path: the PackedScene for this floor type
# slots: maps each room slot to Marker2D node paths within the scene
#   spawn_node: where a character stands when "in" the room
#   door_node:  where a character stands to enter/exit
#   room_size:  for future SubViewport sizing

const FLOOR_TYPES: Dictionary = {
	"apartments": {
		"scene_path": "res://scenes/world/FloorApartments.tscn",
		"slots": [
			{
				"door_node": "Spots/Room0_Door",
				"origin_node": "Spots/Room0_Origin",
				"room_size": "apartment",
				"room_scene": "res://scenes/rooms/room_apartment.tscn",
				"doorway_node": "Spots/Room0_Doorway",
			},
			{
				"door_node": "Spots/Room1_Door",
				"origin_node": "Spots/Room1_Origin",
				"room_size": "apartment",
				"room_scene": "res://scenes/rooms/room_apartment.tscn",
				"doorway_node": "Spots/Room1_Doorway",
			},
			{
				"door_node": "Spots/Room2_Door",
				"origin_node": "Spots/Room2_Origin",
				"room_size": "apartment",
				"room_scene": "res://scenes/rooms/room_apartment.tscn",
				"doorway_node": "Spots/Room2_Doorway",
			},
		],
	},
	"large_common": {
		"scene_path": "res://scenes/world/FloorLargeCommon.tscn",
		"slots": [
			{
				"door_node": "Spots/Room0_Door",
				"origin_node": "Spots/Room0_Origin",
				"room_size": "large_common",
				"room_scene": "res://scenes/rooms/room_large_common.tscn",
				"doorway_node": "Spots/Room0_Doorway",
			},
			{
				"door_node": "Spots/Room1_Door",
				"origin_node": "Spots/Room1_Origin",
				"room_size": "apartment",
				"room_scene": "res://scenes/rooms/room_apartment.tscn",
				"doorway_node": "Spots/Room1_Doorway",
			},
		],
	},
	"small_common": {
		"scene_path": "res://scenes/world/FloorSmallCommon.tscn",
		"slots": [
			{
				"door_node": "Spots/Room0_Door",
				"origin_node": "Spots/Room0_Origin",
				"room_size": "apartment",
				"room_scene": "res://scenes/rooms/room_apartment.tscn",
				"doorway_node": "Spots/Room0_Doorway",
			},
			{
				"door_node": "Spots/Room1_Door",
				"origin_node": "Spots/Room1_Origin",
				"room_size": "small_common",
				"room_scene": "res://scenes/rooms/room_small_common.tscn",
				"doorway_node": "Spots/Room1_Doorway",
			},
		],
	},
	# Replace the single "large_common" entry with two specific ones:

	"large_common_bar": {
		"scene_path": "res://scenes/world/FloorLargeCommon.tscn",
		"slots": [
			{
				"door_node": "Spots/Room0_Door",
				"origin_node": "Spots/Room0_Origin",
				"room_size": "large_common",
				"room_scene": "res://scenes/rooms/room_bar.tscn",  # ← bar scene
				"doorway_node": "Spots/Room0_Doorway",
			},
			{
				"door_node": "Spots/Room1_Door",
				"origin_node": "Spots/Room1_Origin",
				"room_size": "apartment",
				"room_scene": "res://scenes/rooms/room_apartment.tscn",
				"doorway_node": "Spots/Room1_Doorway",
			},
		],
	},

	"large_common_grocery": {
		"scene_path": "res://scenes/world/FloorLargeCommon.tscn",
		"slots": [
			{
				"door_node": "Spots/Room0_Door",
				"origin_node": "Spots/Room0_Origin",
				"room_size": "large_common",
				"room_scene": "res://scenes/rooms/room_grocery.tscn",  # ← grocery scene
				"doorway_node": "Spots/Room0_Doorway",
			},
			{
				"door_node": "Spots/Room1_Door",
				"origin_node": "Spots/Room1_Origin",
				"room_size": "apartment",
				"room_scene": "res://scenes/rooms/room_apartment.tscn",
				"doorway_node": "Spots/Room1_Doorway",
			},
		],
	},
}


# ─── BUILDING LAYOUT ─────────────────────────────────────────
# Ordered bottom (index 0) to top. Matches your 5 prototype floors.

const FLOORS: Array = [
	{
		"floor_id": "F00",
		"floor_type": "apartments",
		"rooms": [
			{ "room_id": "lobby_f0_s0", "type": "lobby", "slot": 0 },
			{ "room_id": "lobby_f0_s1", "type": "lobby", "slot": 1 },
			{ "room_id": "lobby_f0_s2", "type": "lobby", "slot": 2 },
		],
	},
	{
		"floor_id": "F01",
		"floor_type": "large_common_bar",
		"rooms": [
			{ "room_id": "bar_f1_s0", "type": "bar", "slot": 0 },
			{ "room_id": "apartment_f1_s1", "type": "apartment", "slot": 1 },
		],
	},
	{
		"floor_id": "F02",
		"floor_type": "large_common",
		"rooms": [
			{ "room_id": "grocery_f2_s0", "type": "grocery", "slot": 0 },
			{ "room_id": "apartment_f2_s1", "type": "apartment", "slot": 1 },
		],
	},
	{
		"floor_id": "F03",
		"floor_type": "apartments",
		"rooms": [
			{ "room_id": "apartment_f3_s0", "type": "apartment", "slot": 0 },
			{ "room_id": "apartment_f3_s1", "type": "apartment", "slot": 1 },
			{ "room_id": "apartment_f3_s2", "type": "apartment", "slot": 2 },
		],
	},
	{
		"floor_id": "F04",
		"floor_type": "small_common",
		"rooms": [
			{ "room_id": "apartment_f4_s0", "type": "apartment", "slot": 0 },
			{ "room_id": "cafe_f4_s1", "type": "cafe", "slot": 1 },
		],
	},
]


# ─── HELPERS ─────────────────────────────────────────────────

# World Y of a floor's top edge. F00 at bottom, top floor at y=0.
static func get_floor_y(floor_index: int) -> float:
	return float((FLOORS.size() - 1 - floor_index) * FLOOR_HEIGHT)