
# MegaBlock 16 — Event Design Bible
*Living document. The reference for designing, writing, and implementing all events.*
*Last updated: Architecture Planning Meeting, Session 3-4*

---

## How To Use This Document

This is the manual for creating content — events, sequences, actions, and storybook text. Every time you design a new event (whether in a brainstorm chat, an Event Design Chat, or a dev session), refer here first.

**For Event Design Chat sessions:** upload this document alongside the GDD and Architecture Reference. The chat uses this as its primary reference for what's possible and what format to output.

**For dev sessions:** refer here when implementing events in `events.gd` and `actions.gd`. The data shapes here are authoritative.

---

## How To Edit This Document

**When to update:**
- A new condition key is added (add it to Section 5 — Condition Keys)
- A new action function is written (add it to Section 6 — Action Functions)
- A new filter key is added to target resolution (add it to Section 3)
- A new event category is established (add it to Section 7)
- A naming convention changes (update Section 2)
- A new storybook template pattern is discovered that works well (add to Section 8)

**How to update:**
Open an Event Design Chat or a brainstorm chat, paste the relevant section, say "add X to this section," paste the result back into this document. Don't rewrite the whole document — surgical edits only.

**What NOT to put here:**
Actual event definitions (those live in `events.gd`). Specific event ideas (those live in the Starter Event List). Balance numbers (those get tuned in playtesting). This document is structure and rules, not content.

---

# SECTION 1 — THE EVENT SYSTEM

## What Is An Event?

An event is one beat of simulation. A character does something, something changes in the world, and the story advances. Events are the atoms of gameplay.

Events are not animations, not scripted sequences, not authored stories. They are probabilistic outcomes that fire when conditions are met, produce state changes, and write to the storybook. Stories emerge from events chaining together over time.

## What Makes A Good Event?

**Good events are:**
- Specific enough to produce interesting storybook text
- General enough to fire for many characters in many situations
- Readable — the outcome is understandable from the name alone
- Connected — they produce conditions that other events can build on

**Bad events are:**
- Too vague ("CHARACTER_DOES_SOMETHING")
- Too specific to ever fire ("MARCUS_SPECIFICALLY_GETS_ANGRY_AT_JESS")
- Isolated — nothing can follow from them
- Redundant — duplicating an existing event with only cosmetic differences

## Event vs Sequence

An **event** is a single beat. It fires, changes state, writes one storybook entry, done.

A **sequence** is a multi-beat locked activity. Both (or all) participants are locked for the duration. Each beat has its own outcomes and storybook text. Branching is possible (pool game winner/loser diverge at beat 3).

Use a sequence when:
- The activity has clear phases (setup → middle → resolution)
- Two or more characters need to stay co-located for multiple beats
- The outcome should feel earned (a conversation that escalates, a game with a winner)

Use an event when:
- It's a single moment
- Only one character needs to be locked
- The outcome is immediate

---

# SECTION 2 — NAMING CONVENTIONS

## Event IDs

ALL_CAPS_SNAKE_CASE. Always. No exceptions.

```
GOOD:  PLAY_POOL, ASK_OUT, FORM_GANG, WITNESS_FIGHT, COMFORT_CRYING_BABY
BAD:   playPool, PlayPool, play_pool, PLAYPOOL
```

**Naming pattern:** `[VERB]_[OBJECT/TARGET]` or `[VERB]_[CONTEXT]`

```
VISIT_BAR                   → character visits the bar
ASK_OUT                     → character asks another out
WITNESS_ARGUMENT            → character witnesses two others arguing
COMFORT_FRIEND              → character comforts a friend
BREAK_POOL_CUE              → character breaks the pool cue
FORM_GANG                   → character founds a gang
RIOT_BREAKS_OUT             → building-scope riot event
```

For building-scope events, the subject is the building, not a character:
```
POWER_OUTAGE, ELEVATOR_BREAKDOWN, RIOT_BREAKS_OUT, FESTIVAL_BEGINS
```

## Action Function IDs

snake_case. Match the event name closely.

```
Event:  PLAY_POOL
Action: play_pool

Event:  ASK_OUT
Action: ask_out

Event:  FORM_GANG
Action: form_gang
```

## Sequence IDs

