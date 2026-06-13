# MegaBlock 16 — GDD Reference
*Exhaustive design detail. Load only when working in the relevant area.*
*Overviews and principles live in GDD_CORE. Codebase structure lives in Architecture Reference.*

---

# 1. THE BUILDING

MegaBlock 16 is a freshly-built megabuilding on the edge of the city. Self-contained, self-governing. Viewed in 2D cross-section; rooms are bespoke 3D SubViewport scenes.

Each floor has one full-width hallway. Rooms sit on the hallway with side doors and full-wall windows so the player can see in. Characters enter/leave via doors — never through other rooms.

- 22 levels above ground (F00–F20 + Rooftop), 2 underground (-01 Power Plant, -02 Sewer).
- F00 = lobby/entry. Management = F11 (vertical midpoint, "the heart").
- Elevators: EL1 & EL2 on the left (full height, -02 to Rooftop). EL3 on the right (F01–F20 only — no underground, F00, or Rooftop).
- Staircases mid-floor, architecturally haphazard, in runs of 2–3 floors only.

## Population & Occupancy

The Mayor approves new move-ins only when an apartment is vacant. **Hard cap: 35 residents** (one per apartment; couples/families share). Homeless characters are the exception — they enter but hold no apartment. Building starts nearly empty and fills over play time.

> Note: the elevator-pitch language elsewhere has said "45 residents." The locked design cap is 35 apartments. 45 is the eventual stress-test/scale target (Roadmap Phase 16), achievable only counting homeless above the apartment cap. Treat 35 as canonical for apartments.

## Building Progression

Managed by the Mayor with a move-in schedule:
```
Day 0:    4–6 characters + player, essential roles robot-filled
Day 14:   first wave (+2)
Day 30:   +3, first robot replaced by a human worker
Day 60:   continued growth
Day 120+: approaching full capacity
```
Arc: Day 1 cold/automated/lonely → Day 200 messy/human/alive. Each "robot replaced by human" is a major storybook moment. Characters never voluntarily move out — they stay until death. Eviction → homeless (still in building).

---

# 2. ROOM TYPES

All rooms exist from Day 0.

**Communal:** Bar, Cafe, Library, Cinema, Shop (Grocery), Shop (Decoration), Nightclub, Gym, Arcade, Rooftop, Park, VR Pods, Casino.

**Dedicated floors:**
- **Hospital** — healing and births only. Robot-staffed; humans can be doctors/nurses. Ambulance robots retrieve injured/dying characters.
- **School** — children attend mornings. Human teacher if filled, robot fallback. Unlocked by population (needs ≥1 child).
- **Park** — full floor. Indoor trees, lawn, festival stage. Peaceful by day, criminal-adjacent at night.

**Residential:** four apartment models — single, couple, couple_with_child, single_with_child. Model changes on life events (marriage, baby). Rent scales by model. Decorations migrate on model swap; items in now-missing spots go to apartment_storage.
- **APT 18A** (adjacent to Nightclub) flagged for unique event DISTURBED_BY_MUSIC.

**Management Floor (F11):** robot workstations (Mayor, Strata, Jobs, etc.). Status screens reflect building state. Police Station shares the floor and is accessible to characters. Detective office planned, parked.

**Underground:**
- **Power Plant (-01)** — generators powering the building, directly above the sewer. Engineers maintain; criminals may sabotage. Power outage = building-scope event. Mostly inaccessible.
- **Sewer (-02)** — criminal dealings, homeless sleep spots, body disposal. Not on standard pathfinding; needs specific intent to route.
- **Crematorium** — end-of-life processing, includes a small functional chapel (no religious content) for funerals. Funeral events use `bypass_architect: true`.

## Room Schedules

Recurring programs drive event eligibility. Defined per-room in RoomCatalogue via `every_n_days` or `days_of_week`. When the scheduled hour hits, the room enters that program state and related events become eligible.

**Weekly cinema rotation:** one film per week, 18 films/year, multiple daily showings. Characters' `favorite_genre`/`favorite_movie` raise attendance likelihood.

Characters discover schedules via witnessing, gossip, or boredom-scanning. They return to liked ones via program impressions (same dictionary as object impressions).

## Working Building Layout (subject to revision)

