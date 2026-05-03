# robot_data.gd
# Resource class — RobotData extends CharData
# Robots are pipeline-compatible characters with near-zero inner life.
# They can witness events, be insulted, be damaged — but have no feelings,
# no traits, no relationships, no storybook.
# faction_memberships always contains "robots".
# Events use exclude_robots: true to filter them out of romance/gossip/etc.

class_name RobotData
extends CharData

# Robot-specific identity
@export var robot_model: String = ""       # "STRATA_DRONE", "BARTENDER_BOT", etc.
@export var job_role: String = ""          # what this robot does
@export var is_decommissioned: bool = false


func _init() -> void:
	# Override CharData defaults for robots
	faction_memberships = ["robots"]

	# Robots only track health — other stats unused
	stats = { "health": 100.0 }

	# No inner life
	feelings = []
	traits = []
	hidden_traits = []
	starter_traits = []
	states = []
	storybook = []
	intent_queue = []
	object_impressions = {}
	faction_sentiment = {}


# Robots are always actionable unless decommissioned or broken
func is_actionable() -> bool:
	if is_decommissioned:
		return false
	if stats.get("health", 100) <= 0:
		return false
	if "IN_VR_POD" in persistent_states:
		return false
	return true


# Robots have no traits — always returns []
func get_all_active_traits() -> Array:
	return []


func get_debug_label() -> String:
	return "%s [ROBOT — %s]" % [char_name, robot_model]