# memory.gd
# Autoload — available globally as Memory
# Tier 2 Core — reads Tier 1
#
# Reads and writes to character memory (stored on CharData).
# Short-term: 5 categories × 2 entries.
# Long-term: flagged storybook entries with times_recalled counter.
# Intent queue: ordered list of pending actions.
#
# Memory lives ON CharData — this autoload provides the API,
# not the storage. Full implementation in Phase 2.

extends Node


func _ready() -> void:
	print("[Memory] Loaded. (shell — Phase 2)")


# ── SHORT-TERM MEMORY ────────────────────────────────────────
# 5 categories: thought, action, interaction, observation, felt
# Max 2 entries per category. Newest pushes oldest out.

func write_short_term(character, category: String, entry: Dictionary) -> void:
	push_warning("[Memory] write_short_term() not yet implemented.")

func read_short_term(character, category: String) -> Array:
	push_warning("[Memory] read_short_term() not yet implemented.")
	return []


# ── STORYBOOK (long-term) ────────────────────────────────────
# All events write a storybook entry. Memorable ones get flagged.
# times_recalled increments when think_about surfaces them.

func write_storybook(character, entry: Dictionary) -> void:
	push_warning("[Memory] write_storybook() not yet implemented.")

func get_storybook(character) -> Array:
	push_warning("[Memory] get_storybook() not yet implemented.")
	return []

func get_memorable_entries(character) -> Array:
	push_warning("[Memory] get_memorable_entries() not yet implemented.")
	return []

func recall_entry(character, entry_index: int) -> void:
	# Increments times_recalled, updates last_recalled_day
	push_warning("[Memory] recall_entry() not yet implemented.")


# ── INTENT QUEUE ─────────────────────────────────────────────
# Ordered list on CharData. Priority: critical > high > normal > low
# Patience counter decrements each tick — at 0, GIVE_UP fires.

func push_intent(character, intent: Dictionary) -> void:
	push_warning("[Memory] push_intent() not yet implemented.")

func peek_intent(character):
	# Returns the top intent without removing it, or null
	push_warning("[Memory] peek_intent() not yet implemented.")
	return null

func pop_intent(character):
	# Removes and returns the top intent, or null
	push_warning("[Memory] pop_intent() not yet implemented.")
	return null

func clear_clearable_intents(character) -> void:
	# Flush all clearable intents (e.g. fire alarm interrupts)
	push_warning("[Memory] clear_clearable_intents() not yet implemented.")

func has_intents(character) -> bool:
	push_warning("[Memory] has_intents() not yet implemented.")
	return false


# ── DAILY PRUNING (stub) ─────────────────────────────────────
# Connected to Clock.day_ticked. Prunes non-memorable entries,
# enforces 40-year rolling cap, 50 memorable entry soft cap.

func daily_prune(character) -> void:
	push_warning("[Memory] daily_prune() not yet implemented.")