```
ROF  ROOFTOP — open air, full width
F20  CASINO — full width
F19  APT 19A | APT 19B | APT 19C
F18  APT 18A ★ [S] | NIGHTCLUB (lg)
F17  APT 17A | APT 17B | APT 17C
F16  APT 16A | GYM (lg) | APT 16B
F15  VR PODS (lg) [S] | APT 15A | APT 15B
F14  APT 14A [S] | APT 14B
F13  APT 13A [S] | ARCADE | APT 13B
F12  APT 12A | APT 12B | CINEMA (lg)
F11  MANAGEMENT (lg) | POLICE STATION
F10  HOSPITAL — full width
F09  APT 9A | APT 9B | APT 9C
F08  APT 8A [S] | LIBRARY (lg) | APT 8B
F07  DECO SHOP (lg) [S] | APT 7A | APT 7B
F06  PARK — full width
F05  APT 5A | SCHOOL (lg) | APT 5B
F04  APT 4A | APT 4B | CAFE (lg)
F03  APT 3A [S] | APT 3B | APT 3C
F02  APT 2A [S] | GROCERY (lg) | APT 2B
F01  BAR (lg) | APT 1A | APT 1B
F00  LOBBY — entry right side, ads, sparse, homeless
-01  POWER PLANT — narrow
-02  SEWER — narrow
[S] = staircase mid-floor. Stair runs: A(F02–03) B(F07–08) C(F13–15) D(F18–19)
★  = DISTURBED_BY_MUSIC apartment | (lg) = larger footprint
EL1/EL2 left full height | EL3 right F01–F20 only
```

---

# 3. GROCERIES, VR PODS

**Groceries:** abstract pooled int on CharData. Bought at the grocery store (+N per visit), consumed eating/cooking at home. No ingredient tracking — storybook text varies ("made something from what was left", "cooked a proper meal"). `groceries: 0` → must eat out.

**VR Pods:** happiness/stress booster with addiction risk. Simulation inside never shown — player sees a character lying absent in a pod. Duration locked (uninterruptible while under). `VR_ADDICT` persistent state → strong pull regardless of needs, deepening isolation. Grief mechanic (flagged for event design): bereaved characters may simulate a deceased loved one — can aid grief or deepen dependency. Isolation is mechanical, not flavour.

---

# 4. CHARACTERS (full)

## Identity fields
```
char_id, char_name, internal_age (hidden, drives life_stage),
life_stage (Baby/Child/Teen/Adult/Elderly), pronouns (they/she/he),
sexuality/preference (romantic tier eligibility),
favourite_color (clothing, wallpaper, lighting, UI accent),
interests (gate object/program impressions),
life_arch (genre-suggestive, time-phased weight set: romance/drama/neutral/wildcard/crime),
birth_month (1–6), birth_day (1–15), favorite_genre, favorite_movie
```

## Stats (16)
```
stress 0–100 (d20)        happiness 0–100 (d50)     health 0–100 (d80)
energy 0–100 (d80)        hunger 0–100 (d20, high=hungry)
boredom 0–100 (d10)       loneliness 0–100 (d30)    horniness 0–100 (d20)
need_for_toilet 0–100 (d0) grief 0–100 (d0)         global_reputation 0–100 (d50)
attractiveness 0–100 (d50) cash 0–999999 (d200)
criminal_inclination 0–100 (d5)  criminal_reputation 0–100 (d0)  addiction 0–100 (d0)
```
Inventory capacity is a visible stat: Normal / Full / Over-encumbered (speed penalty only at over-encumbered).

## Traits
```
FLIRTATIOUS, SHORT_TEMPERED, CHARMING, STUBBORN, OPTIMISTIC, PESSIMISTIC,
FUNNY, PARANOID, RECLUSIVE, GOSSIP, ROMANTIC, LONER, NOSY,
CRIMINAL_HEART, GAMBLER, VIOLENT, MANIPULATIVE, ADDICT_PRONE,
MOTIVATED, LAZY, INSOMNIAC, NEAT_FREAK, FORGETFUL,
HYPOCHONDRIAC, BIG_APPETITE, WEAK_BLADDER, HIGH_LIBIDO, SECRETIVE,
CORRUPT, BY_THE_BOOK
(+ evolution traits: ALCOHOLIC, RECOVERING_ALCOHOLIC, WELL_READ, BRAWLER,
 GOSSIP_EVOLVED, REGULAR — and hidden/preference traits added in build)
```
Weight modifiers only, never hard gates. Hidden traits rolled at generation, discovered through behaviour. Starter traits apply once at creation (backstory, visible in bio forever); permanent traits apply always.

