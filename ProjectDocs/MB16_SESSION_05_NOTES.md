# MB16 Session 05 Notes
**Date:** May 2026
**Type:** Dev session
**Phase:** Phase 1 complete, Phase 2 complete

---

## Summary
Completed all remaining Phase 1 tasks and all Phase 2 tasks in one session.
No architectural changes — all work was additive.

---

## Phase 1 Tasks Completed

### 1. Context autoload — full implementation
**File:** `res://scripts/autoloads/systems/context.gd`

Replaced the shell with full implementation:
- `build_frame()` now injects pronoun variables for actor and target
- Room IDs prettified via `ROOM_DISPLAY_NAMES` (e.g. "bar_f1_s1" → "the bar")
- Verb conjugation helpers handle they/them plurality correctly

**Template variables now available:**

| Variable | Example (she/her) | Example (they/them) |
|---|---|---|
| `{name}` | Sara Vega | Kai Lindqvist |
| `{they}` | she | they |
| `{them}` | her | them |
| `{their}` | her | their |
| `{theirs}` | hers | theirs |
| `{themself}` | herself | themself |
| `{They}` | She | They |
| `{s}` | s | (empty) |
| `{es}` | es | (empty) |
| `{have_has}` | has | have |
| `{are_is}` | is | are |
| `{were_was}` | was | were |

Target variants use `target_` prefix: `{target_they}`, `{target_them}`, etc.
Capitalised variants: `{They}`, `{Target_they}`, etc.

**Usage examples:**
```gdscript
# Pronoun-aware templates
"{name} couldn't keep {their} eyes open any longer."
"{They} {were_was} the last one standing."
"{name} caught {themself} smiling. {target}. That was why."
"{name} watch{es} the door."
"{name} {are_is} tired."

# Target pronouns
"{name} told {target} something. {Target_they} didn't respond."
```

**Notes:**
- Old templates using hardcoded "their/them" still work — {name}, {target}, {room} unchanged
- "someone" fallback for unknown targets defaults to they/them pronouns
- `_pretty_room()` splits on `_f` to extract room type prefix

---

### 2. ForceEvent panel (F3)
**Files:** 
- `res://scripts/ui/force_event.gd` (new)
- `res://scenes/debug/force_event.tscn` (new — minimal CanvasLayer scene)
- `res://scripts/autoloads/simulation/sim.gd` (added `force_fire_event()`)

**Setup required (editor):**
- Create scene: CanvasLayer root named "ForceEvent", attach script, save to `res://scenes/debug/force_event.tscn`
- Add to main scene as sibling of EventInspector
- Register input action: Project Settings → Input Map → `ui_force_event_toggle` → F3

**How it works:**
- Dropdowns populated on panel open (always fresh)
- Auto-fire events marked with ⚡ suffix in event list
- Fires via `Sim.force_fire_event()` — skips eligibility and cooldown
- Result line shows storybook text after firing
- Panel sits at x=770 to avoid overlapping EventInspector (x=0)

**`force_fire_event()` on sim.gd:**
- Runs full pipeline: RESOLVE → FRAME → ACT → EXECUTE → ECHO
- Skips cooldown — forced events don't block normal firing
- Logs with 🔧 prefix
- Returns storybook summary string

**Pending enhancement (flagged for later):**
- Add target/context picker — currently fires with auto-resolved target only

---

### 3. EventInspector upgrades (F2)
**File:** `res://scripts/ui/event_inspector.gd`

Added two new sections:

**ELIGIBLE EVENTS section:**
- Shows all rolled events that pass requirements for selected character
- Displays final weight after all modifiers applied
- Shows `[CD]` tag for events on cooldown
- Shows percentage chance for non-cooldown events (weight / total weight)
- Backed by `Sim.get_eligible_with_weights()` — reuses `_check_requirements()` and `_apply_weight_modifiers()`

**LAST 5 EVENTS section:**
- Last 5 storybook entries for selected character
- Magnitude tag: [M]inor, [M]oderate, [H]uge
- Updates live on every `event_fired` signal

---

## Phase 2 Tasks Completed

### 4. Memory autoload — full implementation
**File:** `res://scripts/autoloads/core/memory.gd`

**Architecture principle:** Memory owns all storybook writes. Sim calls `Memory.write_storybook()` instead of appending directly. This centralises storage logic.

**Three systems implemented:**

**Short-term memory:**
- 5 categories: thought, action, interaction, observation, felt
- Max 2 entries per category — oldest pushed out
- `write_short_term_from_event()` auto-maps event category to memory category
- Called automatically from `Sim._echo()` after every event
- Entry shape: `{ event_key, summary, target_id, tone, at_tick }`

