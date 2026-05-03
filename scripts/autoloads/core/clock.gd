# clock.gd
# Autoload — available globally as Clock
# Tier 2 Core — reads Tier 1 (Settings for sim_speed, paused)
#
# The game's heartbeat. Advances in-game time, emits signals
# that drive the entire simulation.
#
# Time system:
#   Tick          = 6.25 real seconds (at 1x speed)
#   Half-hour     = 3 ticks = 18.75 real seconds
#   Hour          = 6 ticks = 37.5 real seconds
#   Day           = 24 hours = 144 ticks = 15 real minutes
#   Week          = 5 days (Day 5 = Restday)
#   Month         = 3 weeks = 15 days
#   Year          = 6 months = 90 days
#   Lifespan      = 40 years = 3600 days ≈ 900 real hours
#
# Calendar:
#   Months numbered 1-6. No names (bleak, dystopian).
#   Display: "Month 3 · Week 2 · Day 4 — Year 47"
#
# Seasons (by month):
#   Month 1: summer, Month 2: summer, Month 3: neutral
#   Month 4: winter, Month 5: winter, Month 6: neutral
#   Intensity peaks at day 8 of each 15-day month (midpoint).

extends Node

# ── SIGNALS ──────────────────────────────────────────────────
# Connect to these from other autoloads.
# Example: Clock.tick.connect(_on_tick)

signal tick                     # every sim tick (3x per half-hour)
signal half_hour_ticked         # every in-game half-hour
signal hour_ticked              # every in-game hour
signal day_ticked               # every in-game day
signal week_ticked              # every in-game week (Day 5 → Day 1)
signal month_ticked             # every in-game month
signal year_ticked              # every in-game year
signal season_changed(new_season: String)  # when season transitions

# ── TIME CONSTANTS ───────────────────────────────────────────
const BASE_TICK_INTERVAL: float = 6.25  # real seconds at 1x speed
const TICKS_PER_HALF_HOUR: int = 3
const HALF_HOURS_PER_HOUR: int = 2
const HOURS_PER_DAY: int = 24
const DAYS_PER_WEEK: int = 5
const WEEKS_PER_MONTH: int = 3
const MONTHS_PER_YEAR: int = 6

# Derived
const TICKS_PER_HOUR: int = TICKS_PER_HALF_HOUR * HALF_HOURS_PER_HOUR          # 6
const TICKS_PER_DAY: int = TICKS_PER_HOUR * HOURS_PER_DAY                      # 144
const DAYS_PER_MONTH: int = DAYS_PER_WEEK * WEEKS_PER_MONTH                    # 15
const DAYS_PER_YEAR: int = DAYS_PER_MONTH * MONTHS_PER_YEAR                    # 90

# ── SEASON MAP ───────────────────────────────────────────────
# 1 = first month of season pair (intensity rising)
# 2 = second month of season pair (intensity falling)
# 0 = neutral (no intensity)
const SEASON_MONTH_POSITION: Dictionary = {
	1: 1, 2: 2,   # summer pair
	3: 0,          # neutral
	4: 1, 5: 2,   # winter pair
	6: 0,          # neutral
}
const SEASON_BY_MONTH: Dictionary = {
	1: "summer", 2: "summer", 3: "neutral",
	4: "winter", 5: "winter", 6: "neutral",
}

# ── CURRENT TIME STATE ───────────────────────────────────────
var current_tick: int = 0       # tick within current hour (0 to TICKS_PER_HOUR-1)
var current_hour: int = 8       # start at 8am
var current_day: int = 1        # 1-5 within week
var current_week: int = 1       # 1-3 within month
var current_month: int = 1      # 1-6
var current_year: int = 1

var current_season: String = "summer"
var season_intensity: float = 0.0   # 0.0 to 7.0 — peaks at mid-month

# Internal tick counter (tracks half-hour subdivisions)
var _tick_in_half_hour: int = 0
var _timer: Timer


func _ready() -> void:
	# Create and configure the heartbeat timer
	_timer = Timer.new()
	_timer.wait_time = BASE_TICK_INTERVAL
	_timer.autostart = false
	_timer.one_shot = false
	_timer.timeout.connect(_on_tick)
	add_child(_timer)

	_update_season()
	_timer.start()

	print("[Clock] Loaded. Starting at Hour %d, Day %d, Month %d, Year %d — %s (intensity %.1f)" % [
		current_hour, _absolute_day_in_month(), current_month, current_year,
		current_season, season_intensity
	])


