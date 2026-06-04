\# MegaBlock 16 — Decisions Log  
\*Living document. Add new entries at the top of each section when decisions are made.\*  
\*Format: Decision — Reason — Session\*  
\*Created: Architecture Planning Meeting, Session 3-4\*

\---

\#\# How To Use This Document

When you wonder "why is X shaped this way?" — check here first. Every significant architectural decision is logged with its reasoning. This stops settled questions getting relitigated and stops future-you from undoing something past-you thought hard about.

New decisions go at the TOP of the relevant section.

\---

\#\# Character Data

\*\*Groceries are an abstract pooled resource, not tracked by ingredient\*\* — groceries: int on CharData. Bought at the grocery store, consumed when eating/cooking at home. Player uses imagination for what's in the pool. Storybook text handles variety. Avoids ingredient-tracking complexity entirely.  
\*Room Design Session\*

\*\*CharData renamed from CharacterData\*\* — shorter, typed thousands of times, saves friction. Full rename pass in Item 19\.  
\*Architecture Meeting\*

\*\*CharData is the single source of truth for all character state\*\* — no secondary stores, no caching character data in other autoloads. Everything reads from CharData directly or via ID lookup.  
\*Architecture Meeting\*

\*\*Age is hidden from the player, life stage is shown\*\* — prevents players min-maxing age-based events. Life stage is the meaningful unit, not the raw number.  
\*Architecture Meeting\*

\*\*Player character starts at age 16\*\* — young adult, gives maximum possible lifespan in one playthrough, lets the player grow with the building.  
\*Architecture Meeting\*

\*\*Hidden traits are rolled at generation, not revealed\*\* — player discovers them through behaviour, same as real people. Visible trait pool gives 3 player choices.  
\*Architecture Meeting\*

\*\*favourite\_color drives clothing, apartment wallpaper, lighting, and UI accent\*\* — one choice, maximum personality expression for minimum UI complexity.  
\*Architecture Meeting\*

\*\*Inventory capacity is a visible stat with a UI bar\*\* — three states: Normal, Full, Over-encumbered (speed penalty only). Kept mechanical, not dramatic.  
\*Architecture Meeting\*

\*\*Traits are weight modifiers only, never hard gates\*\* — they nudge probability, never lock eligibility. Criminal events gate on stats (criminal\_inclination threshold), not traits. Keeps emergence possible.  
\*Architecture Meeting\*

\*\*Feelings can be hidden\*\* — all mechanical effects still apply, no UI bubble. Player infers from behaviour. Adds realism, rewards attention.  
\*Architecture Meeting\*

\*\*Coexisting traits are possible\*\* — ALCOHOLIC \+ RECOVERING\_ALCOHOLIC both present, recovery trait suppresses the other's weight modifiers. Allows character complexity and relapse mechanics.  
\*Architecture Meeting\*

\*\*Starter traits separate from permanent traits\*\* — starter traits apply once at creation (backstory), permanent traits apply always (behaviour). Both visible in character bio forever. Character history matters.  
\*Architecture Meeting (confirmed from earlier sessions)\*

\*\*RobotData extends CharData with minimal overrides\*\* — same architecture, same pipeline compatibility, near-zero fields populated. On decommission, RobotGhostRecord replaces it so memory references don't break. Avoids special-casing robots everywhere.  
\*Architecture Meeting\*

\*\*BabyData extends InteractableData\*\* — babies are smart interactables, not full characters. No stats, no feelings, no tick consumption. Witnesses events into a buffer that transfers to CharData at Child stage. Converts fully at the Child life stage transition.  
\*Architecture Meeting\*

\---

\#\# Simulation Pipeline

\*\*7-stage pipeline: ROLL → RESOLVE → FRAME → PLAYER\_GATE → ACT → EXECUTE → ECHO → CONTINUE\*\* — clean separation of concerns. Each stage has one job. PLAYER\_GATE inserts cleanly without touching any other stage for non-player characters.  
\*Architecture Meeting\*

\*\*PLAYER\_GATE only fires when actor is player character AND event has player\_choice: true\*\* — zero performance impact on 44 other characters. Most events don't have player\_choice set.  
\*Architecture Meeting\*

\*\*Auto-fire events still ask the Architect for permission\*\* — prevents riot stacking on riot, prevents dramatic auto-fires during already-chaotic periods. Calendar events bypass Architect via bypass\_architect: true (birthdays always happen).  
\*Architecture Meeting\*

