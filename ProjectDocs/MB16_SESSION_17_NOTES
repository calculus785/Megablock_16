

# MB16 Session 17 — Full Session Notes

**Session type:** Dev + Brainstorm
**Phase:** Phase 4 — Relationships & Social Drama (extension)
**Status:** Gossip propagation, secret system, AVOID_CHARACTER, and bug fixes all shipped. Phase 4 extension wave designed and documented.

---

## Overview

This session built the full gossip propagation and secret inventory systems from scratch, implemented AVOID_CHARACTER intent, fixed a series of bugs across multiple files, and ended with a brainstorm session designing the Phase 4 extension wave. By end of session, secrets spread through the building via gossip chains, TELL_ON fired organically, bystanders overheard gossip about themselves, and characters fled rooms containing people they were avoiding.

---

## Gossip Propagation System

### memory.gd — New sections added

**SECRETS section** — new helpers for secret inventory:
- `generate_secret_id(owner_id)` — unique ID generator
- `add_secret(character, secret)` — adds to `character.secrets` array with debug log
- `has_secret(character, secret_id)` — deduplication check
- `has_any_secrets(character)` — quick check
- `get_secrets_about(character, owner_id)` — filter by subject
- `get_tellable_secrets(character)` — secrets with `betrayal_chain_known == true`, original owner not self
- `get_betrayable_secrets(character)` — secrets where character is not the owner

**GOSSIP HELPERS section** — memory transfer helpers:
- `pick_gossipable_entry(gossiper, target)` — weighted pool picker. Prefers negative tone (weight 4), positive (weight 2), neutral (weight 1). Skips entries already shared to this target via `shared_to` array. GOSSIP trait adds +2 to all weights.
- `write_secondhand_storybook(listener, gossiper, original_entry)` — writes secondhand entry on the listener. Stores `root_summary` field to prevent nesting on future hops. Copies `secret_id` if the gossip involves a secret.

**Secret entry shape:**
```gdscript
{
    secret_id: String,
    original_owner_id: String,
    content: String,
    shared_by_id: String,
    betrayal_chain_known: bool,
    betrayer_id: String,
    heard_at_tick: int,
}
```

**Secondhand storybook entry shape:**
```gdscript
{
    event_key: "GOSSIP_HEARD",
    summary: "Heard from {name}: {root_summary}",
    root_summary: String,        # original unwrapped text, never nests
    secondhand: true,
    source_id: String,
    original_event_key: String,
    secret_id: String,           # populated if gossip involves a secret
    memory_tags: ["gossip", "secondhand"],
}
```

### char_data.gd — New field

```gdscript
@export var secrets: Array = []
```

Added after `intent_queue` in the MEMORY section.

### actions.gd — `_gossip()` full rewrite

Replaces the counter-only stub. Full behaviour:
- Increments `gossip_shared` trait counter
- Calls `Memory.pick_gossipable_entry()` to find something to share
- If nothing found: logs `🗣️ nothing juicy to share` and returns DONE
- Marks entry `shared_to` with target's char_id
- Calls `Memory.write_secondhand_storybook()` on target
- Tone-based relationship adjustment: negative gossip → bond -3, trust -2 on target toward subject; positive → bond +2; both adjust subject's `global_reputation`
- Calls `_propagate_secret_via_gossip()` if the gossip entry has a `secret_id`
- Checks if target IS the gossip subject → HUMILIATED + bond/trust damage
- LISTEN_IN loop: iterates room occupants, 25% base chance (50% NOSY, halved for OBLIVIOUS), writes secondhand entry + secret propagation for each bystander
- Bystander self-gossip check: if bystander IS the subject → HUMILIATED + memorable storybook entry instead of secondhand

**`_propagate_secret_via_gossip()` helper:**
- Checks if gossip entry has a `secret_id`
- Copies secret to listener with `betrayal_chain_known: false` and empty `betrayer_id`
- Logs `🤫📢`

**Log prefixes:**
- `🗣️` — gossip transfer (or nothing to share)
- `👂` — bystander overheard
- `👂😳` — bystander overheard gossip about themselves
- `🗣️😳` — gossiper accidentally gossiped about target to their face

---

## Secret System

### actions.gd — `_share_secret()` rewrite