func _on_tick() -> void:
	# Respect pause and sim speed
	if Settings.paused:
		return
	_timer.wait_time = BASE_TICK_INTERVAL / maxf(Settings.sim_speed, 0.1)

	# Emit the base tick — Sim listens to this
	tick.emit()

	# Track ticks within the current half-hour
	_tick_in_half_hour += 1

	if _tick_in_half_hour >= TICKS_PER_HALF_HOUR:
		_tick_in_half_hour = 0
		_advance_half_hour()


func _advance_half_hour() -> void:
	half_hour_ticked.emit()

	current_tick += TICKS_PER_HALF_HOUR

	# Check if we've completed a full hour
	if current_tick >= TICKS_PER_HOUR:
		current_tick = 0
		_advance_hour()


func _advance_hour() -> void:
	current_hour += 1
	hour_ticked.emit()

	if current_hour >= HOURS_PER_DAY:
		current_hour = 0
		_advance_day()


func _advance_day() -> void:
	current_day += 1
	day_ticked.emit()

	if Settings.debug_console_logging:
		print("[Clock] Day %d, Week %d, Month %d, Year %d — %s" % [
			_absolute_day_in_month(), current_week, current_month, current_year, current_season
		])

	if current_day > DAYS_PER_WEEK:
		current_day = 1
		_advance_week()

	_update_season_intensity()


func _advance_week() -> void:
	current_week += 1
	week_ticked.emit()

	if current_week > WEEKS_PER_MONTH:
		current_week = 1
		_advance_month()


func _advance_month() -> void:
	var old_season: String = current_season
	current_month += 1
	month_ticked.emit()

	if current_month > MONTHS_PER_YEAR:
		current_month = 1
		_advance_year()

	_update_season()
	if current_season != old_season:
		season_changed.emit(current_season)


func _advance_year() -> void:
	current_year += 1
	year_ticked.emit()
	if Settings.debug_console_logging:
		print("[Clock] ═══ YEAR %d ═══" % current_year)


# ── SEASON LOGIC ─────────────────────────────────────────────

func _update_season() -> void:
	current_season = SEASON_BY_MONTH.get(current_month, "neutral")
	_update_season_intensity()


func _update_season_intensity() -> void:
	var position: int = SEASON_MONTH_POSITION.get(current_month, 0)

	# Neutral months have no intensity
	if position == 0:
		season_intensity = 0.0
		return

	var day: int = _absolute_day_in_month() % DAYS_PER_MONTH
	if day == 0:
		day = DAYS_PER_MONTH

	# Position 1 (first month): intensity rises from ~0 to 7.0
	# Position 2 (second month): intensity falls from 7.0 to ~0
	if position == 1:
		season_intensity = (float(day) / float(DAYS_PER_MONTH)) * 7.0
	else:
		season_intensity = (float(DAYS_PER_MONTH - day + 1) / float(DAYS_PER_MONTH)) * 7.0


# ── CONVENIENCE GETTERS ──────────────────────────────────────

# Day within the month (1-15), combining week + day
func _absolute_day_in_month() -> int:
	return (current_week - 1) * DAYS_PER_WEEK + current_day

# Absolute day count since start of game
func get_total_days() -> int:
	return (current_year - 1) * DAYS_PER_YEAR \
		+ (current_month - 1) * DAYS_PER_MONTH \
		+ _absolute_day_in_month()

# Time of day bucket — used by event requirements
func get_time_of_day() -> String:
	if current_hour >= 5 and current_hour < 12:
		return "morning"
	elif current_hour >= 12 and current_hour < 17:
		return "day"
	elif current_hour >= 17 and current_hour < 22:
		return "evening"
	else:
		return "night"

# True on Restday (Day 5 of week)
func is_restday() -> bool:
	return current_day == DAYS_PER_WEEK

# Formatted display string for UI
func get_display_string() -> String:
	return "Month %d · Week %d · Day %d — Year %d" % [
		current_month, current_week, current_day, current_year
	]