ALL_CAPS_SNAKE_CASE with _SEQ suffix.

```
POOL_GAME_SEQ, ARGUMENT_SEQ, DATE_SEQ, NEGOTIATION_SEQ
```

## Storybook Template Variables

```
{name}          → actor character's display name
{target}        → target character's display name
{item}          → item name
{room}          → room display name
{faction}       → faction display name
{film}          → film title
{bond_tier}     → relationship tier label
```

---

# SECTION 3 — FULL EVENT DATA SHAPE

Every event in `events.gd` follows this structure. Fields marked (optional) can be omitted.

```gdscript
"EVENT_ID": {

    # ── SCOPE ─────────────────────────────────────────────────
    "scope": "character",       # "character" | "building"
                                # character = runs per-character in tick loop
                                # building = checked by Architect once per tick

    # ── TRIGGER MODE ──────────────────────────────────────────
    "trigger_mode": "rolled",   # "rolled" | "auto_fire"
                                # rolled = weighted random (default)
                                # auto_fire = fires whenever requirements met
                                #             (still needs Architect approval)

    "priority": 50,             # (optional, auto_fire only) 0-100
                                # higher = checked first when multiple auto_fires
                                # match on same tick

    "bypass_architect": false,  # (optional) true = always fires, no Architect
                                # gate. Only for calendar events (birthdays etc)

    # ── BASE WEIGHT ────────────────────────────────────────────
    "base_weight": 10,          # Starting probability weight before modifiers.
                                # Minor events: 5-15, Moderate: 8-20, Major: 1-5
                                # Rare: 0.5-2, Auto-fire: irrelevant

    # ── REQUIREMENTS ───────────────────────────────────────────
    "requirements": {
        # See Section 5 for all condition keys.
        # All requirements must be true for the event to be eligible.
        "stats_above": {"energy": 30, "boredom": 40},
        "has_trait": ["SOCIAL"],
        "in_room": ["bar", "cafe"],
        "relationship_tier_at_least": "FRIEND"
    },

    # ── WEIGHT MODIFIERS ───────────────────────────────────────
    "weight_modifiers": [
        # Each modifier multiplies base_weight when its conditions are true.
        # Multiple modifiers stack multiplicatively.
        # Partial matches: only the matched modifier applies.
        {
            "condition": {"has_trait": ["FLIRTATIOUS"]},
            "multiply": 2.0
        },
        {
            "condition": {"stats_above": {"happiness": 70}},
            "multiply": 1.5
        },
        {
            "condition": {"in_season": "summer", "season_intensity_above": 10},
            "multiply": 1.8
        },
        {
            "condition": {"has_targeted_feeling": "FURIOUS",
                         "at_filter": "target"},
            "multiply": 3.0
        }
    ],

    # ── TARGET RESOLUTION ──────────────────────────────────────
    "target_resolution": {
        "type": "character",    # "character" | "interactable" | "memory" |
                                # "self" | "room" | "none"

        "filter": "same_room",  # highest_affection, lowest_affection,
                                # recent_interaction, same_room, random_known,
                                # grudge_holder, self, none, closest,
                                # shared_memory

        "scope": "same_room",   # "same_room" | "building" | "known"
                                # limits which characters/objects are candidates

        "exclude_robots": false # (optional) true = robots never selected
                                # use for romance, gossip, deep conversation
    },

    # ── CONTEXT FRAMING ────────────────────────────────────────
    # Option A: declarative (most events)
    "context_framing": {
        "verb": "challenges",
        "location": "current_room",
        "item": "pool_cue"
    },

    # Option B: resolver function (complex context)
    "context_resolver": "resolve_pool_challenge",
    # (function lives in context.gd)

    # ── ACTION ─────────────────────────────────────────────────
    "call_action": "play_pool",
    # (function lives in actions.gd)
    # Returns: DONE | REPEAT | LOCK_SEQUENCE

    # ── OUTCOMES ───────────────────────────────────────────────
    "outcomes": {
        # Applied to actor character
        "stats": {
            "stress": -10,
            "happiness": +15,
            "boredom": -20
        },

        # Applied to target character (if target_resolution has a character)
        "target_stats": {
            "happiness": +5
        },

        # Feelings pushed onto actor
        "feelings": ["HAPPY", "CONFIDENT"],

        # Feelings pushed onto target
        "target_feelings": ["FLIRTY"],

        # Targeted feeling pushed onto actor, directed at target
        "targeted_feeling": {
            "feeling": "INFATUATED_WITH",
            "target": "target_id"
        },

        # Faction sentiment delta on actor
        "faction_sentiment": {
            "police": -20
        },

        # Relationship delta between actor and target
        "relationship_delta": {
            "bond": +8,
            "trust": +5
        },

        # Move actor to a different room
        "move_to": "bar",

        # Add item to actor's inventory
        "grant_item": "pool_trophy",

        # Spawn interactable in current room
        "spawn_interactable": "broken_pool_cue",

        # Set/clear persistent states
        "set_persistent_state": "BANNED_FROM_BAR",
        "clear_persistent_state": "ON_PAROLE",

        # Open/close a story thread
        "open_thread": "RIVALRY_BREWING",
        "close_thread": "RIVALRY_BREWING"
    },

    # ── PLAYER POP-UP ──────────────────────────────────────────
    "player_choice": false,     # (optional) true = PLAYER_GATE fires if actor
                                # is player character. Pushes to Decisions queue.

    "choices": [                # (optional, only if player_choice: true)
        {
            "label": "Accept warmly",
            "outcome_key": "accept_warm",
            "tone": "warm"
        },
        {
            "label": "Accept nervously",
            "outcome_key": "accept_nervous",
            "tone": "neutral"
        },
        {
            "label": "Decline",
            "outcome_key": "decline",
            "tone": "cold"
        }
    ],

    "auto_resolve": "decline",  # (optional) which choice fires on timer expiry

    # ── STORYBOOK ──────────────────────────────────────────────
    "ticker_worthy": false,     # (optional) true = appears in news ticker
                                # Use sparingly. Major/dramatic events only.

    "magnitude": "minor",       # "minor" | "moderate" | "major" | "huge"
                                # Affects Architect tracking, memorable flagging,
                                # grief propagation weight

    "storybook_templates": [
        # 2-4 variants. Same event, different narrative angle.
        # Rotated based on times_recalled and context.
        "{name} challenged {target} to a game of pool.",
        "{name} and {target} squared off at the pool table.",
        "It was {name} against {target}. The pool table was the battleground.",
        "{target} didn't know what they were getting into when {name} picked up the cue."
    ],

    # ── AUDIO ──────────────────────────────────────────────────
    "sound": "pool_cue_rack",   # (optional) key in Audio autoload config

    # ── OCCASION ───────────────────────────────────────────────
    "occasion_type": "holiday", # (optional) "holiday" | "festival" | "gathering"

    "calendar_trigger": {       # (optional) fires on specific calendar date
        "month": 3,
        "day": 5
    },
    # OR: "calendar_trigger": "birthday"   (fires on character's birth date)

    # ── BUILDING-SCOPE EXTRAS ──────────────────────────────────
    # (building scope events only)
    "global_weight_mods": {     # Applied building-wide while event is active
        "social_events": 1.8,
        "violent_events": 0.3
    },
    "duration_days": 1,         # How long the global mods stay active
    "venue_room": "park"        # Strong intent pull toward this room during event
}
```