- Generates `content` from character's memorable storybook (prefers negative/neutral tone entries)
- Generates unique `secret_id` via `Memory.generate_secret_id()`
- Writes `Memory.add_secret()` on **target only** (owner does not get a copy of their own secret — they lived it)
- Writes storybook entry on target with `memory_tags: ["secret_received"]` and `secret_id` field
- Adds extra trust delta on top of event outcomes

### actions.gd — `_betray_secret()` rewrite

- Calls `Memory.get_betrayable_secrets()` to find a secret to betray
- Guards: target already knows → skip; target is original owner → skip; self-betray → skip
- Copies secret to target with `betrayal_chain_known: true` and `betrayer_id` set to the betrayer
- Writes storybook on target with `memory_tags: ["betrayal_info", "secret_secondhand"]`
- **No immediate rivalry** — rivalry only fires when TELL_ON fires
- Increments `secrets_betrayed` trait counter
- Logs `💔`

### actions.gd — `_tell_on()` new function

- Calls `Memory.get_tellable_secrets()` to find secrets where chain is known
- Scans room for original owner
- Fires trust/bond/rivalry damage on original owner toward betrayer
- Pushes FURIOUS and HUMILIATED on owner
- Pushes `_maybe_push_avoidance()` on owner toward betrayer (90% chance, 48h)
- Teller gains trust +5 and bond +3 from owner
- Marks secret `told_owner: true` to prevent repeat
- Logs `🫵`

### events.gd — TELL_ON event added

```gdscript
"TELL_ON": {
    "base_weight": 2,
    "category": "social",
    "magnitude": "moderate",
    "cooldown_events": 20,
    "requirements": {
        "other_character_in_room": true,
        "has_memory_tag": "betrayal_info",
    },
    "weight_modifiers": [
        BY_THE_BOOK +2.0, GOSSIP +2.0, MEAN 0.4, SECRETIVE 0.3
    ],
    "call_action": "tell_on",
}
```

### event_inspector.gd — New sections

**SECRETS section:**
- Shows each secret in `character.secrets`
- Own secrets flagged with "OWN SECRET (shared)"
- Others show: "About {owner} (from {sharer}) [betrayer: {name}]" or "[told owner]"

**RECENT GOSSIP section:**
- Shows last 5 entries from storybook where `secondhand == true`
- Displays `"Heard from {name}: {root_summary}"` cleanly at one level

---

## AVOID_CHARACTER System

### feelings.gd — AVOIDING feeling added

```gdscript
"AVOIDING": {
    "label": "Avoiding",
    "description": "Actively trying to stay away from someone.",
    "duration_hours": 12,
    "drift_modifiers": { "stress": 2, "happiness": -1 },
    "conflicting": [],
    "can_be_hidden": false,
    "can_be_targeted": true,
},
```

Must match exact field shape of all other feelings (`duration_hours`, `drift_modifiers`, `conflicting`, `can_be_hidden`, `can_be_targeted`).

### actions.gd — `_maybe_push_avoidance()` helper

```gdscript
func _maybe_push_avoidance(character, avoided, base_chance, base_hours, reason):
```

- Trait modifiers: SHORT_TEMPERED +20% chance, STUBBORN ×1.5 hours, FORGIVING ×0.5 hours -15% chance, LONER +15% chance
- Guards: `avoided.char_id` must be non-null and non-empty before push
- Guards: `FeelingDriver.has_feeling(character, "AVOIDING", avoided.char_id)` — skip if already avoiding this person (prevents double-push)
- Logs `🚷`

**Wired into:**
- `_physical_fight()` — 80% chance, 24h for both sides
- `_confront()` — 50% chance on target, 12h
- `_tell_on()` — 90% chance on owner toward betrayer, 48h
- `_gossip()` — 70% chance when bystander overheard gossip about themselves

### sim.gd — `_check_and_flee_avoided()` new function

Runs at top of `_on_tick()` for every character, before intent processing.

- Guards: `current_room` must be non-null and non-empty string
- Guards: `avoid_id` extracted with null-safe pattern (`var raw_avoid = feeling.get("target_id", null)`)
- If avoided character is in the same room: pushes `GO_HOME` intent (or `WANDER` if already home) with `flee_from` field
- Intent has `clearable: false` and patience 5
- Writes storybook entry `FLEE_AVOIDED`
- Skips if flee intent already queued (checks `intent.has("flee_from")`)
- Logs `🚷 {name} spotted {avoided} — leaving {room}`