## Feelings
```
Positive: HAPPY, ELATED, AFFECTIONATE, FLIRTY, CONFIDENT, INSPIRED,
          GRATEFUL, EXCITED, SATISFIED, AMOROUS
Negative: MISERABLE, HUMILIATED, FURIOUS, ANXIOUS, HEARTBROKEN,
          GRIEVING, BITTER, DISGUSTED, PARANOID_FEELING, EXHAUSTED_FEELING
Physical: WELL_FED, HUNGOVER, CRAVING, RELIEVED
Neutral:  CONTENT_FEELING
Sequence/social: FRUSTRATED, COCKY, COMPETITIVE, RECKLESS, AVOIDING (targeted)
```
Each active feeling carries `causes` (event_key, at_tick, summary; cap 4). Can be hidden (mechanics apply, no bubble) or targeted at a character.

## Life Stages & Death
```
Baby 0–2 (BabyData) | Child 2–8 | Teen 8–16 | Adult 16–35 | Elderly 35–40
```
Age hidden; UI shows stage. Player starts 16; generated start 18–35. Stage transitions are ticker-worthy.

**Death** causes: natural (age past 35), accident, illness (health 0), violence, overdose, starvation. On death: body → brief interactable, undertaker robot, CharData → GhostRecord, grief propagates by bond, memories auto-tagged, apartment inheritance, job vacancy → robot. Frequency ~1 per 15–30 days at full pop; Architect suppresses clustering of natural/illness only. Player death: 3-year grace (disableable), then 2-day gap, then creation reopens.

## Art Direction
RimWorld-adjacent pill body, billboard sprites. No legs; floating white-gloved hands (masc/fem variants). Same sprite in 2D and 3D. Expression via BubbleContainer feeling icons, 6 face swaps (neutral/happy/sad/angry/scared/lovestruck), body-colour tint for extremes, eyebrow overlay. Variety: 3 silhouettes × 8 skin tones × 10 hair styles × 6 hair colours × clothing (favourite_color) × 6 eye colours.

---

# 5. SIMULATION (full)

## Target Resolution
Five target types: character, interactable, memory, self, room. Filter keys: highest_affection, lowest_affection, recent_interaction, same_room, random_known, grudge_holder, self, none, closest, shared_memory, exclude_robots.

## Event Scope
- `"character"` — runs per-character in the tick loop.
- `"building"` — checked by the Architect once per tick (power outages, festivals, pandemics, elevator breakdowns).

## Sequences
Multi-beat, lock all participants. Each beat has its own outcomes, storybook, and branching (e.g. a pool game: setup → play → outcome with weighted winner/loser reactions).

---

# 6. THE ARCHITECT (full)

A **traffic controller, not a director.** Sits between eligibility check and weighted roll, applying global modifiers. Prevents boredom/chaos extremes without fighting emergence. Never fires events directly.

**Building mood** (daily, from rolling event log):
- Quiet (0 majors in 5 days) → boost majors ×1.5
- Normal → no modifier
- Chaotic (3+ majors in 3 days) → suppress majors ×0.4
All thresholds are `@export` vars on the Architect autoload (no separate config autoload).

**Character selection** (inject a major during quiet): roll scope (30% building / 70% character), build pool of characters with eligible majors, player ×1.5 weight, pick weighted-random, apply ×3.0 to their majors, let Sim roll. Pool-first — never "pick then check" (avoids infinite loops).

**Story threads:** auto-managed. Open when a major fires with no matching thread; close on resolution or after 5 idle days. Cap 5–7; at cap, suppress new majors but boost existing-thread continuations.

**Other:** building event scheduling, calendar event firing, death-clustering suppression (NATURAL/ILLNESS only, ×0.2 within 5 days), emotion-loop breaker (stuck feeling >3 days), occasion tracking, auto-fire approval gate.

---

# 7. RELATIONSHIPS (full)