---

# SECTION 4 — SEQUENCE DATA SHAPE

```gdscript
"SEQUENCE_ID": {
    "participants": 2,          # How many characters are locked (usually 2)
    "roles": ["initiator", "responder"],

    "beats": [
        {
            "beat_id": 0,
            "description": "Setup — initiator racks the balls",
            "actor_role": "initiator",
            "call_action": "rack_pool_balls",
            "outcomes": { "stats": {"boredom": -5} },
            "storybook_templates": [
                "{name} racked the balls. {target} watched."
            ],
            "sound": "pool_rack",
            "next_beat": 1      # fixed progression
        },
        {
            "beat_id": 1,
            "description": "Play — weighted roll for winner",
            "actor_role": "both",
            "call_action": "play_pool_round",
            "weighted_outcomes": [
                {
                    "weight": 50,
                    "outcome_key": "initiator_wins",
                    "next_beat": 2
                },
                {
                    "weight": 50,
                    "outcome_key": "responder_wins",
                    "next_beat": 3
                }
            ],
            "weight_modifiers": [
                {
                    "condition": {"actor_has_trait": ["COMPETITIVE"]},
                    "outcome": "initiator_wins",
                    "multiply": 1.5
                }
            ]
        },
        {
            "beat_id": 2,
            "description": "Initiator wins — reaction",
            "actor_role": "initiator",
            "call_action": "pool_victory",
            "outcomes": {
                "stats": {"happiness": +20, "boredom": -30},
                "target_stats": {"happiness": -5},
                "feelings": ["COCKY"],
                "target_feelings": ["FRUSTRATED"],
                "relationship_delta": {"bond": +5, "rivalry": +3}
            },
            "storybook_templates": [
                "{name} won. They tried not to look too smug about it.",
                "{target} lost to {name} at pool. Again."
            ],
            "next_beat": "END"
        },
        {
            "beat_id": 3,
            "description": "Responder wins — reaction",
            "actor_role": "responder",
            "call_action": "pool_victory",
            "outcomes": {
                "stats": {"happiness": +20},
                "target_stats": {"happiness": -5},
                "feelings": ["COCKY"],
                "target_feelings": ["FRUSTRATED"],
                "relationship_delta": {"bond": +5, "rivalry": +3}
            },
            "storybook_templates": [
                "{name} beat {target} at pool. {target} didn't take it well.",
                "{name} won. {target} put the cue down too hard."
            ],
            "next_beat": "END"
        }
    ]
}
```

