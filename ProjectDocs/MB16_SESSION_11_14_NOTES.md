# MB16 Sessions 11–14 Notes
Session type: Dev session
Phase: Phase 4 — Relationships & Social Drama
Status: Phase 4 substantially complete. Three items deferred (noted below).

---

## Overview

This block of sessions built the entire relationships layer from scratch and carried it
through to working emergent storytelling. By end of session 14, organic romantic arcs,
apology chains, social drama, and trait evolution were all firing without intervention.

Notable moment: Cyrus Adisa asked Riona Tanaka out on Day 3, was accepted, and both
entered ROMANTIC_INTEREST tier. Priya Nair asked Riona out on the same day, was rejected,
and gained HEARTBROKEN — completely unscripted.

---

## Session 11 — Relationships Data Layer

### relationships.gd — Full implementation

New autoload replacing the stub. Pairwise records indexed by ID pair for O(1) lookup.

**RelationshipRecord fields:**
- `bond` — -100 to +100, drives tier calculation
- `trust` — 0 to 100, affects apology/confession acceptance
- `rivalry` — 0 to 100, persists independently of bond
- `familiarity` — 0 to 100, never decays

**Directional feelings** (stored per direction A→B and B→A):
- FLIRTY, AFFECTIONATE, BITTER, RESENTFUL, INFATUATED

**15-tier spectrum** (bond score → tier name):
- MORTAL_ENEMY → ENEMY → HOSTILE → RIVAL → COLD → NEUTRAL → ACQUAINTANCE
- FRIENDLY → FRIEND → CLOSE_FRIEND → BEST_FRIEND
- (event-gated): ROMANTIC_INTEREST → PARTNER → DEEPLY_BONDED → MARRIED

**Bond decay:** fires on `Clock.day_ticked`. Rate varies by tier. Familiarity never decays.
LONER trait caps bond gain at 84 (BEST_FRIEND tier) with 5% override.

**API added:**
```
get_bond / get_trust / get_rivalry / get_familiarity
modify_bond / modify_trust / modify_rivalry / modify_familiarity
get_tier / get_all_above_tier / get_all_below_tier / get_all_for_character
set_event_gated_tier / is_partnered
set_directional_feeling / has_directional_feeling / clear_directional_feeling
get_debug_lines  (for EventInspector)
propagate_grief  (ready for when death events arrive)
```

**Seeding API:** `seed_relationship()` called from `bootstrap.gd` to set starting bonds.
5 starting relationships seeded (Sara↔Marcus, Sara↔Kai, Sara↔Priya, Kai↔Marcus, Priya↔Kai).

### sim.gd — Relationship requirement keys

Added to `_check_requirements()`:
- `relationship_bond_above` / `relationship_bond_below`
- `relationship_tier_at_least` / `relationship_tier_at_most`
- `relationship_familiarity_above`
- `is_partnered` / `compatible_sexuality` / `no_existing_relationship`

Added to `_apply_outcomes()`: reads `"relationship"` dict from event outcomes and applies
bond/trust/rivalry/familiarity deltas.

Bond change console format: `[Sim] 💛 name ↔ name: bond +X, fam +Y (→Z TIER)`

### context.gd — resolve_target upgrade

`resolve_target()` "character" case upgraded with relationship-aware filtering.
New `_filter_by_relationship()` helper. Supports:
- `exclude_robots`
- `highest_affection` — targets character with highest bond
- `lowest_affection` — targets character with lowest bond

### event_inspector.gd — RELATIONSHIPS section

Added RELATIONSHIPS debug section showing bond/trust/rivalry/familiarity/tier per relationship.

---

## Session 12 — Event Wiring + THINK_ABOUT Upgrade

### Relationship outcomes wired to existing events

14 events given `"relationship"` outcome dicts:
- CHAT: bond +3, fam +2
- COMPLIMENT: bond +4, fam +1
- GREET: bond +2, fam +2
- HALLWAY_CHAT: bond +2, fam +1
- BRIEF_CONVERSATION: bond +3, fam +2
- INSULT: bond -6, trust -3, rivalry +3
- ARGUE: bond -8, trust -5, rivalry +5
- PHYSICAL_FIGHT: bond -15, trust -10, rivalry +10
- DEEP_CONVERSATION: bond +10, trust +8, fam +5
- SHARE_MEAL: bond +4, trust +2, fam +2
- STUDY_TOGETHER: bond +3, trust +2, fam +2
- QUIET_MOMENT_TOGETHER: bond +2, trust +1, fam +1
- GOSSIP: bond +2, fam +2
- REMINISCE_TOGETHER: bond +5, trust +3, fam +3
- SPILL_DRINK: fam +1 (shared awkwardness)

