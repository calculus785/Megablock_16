# memory.gd
# Autoload — available globally as Memory
# Tier 2 Core — reads Tier 1
#
# The API for character memory. All storage lives ON CharData —
# this autoload provides read/write/prune logic.
#
# Four systems:
#   1. Short-term memory — 5 categories × 2 entries, newest pushes oldest out
#   2. Storybook — long-term event log, memorable entries flagged
#   3. Intent queue — pending actions in priority order
#   4. Object impressions — per-character scores for notable interactables
#
# Connected to Clock.day_ticked for daily pruning.

extends Node

# ── CONSTANTS ────────────────────────────────────────────────

const MAX_PER_CATEGORY: int = 2     # short-term slots per category
const PRUNE_AGE_DAYS: int = 2       # non-memorable entries older than this get pruned
const MEMORABLE_SOFT_CAP: int = 50  # memorable entry limit per character
const STORYBOOK_HARD_CAP: int = 500 # absolute max entries (safety net)

# Maps event categories (from events.gd) to short-term memory categories.
# Used by write_short_term_from_event() so Sim doesn't need to know the mapping.
const CATEGORY_TO_MEMORY: Dictionary = {
	"social":      "interaction",
	"romantic":    "interaction",
	"violence":    "interaction",
	"comedy":      "interaction",
	"family":      "interaction",
	"gang":        "interaction",
	"psychology":  "thought",
	"health":      "felt",
	"death":       "felt",
	"homeless":    "felt",
	"crime":       "action",
	"work":        "action",
	"building":    "observation",
	"management":  "observation",
	"object":      "observation",
	"seasonal":    "observation",
	"calendar":    "observation",
	"police":      "observation",
}

# Priority values for intent queue — higher number = fires first.
const PRIORITY_VALUES: Dictionary = {
	"critical": 40,
	"high":     30,
	"normal":   20,
	"low":      10,
}


func _ready() -> void:
	Clock.day_ticked.connect(_on_day_ticked)
	print("[Memory] Loaded. Listening to Clock.day_ticked.")


# ─────────────────────────────────────────────────────────────
# SHORT-TERM MEMORY
# 5 categories: thought, action, interaction, observation, felt
# Max 2 entries per category. Newest pushes oldest out.
#
# Entry shape:
#   { event_key: String, summary: String, target_id: String,
#     tone: String, at_tick: int }
# ─────────────────────────────────────────────────────────────

# Write a short-term memory entry into a specific category.
# If the category is full (2 entries), the oldest gets dropped.
func write_short_term(character: CharData, category: String, entry: Dictionary) -> void:
	if not character.short_term_memory.has(category):
		push_warning("[Memory] Unknown short-term category: %s" % category)
		return

	var bucket: Array = character.short_term_memory[category]
	bucket.append(entry)

	# Enforce cap — drop oldest (front of array) if over limit
	while bucket.size() > MAX_PER_CATEGORY:
		bucket.pop_front()


# Convenience: write short-term memory from an event, auto-mapping the category.
# Called by Sim after each event fires.
func write_short_term_from_event(character: CharData, event_key: String,
		event_def: Dictionary, summary: String, target_id: String) -> void:

	var event_category: String = event_def.get("category", "psychology")
	var memory_category: String = CATEGORY_TO_MEMORY.get(event_category, "action")
	var tone: String = _derive_tone(event_def)

	write_short_term(character, memory_category, {
		"event_key": event_key,
		"summary": summary,
		"target_id": target_id,
		"tone": tone,
		"at_tick": Clock.get_total_days(),
	})


# Read all entries in a short-term category. Returns an array (may be empty).
func read_short_term(character: CharData, category: String) -> Array:
	return character.short_term_memory.get(category, [])


# Read ALL short-term entries across all categories, flattened.
func read_all_short_term(character: CharData) -> Array:
	var result: Array = []
	for category in character.short_term_memory:
		result.append_array(character.short_term_memory[category])
	return result


# ─────────────────────────────────────────────────────────────
# STORYBOOK (long-term memory)
# All events write a storybook entry. Memorable ones are flagged.
# Sim calls write_storybook() instead of appending directly.
#
# Entry shape:
#   { event_key, summary, at_tick, target_id, magnitude,
#     memorable, memory_tags, times_recalled, last_recalled_day,
#     pinned_to_story }
# ─────────────────────────────────────────────────────────────

# Write a storybook entry. This is the ONLY place storybook gets appended to.
func write_storybook(character: CharData, entry: Dictionary) -> void:
	character.storybook.append(entry)


# Return the full storybook array (by reference — don't modify externally).
func get_storybook(character: CharData) -> Array:
	return character.storybook


# Return only entries flagged as memorable.
func get_memorable_entries(character: CharData) -> Array:
	var result: Array = []
	for entry in character.storybook:
		if entry.get("memorable", false):
			result.append(entry)
	return result


