# CLAUDE.md — MegaBlock 16 Start Here
*The one file every chat reads first. Index + cheat-sheet + current state + session protocol.*
*Keep this dense. Detail lives in the documents this points to.*

---

## What This Project Is

**MegaBlock 16 (MB16)** — a cyberpunk life simulation in **Godot 4.6.2 / GDScript**. Up to 35 AI-driven residents in one apartment building generate emergent stories through interconnected autonomous systems. No scripted plots — romance, betrayal, gossip, and drama emerge from weighted event pipelines. Solo dev (Alexander, newer to Godot, father advises). Claude is the dev mentor.

---

## How To Use The Docs (load only what the session needs)

| Document | Load when | Canonical for |
|---|---|---|
| **CLAUDE.md** (this) | Always | Current state, quick refs, session protocol |
| **GDD_CORE** | Most sessions | Vision, pillars, principles, system overviews |
| **GDD_REFERENCE** | Designing a specific area | Building layout, room types, factions, jobs, families, holidays, player UX, save, audio, settings, parking lot |
| **Architecture Reference** | Any code work | Folder tree, autoload map, CharData fields, system comms |
| **Decisions Log** | "Why is X like this?" | The reasoning behind locked decisions |
| **Event Design Bible** | Authoring events | Event/sequence/action rules, naming, storybook patterns |
| **Starter Events** | Building event content | Plain-English event backlog |
| **Context Template Guide** | Writing storybook text | `{name}`, pronoun, conjugation variables |
| **Character Roster** | Adding/using bespoke characters | Hand-authored residents |
| **Roadmap** | Planning / phase questions | Phase plan and ship targets |
| **Latest session notes** | Continuing recent work | What happened in the last 1–3 sessions |

**Don't load** the Event Bible / Starter Events / Roster for a pathfinding bug. Don't load old session notes (4+ back) — their content is already absorbed into the reference docs.

To resolve any duplication: **the table above wins.** If two docs disagree, the "canonical for" column decides.

---

## ▶ CURRENT SPRINT  *(update this at the end of every session — it's the fast handoff)*

```
Phase:        Phase 4 — Relationships & Social Drama (extension wave)
Next session: 20
Just shipped: CONVERSE_SEQ (pool-based conversations, mood tracking, arc detection,
              beat pools, escalation, summaries), Hallway Conversations v2
              (hallways-as-rooms architecture — characters register in hallway_fN
              rooms during transit, CONVERSE fires via allow_hallway flag,
              re-plan on resume via _plan_from_hallway).
Working on:   Hallway conversation bugs — system is partially working but unstable.
Known issues: 
  1. Characters immediately re-entering CONVERSE after it ends (cooldown not set
     on LOCK_SEQUENCE path in _run_hallway_check — fix identified, one line).
  2. Characters floating through rooms / getting stuck in repeated convo loops.
     Root cause unclear — likely a state leak when is_in_transit gets out of sync
     with movement controller state, or zone_target_pos not clearing correctly.
  3. Spot assignment: characters pick spots by lane order, not proximity — one
     character sometimes walks across the full hallway to reach their spot.
  4. Old proximity system (fire_proximity_event, loiter fields, etc.) still in
     codebase alongside new system — dead code causing confusion.
Build order
remaining:    0) DEBUG + CLEAN UP hallway conversations (see next session prompt)
              1) Passive relationship decay (relationships.gd only)
              2) Public Humiliation (context-severity)
              3) Cold Phase (is_cold on RelationshipRecord)
              4) Jealousy system (watching array, 3 intensity levels)
              5) Lying system (lies array, contradiction exposure)
Parked:       BETRAY_SECRET redesign. ASK_TO_GO_STEADY/PROPOSE (needs UI).
              Grocery checkout (Phase 5). Group conversations.
              Spot selection refinement (proximity-based, not lane-order).
```

---

## Quick Reference

### Pipeline (per event)
`ROLL → RESOLVE → FRAME → PLAYER_GATE → ACT → EXECUTE → ECHO → CONTINUE?`
PLAYER_GATE only fires for the player character on `player_choice: true` events.

### Tick loop
skip if sleeping → skip if in transit (except proximity-reactive) → **flee-avoided check** → intent queue → auto-fire pool (Architect-gated) → advance sequence → else full pipeline.
**Critical ordering:** sequence advance runs *before* transit check, so movement can't override an active sequence lock.

### Autoloads (30, 6 tiers)
```
T1 Config (9):  Settings, Stats, Traits, Identity, Feelings, States, Events, Sequences, Interactables
T2 Core (5):    Clock, Registry, Rooms, Pathfinder, Memory
T3 Systems (7): FeelingDriver, StateDriver, Relationships, Context, Actions, Audio, Camera
T4 Sim (1):     Sim
T5 Domain (6):  Architect, Mayor, Strata, Police, Factions, Jobs
T6 Player (2):  Decisions, Saves
```
Load order = tier order. **No new autoloads without discussion.** Full map + folder tree in Architecture Reference.