### _think_about() upgraded — bond-aware emotional coloring

- Bond ≥30 + positive memory → happiness boost + AFFECTIONATE directional feeling + CONTENT_FEELING pushed
- Bond ≤-20 → stress increase + BITTER directional feeling
- Rivalry ≥20 → stress increase + RESENTFUL directional feeling
- No relationship context → tone-based fallback (original logic)

---

## Session 13 — Romantic Chain + New Social Events

### FLIRT upgraded

Added requirements: `compatible_sexuality`, `relationship_bond_above: 20`

Reciprocate roll (base 50%):
- Actor CHARMING: +20%
- Target FLIRTATIOUS: +15%
- Target SHY: -15%
- Bond below 10: -20%
- Target not attracted (sexuality check): 0% hard floor

Reciprocated → push FLIRTY directional feeling on target, bond +3
Rejected → mild stress on actor

### DEEP_CONVERSATION upgraded

Added requirement: `relationship_bond_above: 30`

### New events added to events.gd

**ASK_OUT** (romantic, major, cooldown 30)
- Requirements: bond_above 60, CLOSE_FRIEND tier, compatible_sexuality
- Acceptance roll: base 40%, boosted by FLIRTY/AFFECTIONATE directional feelings
- Accept → ROMANTIC_INTEREST event gate, ELATED on both, INFATUATED directional feelings
- Reject → HEARTBROKEN on actor, bond -10

**APOLOGISE** (social, moderate, cooldown 20)
- Requirements: bond_below 30, bond_above -40
- Acceptance roll: base 50%, modified by bond and target traits (STUBBORN -20%, FORGIVING +25%)
- Accept → bond +12, rivalry -5, trust +3, clears BITTER/RESENTFUL
- Reject → bond -5, UPSET_FEELING on actor

**SHARE_STORY** (social, minor, cooldown 10)
- Requirements: familiarity_above 5
- Outcomes: bond +4, trust +2, fam +3

**VENT_TO_FRIEND** (social, moderate, cooldown 15)
- Requirements: stress_above 45, FRIEND tier
- Outcomes: stress -15, loneliness -10, trust +5 on relationship

### Bug fixes this session

**ENERGY_CRASH bed bug:** Characters were sleeping in wrong rooms. Fixed `_energy_crash()`
to send character home with critical SLEEP intent if not already in home_room.

**events.gd parser error:** New events placed after closing `}` of EVENTS dictionary.
Fix: deleted stray `}` between PHYSICAL_FIGHT and ASK_OUT.

**_gossip() / _physical_fight() parameter bug:** Functions used `_character` parameter
prefix (unused convention) but body referenced `character` without underscore.
Fix: removed underscore prefix from parameter names in both functions.

---

## Session 14 — Speed Controls, ForceEvent Upgrade, Trait Evolution

### Speed controls — settings.gd + clock.gd + speed_hud.gd

**Approach:** `Engine.time_scale` for all speed control. Scales everything uniformly:
timers, tweens, movement, elevators, proximity pauses, FeelingDriver/StateDriver.

**settings.gd changes:**
- Removed `sim_speed` and `paused` variables
- Added `speed_preset: int`, `SPEED_PRESETS: [0.0, 1.0, 3.0, 10.0, 30.0]`, `SPEED_NAMES`
- Added `set_speed(preset_index)` which sets `Engine.time_scale`
- `set_speed(1)` called in `_ready()`

**clock.gd changes:**
- Removed `if Settings.paused: return`
- Removed `_timer.wait_time` adjustment line
- Timer now runs at fixed `BASE_TICK_INTERVAL`

**speed_hud.gd — New file** (`res://scripts/ui/speed_hud.gd`)
- CanvasLayer with Label showing current speed, color-coded by preset
- Keys: Space = pause toggle (restores last speed), 1-4 = presets
- `process_mode = PROCESS_MODE_ALWAYS` so it updates while paused
- HUD position: top-center of screen

### ForceEvent panel upgrade — force_event.gd

Complete rewrite of `res://scripts/ui/force_event.gd`. New sections:

**Target dropdown:** "Auto (resolve_target)" or specific character. When specific target
selected, calls new `Sim.force_fire_event_with_target()` which skips `resolve_target()`.
Fixes "someone" bug when force-firing social events.

**Stat modifier:** Stat dropdown + delta spinbox + Apply button.
Calls `Actions.modify_stat()`. Logs result to panel.

**Feeling push/remove:** Feeling dropdown + Push/Remove buttons.
Calls `FeelingDriver.push()` / `FeelingDriver.remove()`.