---

# SECTION 5 — CONDITION KEYS

Used in both `requirements` and `weight_modifiers` across all event definitions. All keys work in both contexts unless marked (requirements only) or (weight only).

## Stat Conditions

```
"stats_above": {"stat_name": value}     both actor's stat > value
"stats_below": {"stat_name": value}     both actor's stat < value
"target_stats_above": {"stat": value}   target's stat > value (weight only)
"target_stats_below": {"stat": value}   target's stat < value (weight only)
```

## State & Trait Conditions

```
"has_state": ["STATE_NAME"]             actor has this stat-derived state
"has_persistent_state": ["STATE"]       actor has this persistent state
"not_has_persistent_state": ["STATE"]   actor does NOT have this state
"has_trait": ["TRAIT_NAME"]             actor has this trait
"not_has_trait": ["TRAIT_NAME"]         actor does NOT have this trait
"target_has_trait": ["TRAIT"]           target has this trait (weight only)
"actor_has_trait": ["TRAIT"]            same as has_trait (sequence contexts)
```

## Feeling Conditions

```
"has_feeling": ["FEELING_NAME"]         actor currently has this feeling
"has_targeted_feeling": "FEELING"       actor has this feeling, any target
"has_targeted_feeling": "FEELING",
"at_filter": "target"                   actor has this feeling directed at target
"not_has_feeling": ["FEELING"]          actor does NOT have this feeling
```

## Location Conditions

```
"in_room": ["room_type"]                actor is in one of these room types
"not_in_room": ["room_type"]            actor is NOT in these room types
"in_home_room": true                    actor is in their own apartment
"not_in_home_room": true                actor is NOT in their apartment
"other_character_in_room": true         at least one other character present
"target_in_same_room": true             target is in same room as actor
"in_room_program": "PROGRAM_KEY"        room is currently running this program
"is_homeless": true/false               actor is/isn't homeless
```

## Relationship Conditions

```
"relationship_bond_above": value                bond score > value
"relationship_bond_below": value                bond score < value
"relationship_tier_at_least": "TIER_NAME"       relationship >= this tier
"relationship_tier_at_most": "TIER_NAME"        relationship <= this tier
"relationship_familiarity_above": value         familiarity > value
"has_directional_feeling": "FEELING"            actor has directional feeling
                                                toward target
"no_existing_relationship": true                first meeting
"is_partnered": true/false                      actor is/isn't in PARTNER+ tier
```

## Time Conditions

```
"time_of_day": ["night","evening","day","morning"]
"day_of_week": [1,2,3,4,5]             1=Day1, 5=Restday
"in_season": "summer"                  "summer"|"winter"|"neutral"
"season_intensity_above": value        season intensity curve value > threshold
"in_season_and_intensity_above":       combined shorthand
  {"season": "summer", "intensity": 10}
```

