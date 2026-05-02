# settings.gd
# Autoload — available globally as Settings
# Tier 1 Config — loaded FIRST, no dependencies
#
# Reads/writes player preferences to user://settings.cfg
# This is Godot's user data folder — persists between runs,
# separate from the project folder. On Windows it's usually:
# %APPDATA%/Godot/app_userdata/MegaBlock16/

extends Node

# --- Game speed ---
var sim_speed: float = 1.0       # 1.0 = normal, 2.0 = double, etc.
var paused: bool = false

# --- Display ---
var fullscreen: bool = false
var resolution_scale: float = 1.0

# --- Audio ---
var master_volume: float = 1.0
var music_volume: float = 0.8
var sfx_volume: float = 1.0
var ambience_volume: float = 0.7

# --- Debug ---
var debug_overlay_enabled: bool = true   # F2 EventInspector
var debug_console_logging: bool = true   # print() spam in Output

# Path to the config file on disk
const CONFIG_PATH: String = "user://settings.cfg"


func _ready() -> void:
	_load_settings()
	print("[Settings] Loaded.")


# --- Save to disk ---
func save_settings() -> void:
	var config := ConfigFile.new()

	config.set_value("game", "sim_speed", sim_speed)
	config.set_value("game", "paused", paused)

	config.set_value("display", "fullscreen", fullscreen)
	config.set_value("display", "resolution_scale", resolution_scale)

	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("audio", "ambience_volume", ambience_volume)

	config.set_value("debug", "overlay_enabled", debug_overlay_enabled)
	config.set_value("debug", "console_logging", debug_console_logging)

	config.save(CONFIG_PATH)


# --- Load from disk ---
func _load_settings() -> void:
	var config := ConfigFile.new()
	var err := config.load(CONFIG_PATH)

	# If no config file exists yet, that's fine — we use the defaults above
	if err != OK:
		return

	sim_speed = config.get_value("game", "sim_speed", sim_speed)
	paused = config.get_value("game", "paused", paused)

	fullscreen = config.get_value("display", "fullscreen", fullscreen)
	resolution_scale = config.get_value("display", "resolution_scale", resolution_scale)

	master_volume = config.get_value("audio", "master_volume", master_volume)
	music_volume = config.get_value("audio", "music_volume", music_volume)
	sfx_volume = config.get_value("audio", "sfx_volume", sfx_volume)
	ambience_volume = config.get_value("audio", "ambience_volume", ambience_volume)

	debug_overlay_enabled = config.get_value("debug", "overlay_enabled", debug_overlay_enabled)
	debug_console_logging = config.get_value("debug", "console_logging", debug_console_logging)