---

## Bug Fixes This Session

| Bug | File | Fix |
|---|---|---|
| Owner got copy of own secret | `actions.gd _share_secret()` | Removed `Memory.add_secret(character, ...)` block — owner doesn't hold their own secret |
| Target's secret copy never saved | `actions.gd _share_secret()` | Re-added `Memory.add_secret(target, ...)` — was accidentally removed with owner block |
| 💔 emoji collision (flirt vs betray) | `actions.gd _flirt()` | Changed flirt rejection from `💔` to `💨` |
| Gossip nesting ("Heard from X: Heard from Y: ...") | `memory.gd write_secondhand_storybook()` | Added `root_summary` field — always stores original text, used on all future hops |
| Self-gossip crash (Marcus gossiped to Marcus) | `actions.gd _gossip()` | Added `if target.char_id == character.char_id: return DONE` guard |
| Self-betray crash | `actions.gd _betray_secret()` | Added same self-guard |
| AVOIDING feeling field mismatch | `feelings.gd` | Rewrote AVOIDING to use correct field names (`duration_hours` not `default_hours`, etc.) |
| `_check_and_flee_avoided` null crash | `sim.gd` | Added null guards for `current_room` and `avoid_id`; used `feeling.get("target_id", null)` pattern |
| AVOIDING double-push | `actions.gd _maybe_push_avoidance()` | Added `has_feeling` guard before FeelingDriver.push() |

---

## Emergent Stories Observed

**Leon Finch secret chain** (earlier cast) — Leon shared secret with Kai. Kai betrayed it to Dani. Leon found out and told Sara. Sara gained FURIOUS toward Kai and HUMILIATED. Completely unscripted. Full chain confirmed working end-to-end.

**Tamsin Park gossip spiral** — Marcus shared Tamsin Park's secret. Within one session at 30x, Kai, Mira, Tamsin Rourke, Priya, and Sara all had copies via different gossip paths. Tamsin overheard gossip about herself three times, gaining HUMILIATED repeatedly.

**Sara & Priya romantic arc** — `Sara Vega asked Priya Nair out → ACCEPTED` fired organically. Simultaneous with `Marcus Webb asked Kai Lindqvist out → ACCEPTED` in the same run. Two parallel unscripted romantic arcs.

**Jared Banks betray chain** — `Jared Banks betrayed Marcus Webb's secret to Finley Banks` fired naturally after relationship building, no intervention.

**Trait evolution** — `Kai Lindqvist evolved: GOSSIP_EVOLVED` from natural gossip accumulation. `Reese Volkov evolved: WELL_READ`. `Jared Banks evolved: REGULAR`. All organic.

---

## Balance Notes

Bond ceiling problem identified — at 30x almost all characters reach BEST_FRIEND within a few days. Root causes:
- Positive bond events too frequent and low-cooldown
- Negative events have stress thresholds rarely met when characters are comfortable
- Bond decay rate (-1/10 days) too slow for building social pace

Will be addressed by passive decay system and CONVERSE_SEQ in Phase 4 extension.

---

## Phase 4 Extension — Systems Designed

Full designs documented above (see brainstorm section). Build order:

1. **Passive relationship decay** — `relationships.gd` only, small, immediate impact
2. **CONVERSE_SEQ** — replaces CHAT, solo version first then group
3. **Conversation beats** — UNSOLICITED_ADVICE, RUB_WRONG_WAY, SHOW_OFF, HEATED_ARGUMENT_BEAT, DEEP_MOMENT inside CONVERSE_SEQ
4. **Public Humiliation** — standalone event, context-severity
5. **Cold Phase** — `is_cold` bool on RelationshipRecord
6. **Jealousy System** — full system after CONVERSE_SEQ stable
7. **Lying System** — after jealousy, uses CONVERSE_SEQ beats

---

## Decisions Log Entries

**Gossip propagation uses `shared_to` array on storybook entries** — tracks which characters have heard each piece of gossip. Same gossip can spread to new people each time, but never double-copied to someone who already heard it. Session 17.