**Category mapping:**
| Event category | Memory category |
|---|---|
| social, romantic, violence, comedy, family, gang | interaction |
| psychology | thought |
| health, death, homeless | felt |
| crime, work | action |
| building, management, object, seasonal, calendar, police | observation |

**Storybook API:**
- `write_storybook(character, entry)` — the ONLY place storybook gets appended
- `get_storybook(character)` — returns full array
- `get_memorable_entries(character)` — returns entries with `memorable: true`
- `get_memories_about(character, target_id)` — memorable entries involving specific char
- `recall_entry(character, index)` — increments `times_recalled`, updates `last_recalled_day`
- `pick_random_memorable(character)` — returns `{ index, entry }` or null

**Notable:** `memorable` flag is now set for `moderate`, `major`, and `huge` magnitude events (was only major/huge — fixed mid-session so memory events fire properly).

**Daily pruning (connected to Clock.day_ticked):**
- Non-memorable entries older than 2 days pruned
- Pinned entries (`pinned_to_story: true`) never pruned
- Memorable soft cap: 50 entries — least recalled dropped first
- Hard cap: 500 entries absolute safety net

**Constants:**
```gdscript
MAX_PER_CATEGORY: int = 2
PRUNE_AGE_DAYS: int = 2
MEMORABLE_SOFT_CAP: int = 50
STORYBOOK_HARD_CAP: int = 500
```

---

### 5. Intent queue — full implementation
**File:** `res://scripts/autoloads/core/memory.gd`

**Priority values:**
```gdscript
PRIORITY_VALUES: Dictionary = {
    "critical": 40, "high": 30, "normal": 20, "low": 10,
}
```

**API:**
- `push_intent(character, intent)` — inserts in priority order
- `peek_intent(character)` — top intent without removing
- `pop_intent(character)` — removes and returns top intent
- `tick_intents(character)` — decrements patience, returns array of expired intent_keys
- `clear_clearable_intents(character)` — flushes clearable intents (fire alarms etc)
- `has_intents(character)` — bool check

**Intent shape:**
```gdscript
{
    "intent_key": "ORDER_DRINK",  # event key to fire
    "priority": "normal",          # critical/high/normal/low
    "target_id": "",               # specific target char_id, or ""
    "patience": 15,                # ticks before GIVE_UP
    "clearable": true,             # false = survives interrupts
}
```

**Pipeline integration (sim.gd `_on_tick()`):**
1. `Memory.tick_intents()` — decrement patience, get expired keys
2. `_fire_give_up()` for each expired intent
3. `_try_fire_intent()` — fire top intent if requirements met, else fall through
4. Normal pipeline (auto-fire → roll)

**Intent firing (`_try_fire_intent()`):**
- Checks requirements — if not met, leaves intent in queue
- If met, pops intent and runs full pipeline
- Supports specific `target_id` override
- Logs with 📋 prefix

**GIVE_UP behaviour:**
- Writes storybook entry
- +5 stress always
- SHORT_TEMPERED → also pushes FRUSTRATED feeling
- STUBBORN → additional +8 stress
- Logs with ❌ prefix

**Actions that push intents:**
| Action | Intent pushed | Default patience | Trait modifiers |
|---|---|---|---|
| `queue_intent_visit_bar` | ORDER_DRINK | 15 | STUBBORN+10, LAZY-5, ALCOHOLIC+15 |
| `queue_intent_visit_library` | READ_BOOK | 12 | STUBBORN+8, LAZY-5 |
| `queue_intent_visit_cafe` | ORDER_FOOD | 12 | STUBBORN+8, LAZY-5, BIG_APPETITE+5 |

---

### 6. THINK_ABOUT — real memory targets
**Files:** `context.gd`, `actions.gd`, `events.gd`, `sim.gd`

**Changes:**
- `THINK_ABOUT` now requires `has_memorable_entries: true`
- `has_memorable_entries` check added to `sim.gd _check_requirements()`
- Context `"memory"` target resolution now calls `Memory.pick_random_memorable()` and returns the involved CharData
- If no target_id on memory entry, falls back to "someone"
- `_think_about()` in actions.gd reads memory tone and applies stat effects:
  - Positive memory → happiness +5, loneliness -5
  - Negative memory → stress +5, happiness -3
  - Neutral → boredom -5
- `recall_entry()` called on every surface

---

### 7. New memory-aware events
Three new events added to `events.gd`:

**BROOD** — stressed characters fixate on a bad memory, making things worse. Requires `has_memorable_entries`, stress > 40. `target_resolution: memory`.