**Bond setter:** Two character dropdowns + bond value spinbox + Set Bond.
Calls `Relationships.set_bond()`. Logs tier result.

**Teleport:** Room dropdown + Teleport. Releases old spots, updates occupancy, snaps
character body to new room's SpawnPos.

**Event log:** Last 8 forced events, shown at bottom of panel.

**sim.gd addition:** `force_fire_event_with_target(character, event_key, target)` — same
as `force_fire_event()` but accepts explicit target, skips `Context.resolve_target()`.

### Trait evolution — traits.gd

**EVOLUTION_THRESHOLDS const** (full list):
- ALCOHOLIC: drinks_at_bar ≥ 30
- RECOVERING_ALCOHOLIC: sober_days ≥ 20, requires ALCOHOLIC
- WELL_READ: books_read ≥ 15
- BRAWLER: fights ≥ 5
- GOSSIP_EVOLVED: gossip_shared ≥ 20
- REGULAR: bar_visits ≥ 15

**evaluate_evolution_for_character()** implemented (was stub):
- Checks all thresholds daily
- Verifies prerequisite traits
- Grants trait (hidden or visible)
- Applies stat modifiers via `apply_trait_modifiers()`
- Handles `replaces` field for trait replacement
- Logs: `[Traits] 🌱 name evolved: TRAIT (counter = N)`

**_on_day_ticked()** added, connected to `Clock.day_ticked` in `_ready()`.
Also handles sober_days tracker for ALCOHOLIC characters.

**Missing TRAITS dict entries added:**
- `WELL_READ` — library events bonus, happiness +5
- `BRAWLER` — can_start_fights flag, health -5, stress -10
- `REGULAR` — bar events bonus, loneliness -10
- `GOSSIP_EVOLVED` — shares_information flag, loneliness -5

**Counter increments added to actions.gd:**

| Function | Counter |
|---|---|
| `_order_drink()` | `drinks_at_bar` |
| `_drink_alone()` | `drinks_at_bar` |
| `_read_book()` | `books_read` |
| `_browse_shelves()` | `books_read` |
| `_physical_fight()` | `fights` |
| `_gossip()` | `gossip_shared` |
| `_queue_intent_visit_bar()` | `bar_visits` |

`modify_faction()` helper added to `actions.gd`.

### Faction sentiment requirement keys — sim.gd

Added to `_check_requirements()`:
- `faction_sentiment_above` — dict of faction: threshold
- `faction_sentiment_below` — dict of faction: threshold

### EventInspector upgrades — event_inspector.gd

New sections added to `_refresh()`:

**TRAIT PROGRESS** — shows each `trait_progress` counter with its threshold and target
trait name (e.g. `drinks_at_bar: 12 / 30 → ALCOHOLIC`).

**FACTION SENTIMENT** — shows all faction scores with ★ above 70, ▼ below 30.

`process_mode = PROCESS_MODE_ALWAYS` added so inspector works while paused.

### THINK_ABOUT memory weighting — memory.gd

`pick_random_memorable()` rewritten with weighted pool:
- Entry has `target_id` + bond ≥30 → weight 6
- Entry has `target_id` + any bond → weight 3
- Entry has no `target_id` (solo event) → weight 1

Result: characters think about named people ~85% of the time instead of "someone".
"Someone" still appears for characters with no relationships yet — correct behaviour.

---

## Emergent Stories Observed (30x speed test runs)

**Cyrus & Riona** — Built to bond 100 across 3 days via social events. Cyrus asked Riona
out, was accepted. Both entered ROMANTIC_INTEREST. Simultaneously, Priya asked Riona out,
was rejected, gained HEARTBROKEN. Neither was scripted.

**Sara & Dani** — Bond 0→43 in Day 1 via GOSSIP, COMPLIMENT, FLIRT (reciprocated).
Sara's THINK_ABOUT repeatedly pulling Dani with CONTENT_FEELING by Day 2.

**Marcus Webb & Kai Lindqvist** — CLOSE_FRIEND tier entirely through grocery/bar
encounters. Two characters who share a floor converging naturally.

**Soren → Priya** (earlier run) — APOLOGISE rejected, then COMPLIMENT, then repeated
THINK_ABOUT. Obsession arc emergent through the negative relationship pipeline.

**Jared → Marcus Finch** — THINK_ABOUT firing specifically on Marcus Finch (`Jared Finch →
Marcus Finch crossed Jared Finch's mind again.`) after genuine shared interactions.

---

## Phase 4 Completion Status