\*\*trigger\_mode: "rolled" is the default\*\* — no migration needed for existing events. auto\_fire is opt-in, reserved for events with costly/rare requirements.  
\*Architecture Meeting\*

\*\*Proximity-reactive events in transit\*\* — light actions (nod, wave) don't interrupt transit. Heavy actions (conversation) pause transit, push to intent queue, resume after. Makes hallways feel alive without breaking routing.  
\*Architecture Meeting\*

\*\*Characters silent during transit\*\* — no events fire mid-movement except proximity-reactive. Prevents log spam, prevents event-in-hallway weirdness with room context.  
\*Architecture Meeting (confirmed from earlier sessions)\*

\*\*Characters locked during sequences\*\* — no other events fire while a sequence is active. Prevents overlap, keeps sequence beats coherent.  
\*Architecture Meeting (confirmed from earlier sessions)\*

\---

\#\# Memory

\*\*Long-term memory is flagged storybook entries, not a separate structure\*\* — reduces data duplication. memorable flag \+ memory\_tags \+ times\_recalled live on the storybook entry itself.  
\*Architecture Meeting\*

\*\*40-year rolling cap on general storybook\*\* — one full character lifespan of data. 50 memorable entry soft cap (most-recalled survive). Pinned entries (Chronicle) exempt from all pruning.  
\*Architecture Meeting\*

