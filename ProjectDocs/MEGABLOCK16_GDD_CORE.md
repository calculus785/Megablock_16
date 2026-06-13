# MegaBlock 16 — GDD Core
*The vision and the system overviews. Load this most sessions.*
*Exhaustive detail lives in GDD_REFERENCE. Codebase structure lives in Architecture Reference.*
*Codename: MegaBlock 16 (final title TBD)*

---

## How To Read This

This is the "what the game is and how the systems fit together" document. It is deliberately kept short and scannable. When you need exhaustive detail on a single area (room layouts, factions, jobs, families, save format, etc.), open GDD_REFERENCE. When you need to know how the code is organised, open the Architecture Reference.

---

# 1. VISION

## What Is This Game?

A cyberpunk life simulation set entirely inside one apartment building. Up to 35 residents living, fighting, loving, dying — all simulated in real time. The player watches emergent stories unfold and occasionally intervenes through their own character.

No storyline is written in advance. Every romance, betrayal, and tragedy is the result of systems interacting.

**The hook:** you follow stories, not people. The building is the character.

**The Sims meets Dwarf Fortress meets a soap opera.** RimWorld's emergent storytelling in a vertical dollhouse.

## Design Pillars

1. **Stories emerge, they are not scripted.** Every romance, betrayal, and tragedy is the result of systems interacting — not a predetermined plot.
2. **Every character has a life worth watching.** The player character is not special. The building is the protagonist.
3. **Darkly comedic with real stakes.** A satirical soap opera. Funny and heartbreaking, sometimes at once.
4. **Attachment is earned, not forced.** The building starts nearly empty. By the time it's full, you have history with almost everyone in it.
5. **The player is always in control.** Pause anytime. Follow anyone. Save your favourite moments.

## Core Design Principles (apply every session)

1. **Data-driven.** Behaviour lives in Resources/config, not hardcoded logic.
2. **Event-based.** Ticks → events → state change → next events.
3. **Single source of truth.** CharData is canonical.
4. **Handoff pattern.** Systems own their domain, hand off at boundaries.
5. **TV show mindset.** Dramatic beats, not chores. The Storybook is the recap.
6. **Emergence over authoring.** Set up systems that produce stories; don't script them.
7. **Room → Zone → Spot.** Always. Every time.
8. **Test small.** Small testable chunks over massive refactors.
9. **Profile before optimising.** Don't guess what's slow.
10. **The building is the character.** Not any one person. The whole thing.

---

# 2. THE WORLD (overview)

The building is viewed in 2D cross-section (dollhouse style). Individual rooms are bespoke 3D scenes inside SubViewport cutouts. Characters are 2.5D billboard sprites — same sprite in a 2D hallway or a 3D room.

22 levels above ground (F00–F20 + Rooftop), plus two underground (-01 Power Plant, -02 Sewer). F00 is the lobby. Management sits at F11, the vertical midpoint. All rooms exist from Day 0 — no event-triggered unlocks.

**Population is capped at 35** (one apartment per resident; couples/families share). Homeless characters are the exception — they exist in the building without an apartment. Building starts nearly empty and fills over play time.

> Full building layout, room types, schedules, and underground detail → **GDD_REFERENCE §1–3**.

## Vocabulary (used everywhere)

- **Room** → the full space (bar, apartment, library)
- **Zone** → an area within a room (pool table area, bar counter)
- **Spot** → a specific pre-authored standing position within a zone

Room IDs: `type_fFLOOR_sSLOT` (e.g. `bar_f2_s2`). Events use type keys ("bar"); Rooms autoload resolves to real IDs.

## Calendar (quick)

```
Tick = 5–8s  |  Half-hour ≈ 18.75s  |  Day = 15 min
Week = 5 days (Day 5 = Restday)  |  Month = 3 weeks = 15 days
Year = 6 months = 90 days  |  Lifespan = 40 years
Months numbered 1–6, no names. Display: "Month 3 · Week 2 · Day 4 — Year 47"
Seasons: summer/summer/neutral/winter/winter/neutral (30 days each).
Intensity peaks day 15 of each season. Weight mod only, never a requirement.
```

---

# 3. CHARACTERS (overview)

Every character is a **CharData** Resource — the single source of truth for all character state. RobotData extends CharData with minimal overrides (health only, no feelings/traits/relationships/storybook).

- **Identity:** char_id, name, hidden internal_age (drives life_stage), pronouns, sexuality/preference, favourite_color, interests, life_arch, birthday, favorite_genre/movie.
- **Stats (16):** stress, happiness, health, energy, hunger, boredom, loneliness, horniness, need_for_toilet, grief, global_reputation, attractiveness, cash, criminal_inclination, criminal_reputation, addiction.
- **Traits:** permanent personality weight-modifiers. Never hard gates — they nudge probability. Criminal events gate on stats, not traits. Coexisting traits possible (ALCOHOLIC + RECOVERING_ALCOHOLIC). Gained/lost via trait evolution (daily counter-based check).
- **Feelings:** temporary emotional states, decay over time. Global or targeted (at a character). Can be hidden (mechanics still apply, no UI bubble).
- **States:** stat-derived labels (StateDriver, half-hourly) + persistent states set by events (ON_PAROLE, IN_HOSPITAL, etc.).
- **Life stages:** Baby 0–2 (BabyData) → Child 2–8 → Teen 8–16 → Adult 16–35 → Elderly 35–40. Age hidden; UI shows stage. Player starts at 16.