### Done
- Relationships autoload with full pairwise API
- 15-tier spectrum with event-gated romantic tiers
- Bond decay, familiarity persistence, LONER soft-lock
- Sexuality compatibility checks
- Relationship requirement keys in sim.gd
- All social events wired with bond/trust/rivalry/familiarity deltas
- THINK_ABOUT weighted toward known characters
- Trait evolution with daily counter checks
- Trait evolution stat modifiers for all 6 evolved traits
- FLIRT with compatible_sexuality gate and reciprocate roll
- ASK_OUT → ROMANTIC_INTEREST pipeline firing end-to-end
- APOLOGISE with accept/reject roll
- SHARE_STORY and VENT_TO_FRIEND
- Directional feelings (AFFECTIONATE, BITTER, RESENTFUL, FLIRTY, INFATUATED)
- Faction sentiment field and requirement keys
- EventInspector: relationships, trait progress, faction sentiment sections
- Speed controls (Engine.time_scale, Space/1-4 keys, HUD)
- ForceEvent panel fully upgraded (target, stats, feelings, bond, teleport, log)
- Grief propagation function written and waiting for death events

### Deferred (intentional)

**ASK_TO_GO_STEADY / PROPOSE** — PARTNER and MARRIED tiers require player choice UI
to feel right. Deferred until player choice system built. Cyrus and Riona are sitting
at ROMANTIC_INTEREST with nowhere to go until then.

**AVOID_CHARACTER intent** — negative interactions should push avoidance routing.
Not yet built. AWKWARD_HALLWAY_PASS, INSULT, ARGUE should all push this.

**Gossip memory propagation** — `_gossip()` increments counter but doesn't transfer
memory content to target. Building-wide knowledge spread not yet implemented.

---

## Balance Notes

At 30x speed, nearly everyone reaches BEST_FRIEND within 2-3 days. Bond deltas per
event are calibrated for real gameplay pace (~1x), not test speed. No tuning needed
until Phase 8 scale testing with real player session lengths.

COMPLIMENT has high base_weight relative to other social events — consider cooldown
increase during balance pass.

SPILL_DRINK familiarity outcome (`"relationship": { "familiarity": 1 }`) was confirmed
working in outputs.

---

## Decisions Log Entries

**Engine.time_scale for all speed control** — Single approach scales everything uniformly.
No per-system speed adjustments. BASE_TICK_INTERVAL stays fixed. Session 14.

**Pre-scan approach for relationship requirements** — Check room occupants in
`_check_requirements()` before target resolution, then filter again in `resolve_target()`.
Avoids resolving a target then finding no compatible relationship exists. Session 11.

**Relationship counters on CharData, not Relationships autoload** — `trait_progress`
dictionary lives on CharData. Cheap to read, no cross-autoload lookup per action.
Session 14.

**RECOVERING_ALCOHOLIC coexists with ALCOHOLIC** — Both traits can be active
simultaneously. `replaces` field left empty for this pair. Session 14.

**Gossip propagation deferred** — `_gossip()` is intentionally a stub that only
increments counter. Full memory transfer between characters is a Session 15 item. Session 13.

**ASK_TO_GO_STEADY and PROPOSE deferred** — These are the tail end of the romantic chain
and require player choice UI to feel meaningful. Flagged in roadmap as
"Phase 4 extension, implement when player choice UI exists." Session 14.

---

## Files Modified This Block

| File | Type |
|---|---|
| `relationships.gd` | New autoload |
| `sim.gd` | Requirement keys, outcome handler, force_fire_event_with_target |
| `context.gd` | resolve_target relationship filtering |
| `bootstrap.gd` | _seed_starting_relationships |
| `event_inspector.gd` | RELATIONSHIPS, TRAIT PROGRESS, FACTION SENTIMENT sections |
| `events.gd` | Relationship outcomes on 14 events + 4 new events |
| `actions.gd` | _flirt, _ask_out, _apologise, _share_story, _vent_to_friend, _gossip, _physical_fight, counter increments, modify_faction |
| `memory.gd` | pick_random_memorable weighted rewrite |
| `traits.gd` | EVOLUTION_THRESHOLDS, evaluate_evolution_for_character, _on_day_ticked, 4 new TRAITS entries |
| `settings.gd` | Removed sim_speed/paused, added speed preset system |
| `clock.gd` | Removed paused/speed adjustment lines |
| `speed_hud.gd` | New file |
| `force_event.gd` | Complete rewrite |

---

## On the Horizon (Session 15+)

- AVOID_CHARACTER intent (negative relationship → reroute)
- Gossip memory propagation (transfer storybook entry to target)
- More enemy-making events + new sequences (session ended before this was built)
- ASK_TO_GO_STEADY / PROPOSE (deferred — needs player choice UI)
- Phase 5 planning