\*\*Object impressions and program impressions share one dictionary\*\* — same system, same scale, same thresholds. Program keys follow pattern \`program\_room\`. No new system needed.  
\*Architecture Meeting\*

\*\*Intent queue patience counter modified by traits\*\* — STUBBORN \= high patience, LAZY \= low. At zero, GIVE\_UP event fires. Non-clearable intents (biological needs) survive interrupts.  
\*Architecture Meeting\*

\---

\#\# Relationships

\*\*15-tier spectrum calculated from bond score\*\* — continuous score (-100 to \+100) maps to named tiers. Romantic tiers (ROMANTIC\_INTEREST, PARTNER, MARRIED) require formalising events, not just score threshold. Score is necessary but not sufficient.  
\*Architecture Meeting\*

\*\*Familiarity never decays\*\* — once you've met someone, you always remember them. Bond decays, familiarity doesn't. This is the realism choice.  
\*Architecture Meeting\*

\*\*Reproduction doesn't require partnership\*\* — bond\_above 20 is sufficient. One-night stands produce pregnancies. Partnerships emerge from relationship progression, not as a requirement for anything.  
\*Architecture Meeting\*

\*\*Characters never voluntarily move out\*\* — they stay until they die. Simplifies real estate dramatically. Eviction makes them homeless (in the building), not gone.  
\*Architecture Meeting\*

\*\*Grief propagates based on bond tier\*\* — both sides 70+ → DEEP\_GRIEF. 50+ → GRIEF. 30+ → MILD\_SADNESS. Below 30 → none. Witnessed violent death → minimum GRIEF \+ TRAUMATISED regardless of bond.  
\*Architecture Meeting\*

\*\*Inheritance order: partner first, then child, then highest bond, then vacant\*\* — mirrors emotional logic. Partner lived there. Child is next of kin. Highest bond is the person who cared most.  
\*Architecture Meeting\*

\---

\#\# Movement

\*\*Three-lane hallways\*\* — Lane 0 (back) rightward, Lane 1 (middle) overtaking, Lane 2 (front) leftward. Characters default to directional lane. Blocked lanes from interactables. All three blocked \= impassable.  
\*Architecture Meeting\*

\*\*Hallways are real rooms with event tags\*\* — CharacterData.current\_room is always a valid room\_id. No special "in transit" non-room state. Hallway events can fire.  
\*Architecture Meeting (confirmed from earlier sessions)\*

\*\*Pathfinder absorbs ElevatorManager\*\* — elevators are just vertical pathfinding segments. No separate autoload needed.  
\*Architecture Meeting\*

\*\*Stairs always available, always slower, never break\*\* — simple fallback that doesn't need its own system. Elevator breakdown remains dramatic because stairs exist but are worse.  
\*Architecture Meeting\*

\---

\#\# Audio

\*\*Positional audio via AudioStreamPlayer2D\*\* — parented to CharacterBody or Interactable. Godot handles volume falloff from camera position/zoom automatically. No manual zoom variable. Inspired by RCT3 proximity audio.  
\*Architecture Meeting\*

\*\*Decoration drones don't witness events\*\* — visually distinct from worker robots (drone sprites). Separation is clear: worker robots witness, drones don't.  
\*Architecture Meeting\*

\*\*Audio ships in pre-alpha, not prototype\*\* — pure flavour. Zero gameplay impact. The system design is locked so it slots in cleanly.  
\*Architecture Meeting\*

\---

\#\# The Architect

\*\*Lean Architect — traffic controller, not director\*\* — applies global multipliers, never fires events directly. Prevents boredom and chaos extremes without fighting emergence. An active Architect would fight against the emergent storytelling that makes the game worth playing.  
\*Architecture Meeting\*

\*\*Three mood states: quiet/normal/chaotic\*\* — grieving mood was considered and rejected. A death sparking a revolution is exactly the kind of emergence to preserve. Death clustering suppression is handled separately and narrowly (NATURAL/ILLNESS only).  
\*Architecture Meeting\*

\*\*Character selection is pool-first\*\* — build pool of eligible characters, weighted-random pick from pool. Never "pick character, check eligible, re-roll" — that risks infinite loops.  
\*Architecture Meeting\*

\*\*All Architect tunables as @export vars on the Architect autoload itself\*\* — no separate ArchitectConfig autoload. Architect is the only consumer. @export vars show in Godot Inspector for live tuning.  
\*Architecture Meeting\*

\---

\#\# Factions

\*\*Faction sentiment and faction membership are independent\*\* — you can hate a faction you're in (about to defect). You can love one you're not in (aspiring member). Both as separate fields on CharData.  
\*Architecture Meeting\*

\*\*Single homeless faction at a time\*\* — only one collective, no cap on members. Auto-membership when is\_homeless \= true, auto-removal when false. Separate name generator pool (scrappy survivor energy, not gang energy).  
\*Architecture Meeting\*

\*\*Gang member cap: 4-6 (tunable)\*\* — prevents one gang absorbing all criminals. Multiple smaller gangs more interesting than one dominant one.  
\*Architecture Meeting\*

\---

\#\# Management

\*\*All rooms present from Day 0, no event-triggered unlocks\*\* — removes complexity from the Architect and building progression. Simpler to design events around. The building feeling empty at the start comes from low population, not missing rooms.  
\*Room Design Session\*

\*\*Detective office parked for a late phase\*\* — high complexity, needs its own system design. Film noir tone, clue-roll mechanic, gang investigation links confirmed as the design direction when built.  
\*Room Design Session\*

\*\*Mayor, Strata, Police, Jobs are permanently robots\*\* — no human replacements for management roles. Cyberpunk aesthetic. The bureaucracy is always the machine.  
\*Architecture Meeting\*

\*\*Mayor absorbs RealEstateAgent and GameProgression\*\* — all three were the same domain (building policy). Collapsing them removes an autoload without losing any function.  
\*Architecture Meeting\*

\*\*Vending machine fallback for unstaffed rooms\*\* — cinema, shop, and other low-drama rooms don't need workers. Vending machine \= interactable, no employee needed. Build worker jobs only where the worker matters dramatically (bartender matters, cinema usher doesn't).  
\*Architecture Meeting\*

\*\*Robots fill vacancies immediately on death/quit\*\* — no service interruption. The day a human takes a robot's job is a storybook moment. The day they die and a robot takes it back is also a moment.  
\*Architecture Meeting\*

\*\*Police dispatch: humans first, robots backup, everyone for riots\*\* — human cops have discretion (CORRUPT/BY\_THE\_BOOK traits matter). Robot cops always process (no roll). This asymmetry creates richer policing stories.  
\*Architecture Meeting\*

\*\*Robot cops always process witnessed crimes, human cops roll\*\* — robot \= rule of law, human \= discretion. CORRUPT trait \= high chance of letting things slide. BY\_THE\_BOOK \= always processes.  
\*Architecture Meeting\*

\*\*Homeless characters can still be employed\*\* — that's the path back to housing. Job → income → money threshold → apartment application. Blocking employment from homeless would trap them permanently.  
\*Architecture Meeting\*

\---

\#\# Player Experience

\*\*Philosophy B with watcher mode option\*\* — player IS a specific character (Philosophy B), but can observe anyone and optionally disable all interaction. Watcher mode locked at creation — commitment changes how you play.  
\*Architecture Meeting\*

\*\*Pop-up choices are actual event options\*\* — no custom pop-up-specific responses. Player sees the same options any NPC would roll. "Choose for me" fires weighted-random from available options.  
\*Architecture Meeting\*

\*\*Management trio has distinct voice personalities\*\* — Mayor (formal, bureaucratic), Architect (cryptic, observational), Jobs (efficient, transactional). Same pop-up component, different header text. Diegetic framing: building systems talking to you, not the game talking to you.  
\*Architecture Meeting\*

\*\*Player death: 2-day grace gap\*\* — player watches the building for 2 in-game days before character creation reopens. Respects whatever story was playing out. Tunable.  
\*Architecture Meeting\*

\*\*News ticker colour-coded by event category\*\* — romance/pink, crime/red, death/purple, comedy/green, management/blue, Architect/gold. ticker\_worthy flag on event definitions. Most events don't appear.  
\*Architecture Meeting\*

\---

\#\# The Chronicle

\*\*"The Chronicle" is the player story curation tool\*\* — named timelines that roll up into "Life." Pinned entries exempt from all pruning. Player names each timeline (text input). The feature that makes this game worth talking about.  
\*Architecture Meeting\*

\*\*times\_recalled flavour text\*\* — when characters repeat a behaviour, the storybook narrates the pattern: "It had become something of a ritual." Driven by times\_recalled counter on memory entries.  
\*Architecture Meeting\*

\---

\#\# Calendar

\*\*Numbered months, no names\*\* — bleak and dystopian. Names can be added later if desired. Display: "Month 3 · Week 2 · Day 4 — Year 47."  
\*Architecture Meeting\*

\*\*Seasons are weight modifiers only, never requirements\*\* — fires can happen in winter. They're just unlikely. Rarity makes them dramatic when they do.  
\*Architecture Meeting\*

\*\*Season intensity is a curve, not a step function\*\* — peaks at day 15 of each season, returns to zero at transitions. Calculated as \`intensity \= 15 \- abs(day\_in\_season \- 15)\`. Gradual, not sudden.  
\*Architecture Meeting\*

\*\*Birthdays trimmed for prototype\*\* — age-up \+ WISH\_HAPPY\_BIRTHDAY interaction only. 45 birthdays in 90 days is one every other day. Full birthday system (gifts, parties, effects) parked until post-prototype.  
\*Architecture Meeting\*

\*\*Occasions folded into Architect\*\* — no separate OccasionManager autoload. The Architect tracks upcoming\_occasions. Saves one autoload.  
\*Architecture Meeting\*

\---

\#\# Save System

\*\*Godot Resource .tres format\*\* — per-character files, WorldState bundle, SaveMeta per slot. Pre-save cleanup pass before every write. Versioned migrations for evolving data structures.  
\*Architecture Meeting\*

\*\*Stories feature (Chronicle) pinned entries exempt from all pruning\*\* — player-saved \= permanent. Sim prunes, player decides what survives.  
\*Architecture Meeting\*

\*\*Pre-save cleanup runs before every save\*\* — prune storybooks, trim logs, verify caps. File is lean when written, not just when loaded.  
\*Architecture Meeting\*

\---

\#\# Autoloads

\*\*30 autoloads in 6 tiers\*\* — down from 38 after merge pass. MovementConfig → Stats. TraitEvolutionManager → Traits. AuraManager → Rooms. ElevatorManager → Pathfinder. AudioConfig → Audio. ArchitectConfig → Architect. FactionConfig → Factions. JobConfig → Jobs.  
\*Architecture Meeting\*

\*\*Rule: if only one system reads the config, it lives inside that system\*\* — separate config autoloads only exist when multiple systems need the same data.  
\*Architecture Meeting\*

\*\*Short names, no suffix\*\* — Settings not SettingsManager, Stats not StatConfig, Sim not EventManager. Tier structure implies role. FeelingDriver suffix distinguishes logic from config (Feelings \= data, FeelingDriver \= logic).  
\*Architecture Meeting\*

\---

\#\# Technical

\*\*3D rooms inside 2D building via SubViewport\*\* — cross-section dollhouse view in 2D, individual rooms rendered as bespoke 3D scenes. Characters are 2.5D billboard sprites consistent in both contexts.  
\*Architecture Meeting\*

\*\*SimRunner \= main game at max speed with rendering disabled\*\* — full pathfinding and transit included. Headless sim without pathfinding would produce results that don't match real gameplay. Accurate results matter more than pure speed.  
\*Architecture Meeting\*

\*\*Profile before optimising\*\* — don't guess what's slow. Godot's built-in profiler shows exactly which functions are slow. No premature optimisation.  
\*Architecture Meeting\*

\*\*Scale staged: 4 → 10 → 25 → 45\*\* — each step reveals different bottlenecks. Don't jump to 45\.  
\*Architecture Meeting\*

\#\# Rooms

\*\*Nightclub is a separate room from the bar\*\* — bar is for casual mingling, trivia nights, and low-key social events. Nightclub is night-only, higher energy, more anonymous. Dance floor enables different event types. Both rooms serve distinct dramatic functions and may run simultaneously.  
\*Room Design Session\*

\*\*Boxing ring is a zone inside the gym, not a separate room\*\* — gym becomes a larger room with a dedicated ring zone. Accidental death in the ring feeds directly into hospital and crematorium event chains. Richer single room beats a split floor space.  
\*Room Design Session\*

\*\*Hospital is a dedicated floor — healing and birth only\*\* — no other functions. Ambulance robots handle transport. Humans can fill doctor/nurse jobs. Keeping scope narrow prevents the floor from becoming a system sprawl problem.  
\*Room Design Session\*

\*\*Crematorium includes a small chapel for funerals\*\* — no religious content. Chapel is purely a functional space for grief events. Funeral events use bypass\_architect: true — bond-threshold characters are pulled automatically, other intents suspended.  
\*Room Design Session\*

\*\*Funeral events bypass the Architect\*\* — deaths are always significant. Characters above bond threshold attend regardless of Architect mood state. Same logic as calendar events (birthdays bypass Architect). Death gets the same treatment.  
\*Room Design Session\*

\*\*VR pods addiction and grief mechanic flagged for dedicated event design session\*\* — characters can visit pods to simulate deceased loved ones. Can aid grief or deepen dependency. Full event design parked until pods are built.  
\*Room Design Session\*

\*\*Rooftop includes intervention window for suicidal characters\*\* — TALK\_DOWN is a sequence-eligible event when another character is in the same zone as a suicidal character at the rooftop edge. Auto-fire candidate with a witness requirement.  
\*Room Design Session\*

\*\*Power plant is underground, directly above the sewer\*\* — vertical stack: surface floors → power plant → sewer. Not on standard pathfinding graph. Access gated by role or criminal stat threshold.  
\*Room Design Session\*

\*\*Population cap tied to apartment vacancy\*\* — Mayor/real estate system only allows  
new characters to move in when an apartment is free. Hard cap of 35 residents (one per  
apartment). Homeless characters are an exception — they enter but have no apartment assigned.  
\*Building Layout Session\*

\*\*Building has 22 above-ground levels \+ 2 underground\*\* — F00 (lobby) through F20 \+ Rooftop.  
Underground: \-01 Power Plant, \-02 Sewer. Both narrower horizontally than above-ground floors.  
Underground accessible via left elevators only.  
\*Building Layout Session\*

\*\*Three elevators\*\* — EL1 and EL2 on the left, full height (-02 to Rooftop). EL3 on the  
right, F01 to F20 only. No EL3 access to underground, F00, or Rooftop. Right elevator  
feels more residential/everyday; left elevators are the building's spine.  
\*Building Layout Session\*

\*\*Management floor at F11\*\* — vertical midpoint of the building. Framed as the  
"heart" of the building. Shares its floor with the Police Station (accessible to characters).  
\*Building Layout Session\*

\*\*F00 is the entry/lobby floor\*\* — sparse, mostly empty. New characters enter from the  
right side and walk the full width to the left elevator. Gives the player time to observe  
new arrivals before they integrate. Some homeless may sleep here.  
\*Building Layout Session\*

\*\*Stairs are mid-floor and architecturally haphazard\*\* — not on the sides of the building.  
Appear in runs of 2–3 floors only, placed without obvious logic. Intentional: reflects  
cyberpunk megabuilding aesthetic of ad-hoc construction.  
\*Building Layout Session\*

\*\*Nightclub at F18, APT 18A is the disturbed neighbour\*\* — APT 18A flagged for the  
unique event DISTURBED\_BY\_MUSIC. Event fires at night when nightclub is active.  
Full design parked for event design phase.  
\*Building Layout Session\*

\*\*Casino on F20\*\* — top floor. Aspirational and exclusive by position. Characters must  
travel the full building height to reach it, making visits feel like an event.  
\*Building Layout Session\*

\*\*Rooftop is stairs/left-elevator only\*\* — no EL3 access. Slight friction to reach it  
is intentional. Outdoor space, full building width.  
\*Building Layout Session\*

\#\# Building Layout (Temporary — Subject to Revision)

The layout below is a working draft. Room positions and floor assignments will be revised  
in a dedicated layout session before Phase 3 art work begins.

ROF  ROOFTOP — open air, full width  
F20  CASINO — dedicated full width  
F19  APT 19A | APT 19B | APT 19C  
F18  APT 18A ★ \[S\] | NIGHTCLUB (lg)  
F17  APT 17A | APT 17B | APT 17C  
F16  APT 16A | GYM (lg) | APT 16B  
F15  VR PODS (lg) \[S\] | APT 15A | APT 15B  
F14  APT 14A \[S\] | APT 14B  
F13  APT 13A \[S\] | ARCADE | APT 13B  
F12  APT 12A | APT 12B | CINEMA (lg)  
F11  MANAGEMENT (lg) | POLICE STATION  
F10  HOSPITAL — dedicated full width  
F09  APT 9A | APT 9B | APT 9C  
F08  APT 8A \[S\] | LIBRARY (lg) | APT 8B  
F07  DECO SHOP (lg) \[S\] | APT 7A | APT 7B  
F06  PARK — dedicated full width  
F05  APT 5A | SCHOOL (lg) | APT 5B  
F04  APT 4A | APT 4B | CAFE (lg)  
F03  APT 3A \[S\] | APT 3B | APT 3C  
F02  APT 2A \[S\] | GROCERY (lg) | APT 2B  
F01  BAR (lg) | APT 1A | APT 1B  
F00  LOBBY — entry right side, ads, sparse, homeless  
\-01  POWER PLANT — narrow floor  
\-02  SEWER — narrow floor

\[S\] \= staircase mid-floor. Stair runs: A(F02–F03) B(F07–F08) C(F13–F15) D(F18–F19)  
★  \= DISTURBED\_BY\_MUSIC apartment  
(lg) \= larger room footprint  
EL1/EL2 left shafts full height | EL3 right shaft F01–F20 only

**Grow Apart is passive decay, not an event** — Bond decay on inactive
relationships lives in relationships.gd connected to Clock.day_ticked.
last_positive_interaction_tick field on RelationshipRecord tracks recency.
THINK_ABOUT toward a character counts as keeping the relationship alive.
Phase 4 extension session.

**CHAT replaced by CONVERSE_SEQ** — Chat becomes a full multi-beat sequence
with a continue/end roll each beat, a conversation beat pool, and an ending
beat pool. Group conversations supported via mid-sequence join mechanic.
EXCLUDED feeling fires if a participant goes 4+ beats without speaking.
Phase 4 extension session.

**Jealousy is a full system, not a single event** — Three intensity levels,
triggered by witnessing or hearing about romantic events involving an attachment.
CharData.watching array tracks surveillance targets. JEALOUSY_SCENE is the
confrontation event gated on CONSUMING_JEALOUSY. Comparable scope to the
secret/gossip system. Phase 4 extension session.

**Cold Phase is a RelationshipRecord state, not a CharData state** — is_cold
bool lives on the relationship record between two specific characters. Only
fires for ROMANTIC_INTEREST+ pairs inactive for 3+ days. Doubles decay,
biases conversation negative, visible in EventInspector. Phase 4 extension.

**Lying System deferred from secrets** — lies array on CharData separate
from secrets. Exposure mechanic: contradicting event reaching lied-to
character triggers CAUGHT_LYING roll. Gossip can carry contradictions.
ALIBI variant deferred to police phase. Phase 4 extension session.

**Spread Rumour is a gossip subtype, not a separate event** — Rumours are
distorted gossip entries. Distortion chance modified by MEAN trait, rivalry,
and active jealousy toward subject. Contradiction exposure costs the
rumour-spreader trust with all who heard it. Phase 4 extension session.

**Public Humiliation severity determined by context** — Witness count,
target reputation, and attacker traits determine low vs high severity at
runtime. Not two separate events. Phase 4 extension session.

**Heated Argument is a CONVERSE_SEQ beat** — Not a standalone event.
Weight toward this beat increases as conversation turns negative (feelings
and bond tracked through sequence context). Phase 4 extension session.