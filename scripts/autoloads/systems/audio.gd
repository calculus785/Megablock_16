# audio.gd
# Autoload — available globally as Audio
# Tier 3 Systems — stub, implemented Phase 3
# Positional playback, ambience, stings.

extends Node


func _ready() -> void:
	print("[Audio] Loaded. (stub — Phase 3)")


func play_sfx(_sound_key: String, _position: Vector2 = Vector2.ZERO) -> void:
	pass

func play_ambience(_room_id: String) -> void:
	pass

func stop_ambience() -> void:
	pass

func play_sting(_sting_key: String) -> void:
	pass