**SMILE_AT_MEMORY** — happy characters surface a good memory. Requires `has_memorable_entries`, happiness > 40. Uses `{themself}` pronoun template correctly.

**REMINISCE_TOGETHER** — two characters talk about something from the past. Evening/night only. Requires `has_memorable_entries`. Social event with loneliness relief.

---

### 8. Object impressions
**Files:** `interactables.gd`, `memory.gd`, `actions.gd`, `event_inspector.gd`

**Design:**
- Only objects flagged `notable: true` participate
- Two accumulation paths: passive (room arrival) and active (event use)
- Passive is interest-gated with 50% random roll
- Active bypasses interest gate — if you used it, it left a mark
- Both paths log tier transitions to console

**Notable objects and their settings:**
| Object | Interest tags | Passive bump | Active bump |
|---|---|---|---|
| pool_table | sports, gambling, card_games | 1 | 5 |
| bar_counter | nightlife, people_watching | 1 | 3 |
| bookshelf | books, history, philosophy | 1 | 4 |
| statue | art, history | 2 | 6 |

**Impression tiers:**
| Score | Tier |
|---|---|
| 0-9 | Unaware |
| 10-29 | Noticed |
| 30-59 | Familiar |
| 60-99 | Attached |
| 100+ | Connected |

**Room → notable objects mapping (in interactables.gd):**
```gdscript
ROOM_NOTABLE_OBJECTS: Dictionary = {
    "bar":     ["bar_counter", "pool_table"],
    "cafe":    [],
    "library": ["bookshelf"],
    "hallway": ["statue"],
}
```

**Active impression wiring:**
- `_order_drink()` → bar_counter +3
- `_drink_alone()` → bar_counter +3
- `_play_pool_round()` → pool_table +5 (both players) — fires at beat 1, not on invite
- `_read_book()` → bookshelf +4
- `_study_together()` → bookshelf +4

**Memory API:**
- `tick_passive_impressions(character, room_id)` — called from `_wander()` on room change
- `add_active_impression(character, interactable_key)` — called from action functions
- `get_impression(character, interactable_key)` → int score
- `get_impression_tier(character, interactable_key)` → tier string

**EventInspector:** Added IMPRESSIONS section showing all impression scores and tiers, sorted alphabetically.

---

### 9. EventInspector final state
**Sections (top to bottom):**
1. Header (character name, index, arch, room)
2. Stats (two columns)
3. Traits (visible + hidden)
4. Feelings (with causes)
5. States (derived + persistent)
6. Intent queue (key, priority, patience, clearable flag)
7. Short-term memory (tone tag, category, summary)
8. Impressions (object key, score, tier)
9. Eligible events (weight, %, cooldown tag)
10. Last 5 storybook entries (magnitude tag, summary)
11. Clock

---

## Bugs Fixed
- `clear_clearable_intents()` — replaced lambda filter with explicit loop (GDScript scope bug)
- `memorable` threshold — changed from `major/huge` to `moderate/major/huge` so memory events fire naturally
- Memory autoload path not registered in Project Settings — manual fix required

## Known Issues (carry forward)
- ORDER_FOOD GIVE_UP spam — expected, characters push cafe intent but can't reach it (no movement). Patience could be reduced or accept as noise until Phase 3
- ForceEvent panel needs target/context picker (flagged for future)

## Files Modified This Session
- `res://scripts/autoloads/systems/context.gd` — full implementation
- `res://scripts/autoloads/core/memory.gd` — full implementation
- `res://scripts/autoloads/simulation/sim.gd` — force_fire_event, get_eligible_with_weights, intent pipeline, has_memorable_entries check
- `res://scripts/autoloads/config/events.gd` — THINK_ABOUT requirement update, BROOD/SMILE_AT_MEMORY/REMINISCE_TOGETHER added
- `res://scripts/autoloads/config/interactables.gd` — notable flag, interest_tags, impression weights, ROOM_NOTABLE_OBJECTS, helpers
- `res://scripts/autoloads/systems/actions.gd` — think_about real implementation, queue_intent functions wired, active impression calls, passive tick on wander
- `res://scripts/ui/event_inspector.gd` — intent queue, short-term memory, impressions sections added
- `res://scripts/ui/force_event.gd` — new file
- `res://scenes/debug/force_event.tscn` — new scene

## Git
Commit after this session.

---

## Phase 2 Status: COMPLETE ✅
All roadmap criteria met.

## Next: Phase 3 — Movement & Pathfinding
Characters move between rooms. Real room occupancy. Pathfinder implementation.
Intent queue will drive movement naturally (VISIT_BAR pushes movement intent before ORDER_DRINK).