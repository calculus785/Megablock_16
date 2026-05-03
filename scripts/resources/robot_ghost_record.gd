# robot_ghost_record.gd
# Resource class — RobotGhostRecord
# Ultra-lightweight archive of a RobotData on decommission.
# Exists purely so storybook entries referencing this robot
# don't point to null. Stores almost nothing.

class_name RobotGhostRecord
extends Resource

@export var char_id: String = ""
@export var char_name: String = ""
@export var robot_model: String = ""
@export var job_role: String = ""
@export var decommission_day: int = 0


static func from_robot_data(robot: RobotData, day: int) -> RobotGhostRecord:
	var ghost := RobotGhostRecord.new()
	ghost.char_id = robot.char_id
	ghost.char_name = robot.char_name
	ghost.robot_model = robot.robot_model
	ghost.job_role = robot.job_role
	ghost.decommission_day = day
	return ghost