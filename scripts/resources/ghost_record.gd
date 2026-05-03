# ghost_record.gd
# Resource class — GhostRecord
# Archived snapshot of a CharData on death.
# Kept in Registry._ghosts so memory references (storybook, relationships)
# don't point to null. Lightweight — only what's needed for display.
# Full CharData is discarded. GhostRecord persists forever in the save.

class_name GhostRecord
extends Resource

@export var char_id: String = ""
@export var char_name: String = ""
@export var pronouns: String = "they/them"
@export var favourite_color: String = "white"
@export var hair_colour: String = "dark"
@export var life_stage: String = "Adult"
@export var internal_age_at_death: float = 0.0

# Cause of death key — used by grief events and storybook templates
# e.g. "natural", "accident", "illness", "violence", "overdose", "starvation"
@export var death_cause: String = ""
@export var death_day: int = 0              # Clock.get_total_days() at time of death

# Snapshot of visible traits for bio display and memory context
@export var traits_at_death: Array[String] = []

# The apartment this character lived in — passed to inheritance system
@export var apartment_id: String = ""

# Relationships at death — char_id → bond score snapshot for inheritance order
@export var bond_snapshot: Dictionary = {}


static func from_char_data(character: CharData, cause: String, day: int) -> GhostRecord:
	# Factory — call this on death to create the archive from a live CharData.
	var ghost := GhostRecord.new()
	ghost.char_id = character.char_id
	ghost.char_name = character.char_name
	ghost.pronouns = character.pronouns
	ghost.favourite_color = character.favourite_color
	ghost.hair_colour = character.hair_colour
	ghost.life_stage = character.life_stage
	ghost.internal_age_at_death = character.internal_age
	ghost.death_cause = cause
	ghost.death_day = day
	ghost.traits_at_death = character.traits.duplicate()
	ghost.apartment_id = character.apartment_id
	return ghost


func get_debug_label() -> String:
	return "%s [DECEASED — %s, day %d]" % [char_name, death_cause, death_day]