## Tier bands
```
-100        MORTAL_ENEMY   |  +10..+19   ACQUAINTANCE
-80..-99    ENEMY          |  +20..+39   FRIENDLY
-60..-79    RIVAL          |  +40..+59   FRIEND
-40..-59    DISLIKED       |  +60..+74   CLOSE_FRIEND
-20..-39    UNFRIENDLY     |  +75..+84   BEST_FRIEND
-10..-19    COOL           |  +85..+94   ROMANTIC_INTEREST ★
-9..+9      NEUTRAL        |  +95..+97   PARTNER ★
                           |  +98..+99   DEEPLY_BONDED
                           |  +100       MARRIED ★
                           ★ = event-gated transition
```
Romantic tiers require formalising events (ASK_OUT, ASK_TO_GO_STEADY, PROPOSE), not just score. Reproduction needs bond > 20 only. Bond decay: -1 per 10 days without interaction (slower above BEST_FRIEND, none for MARRIED unless active damage). Familiarity never decays. Affairs emerge from parallel bond progression.

## Grief Propagation
Both 70+ → DEEP_GRIEF. Living 50+ → GRIEF. 30+ → MILD_SADNESS. <30 → none. Witnessed violent death → minimum GRIEF + TRAUMATISED regardless of bond.

---

# 8. MOVEMENT & PATHFINDING (full)

**Three layers:** Pathfinder (autoload — routes, blockages, elevator dispatch; knowledge-limited, blockages discovered on arrival, gossip writes known_blockages with expiry). MovementController (node — waypoints, tweens, speed, animations, arrival events). Movement types (Stats): walk 1.0×, run 2.0× (BURSTING/TERRIFIED/FURIOUS), skip 1.2× (ELATED), crawl 0.3×, sneak 0.7×, limp 0.6× (INJURED), shuffle 0.5×.

**Three-lane hallways:** Lane 0 (back) rightward, Lane 1 (middle) overtaking, Lane 2 (front) leftward. Blocked lanes from interactables; all three blocked = impassable.

**Elevators:** physical cars with state (idle/moving/doors_open/broken), managed by Pathfinder, lobby waiting zones per floor. Interior is a mini room context. Broken = world event + trapped sequence. Stairs always available, always slower, never break.

**Proximity-reactive:** fire for in-transit characters near another in a hallway. Light (nod/wave) doesn't interrupt; heavy (conversation) pauses transit, pushes intent, resumes after.

---

# 9. INVENTORY & INTERACTABLES (full)

**Inventory:** held_items (max 2, one/hand, visible), carried_items (backpack, hidden), equipped (hat/costume/faction_badge), apartment_items (placed, limited by spots), apartment_storage. Two-handed items use both slots. Encumbrance affects speed only at over-encumbered.

**Interactables:** InteractableData with tags, aura effects, interaction tags, ownership (building/communal/personal), state. Ownership transfers on theft; police only called if witnessed AND witness rolls CALL_POLICE. Auras opt-in (only populated aura_effects emit), capped per-stat (+5) and per-room (+12), personality sensitivity roll, ticked in occupied rooms only. Breaking: material-based broken texture, optional secondary spawn (glass → shards + spill), broadcast to nearby.

**Gifting:** transfer item; gift value from personality match (interests, favourite_color); both sides get relationship delta; receiver object_impression set to 10.

**Babies:** BabyData extends InteractableData. No stats/feelings/tick. Crying aura unattended, comforting aura when held. Witnesses events into a buffer (transfers at Child stage). Throwable (witnesses HORRIFIED). FULL_DIAPER interactable (throwable, weapon-usable). Converts to full CharData at Child with seed memories and partially inherited traits.

---

# 10. FACTIONS (full)

**Two types:** Institutional (police, management, robots, building — permanent; every character has a sentiment; membership by job) and Generated (gangs + homeless collective — runtime, can dissolve; Faction resource with procedural name, badge colour, accessory; gang cap 4–6 tunable).

**Faction sentiment:** dict on CharData, -100..+100. Shifts from witnessed events (see a cop beat a friend → police -30). Independent of membership — you can hate a faction you're in.

**Gangs:** FORM_GANG fires on high criminal_inclination + criminal_reputation. Procedural names (The Crimson Wolves, Neon Knives). Badge renders in equipped slot.

**Homeless faction:** single auto-managed collective, no cap. Auto-join when is_homeless true, auto-leave when false. Scrappy name pool (The Vent Crew, Sub-Level Strays).

**Riots:** RIOT_BREAKS_OUT auto-fire, requires 4+ characters in one room with police sentiment < -50. Architect gates, doesn't author.

---

# 11. MANAGEMENT & JOBS (full)