> Full stat table, trait list, feeling list, death system, and art direction → **GDD_REFERENCE §4**.

---

# 4. THE SIMULATION (overview)

## The Pipeline (per event)

```
ROLL → RESOLVE → FRAME → PLAYER_GATE → ACT → EXECUTE → ECHO → CONTINUE?
```
- **ROLL** weighted-random pick from eligible pool
- **RESOLVE** pick target (character / interactable / memory / room / self)
- **FRAME** resolve context args (declarative table or Context function)
- **PLAYER_GATE** only if actor is player AND event has `player_choice: true` → pop-up, pause
- **ACT** `Actions.call_action(character, target, args)`
- **EXECUTE** movement, stats, storybook, inventory, world state
- **ECHO** short-term memory, flag storybook if memorable, relationship delta if target is a character
- **CONTINUE?** action returns DONE / REPEAT / LOCK_SEQUENCE

## The Loop

```
Every tick (per character):
  skip if sleeping → skip if in transit (except proximity-reactive)
  → check intent queue (fire if any) → check auto-fire pool (fire highest if Architect approves)
  → if in sequence, advance beat → else run full pipeline
Half-hour: Clock advances, FeelingDriver decays, StateDriver evaluates, Rooms ticks auras, passive stat ticks
Daily: Memory prunes, Relationships decay, Traits check evolution, Architect evaluates mood + calendar
On room arrival: one room-context reactive event
```

## Event vs Sequence

An **event** is a single beat: fires, changes state, writes one storybook entry, done.
A **sequence** is a multi-beat locked activity: all participants locked, each beat has its own outcomes/text, branching possible. Use a sequence when an activity has phases, needs co-location across beats, or the outcome should feel earned.

**Auto-fire** events (`trigger_mode: "auto_fire"`) skip the weighted roll when requirements are met but still run the pipeline and still need Architect approval. Reserved for costly/rare events (riots, interventions). Calendar events bypass the Architect (`bypass_architect: true`).

> Target resolution filters, scope detail, and the Architect's full role → **GDD_REFERENCE §5–6**.

---

# 5. MEMORY (overview)

- **Short-term:** 5 categories (thought, action, interaction, observation, felt) × 2 entries each. Written in ECHO.
- **Long-term:** flagged storybook entries (not a separate structure). `memorable` flag + `memory_tags` + `times_recalled`. Pruned daily; 40-year rolling cap; 50 memorable soft cap (most-recalled survive). Pinned (Chronicle) entries never pruned.
- **Intent queue:** ordered pending actions on CharData, checked before ROLL. Priority critical→low. Patience decrements; at 0, GIVE_UP fires (STUBBORN high, LAZY low). Non-clearable intents (biological needs) survive interrupts.
- **Impressions:** per-character scores for interactables + room programs in one dictionary, gated by interests. Tiers: Unaware/Noticed/Familiar/Attached/Connected. Negative = aversion.

---

# 6. RELATIONSHIPS (overview)

Pairwise **RelationshipRecord** per pair: bond (-100..+100), trust (0–100), rivalry (0–100, coexists with positive bond), familiarity (0–100, never decays). Directional feelings each way (AFFECTIONATE, BITTER, RESENTFUL, FLIRTY, INFATUATED, etc.).

**15-tier spectrum** from bond score:
```
MORTAL_ENEMY → ENEMY → RIVAL → DISLIKED → UNFRIENDLY → COOL → NEUTRAL
→ ACQUAINTANCE → FRIENDLY → FRIEND → CLOSE_FRIEND → BEST_FRIEND
→ ROMANTIC_INTEREST★ → PARTNER★ → DEEPLY_BONDED → MARRIED★
(★ = event-gated, not just score)
```
Bond decays without interaction (slower above BEST_FRIEND, none for MARRIED). Reproduction needs only bond > 20 (partnership not required). Grief propagates by bond tier on death.

> Exact tier bands, grief thresholds, and decay rates → **GDD_REFERENCE §7** and Decisions Log.

---

# 7. WHAT EXISTS vs WHAT'S DESIGNED

For current build state, see **CLAUDE.md → Current Sprint** and the latest session notes.
For the phase plan, see **Roadmap**.
For the deep design of systems not yet built (factions, jobs, families, police, holidays, save, settings, player experience, pop-ups, Chronicle, audio), see **GDD_REFERENCE §8 onward**.