# Return memorable entries that involve a specific character.
func get_memories_about(character: CharData, target_id: String) -> Array:
	var result: Array = []
	for entry in character.storybook:
		if entry.get("memorable", false) and entry.get("target_id", "") == target_id:
			result.append(entry)
	return result


# Increment times_recalled and update last_recalled_day on a storybook entry.
# Called when THINK_ABOUT surfaces an old memory.
func recall_entry(character: CharData, entry_index: int) -> void:
	if entry_index < 0 or entry_index >= character.storybook.size():
		return
	character.storybook[entry_index]["times_recalled"] += 1
	character.storybook[entry_index]["last_recalled_day"] = Clock.get_total_days()


# Find a random memorable entry for THINK_ABOUT to surface.
# Returns the entry dict and its index, or null if none exist.
func pick_random_memorable(character: CharData):
	var memorable: Array = []
	for i in range(character.storybook.size()):
		if character.storybook[i].get("memorable", false):
			memorable.append(i)

	if memorable.is_empty():
		return null

	var idx: int = memorable[randi() % memorable.size()]
	return { "index": idx, "entry": character.storybook[idx] }


# ─────────────────────────────────────────────────────────────
# INTENT QUEUE
# Ordered list on CharData. Higher priority fires first.
# Patience counter decremented externally by Sim each tick.
#
# Entry shape:
#   { intent_key: String, priority: String, target_id: String,
#     patience: int, clearable: bool }
# ─────────────────────────────────────────────────────────────

# Add an intent, inserted in priority order (highest first).
func push_intent(character: CharData, intent: Dictionary) -> void:
	var new_priority: int = PRIORITY_VALUES.get(intent.get("priority", "normal"), 20)

	# Find insertion point — keep sorted by priority descending
	var insert_at: int = character.intent_queue.size()
	for i in range(character.intent_queue.size()):
		var existing_priority: int = PRIORITY_VALUES.get(
			character.intent_queue[i].get("priority", "normal"), 20
		)
		if new_priority > existing_priority:
			insert_at = i
			break

	character.intent_queue.insert(insert_at, intent)


# Return the top intent without removing it, or null if empty.
func peek_intent(character: CharData):
	if character.intent_queue.is_empty():
		return null
	return character.intent_queue[0]


# Remove and return the top intent, or null if empty.
func pop_intent(character: CharData):
	if character.intent_queue.is_empty():
		return null
	return character.intent_queue.pop_front()


# Remove all intents marked as clearable (e.g. fire alarm interrupts).
func clear_clearable_intents(character: CharData) -> void:
	var surviving: Array = []
	for intent in character.intent_queue:
		if not intent.get("clearable", true):
			surviving.append(intent)
	character.intent_queue = surviving


# Remove ALL intents regardless of clearable flag.
# Called when a character commits to a new destination (e.g. visiting bar
# wipes any old food intent from a previous cafe trip).
func clear_intents(character: CharData) -> void:
	character.intent_queue.clear()


# True if the character has any pending intents.
func has_intents(character: CharData) -> bool:
	return not character.intent_queue.is_empty()


# Decrement patience on all intents. Returns an array of expired intent_keys
# (patience hit 0) so Sim can fire GIVE_UP for each.
func tick_intents(character: CharData) -> Array:
	var expired: Array = []
	var surviving: Array = []

	for intent in character.intent_queue:
		intent["patience"] -= 1
		if intent["patience"] <= 0:
			expired.append(intent.get("intent_key", "unknown"))
		else:
			surviving.append(intent)

	character.intent_queue = surviving
	return expired


# ─────────────────────────────────────────────────────────────
# OBJECT IMPRESSIONS
# Per-character scores for notable interactables.
# Stored in CharData.object_impressions as { interactable_key: int }
# Two paths: passive (room arrival, interest-gated) and active (event use, ungated).
# ─────────────────────────────────────────────────────────────

# Called when a character enters a room. Checks notable objects in that room
# and gives a small passive bump for each one the character has interests in.
func tick_passive_impressions(character: CharData, room_id: String) -> void:
	# Extract room type from room_id (e.g. "bar_f1_s1" → "bar")
	var f_index: int = room_id.find("_f")
	var room_type: String
	if f_index > 0:
		room_type = room_id.substr(0, f_index)
	else:
		room_type = room_id

	var notables: Array = Interactables.get_notable_for_room(room_type)
	if notables.is_empty():
		return

	var char_interests: Array = character.interests

	for obj_key in notables:
		var interest_tags: Array = Interactables.get_interest_tags(obj_key)

		# Check if any of the character's interests match
		var has_match: bool = false
		for interest in char_interests:
			if interest in interest_tags:
				has_match = true
				break

		if not has_match:
			continue

		# 50% chance — not every visit registers consciously
		if randf() > 0.5:
			continue

		# Interest match — apply passive bump
		var def: Dictionary = Interactables.get_interactable(obj_key)
		var bump: int = def.get("passive_impression", 1)
		_add_impression(character, obj_key, bump)