- **Mayor (robot):** progression/move-ins, apartment assignment + inheritance (partner → child → highest bond → vacant), monthly rent, eviction → homelessness, room open/close, holiday decoration dispatch, procedural holiday naming. Absorbs RealEstateAgent + GameProgression.
- **Strata (robot):** robot pool/deployment, elevator maintenance, decoration drones (visually distinct, don't witness), immediate vacancy fill.
- **Police:** witness-based only. Case filing, investigation (evidence over X days), arrest, jail timer. Dispatch: humans first, robots backup, everyone for riots. Detective role (INTERVIEW_SUSPECT, FOLLOW_LEAD, CRACK_CASE). CORRUPT (often lets slide) vs BY_THE_BOOK (always processes); robot cops always process. Courtroom/judge/prison parked.
- **Jobs:** shift coverage tables per room (required/robot_only/human_preferred). Daily human/robot matching. job_satisfaction 0–100; below 25 → QUIT_JOB eligible. Vending-machine fallback for low-drama rooms (cinema, shop). Homeless can be employed — the path back to housing.
- **Homelessness:** is_homeless true, home_room cleared, sleep in designated spots. Survival events (BUSK, BEG, STEAL, FIND_WORK). Path back: job → income → APPLY_FOR_APARTMENT.
- **Robot workers:** RobotData. Can witness, be insulted, be damaged. No inner life. Decommission → RobotGhostRecord. `exclude_robots: true` filter on romance/gossip/deep events.

---

# 12. PLAYER EXPERIENCE (full)

**Character creation:** name, pronouns, favourite colour; 3 visible traits (hidden rolled); life arch from vague descriptions (RANDOM option); age locked 16; watcher mode offered (locked post-creation, explicit warning).

**Two modes:** Character (player IS a resident — job, rent, relationships, pop-ups, death/transfer) and Watcher (no PC, pure observation, all auto-resolve, Chronicle still available).

**Pop-ups:** three diegetic voices — Architect (cryptic), Mayor (bureaucratic), Job Agent (transactional). Rules: one at a time (queue), always an auto-resolve timer, "Choose for me" everywhere, choices = actual event outcomes (no pop-up-only options), max 3 options, never >20% of screen, non-modal. Settings: pause all / pause major only / timer on all (recommended) / off; per-source toggles; timer slider. First-run tutorial pop-up then preference select.

**Player death:** 3-year grace (suppresses lethal rolls, disableable). If mid-major, resolve first. 2-day watch gap, then creation reopens.

**News ticker:** flagged (ticker_worthy) entries only, bottom (movable to top). Colour-coded: romance/pink, crime/red, death/purple, comedy/green, management/blue, Architect/gold. Single line, fades after 8s, stacks upward.

**Camera:** FREE (default), FOLLOW (click to lock), CINEMATIC (Architect major events), OVERVIEW (Tab). Smooth lerp; Escape → FREE.

**The Chronicle:** the curation tool. Browse any storybook, pin entries to named timelines, all roll up into "Life." Pinned entries never pruned. `times_recalled` flavour ("It had become something of a ritual"). Filter by character/event/day; thread click-through to multi-POV view.

**HUD:** clock, speed controls, active threads (clickable), selected-character panel.

---

# 13. AUDIO, SAVE, FAMILIES, HOLIDAYS, SETTINGS

**Audio:** positional via AudioStreamPlayer2D parented to body/interactable — Godot handles falloff from camera position/zoom (no manual zoom var). Room ambience via in-scene AudioStreamPlayer2D. Stings/music non-positional. Audio autoload holds config (keys→paths, bus, loop, category: action/ambience/music/ui/sting). Ships pre-alpha.

**Save:** Godot .tres. Per-character files in slot subfolders; WorldState bundle; SaveMeta per slot. Pre-save cleanup (prune storybooks, trim logs). Versioned migrations. Auto-save daily at 04:00 (3 rotating slots); manual (5 named slots). Target < 5MB. Switch to .res binary at ship.

**Families & reproduction:** both Adult, bond > 20, one has a home, building below cap, player gets a pop-up. PREGNANCY_BEGINS → 9 days, hidden then REALISE_PREGNANT, other parent via TELL_ABOUT_PREGNANCY. parent_ids/child_ids/sibling_ids on CharData; parental/filial bond as directional feelings. Orphan priority: other parent → highest bond w/ parental_bond → highest bond → robot ward (story thread opens). Parenting events: SETTLE_BABY, CHECK_ON_BABY, COMFORT_CRYING_BABY, PICK_UP_BABY, SHOW_OFF_BABY, CHANGE_DIAPER, PANIC_BABY_MISSING. Protective behaviour emergent from parental bond.

**Holidays & occasions (three tiers):** Holiday (calendar-fixed, building-wide, Architect weight package, decoration drones), Festival (calendar-fixed, large-venue, strong intent pull), Gathering (character-organised — party/wedding/trivia; invitations propagate via gossip). Mayor periodically proposes new holidays (3 procedural names, player picks). Birthdays trimmed for prototype (age-up + WISH_HAPPY_BIRTHDAY only).

**Settings:** Player-facing — speed (1x/2x/3x + Pause), accessibility (text_scale, high_contrast, pause_on_major_event), audio volumes, display, pop-ups, ticker. Dev-only (hidden) — sim_speed_multiplier, seconds_per_half_hour/tick, event_frequency, population_size, permadeath, player_grace_period. Debug — debug_print, F2 inspector, F3 force_event, show_auras/spots/zones/routes/relationship_scores/bond_tiers/intent_queues/memory_entries/impression_scores/encumbrance, log_all_rolls.

---

# 14. CONTENT PIPELINE & EVENT DATA SHAPE

**Scenario Design Toolkit** (Roadmap Phase 11.5): dedicated Claude chats — Event Design (plain English → structured event defs), Storybook Template (event ID + context → literary variants), Balance Review (logs → frequency analysis + tuning).

**Event data shape:**
```
"EVENT_NAME": {
  "scope": "character"|"building",
  "trigger_mode": "rolled"|"auto_fire",
  "priority": 0–100 (auto_fire only),
  "player_choice": bool,
  "ticker_worthy": bool,
  "bypass_architect": bool,
  "requirements": { condition keys },
  "weight_modifiers": [ entries ],
  "target_resolution": { type, filter, scope },
  "context_framing": { args } OR "context_resolver": "fn_name",
  "call_action": "fn_name",
  "outcomes": { stats, target_stats, feelings, move_to, faction_sentiment, relationship },
  "sound": "audio_key" (optional),
  "storybook_templates": [ variants with {name}, {target} ],
  "choices": [ { label, outcome_key, tone } ] (player_choice only),
  "auto_resolve": "outcome_key" (player_choice only),
  "occasion_type": "holiday"|"festival"|"gathering" (optional),
  "calendar_trigger": { month, day } or "birthday" (optional)
}
```

**Condition keys** (requirements + weight_modifiers):
```
stats_above, stats_below
has_state, has_feeling, has_trait, has_persistent_state
has_targeted_feeling (at_filter)
time_of_day, in_room, not_in_room, in_home_room, not_in_home_room
other_character_in_room
in_season, season_intensity_above
relationship_bond_above/below, relationship_tier_at_least/at_most
relationship_familiarity_above, has_directional_feeling
object_impression_above
faction_sentiment_below, characters_with_faction_sentiment_below (min_count, in_same_room)
has_child_with_state, not_in_faction_type
has_memory_tag, is_partnered, compatible_sexuality, no_existing_relationship
```
> Full authoring rules → Event Design Bible. Variable reference for storybook text → Context Template Guide.

---

# 15. PARKING LOT

Ideas acknowledged, not designed, not scheduled.

**Characters:** bespoke custom-sprite characters; player nudges (soft weighted influence); disorders/disabilities as special trait rolls; obsession (emergent via REPEAT); favourite room variable.

**Rooms:** pawn shop; tattoo parlour (art complexity — parked); boxing ring (folded into gym as a zone); detective office + noir mystery/clue-roll system (late phase).

**Systems:** phone/calling; store revenue tracking; full hiring/firing; faction/gang wars; cliques (non-criminal generated factions); leaving gangs + consequences; marriage/affairs/divorce chains; apartment store closure on low revenue.

**Content:** rare wild-events session; gangs/syndicates/betrayal; colourblind mode; minimap; camera shake on major events; particle states (steam, zzz, sweat, hearts); storybook visual recaps; player-created characters as NPCs in other saves.

**Management:** courtroom + robot judge; prison floor; full eviction appeal; character-owned businesses.

**Chronicle:** bookmark mechanic; shareable "Stories" format; "Building Stories" menu; visual timeline; story-generator marketing framing.

**Engine-level deferred (from session parking lots):** ForceEvent target/context picker (partially done); lane obstacle reroute (Phase 5+); elevator interior as mini-room event context; stairs as elevator fallback route.