## Inventory & Item Conditions

```
"has_item": ["item_id"]                 actor has this item (any slot)
"has_item_in_hand": ["item_id"]         actor currently holding this item
"not_has_item": ["item_id"]             actor does NOT have this item
"target_has_item": ["item_id"]          target has this item
"room_has_interactable": ["id"]         room contains this interactable type
"room_interactable_state": {"id":"state"}  interactable is in this state
```

## Social & Faction Conditions

```
"faction_sentiment_above": {"faction": value}
"faction_sentiment_below": {"faction": value}
"in_faction": ["faction_id"]            actor is a member of this faction
"not_in_faction": ["faction_id"]        actor is NOT a member
"not_in_faction_type": "gang"           actor is not in any gang
"target_in_faction": ["faction_id"]     target is a member
"characters_with_faction_sentiment_below":
  {"faction": "police", "threshold": -50, "min_count": 4, "in_same_room": true}
```

## Family Conditions

```
"has_child": true/false                 actor has living children
"has_child_with_state": "UNSETTLED"     actor's child has this state
"is_parent_of_target": true             actor is a parent of target character
"target_is_parent_of_actor": true       target is a parent of actor
"has_partner": true/false               actor has a PARTNER or MARRIED tier
```

## Job & Economy Conditions

```
"is_employed": true/false
"job_is": ["bartender","detective"]     actor has this specific job
"job_satisfaction_above": value
"job_satisfaction_below": value
"cash_above": value
"cash_below": value
```

## Life Stage Conditions

```
"life_stage_is": ["Adult","Teen"]
"life_stage_at_least": "Teen"
"age_above": value                      internal age > value
"age_below": value                      internal age < value
```

## Building & Architect Conditions

```
"building_mood_is": "quiet"             "quiet"|"normal"|"chaotic"
"active_thread_exists": "thread_key"    story thread is currently open
"no_active_thread_of_type": "thread"    no matching thread open
"building_population_above": value
"building_homeless_count_above": value
"days_since_major_event_above": value
```

---

# SECTION 6 — ACTION FUNCTIONS

Action functions live in `actions.gd`. Each event's `call_action` field points to one. The function receives `(actor: CharData, target, args: Dictionary)` and returns `DONE`, `REPEAT`, or `LOCK_SEQUENCE`.

## Current Action Functions (Starter Set)

Add new functions here when they're written.

```
# SOLO
think_about(actor, target, args)            → actor recalls a memory
wander_to_room(actor, target, args)         → move to a different room
rest(actor, target, args)                   → reduce stress/boredom
sleep(actor, target, args)                  → full sleep cycle intent
go_home(actor, target, args)                → intent to return to apartment

# SOCIAL
greet(actor, target, args)                  → first-contact interaction
chat(actor, target, args)                   → general conversation
argue(actor, target, args)                  → heated exchange
compliment(actor, target, args)             → positive comment
insult(actor, target, args)                 → negative comment
gossip(actor, target, args)                 → share short-term memory
comfort(actor, target, args)                → emotional support
flirt(actor, target, args)                  → romantic advance
ask_out(actor, target, args)                → formal romantic invitation
wish_happy_birthday(actor, target, args)    → birthday greeting

# OBJECT
use_interactable(actor, target, args)       → generic object use
admire_interactable(actor, target, args)    → aesthetic appreciation
steal_item(actor, target, args)             → ownership transfer
break_item(actor, target, args)             → break + spawn broken variant
gift_item(actor, target, args)              → transfer with scoring
throw_item(actor, target, args)             → projectile with target

# GANG / FACTION
form_gang(actor, target, args)              → spawn Faction resource
join_faction(actor, target, args)           → add to faction.members
show_faction_badge(actor, target, args)     → social display

# POLICE
file_report(actor, target, args)            → open case in Police
resist_arrest(actor, target, args)          → escalation roll

# BABY
settle_baby(actor, target, args)            → place baby in safe spot
comfort_crying_baby(actor, target, args)    → reduce baby cry aura
change_diaper(actor, target, args)          → spawn full_diaper item
show_off_baby(actor, target, args)          → social event with baby

# MANAGEMENT
apply_for_job(actor, target, args)          → file application with Jobs
quit_job(actor, target, args)               → remove from shift, robot fills
pay_rent(actor, target, args)               → cash deduction, Mayor records
```

