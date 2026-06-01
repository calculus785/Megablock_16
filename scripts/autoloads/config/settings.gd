# settings.gd
# Autoload — available globally as Settings
# Tier 1 Config — loaded FIRST, no dependencies
#
# Reads/writes player preferences to user://settings.cfg
# This is Godot's user data folder — persists between runs,
# separate from the project folder. On Windows it's usually:
# %APPDATA%/Godot/app_userdata/MegaBlock16/

extends Node
var speed_preset: int = 1
 
const SPEED_PRESETS: Array = [0.0, 1.0, 3.0, 10.0, 30.0]
const SPEED_NAMES: Array = [
	"⏸ PAUSED", "▶ PLAY", "⏩ FAST (3x)", "⏩⏩ TURBO (10x)", "🚀 ULTRA (30x)"
]

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
	set_speed(1)  # start at 1x play speed

func set_speed(preset_index: int) -> void:
	speed_preset = clampi(preset_index, 0, SPEED_PRESETS.size() - 1)
	Engine.time_scale = SPEED_PRESETS[speed_preset]
	if debug_console_logging:
		print("[Settings] Speed: %s" % SPEED_NAMES[speed_preset])

# --- Save to disk ---
func save_settings() -> void:
	var config := ConfigFile.new()

	config.set_value("game", "speed_preset", speed_preset)

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

	speed_preset = config.get_value("game", "speed_preset", 1)

	fullscreen = config.get_value("display", "fullscreen", fullscreen)
	resolution_scale = config.get_value("display", "resolution_scale", resolution_scale)

	master_volume = config.get_value("audio", "master_volume", master_volume)
	music_volume = config.get_value("audio", "music_volume", music_volume)
	sfx_volume = config.get_value("audio", "sfx_volume", sfx_volume)
	ambience_volume = config.get_value("audio", "ambience_volume", ambience_volume)

	debug_overlay_enabled = config.get_value("debug", "overlay_enabled", debug_overlay_enabled)
	debug_console_logging = config.get_value("debug", "console_logging", debug_console_logging)