**`root_summary` field on secondhand storybook entries** — always stores the original unwrapped event text. All future hops use `root_summary` as the content to display, preventing "Heard from X: Heard from Y: Heard from Z" nesting. Session 17.

**Secrets stored on `CharData.secrets` array, managed by memory.gd** — secrets are knowledge, not physical objects. Live in memory system for now. When inventory arrives, physical items go there but secrets stay in memory. Session 17.

**Owner does not hold a copy of their own secret** — `secrets` array is for knowledge received from others. The original owner lived it; they don't need inventory of it. Target-only copy on SHARE_SECRET. Session 17.

**BETRAY_SECRET fires no immediate rivalry** — rivalry only fires when TELL_ON completes. Betrayal copies the secret with `betrayal_chain_known: true` and `betrayer_id` set. The drama resolves socially, not mechanically. Session 17.

**Gossip-spread secrets always have `betrayal_chain_known: false`** — when a secret propagates through the gossip network rather than direct betrayal, the chain is lost. Recipients get the information but can't trace it back. Session 17.

**AVOID_CHARACTER implemented as feeling + sim-level flee intent** — AVOIDING feeling is targeted (has `can_be_targeted: true`). `_check_and_flee_avoided()` in sim.gd runs before intent processing each tick. Pushes GO_HOME or WANDER intent with `flee_from` field and `clearable: false`. Session 17.

**Grow Apart is passive decay in relationships.gd, not an event** — `last_positive_interaction_tick` field on RelationshipRecord. THINK_ABOUT toward a character counts as interaction. PARTNER/MARRIED tiers immune. Session 17.

**CHAT replaced by CONVERSE_SEQ** — multi-beat sequence with continue/end roll each beat. Beat pool includes positive and negative beats. Group conversation mechanic: third character can join mid-sequence. EXCLUDED feeling after 4+ beats without speaking. Session 17.

**Jealousy is a full system** — three intensity levels (MILD_JEALOUSY, JEALOUS, CONSUMING_JEALOUSY). CharData.watching array tracks surveillance targets. JEALOUSY_SCENE event gated on CONSUMING_JEALOUSY. Gossip propagation triggers jealousy checks. Session 17.

**Cold Phase is a RelationshipRecord state** — `is_cold: bool` on the record between two specific characters. Only for ROMANTIC_INTEREST+ pairs inactive 3+ days. Not a CharData state. Doubles decay rate, biases CONVERSE_SEQ negative. Session 17.

**Lying System separate from secrets** — `lies` array on CharData. Exposure fires when contradicting event reaches lied-to character. ALIBI variant deferred to police phase. FAKE_COMPLIMENT and DENY_INVOLVEMENT as starter CONVERSE_SEQ beats. Session 17.

**Spread Rumour is a gossip subtype, not a separate event** — GOSSIP beat in CONVERSE_SEQ gains rumour subtype. Distortion chance modified by MEAN trait, rivalry, active jealousy toward subject. Session 17.

**Public Humiliation severity determined by context at runtime** — witness count, target reputation, and attacker traits determine low vs high severity. Not two separate events. Session 17.

**Heated Argument is a CONVERSE_SEQ beat, not a standalone event** — weight toward this beat increases as conversation turns negative via sequence context tracking. Session 17.

---

## Files Modified This Session

| File | Change |
|---|---|
| `char_data.gd` | Added `secrets: Array` field |
| `memory.gd` | Added SECRETS section (7 helpers) + GOSSIP HELPERS section (pick_gossipable_entry, write_secondhand_storybook) |
| `actions.gd` | Full `_gossip()` rewrite, `_share_secret()` rewrite, `_betray_secret()` rewrite, `_tell_on()` new function, `_maybe_push_avoidance()` helper, `_propagate_secret_via_gossip()` helper, self-guards on gossip/betray, avoidance wired into fight/confront/tell_on/gossip |
| `events.gd` | Added TELL_ON event |
| `event_inspector.gd` | Added SECRETS section, added RECENT GOSSIP section |
| `feelings.gd` | Added AVOIDING feeling with correct field shape |
| `sim.gd` | Added `_check_and_flee_avoided()`, wired into `_on_tick()` before intent processing |