## Action Return Values

```
DONE            → character free next tick, normal pipeline resumes
REPEAT          → same event fires again next tick (tracks consecutive count,
                   pushes feelings at thresholds e.g. REPEAT × 5 = BORED_OF_IT)
LOCK_SEQUENCE   → start multi-beat sequence, both participants locked
                   pass sequence_id in args
```

---

# SECTION 7 — EVENT CATEGORIES

Use these categories consistently for weight modifier conditions, news ticker colour-coding, and Architect tracking.

```
social          → greeting, chatting, arguing, gossiping
romantic        → flirting, asking out, dating, breakup, marriage
violence        → fights, assault, threats, murder
crime           → theft, dealing, gang events, bribery
police          → reporting, investigating, arresting
death           → dying, witnessing death, funeral
family          → parenting, baby events, inheritance
comedy          → accidents, absurd outcomes, backfires
work            → job events, shift events, hiring, quitting
building        → power outage, elevator, festivals, rent
management      → Mayor decisions, Strata deployment, Police cases
gang            → formation, recruitment, rivalry, violence
homeless        → sleeping rough, begging, busking, survival
health          → illness, injury, recovery
psychology      → thinking, obsessing, introspection, spiral
object          → using, breaking, gifting, stealing interactables
seasonal        → weather-influenced events, seasonal activities
calendar        → birthdays, holidays, festivals
```

---

# SECTION 8 — STORYBOOK TEMPLATE GUIDE

Storybook text is the player's window into what happened. Write it like a novelist, not a log file.

## The Four Template Slots

Each event should have 2-4 variants. They rotate based on context and `times_recalled`.

**Slot 1 (default):** clean, descriptive, third-person. "Sara asked Dylan out."
**Slot 2 (familiar):** slightly more editorial. "Sara finally asked Dylan out."
**Slot 3 (repeated):** pattern acknowledgement. Triggered when `times_recalled > 3`. "It wasn't the first time Sara had asked Dylan out."
**Slot 4 (ironic/sardonic, optional):** tonal contrast. "Dylan said yes. Sara looked surprised."

## Writing Rules

**Use character names, not pronouns, in templates.** Pronouns get confusing when reading multiple characters' storybooks.

```
GOOD: "{name} told {target} something they'd never told anyone."
BAD:  "They told them something important."
```

**Write for the reader who missed it.** The Chronicle player might be reading this 40 in-game years later. Context matters.

**Match tone to magnitude:**

```
Minor (base weight 10-15):
  "{name} and {target} had a drink together."
  Flat. Unremarkable. That's the point.

Moderate (base weight 5-10):
  "{name} and {target} ended up talking for hours.
   Somehow it felt important."
  A little lift. Something shifted.

Major (base weight 1-5):
  "{name} asked {target} to leave and never come back.
   {target} did exactly that."
  Weight it. Make it land.

Huge (rare):
  "{name} pulled the trigger.
   The bar went quiet.
   Nobody moved for a long time."
  Sparse. Let the event breathe.
```

**The "times_recalled" pattern** fires automatically when a character thinks about a memory repeatedly:

```
times_recalled 1-2:  normal template
times_recalled 3-5:  "Again, {name} found themselves thinking about {target}."
times_recalled 6+:   "It had become something of a ritual."
```

**Avoid:** passive voice, event log phrasing, "Character A performed action B on Character C."

**Aim for:** specificity, implication, tiny observed details that feel real.

---

# SECTION 9 — AUTO-FIRE EVENTS GUIDE

Auto-fire events skip the weighted roll when their requirements are met. Use sparingly — they should represent rare, significant moments where the conditions took real simulation effort to create.

## When To Use Auto-Fire