### CharData (the non-obvious bits)
Single source of truth. Mechanical trait checks call `get_all_active_traits()` (traits + hidden_traits); UI bio uses `traits` only. Key arrays: `intent_queue`, `secrets`, `storybook` (memorable/memory_tags/times_recalled/shared_to/pinned_to_story), `trait_progress` (evolution counters), `faction_sentiment`. Full field list in Architecture Reference.

### Relationship tiers (bond score)
`MORTAL_ENEMY → ENEMY → RIVAL → DISLIKED → UNFRIENDLY → COOL → NEUTRAL → ACQUAINTANCE → FRIENDLY → FRIEND → CLOSE_FRIEND → BEST_FRIEND → ROMANTIC_INTEREST★ → PARTNER★ → DEEPLY_BONDED → MARRIED★`  (★ = event-gated)

### Vocabulary & naming
Room → Zone → Spot, always. Room IDs `type_fFLOOR_sSLOT`. Event IDs `ALL_CAPS_SNAKE_CASE`. Resource class PascalCase (`CharData`), file snake_case (`char_data.gd`). Booleans `is_*`.

### Debug
F2 EventInspector · F3 ForceEvent · F4 StorybookDisplay · Space pause, 1–4 speed presets (Engine.time_scale). Log emoji prefixes for fast console search (📍 ⛔ 📋 ❌ 🗣️ 👂 💔 🚷 🫵 🌱 💛).

---

## Code Rules

- GDScript 4.x, static typing where it helps. Tab indentation.
- Explain each section briefly. Beginner-friendly, not dumbed down.
- **Don't rewrite things that work — integrate.** Small testable chunks over massive refactors.
- If you'd need a script you haven't been shown, **ask for it** — don't guess its contents.
- **Everything flows through the Sim pipeline.** Nothing bypasses it.
- Config (events, sequences, beat pools, summary templates) lives in **data files**, not system logic.
- Editor-based placement for geometry/spawns/markers, not procedural.
- Say when you're **guessing vs confident**. Push back on bad architecture — be a mentor, not a yes-machine.

### Hard-won lessons (don't re-learn these)
- Sequence advance before transit check (movement overrides sequence locks otherwise).
- Guard movement-controller internal state (e.g. elevator phase) at boarding/exiting checkpoints — it leaks through sequence locks.
- Memorable threshold = moderate/major/huge (major/huge alone starves memory events).
- Stress income must exceed relief, or conflict events never fire.
- Owner does not hold a copy of their own secret; recipients get copies.
- Secondhand gossip stores `root_summary` to prevent "Heard from X: Heard from Y:" nesting.

---

## Session Types

**Brainstorm** — ideas, architecture, systems, content. When something locks, it becomes a Decisions Log entry. End by offering to update the relevant docs.

**Dev** — write/debug code. Default to the top unfinished item in the Current Sprint build order unless told otherwise. User pastes logs/errors expecting diagnosis-first, then a fix. Prefer complete file rewrites of *changed* files over scattered patches.

**Ask which type at the start if the first message doesn't make it obvious.**

---

## ▣ SESSION WRAP-UP PROTOCOL  *(run this when the user signals the session is ending, or when context is filling / mistakes creeping in)*

When wrapping up, do all of this in one go so the user can copy-paste fast:

1. **Write session notes** using `MB16_SESSION_NOTES_TEMPLATE.md`. Keep them structured and terse: what we built, what's working, what's still broken, bugs fixed (with root cause), files modified, decisions, next priorities. These are a handoff for the next chat — write for a reader who wasn't here.

2. **Produce an updated CURRENT SPRINT block** (the fenced block above), ready to paste over the old one in this file. This is the single most important handoff artifact.

3. **List Decisions Log entries** for anything architectural that locked this session — format `Decision — Reason — Session N`, ready to paste at the top of the relevant section.

4. **List any doc edits**, told as surgical instructions, e.g. "GDD_REFERENCE §10: add the new faction field" or "Roadmap: tick Phase 4 item X." Don't rewrite whole docs — give the user the exact snippet and where it goes.

5. **Flag new Parking Lot items** if any idea came up without a home (→ GDD_REFERENCE §15).

6. Tell the user plainly: **"Start a fresh chat for the next session"** if context is heavy.

Keep the wrap-up itself compact — the user is copy-pasting on mobile. Lead with the Current Sprint block and session notes; everything else is short lists.

---

## Tone For This Project

Scannable on mobile: short paragraphs, minimal formatting, bullets only when they earn their place. Lead with the answer. Push back honestly. Flag guesses.