# Called by action functions when a character directly interacts with an object.
# NOT interest-gated — if you used it, it left a mark.
func add_active_impression(character: CharData, interactable_key: String) -> void:
	var def: Dictionary = Interactables.get_interactable(interactable_key)
	var bump: int = def.get("active_impression", 5)
	_add_impression(character, interactable_key, bump)


# Core impression modifier. Positive = building attachment, negative = aversion.
func _add_impression(character: CharData, interactable_key: String, delta: int) -> void:
	var current: int = character.object_impressions.get(interactable_key, 0)
	var old_tier: String = Interactables.get_impression_tier(current)

	character.object_impressions[interactable_key] = current + delta

	var new_tier: String = Interactables.get_impression_tier(current + delta)

	# Log tier transitions
	if new_tier != old_tier and Settings.debug_console_logging:
		print("[Memory] %s → %s impression: %s (%d)" % [
			character.char_name, interactable_key, new_tier, current + delta
		])


# Read the current impression score for an object. Returns 0 if no impression.
func get_impression(character: CharData, interactable_key: String) -> int:
	return character.object_impressions.get(interactable_key, 0)


# Get the tier label for a character's impression of an object.
func get_impression_tier(character: CharData, interactable_key: String) -> String:
	var score: int = get_impression(character, interactable_key)
	return Interactables.get_impression_tier(score)


# ─────────────────────────────────────────────────────────────
# DAILY PRUNING
# Connected to Clock.day_ticked. Runs for every character.
#
# Rules:
#   1. Non-memorable entries older than PRUNE_AGE_DAYS get removed
#   2. Pinned entries (pinned_to_story) are never pruned
#   3. Memorable soft cap: if over 50, drop least-recalled
#   4. Hard cap: if storybook exceeds 500 entries, force-prune oldest
# ─────────────────────────────────────────────────────────────

func _on_day_ticked() -> void:
	for character in Registry.get_all():
		daily_prune(character)


func daily_prune(character: CharData) -> void:
	var today: int = Clock.get_total_days()
	var pruned_count: int = 0

	# Pass 1 — remove old non-memorable, non-pinned entries
	var kept: Array = []
	for entry in character.storybook:
		var is_pinned: bool = entry.get("pinned_to_story", false)
		var is_memorable: bool = entry.get("memorable", false)
		var age: int = today - entry.get("at_tick", today)

		if is_pinned:
			kept.append(entry)
		elif is_memorable:
			kept.append(entry)
		elif age <= PRUNE_AGE_DAYS:
			kept.append(entry)
		else:
			pruned_count += 1

	character.storybook = kept

	# Pass 2 — enforce memorable soft cap
	var memorable_entries: Array = []
	for i in range(character.storybook.size()):
		var entry: Dictionary = character.storybook[i]
		if entry.get("memorable", false) and not entry.get("pinned_to_story", false):
			memorable_entries.append({ "index": i, "recalled": entry.get("times_recalled", 0) })

	if memorable_entries.size() > MEMORABLE_SOFT_CAP:
		# Sort by times_recalled ascending — least recalled first
		memorable_entries.sort_custom(func(a, b): return a["recalled"] < b["recalled"])
		var to_remove: int = memorable_entries.size() - MEMORABLE_SOFT_CAP
		var remove_indices: Array = []
		for j in range(to_remove):
			remove_indices.append(memorable_entries[j]["index"])

		# Remove in reverse order so indices stay valid
		remove_indices.sort()
		remove_indices.reverse()
		for idx in remove_indices:
			character.storybook.remove_at(idx)
			pruned_count += to_remove

	# Pass 3 — hard cap safety net
	if character.storybook.size() > STORYBOOK_HARD_CAP:
		var overflow: int = character.storybook.size() - STORYBOOK_HARD_CAP
		var removed: int = 0
		var final: Array = []
		for entry in character.storybook:
			if removed < overflow and not entry.get("pinned_to_story", false):
				removed += 1
			else:
				final.append(entry)
		character.storybook = final

	if pruned_count > 0 and Settings.debug_console_logging:
		print("[Memory] Pruned %d entries from %s's storybook." % [
			pruned_count, character.char_name
		])


# ─────────────────────────────────────────────────────────────
# HELPERS
# ─────────────────────────────────────────────────────────────

# Derives a simple tone from event outcomes.
# Looks at happiness and stress deltas — net positive = "positive", etc.
func _derive_tone(event_def: Dictionary) -> String:
	var outcomes: Dictionary = event_def.get("outcomes", {})
	var stats: Dictionary = outcomes.get("stats", {})
	var happiness: float = stats.get("happiness", 0.0)
	var stress: float = stats.get("stress", 0.0)

	var net: float = happiness - stress
	if net > 0.0:
		return "positive"
	elif net < 0.0:
		return "negative"
	return "neutral"