Use `trigger_mode: "auto_fire"` when:
- Requirements are difficult and specific (4+ characters co-located with shared negative sentiment)
- The moment should feel inevitable once the conditions arrive (you can't have a riot condition and NOT have a riot)
- The event would almost certainly lose a weighted roll against minor events despite being more dramatically important

## When NOT To Use Auto-Fire

Don't use it for:
- Common events (they'd fire constantly)
- Events where probability is the point (crime sometimes succeeds, sometimes doesn't)
- Events that can be triggered intentionally by the Architect (let the Architect boost the weight instead)

## Auto-Fire Event Checklist

Before marking any event as auto_fire:
- [ ] Requirements are complex (at least 3 conditions, at least one is rare)
- [ ] Losing a weighted roll would feel wrong ("the conditions were perfect but nothing happened")
- [ ] The event has a meaningful cooldown to prevent continuous re-firing
- [ ] The Architect can still suppress it (chaotic_auto_fire_suppression applies)
- [ ] It has a priority value (0-100) for when multiple auto-fires compete

---

# SECTION 10 — PLAYER CHOICE EVENTS GUIDE

Events with `player_choice: true` surface a pop-up when the actor is the player character.

## Rules For Player Choice Events

**Choices must match actual event outcomes.** Don't write pop-up-specific choices. The player sees the same options any NPC would roll.

**Maximum 3 choices.** Always include a "safe" option that produces a neutral/minor outcome.

**Always set auto_resolve.** The timer-expiry choice should be the safest/most passive option. Characters should be consistent even when the player is AFK.

**Tone is its own outcome modifier.** "warm," "neutral," "cold" tones produce different relationship deltas even when the base outcome is the same. This is the system's quiet power.

## Events That Always Get Player Choice

```
ASK_OUT, RESPOND_TO_ASK_OUT
PROPOSE, RESPOND_TO_PROPOSAL
QUIT_JOB, APPLY_FOR_JOB
RESPOND_TO_CONFRONTATION
REPORT_TO_POLICE (player witnessed crime)
INTERVENE_IN_FIGHT (player witnesses)
```

## Events That Never Get Player Choice

```
All minor social events (GREET, CHAT, THINK_ABOUT)
All events where another character is the actor
Any event with a magnitude of "minor"
```

---

# SECTION 11 — COMMON DESIGN PITFALLS

**The infinite loop** — an event's outcome creates the conditions for the same event to fire again immediately. Always check that outcomes don't instantly re-trigger the same event. Use cooldowns.

**The orphan event** — an event with requirements so specific it almost never fires. Check your requirements — if it needs 4 conditions all above 70, it probably fires 0 times in a 100-day sim run.

**The weight trap** — base weight of 1 with a ×10 modifier. At base conditions it's invisible; with the modifier it dominates. This looks like emergent behaviour but is actually brittle design. Keep base weights in range, keep modifiers modest (×0.3 to ×3.0 is the safe zone for most events).

**Redundant events** — before writing a new event, check if an existing one with a weight modifier would achieve the same result. Fewer events with more modifiers is cleaner than many near-identical events.

**Outcome overreach** — an event that changes 6 stats, pushes 4 feelings, modifies 3 relationships, and moves a character to another room. Pick the 2-3 outcomes that matter most. Less is more. The sim chains events together — let the next event carry the weight.

**Missing the storybook** — every event fires but nothing interesting shows up in the Chronicle. This usually means storybook_templates are too generic. Specificity is what makes moments memorable.

---

# APPENDIX A — QUICK REFERENCE

## Event Magnitude Guide

```
minor    → daily life texture (chat, admire, wander, rest)
moderate → meaningful moments (argument, flirt, gift, steal)
major    → story beats (ask_out, quit_job, form_gang, witness_murder)
huge     → building-defining moments (murder, riot, death, major revelation)
```

## Base Weight Guide

```
minor events:    8-20
moderate events: 5-12
major events:    1-5
huge events:     0.5-2
auto_fire:       irrelevant (fires on conditions, not weight)
```

## Modifier Safe Zone

```
Suppress:   ×0.1 to ×0.5
Neutral:    ×0.8 to ×1.2
Boost:      ×1.5 to ×3.0
Strong:     ×3.0 to ×5.0  (use rarely)
```

## Ticker Worthy Guide

Mark ticker_worthy: true for events that a watching player would notice and care about. Rough guide: any major or huge event that involves a character the player has interacted with, or any building-scope event.

Do NOT mark ticker_worthy for: minor events, repetitive events (chat, wander), events the player just interacted with via pop-up (they already know).