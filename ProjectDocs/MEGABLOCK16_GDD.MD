\# MegaBlock 16 — Game Design Document  
\*Living document. The manual for building the game.\*  
\*Last updated: Architecture Planning Meeting, Session 3-4\*  
\*Codename: MegaBlock 16 (final title TBD — candidates: Concrete Dreams, Megabuilding 16)\*

\---

\# 1\. VISION

\#\# 1.1 — What Is This Game?

A cyberpunk life simulation set entirely inside one apartment building. 45 residents living, fighting, loving, dying — all simulated in real time. The player watches emergent stories unfold and occasionally intervenes through their own character.

No storyline is written in advance. Every romance, betrayal, and tragedy is the result of systems interacting.

\*\*The hook:\*\* you follow stories, not people. The building is the character.

\*\*The Sims meets Dwarf Fortress meets a soap opera.\*\* RimWorld's emergent storytelling in a vertical dollhouse.

\#\# 1.2 — Elevator Pitch

You move into a cyberpunk apartment block run by robots. You're one of the first residents. Over time, more people arrive. Grudges form. Affairs begin. Someone gets murdered. A baby is born. Gangs emerge. A riot breaks out. You watched all of it happen — and you saved the best moments to your Chronicle, naming the stories yourself.

The building starts quiet. It doesn't stay that way.

\#\# 1.3 — Inspirations

\*\*Primary:\*\*  
\- RimWorld — emergent storytelling from systems, story generator framing  
\- The Sims — life simulation, needs-driven behaviour, dollhouse view  
\- Dwarf Fortress — deep simulation, characters with rich inner lives  
\- CubeWorld Toys — small self-contained worlds that connect, characters visiting each other across cubes  
\- Roller Coaster Tycoon 3 — positional audio that scales with camera zoom/proximity

\*\*Aesthetic:\*\*  
\- Electronics with see-through cases — seeing the machinery under the hood (the Management Floor)  
\- Dollhouses — cross-section view, peeking into rooms, intimate scale  
\- Cyberpunk genre — corporate dystopia, neon and concrete, numbered months instead of names

\#\# 1.4 — Design Pillars

\*\*Pillar 1: Stories emerge, they are not scripted.\*\* No storyline is written in advance. Every romance, betrayal and tragedy is the result of systems interacting — not a predetermined plot.

\*\*Pillar 2: Every character has a life worth watching.\*\* The player character is not special. At any moment, something more interesting might be happening across the building. The building is the protagonist.

\*\*Pillar 3: Darkly comedic with real stakes.\*\* Not a grim dystopia. Not a comedy. A satirical soap opera. Things can be funny. Things can be heartbreaking. Sometimes both at the same time.

\*\*Pillar 4: Attachment is earned, not forced.\*\* The building starts nearly empty. Players meet characters gradually. By the time it's full, you have history with almost everyone in it.

\*\*Pillar 5: The player is always in control.\*\* Pause anytime. Follow anyone. Save your favourite moments. The simulation runs itself, but the player decides what matters.

\#\# 1.5 — Core Design Principles

1\. \*\*Data-driven.\*\* Behaviour lives in Resources, not hardcoded logic.  
2\. \*\*Event-based.\*\* Ticks → events → state change → next events.  
3\. \*\*Single source of truth.\*\* CharData is canonical.  
4\. \*\*Handoff pattern.\*\* Systems own their domain, hand off at boundaries.  
5\. \*\*TV show mindset.\*\* Characters have roles (background, supporting, main) that can shift. Design events as dramatic beats, not chores. The Storybook is the show's recap.  
6\. \*\*Emergence over authoring.\*\* Don't script stories. Set up systems that produce them.

\---

\# 2\. THE WORLD

\#\# 2.1 — The Building

MegaBlock 16 is a freshly-built megabuilding on the edge of the city. Self-contained. Self-governing. Home to everyone you'll ever meet.

The building is viewed in 2D cross-section (Fallout Shelter / dollhouse style). Individual rooms are rendered as bespoke 3D scenes inside SubViewport cutouts. Characters are 2.5D billboard sprites that look the same whether in a 2D hallway or a 3D room.

Each floor has one hallway strip running full width. Rooms sit on the hallway with doors on the side and full-wall windows so the player can see inside. Characters enter and leave via doors — never walking through other rooms.

The building has 22 levels above ground (F00–F20 \+ Rooftop), plus two underground levels  
(-01 Power Plant, \-02 Sewer). F00 is the lobby/entry floor. The management floor sits at  
F11 — the vertical midpoint, the heart of the building. Three elevator shafts run on the  
left side (EL1, EL2: full height, \-02 to Rooftop) and one on the right (EL3: F01–F20 only,  
no access to underground, F00, or Rooftop). Staircases appear mid-floor at irregular  
intervals — not architecturally planned. They connect in runs of 2–3 floors only.

\#\# 2.2 — Vocabulary

These terms are used consistently across all documents, code, and conversations:

\*\*Room\*\* → the full space (bar, apartment, library)  
\*\*Zone\*\* → an area within a room (pool table area, bar counter area)  
\*\*Spot\*\* → a specific pre-authored standing position within a zone

Room IDs follow the format: \`type\_fFLOOR\_sSLOT\` (e.g. \`bar\_f2\_s2\`). Events use type keys ("bar"), and the Rooms autoload resolves to real IDs.

\#\# 2.3 — Room Types

All rooms exist from Day 0\. No event-triggered unlocks.

\*\*Communal rooms\*\* — open to all residents:  
Bar, Cafe, Library, Cinema, Shop (Grocery), Shop (Decoration), Nightclub, Gym, Arcade, Rooftop, Park, VR Pods, Casino

\*\*Dedicated floors\*\* — full floors with special rules:  
\- \*\*Hospital\*\* — healing and births only. Staffed by robots; humans can become doctors or nurses. Ambulance robots retrieve injured or dying characters from anywhere in the building.  
\- \*\*School\*\* — children attend every morning. Human teacher if the job is filled; robot fallback if not. Unlocked by population (requires at least one child in the building).  
\- \*\*Park\*\* — entire floor. Indoor trees, open lawn, festival stage. Peaceful by day, criminal-adjacent at night.

\*\*Residential\*\* — one per character (or couple/family):  
Apartments in four models: single, couple, couple\_with\_child, single\_with\_child. Model changes when life events fire (marriage, baby). Rent scales by model. Decorations migrate on model swap — items in spots that don't exist in the new model get pushed to apartment\_storage.  
\*\*Apartment adjacent to Nightclub (APT 18A)\*\* — flagged for the unique event  
DISTURBED\_BY\_MUSIC. Tenant of 18A hears the nightclub through the wall. Event fires  
at night when nightclub is active. Full event design parked for the event design phase.

\*\*Management Floor\*\* — mostly locked off to characters:  
Robot workstations for Mayor, Strata, Jobs, and other building functions. Status screens change with building state. Visible robot animations fire when management functions execute. Police station is accessible to characters. Detective office is planned but not yet designed — parked for a later phase.

\*\*Underground\*\* — below the building:  
\- \*\*Power Plant\*\* — banks of generators powering the building. Located directly above the sewer. Engineers maintain them; criminals may attempt sabotage. Power outage is a building-scope world event. Mostly inaccessible to regular characters.  
\- \*\*Sewer\*\* — below the power plant. Criminal dealings, homeless sleep spots, body disposal. Not on standard pathfinding — requires specific intent to route here.  
\- \*\*Crematorium\*\* — end of life processing. Includes a small chapel used exclusively for funerals. Funeral events use \`bypass\_architect: true\` — all characters above bond threshold are pulled automatically regardless of other intents.

\*\*Underground\*\* — sewers, maintenance, storage:  
Homeless sleep spots. Shady deals. Bodies dropped and never found.

\#\# 2.3b — Occupancy & Population Cap

The Mayor only approves new move-ins when an apartment is vacant. No apartment \= no entry.  
Population is naturally capped at 35 (one per apartment). Couples and families share an  
apartment. Homeless characters may sleep in F00 (lobby) or the underground. The building  
starts nearly empty and fills gradually over play time.

Total apartments: 35\. Spread across F01–F19, minimum one apartment per inhabited floor.

\#\# 2.4 — Room Schedules

Rooms can have recurring programs that drive event eligibility:

\*\*Recurring schedules\*\* (bar trivia, gym hours): defined per-room in RoomCatalogue with \`every\_n\_days\` or \`days\_of\_week\` patterns. When the scheduled hour hits, the room enters that program state and related events become eligible.

\*\*Weekly cinema rotation\*\*: one film per week, 18 films per year. Multiple showings per day of the same weekly film. Characters have \`favorite\_genre\` and \`favorite\_movie\` on CharData — likelihood to attend goes up when their favourite is showing.

Characters discover room schedules through witnessing (being present when it starts), gossip (another character tells them), or boredom scanning (checking what's on when nothing else pulls them). They return to ones they like via the program impressions system (same dictionary as object impressions).

\#\# 2.5 — Calendar

\`\`\`  
Tick (event frequency)  \= 5-8 real seconds (adjustable, dev-only)  
Half-hour advance       \= \~18.75 seconds (adjustable, dev-only)  
Day                     \= 15 real minutes (adjustable, dev-only)  
Week                    \= 5 days (Day 5 \= Restday)  
Month                   \= 3 weeks \= 15 days  
Year                    \= 6 months \= 90 days \= \~22.5 real hours  
Max lifespan            \= 40 in-game years \= \~900 real hours  
\`\`\`

Months numbered 1-6. No names. Bleak and dystopian. Display: "Month 3 · Week 2 · Day 4 — Year 47"

\#\# 2.6 — Seasons

Cycle: summer → summer → neutral → winter → winter → neutral. Each season lasts 30 days (2 months).

Season intensity peaks at the midpoint of each season (day 15\) and drops to zero at the transitions. Calculated as: \`intensity \= 15 \- abs(day\_in\_season \- 15)\`.

Seasons are weight modifiers on events, never requirements. Fires are more likely in deep summer. Sickness is more likely in deep winter. But fires can still happen in winter — that's what makes them dramatic.

\#\# 2.7 — Building Progression

The building starts nearly empty. The player character is one of the first residents (along with 3-5 others). Essential roles are filled by robots. Over time, more characters move in. Robots get replaced by humans for some roles. All rooms are present from Day 0\.

This progression is managed by the Mayor autoload with a move-in schedule:

\`\`\`  
Day 0:    4-6 characters \+ player, all essential roles robot-filled  
Day 14:   first wave of new residents (+2)  
Day 30:   more residents (+3), first robot replaced by human worker  
Day 60:   continued growth  
Day 120+: approaching full capacity  
\`\`\`

The building's character arc: Day 1 is cold, automated, lonely. Day 200 is messy, human, alive. Each "robot replaced by human" event is a major storybook moment.

Characters never voluntarily move out. They stay until they die. Eviction for non-payment of rent makes them homeless, but they remain in the building (sleeping in sewers, vents, or designated spots).

\#\# 2.8 — Groceries

Food is abstracted as a single pooled resource on CharData: \`groceries: int\`.

Characters buy groceries at the grocery store — each purchase adds to the pool (e.g. \+10 per shop visit). When a character eats at home or cooks in their apartment, groceries are deducted. The player is never told what specific items are in the pool — they use their imagination. Storybook entries can vary ("made something from what was left in the fridge", "cooked a proper meal") without the system needing to track ingredients.

Apartment storage UI shows current grocery count when the player inspects the apartment. Characters with \`groceries: 0\` cannot eat at home and must go to the cafe or diner.

This keeps the food system simple and the player's imagination does the heavy lifting.

\#\# 2.9 — VR Pods (Design Notes)

VR pods are a happiness/stress booster with an addiction risk vector.

Characters visit the pods to escape. The simulation inside is never shown — the player only ever sees a character lying in a pod, absent. Duration is locked (character cannot be interrupted while under).

\*\*Addiction:\*\* Characters with the \`VR\_ADDICT\` persistent state get a strong pull to the pods regardless of other needs. VR becomes their highest-priority intent. Social isolation deepens over time — time in pods is time not forming relationships.

\*\*Grief mechanic (flagged for event design):\*\* Characters who have lost someone they were deeply bonded with may visit the pods to experience a simulation of the deceased. This is a distinct event type — not general escapism, but targeted grief processing. The simulation can help (stress relief, closure) or harm (dependency, inability to move on). Exact event design to be done in a dedicated session.

\*\*Key constraint:\*\* Characters in pods cannot interact with others. Isolation is mechanical, not just flavour.

\---

\# 3\. CHARACTERS

\#\# 3.1 — CharData

Every character is a CharData Resource — the single source of truth for all character state. CharData holds identity, stats, traits, feelings, memories, location, inventory, relationships (via IDs), faction sentiment, job data, and family connections.

RobotData extends CharData with minimal overrides: no feelings, minimal stats (health only), no relationships, no storybook, no traits. Faction memberships always include "robots".

\#\# 3.2 — Identity

\`\`\`  
char\_id         unique string ("char\_0")  
char\_name       generated or player-chosen  
internal\_age    hidden float, drives life stage  
life\_stage      derived: Baby/Child/Teen/Adult/Elderly  
pronouns        they/them, she/her, he/him  
sexuality       determines romantic tier eligibility  
favourite\_color drives clothing colour, apartment wallpaper/lighting, UI accent  
interests       rolled at generation, gate object/program impressions  
life\_arch       vague genre-suggestive name, time-phased weight modifier set  
birth\_month     1-6, rolled at generation  
birth\_day       1-15, rolled at generation  
favorite\_genre  rolled at generation, boosts cinema attendance  
favorite\_movie  rolled at generation  
\`\`\`

\#\# 3.3 — Stats (16 total)

\`\`\`  
stress              0-100   default 20  
happiness           0-100   default 50  
health              0-100   default 80  
energy              0-100   default 80  
hunger              0-100   default 20    (high \= very hungry)  
boredom             0-100   default 10  
loneliness          0-100   default 30  
horniness           0-100   default 20  
need\_for\_toilet     0-100   default 0  
grief               0-100   default 0  
global\_reputation   0-100   default 50  
attractiveness      0-100   default 50  
cash                0-999999 default 200  
criminal\_inclination 0-100  default 5  
criminal\_reputation 0-100   default 0  
addiction           0-100   default 0  
\`\`\`

Inventory capacity is a visible stat with a UI bar. Three states: Normal, Full, Over-encumbered (speed penalty only at over-encumbered).

\#\# 3.4 — Traits

Permanent personality modifiers. Influence event weights, stat drift, and relationship caps. Can be gained or lost via the trait evolution system (daily check, counter-based thresholds). Coexisting traits are possible (ALCOHOLIC \+ RECOVERING\_ALCOHOLIC — the recovery trait suppresses the other's weight modifiers).

\`\`\`  
FLIRTATIOUS, SHORT\_TEMPERED, CHARMING, STUBBORN, OPTIMISTIC, PESSIMISTIC,  
FUNNY, PARANOID, RECLUSIVE, GOSSIP, ROMANTIC, LONER, NOSY,  
CRIMINAL\_HEART, GAMBLER, VIOLENT, MANIPULATIVE, ADDICT\_PRONE,  
MOTIVATED, LAZY, INSOMNIAC, NEAT\_FREAK, FORGETFUL,  
HYPOCHONDRIAC, BIG\_APPETITE, WEAK\_BLADDER, HIGH\_LIBIDO, SECRETIVE,  
CORRUPT, BY\_THE\_BOOK  
\`\`\`

Traits are weight modifiers only — they nudge probability, they don't gate events. Criminal events gate on stats (criminal\_inclination \>= threshold), not traits.

\#\# 3.5 — Feelings

Temporary emotional states pushed by events. Decay over time. Can be global (affects all interactions) or targeted (directed at a specific character). Can be hidden (no UI bubble, all mechanical effects still apply — player infers from behaviour) or visible.

\`\`\`  
Positive:  HAPPY, ELATED, AFFECTIONATE, FLIRTY, CONFIDENT, INSPIRED,  
           GRATEFUL, EXCITED, SATISFIED, AMOROUS  
Negative:  MISERABLE, HUMILIATED, FURIOUS, ANXIOUS, HEARTBROKEN,  
           GRIEVING, BITTER, DISGUSTED, PARANOID\_FEELING, EXHAUSTED\_FEELING  
Physical:  WELL\_FED, HUNGOVER, CRAVING, RELIEVED  
Neutral:   CONTENT\_FEELING  
Added via sequences: FRUSTRATED, COCKY, COMPETITIVE, RECKLESS,  
                     INFATUATED\_WITH, NURSING\_GRUDGE  
\`\`\`

\#\# 3.6 — States

Stat-derived labels auto-evaluated by StateDriver each half-hour. Plus persistent states set/cleared by events (ON\_PAROLE, IN\_HOSPITAL, BANNED\_FROM\_BAR, etc.).

\#\# 3.7 — Life Stages

\`\`\`  
Baby      0-2      BabyData (smart interactable, not full CharData)  
Child     2-8      full CharData, limited event pool  
Teen      8-16     expanded event pool, rebellion events  
Adult     16-35    full event pool  
Elderly   35-40    not everyone reaches this, grey hair, shuffle gait  
\`\`\`

Age hidden from player. UI shows life stage only. Player character starts at age 16 (young adult). Generated characters start at 18-35. Life stage transitions fire as ticker-worthy events.

\#\# 3.8 — Death

Causes: natural (age-based probability past 35), accident (severity roll), illness (health hits 0), violence, overdose, starvation. On death: body becomes brief interactable, undertaker robot dispatched, CharData archived as GhostRecord, grief propagates based on bond tier, memories of deceased auto-tagged, apartment goes through inheritance, job vacancy filled by robot.

Death frequency: \~1 per 15-30 in-game days at full population. The Architect suppresses clustering of natural/illness deaths. Violence and accidents are never suppressed.

Player character death: grace period (first 3 in-game years, disableable). On death, announcement pop-up, 2 in-game day gap, then character creation reopens. New character moves in.

\#\# 3.9 — Art Direction

RimWorld-adjacent pill body, billboard sprites. No legs, floating Mickey-style white gloved hands (masculine and feminine variants). Same sprite in 2D hallways and 3D rooms.

Expression through: feeling icons in BubbleContainer, face sprite swap (6 expressions: neutral, happy, sad, angry, scared, lovestruck), subtle body colour tint for extreme states, eyebrow overlay.

Character variety at scale: 3 body silhouettes × 8 skin tones × 10 hair styles × 6 hair colours × clothing driven by favourite\_color × 6 eye colours.

\---

\# 4\. THE SIMULATION

\#\# 4.1 — The 7-Stage Pipeline

Every event flows through this pipeline in order:

\`\`\`  
1\. ROLL       → weighted random picks event from eligible pool  
2\. RESOLVE    → pick target (character/interactable/memory/room/self)  
3\. FRAME      → resolve context args (declarative table or Context function)  
4\. PLAYER\_GATE→ if player character AND player\_choice: true → pop-up, pause  
5\. ACT        → Actions.call\_action(character, target, args)  
6\. EXECUTE    → movement, stats, storybook, inventory, world state changes  
7\. ECHO       → write short-term memory, flag storybook if memorable,  
                 write relationship delta if target is character  
8\. CONTINUE?  → action returns DONE / REPEAT / LOCK\_SEQUENCE  
\`\`\`

\#\# 4.2 — The Simulation Loop

\`\`\`  
Every tick (5-8 real seconds):  
  Sim loops every character:  
    1\. Skip if sleeping  
    2\. Skip if in transit (except proximity\_reactive events)  
    3\. Check intent queue → fire if any  
    4\. Check auto-fire pool → fire highest priority if Architect approves  
    5\. If in sequence → advance to next beat  
    6\. Otherwise → full pipeline

Every half-hour:  
  Clock advances, FeelingDriver decays, StateDriver evaluates, Rooms ticks auras

Every day:  
  Memory prunes, Relationships decays, Traits checks evolution,  
  Architect evaluates mood \+ calendar, Clock updates season intensity

On room arrival:  
  Sim fires one room-context reactive event  
\`\`\`

\#\# 4.3 — Target Resolution

Events specify how to find their target. Five target types (character, interactable, memory, self, room) with filter keys: highest\_affection, lowest\_affection, recent\_interaction, same\_room, random\_known, grudge\_holder, self, none, closest, shared\_memory.

\#\# 4.4 — Auto-Fire Events

Events with \`trigger\_mode: "auto\_fire"\` skip the weighted roll when their requirements are met. They still run through the full pipeline and still require Architect approval. Reserved for events with costly/rare requirements (riots, interventions, gang ambushes). The Architect can suppress auto-fire events during chaotic mood with a tunable probability.

Calendar events (birthdays, holidays) bypass the Architect entirely via \`bypass\_architect: true\`.

\#\# 4.5 — Sequences

Multi-beat events that lock participants. Each beat has its own outcomes, storybook text, and branching. Example: a pool game is a 3-beat sequence (setup → play → outcome with weighted winner/loser reactions).

\#\# 4.6 — Event Scope

Two scopes: \`"character"\` (targets a specific character, runs per-character in the tick loop) and \`"building"\` (targets the building as a whole, checked by the Architect once per tick). Building events include power outages, festivals, pandemics, elevator breakdowns.

\---

\# 5\. MEMORY

\#\# 5.1 — Short-Term Memory

5 categories (thought, action, interaction, observation, felt) × max 2 entries each. Written by actions in the ECHO stage. Each entry has subject, tone, context, and timestamp.

\#\# 5.2 — Long-Term Memory

Not a separate structure — flagged storybook entries. Memorable flag set by magnitude threshold or explicit flag in event data. Memory tags assigned by designer. \`times\_recalled\` counter increments when think\_about surfaces it. Non-memorable entries pruned daily. 40-year rolling cap on general storybook. 50 memorable entry soft cap (most-recalled survive).

\#\# 5.3 — Intent Queue

Ordered list of pending actions on CharData. Checked before ROLL each tick. Priority ordering: critical → high → normal → low. Patience counter decrements each tick without progress — at 0, GIVE\_UP event fires (trait-modified: STUBBORN \= high patience, LAZY \= low). Clearable intents flushed by interrupts (elevator breaks, fire alarm). Non-clearable intents survive (biological needs).

\#\# 5.4 — Object and Program Impressions

Per-character scores for interactables and room programs, stored in one dictionary on CharData. Gated by character interests — only characters with matching interest tags accumulate. Thresholds: 0-9 Unaware, 10-29 Noticed, 30-59 Familiar, 60-99 Attached, 100+ Connected. Negative scores indicate aversion.

\---

\# 6\. RELATIONSHIPS

\#\# 6.1 — RelationshipRecord

Pairwise record per character pair. Bond (-100 to \+100, bidirectional), trust (0-100), rivalry (0-100, can coexist with positive bond), familiarity (0-100, only increases, never decays). Directional feelings on each side (a\_feels, b\_feels: attraction, jealousy, parental\_bond, filial\_bond, etc.).

\#\# 6.2 — 15-Tier Spectrum

\`\`\`  
\-100          MORTAL\_ENEMY      \+10 to \+19    ACQUAINTANCE  
\-80 to \-99    ENEMY             \+20 to \+39    FRIENDLY  
\-60 to \-79    RIVAL             \+40 to \+59    FRIEND  
\-40 to \-59    DISLIKED          \+60 to \+74    CLOSE\_FRIEND  
\-20 to \-39    UNFRIENDLY        \+75 to \+84    BEST\_FRIEND  
\-10 to \-19    COOL              \+85 to \+94    ROMANTIC\_INTEREST ★  
\-9  to \+9     NEUTRAL           \+95 to \+97    PARTNER ★  
                                \+98 to \+99    DEEPLY\_BONDED  
                                \+100          MARRIED ★  
                                ★ \= event-gated transition  
\`\`\`

Romantic tiers require formalising events (ASK\_OUT, ASK\_TO\_GO\_STEADY, PROPOSE), not just bond score. Reproduction doesn't require partnership — bond\_above 20 is sufficient (one-night stands produce pregnancies).

Bond decay: \-1 every 10 days without interaction (slower above BEST\_FRIEND, none for MARRIED unless active damage). Familiarity never decays. Affairs emerge naturally from parallel bond progression.

\#\# 6.3 — Grief Propagation

Both sides high bond (70+) → DEEP\_GRIEF. Living cared (50+) → GRIEF. Somewhat cared (30+) → MILD\_SADNESS. Below 30 → none. Witnessed violent death → minimum GRIEF \+ TRAUMATISED regardless of bond.

\---

\# 7\. MOVEMENT & PATHFINDING

\#\# 7.1 — Three-Layer System

\*\*Pathfinder (autoload)\*\* — plans routes, handles blockages, manages elevator dispatch. Knowledge-limited: characters don't know about blockages on other floors, discover them on arrival. Gossip events write to known\_blockages with expiry timestamps.

\*\*MovementController (node on CharacterBody)\*\* — reads waypoints, advances position tweens, applies movement type speed, plays animations, fires arrival events.

\*\*Movement types\*\* defined in Stats autoload: walk (1.0×), run (2.0×, requires BURSTING/TERRIFIED/FURIOUS), skip (1.2×, requires ELATED), crawl (0.3×), sneak (0.7×), limp (0.6×, requires INJURED), shuffle (0.5×).

\#\# 7.2 — Three-Lane Hallways

Lane 0 (back) for rightward travel, Lane 1 (middle) for overtaking, Lane 2 (front) for leftward travel. Characters default to their directional lane. Blocked lanes from interactables (puddle blocks lane 2). All three blocked \= hallway impassable.

\#\# 7.3 — Elevators

Physical elevator cars with state (idle/moving/doors\_open/broken). Managed by Pathfinder. Lobby waiting zones per floor. Elevator interior is a mini room context where events can fire. Broken elevator \= world event, trapped sequence for occupants. Stairs always available, always slower, never break.

\#\# 7.4 — Proximity-Reactive Events

Fire for in-transit characters when another character is nearby in a hallway. Light actions (nod, wave) don't interrupt transit. Heavy actions (conversation) pause transit, push intent to queue, resume after.

\---

\# 8\. INVENTORY & INTERACTABLES

\#\# 8.1 — Inventory

held\_items (max 2, one per hand, visible on sprite), carried\_items (backpack, hidden), equipped (hat, costume, faction\_badge slots), apartment\_items (placed decorations, limited by spots), apartment\_storage (food, items, decoration buffer).

Two-handed items occupy both held slots. Retrieve from backpack before any interaction (brief animation, no manifestation). Encumbrance affects speed only at over-encumbered threshold.

\#\# 8.2 — Interactables

InteractableData resource with tags, aura effects, interaction tags, ownership (building/communal/personal), and state. Ownership transfers on theft. Police only called if witnessed AND witness rolls CALL\_POLICE.

Auras: opt-in (only interactables with populated aura\_effects emit), capped per-stat (+5) and per-room (+12), personality sensitivity roll. Ticked only in occupied rooms.

Breaking: material-based broken texture selection, optional secondary spawn (whisky glass → shards \+ spill). Broadcast to nearby characters.

\#\# 8.3 — Gifting

Transfer item between characters. Gift value from personality match (interests, favourite\_color). Both sides get relationship delta. Receiver's object\_impression set to 10 immediately.

\#\# 8.4 — Babies As Smart Interactables

BabyData extends InteractableData. No stats, no feelings, no tick consumption. Crying aura when unattended, comforting aura when held. Witnesses events (stored in buffer, transfers to CharData at Child stage). Throwable (witnesses get HORRIFIED). Full diaper state with FULL\_DIAPER interactable (throwable, weapon-usable, hilarious). Converts to full CharData at Child life stage with seed memories and partially inherited traits.

\---

\# 9\. THE ARCHITECT

\#\# 9.1 — Role

The Architect is a traffic controller, not a director. It sits between the Sim's eligibility check and the weighted roll, applying global modifiers. It prevents boredom and chaos extremes without fighting emergence.

\#\# 9.2 — Building Mood

Three states evaluated daily from the rolling event log:

\*\*Quiet\*\* (0 major events in last 5 days) → boost majors ×1.5  
\*\*Normal\*\* → no modifier  
\*\*Chaotic\*\* (3+ majors in last 3 days) → suppress majors ×0.4

All thresholds tunable via @export vars on the Architect autoload.

\#\# 9.3 — Character Selection

When the Architect wants to inject a major event during quiet mood: roll scope (30% building / 70% character, tunable). For character events: build pool of characters with eligible major events, player character gets ×1.5 weight, pick one weighted-random, apply ×3.0 boost to their major events, let Sim roll normally.

\#\# 9.4 — Story Threads

Auto-managed list. Threads open when a major event fires with no matching existing thread. Close on resolution events or after 5 idle days. Cap at 5-7 active threads. When cap reached, new major events suppressed but existing-thread continuations boosted.

\#\# 9.5 — Other Responsibilities

Building event scheduling (own cooldown timer). Calendar event firing (definitions in Events, scheduling in Architect). Death clustering suppression (NATURAL/ILLNESS only, ×0.2 within 5 days of a death). Emotion loop breaker (stuck feeling \> 3 days → intervention event). Occasion tracking (holidays, festivals, gatherings). Auto-fire event approval gate.

\---

\# 10\. FACTIONS

\#\# 10.1 — Two Types

\*\*Institutional\*\* — pre-defined, permanent: police, management, robots, building. Every character has a sentiment toward each. Membership determined by job.

\*\*Generated\*\* — gangs and homeless collective. Created at runtime, can dissolve. Faction resource with procedural name, badge colour, badge accessory. Gang member cap: 4-6 (tunable).

\#\# 10.2 — Faction Sentiment

Dictionary on CharData, same \-100 to \+100 scale as bond. Shifts from witnessed events (see cop beat a friend → police sentiment \-30). Independent from membership — you can hate a faction you're in.

\#\# 10.3 — Gangs

Form when FORM\_GANG event fires (requires high criminal\_inclination \+ criminal\_reputation). Procedural name from word pools (The Crimson Wolves, Toxic Saints, Neon Knives). Badge renders as faction\_badge in equipped slot.

\#\# 10.4 — Homeless Faction

Single auto-managed collective. Auto-membership when is\_homeless \= true, auto-removal when is\_homeless flips false. No cap. Own name pool (scrappy survivor energy: The Vent Crew, Sub-Level Strays, The Forgotten).

\#\# 10.5 — Riots

Emergent, not authored. RIOT\_BREAKS\_OUT is an auto-fire event with requirements: 4+ characters in the same room with police faction sentiment below \-50. The Architect gates it but doesn't author it.

\---

\# 11\. MANAGEMENT & JOBS

\#\# 11.1 — The Mayor (permanently robot)

Building progression / move-in schedule. Apartment assignment and inheritance (partner → child → highest bond → vacant). Rent collection (monthly calendar event). Eviction → homelessness. Room open/close. Holiday decoration dispatch to Strata. Procedural holiday naming (3 generated options, player picks).

\#\# 11.2 — Strata Manager (permanently robot)

Robot pool and deployment. Elevator maintenance dispatch. Decoration drone deployment for holidays (visually distinct from worker robots, no witness capability). Robot vacancy fill (immediate — no service interruption when a human worker dies or quits).

\#\# 11.3 — Police

Witness-based only — no automatic detection. Case filing, investigation (evidence threshold over X days), arrest, jail timer. Robot vs human dispatch (humans first, robots backup, everyone for riots). Detective role with unique events (INTERVIEW\_SUSPECT, FOLLOW\_LEAD, CRACK\_CASE). Max human officers cap (tunable). Two key traits: CORRUPT (high chance of letting things slide), BY\_THE\_BOOK (always processes). Robot cops always process, no roll. Courtroom \+ judge robot \+ prison floor parked for later.

\#\# 11.4 — Job System (Jobs autoload)

Shift coverage tables per room: each role has time blocks marked required/robot\_only/human\_preferred. JobAgent matches humans and robots to shifts daily. Job satisfaction on CharData (0-100): positive interactions boost it, conflict/boredom reduce it. Below 25 → eligible for QUIT\_JOB. Vending machine fallback for unstaffed rooms (cinema, shop — no worker needed). Homeless characters can still be employed — that's the path back to housing.

\#\# 11.5 — Homelessness

Evicted characters get is\_homeless \= true, home\_room cleared. Sleep in designated spots (sewers, vents). Survival events: BUSK, BEG, STEAL, FIND\_WORK. Criminal events more likely (weight modifier from homeless state). Path back: job → income → money threshold → APPLY\_FOR\_APARTMENT. Auto-join homeless faction if one exists.

\#\# 11.6 — Robot Workers

RobotData (extends CharData, minimal). Can witness events, be insulted, be damaged in riots. Don't accumulate inner life. On decommission: RobotGhostRecord (ultra-lightweight) so memory references don't break. Events can exclude robots with \`exclude\_robots: true\` filter flag (romance, gossip, deep conversation).

\---

\# 12\. PLAYER EXPERIENCE

\#\# 12.1 — Character Creation

At new game start:  
\- Name (text input), pronouns (pick), favourite colour (pick)  
\- 3 traits selected from visible pool, hidden traits rolled  
\- Life arch selected from vague descriptions (RANDOM option available)  
\- Age locked at 16 (young adult)  
\- Watcher mode offered as alternative (cannot change post-creation, explicit warning)

\#\# 12.2 — Two Modes

\*\*Character mode (default):\*\* Player IS a specific character. Lives in the building. Has a job, pays rent, has relationships. Pop-ups fire on their events. Can die and transfer to a new character.

\*\*Watcher mode:\*\* No player character. Pure observation. All events auto-resolve. No pop-ups. Chronicle still fully available.

\#\# 12.3 — Pop-up System

Three sources of pop-ups, each with a distinct personality voice:

\*\*The Architect\*\* (cryptic, observational) — building event choices. "The building is restless. A moment of change approaches." Limited to building-scope decisions.

\*\*The Mayor\*\* (formal, bureaucratic) — holiday naming, apartment decisions. "Unit 7B is vacant. A prospective tenant has been identified."

\*\*The Job Agent\*\* (efficient, transactional) — job application approvals. "Marcus Webb. Bartender application. Qualified. Approve?"

Pop-up rules: max one at a time (queue others), always has auto-resolve timer, "Choose for me" on all pop-ups, choices match actual event outcomes (no pop-up-specific options), max 3 options, never covers more than 20% of screen, non-modal (player can still pan camera).

Pop-up settings (adjustable): pause all, pause major only (timer on minor), timer on all (recommended), turn off pop-ups. Per-source toggles. Timer duration slider.

First-run: one tutorial pop-up explaining pop-ups, then preference selection. Only time the game stops to explain itself.

\#\# 12.4 — Player Death

Grace period: Architect suppresses lethal severity rolls on player character for first 3 in-game years (disableable). Same grace on transfer. On death: if mid-major-event, let it resolve first. "Name is gone. A new resident will move into MegaBlock 16 in 2 days." Player watches building for 2 days. Character creation reopens.

\#\# 12.5 — News Ticker

Bottom of screen (adjustable to top). Shows flagged storybook entries only (ticker\_worthy field on event definitions). Colour-coded by category: romance/pink, crime/red, death/purple, comedy/green, management/blue, Architect/gold. Single line format, fades after 8 seconds, multiples stack upward.

\#\# 12.6 — Camera

Four modes: FREE (drag to pan, scroll to zoom, default), FOLLOW (click character to lock), CINEMATIC (Architect-triggered for major events), OVERVIEW (Tab toggle, whole building visible). Smooth lerp between all mode changes. Escape returns to FREE.

\#\# 12.7 — The Chronicle

The player's story curation tool. Browse any character's storybook. Pin entries to named timelines. All timelines roll up into "Life" (master chronological view). Pinned entries exempt from all pruning.

"times\_recalled" flavour text on repeated behaviours — when characters repeat something, the storybook narrates the pattern: "It had become something of a ritual."

Filter by character, event type, day range. Story thread click-through from HUD to multi-POV Chronicle view.

\#\# 12.8 — HUD

Clock display (Month X, Week X, Day X, Year X). Speed controls (1x, 2x, 3x, Pause). Active story threads list (clickable → Chronicle view). Selected character info panel.

\---

\# 13\. AUDIO

\#\# 13.1 — Positional Audio

All action and object sounds use Godot's AudioStreamPlayer2D, parented to the CharacterBody or Interactable scene. Camera position and zoom automatically determine volume falloff. Zoom in close \= loud. Pan away \= fades. No manual zoom variable needed. Godot handles it.

Room ambience via AudioStreamPlayer2D placed inside room scenes. Becomes audible as camera enters that area.

Stings and music via regular AudioStreamPlayer (non-positional), stay at fixed volume.

Audio autoload includes config data (keys → file paths, bus assignment, loop flag, category). Categories: action, ambience, music, ui, sting. Map to Godot audio buses which connect to SettingsManager volume sliders.

Timeline: skip for prototype, add in pre-alpha.

\---

\# 14\. SAVE SYSTEM

Godot Resource saving (.tres format). Per-character files in slot subfolders. WorldState resource bundles all global manager state. SaveMeta for slot metadata (name, date, screenshot, version). Pre-save cleanup pass prunes storybooks and trims logs. Save versioning with migration functions for evolving data structures. Auto-save every in-game day at 04:00 (3 rotating slots). Manual save from pause menu (5 named slots). Target: total save folder under 5MB.

\---

\# 15\. FAMILIES & REPRODUCTION

\#\# 15.1 — Requirements

Both characters Adult life stage. Bond above 20 (partnership not required — one-night stands possible). One character must have a home (not homeless). Building below population cap. Player character gets a pop-up.

\#\# 15.2 — Pregnancy

PREGNANCY\_BEGINS fires as consequence of romantic events. 9 in-game days. Hidden initially — REALISE\_PREGNANT event fires after X days. Other parent notified via TELL\_ABOUT\_PREGNANCY (reactions: supportive, dismissive, scared, excited).

\#\# 15.3 — Family Data

parent\_ids (up to 2), child\_ids, sibling\_ids on CharData. Parenting bond and filial bond as directional feelings on RelationshipRecord. Inheritance: partner first, then oldest child, then highest bond character, then apartment vacated.

\#\# 15.4 — Orphaned Baby

Priority: other biological parent → highest bond character with parental\_bond \> 0 → highest bond character overall → building ward (robot caretaker). Robot caretaker is cold but functional — a story thread opens immediately. Characters with high parental\_bond who notice may roll OFFER\_TO\_ADOPT.

\#\# 15.5 — Parenting Events

SETTLE\_BABY, CHECK\_ON\_BABY, COMFORT\_CRYING\_BABY, PICK\_UP\_BABY, SHOW\_OFF\_BABY, CHANGE\_DIAPER, PANIC\_BABY\_MISSING. Protective behaviour is emergent: high parental bond \= high weight on settling/checking events. Low parental bond \= neglect emerges naturally.

\---

\# 16\. HOLIDAYS & OCCASIONS

\#\# 16.1 — Three Tiers

\*\*Holiday\*\* — calendar-fixed, building-wide. Architect applies global weight mod package (boost social, suppress violence). Strata sends decoration drones. Duration in days.

\*\*Festival\*\* — calendar-fixed, large-venue (park, cinema, common room). Strong intent pull toward venue. Multi-day.

\*\*Gathering\*\* — character-organised (party, wedding, trivia night). Created by character actions. Invitations propagate via gossip.

\#\# 16.2 — Holiday Creation

The Mayor periodically proposes new holidays. Pop-up presents 3 procedurally generated names from word pools. Player picks. Holiday added to calendar for future years.

\---

\# 17\. SETTINGS & ACCESSIBILITY

\#\# 17.1 — Player-Facing

Speed: 1x, 2x, 3x \+ Pause. Accessibility: text\_scale, high\_contrast, pause\_on\_major\_event. Audio: volume\_master, volume\_music, volume\_sfx, volume\_ambience, mute\_all. Display: window\_mode, resolution, ui\_scale. Pop-ups: mode selection, per-source toggles, timer duration. News ticker: enabled/disabled, position (top/bottom).

\#\# 17.2 — Dev-Only (hidden)

sim\_speed\_multiplier, seconds\_per\_half\_hour, seconds\_per\_tick, event\_frequency, population\_size, permadeath, player\_grace\_period.

\#\# 17.3 — Debug (dev builds only)

debug\_print, show\_event\_inspector (F2), force\_event\_mode (F3), show\_auras, show\_spots, show\_zones, show\_pathfinding\_routes, show\_relationship\_scores, show\_bond\_tiers, show\_intent\_queues, show\_memory\_entries, show\_impression\_scores, show\_encumbrance, log\_all\_rolls.

\---

\# 18\. TECHNICAL

\#\# 18.1 — Engine

Godot 4.6.2 / GDScript. 2D building cross-section with 3D room SubViewports. Billboard character sprites. Forward+ renderer.

\#\# 18.2 — Architecture

30 autoloads organised in 6 tiers by dependency. See Architecture Reference document for full map, load order, and folder structure.

\*\*Tier 1 — Config (9):\*\* Settings, Stats, Traits, Identity, Feelings, States, Events, Sequences, Interactables  
\*\*Tier 2 — Core (5):\*\* Clock, Registry, Rooms, Pathfinder, Memory  
\*\*Tier 3 — Systems (7):\*\* FeelingDriver, StateDriver, Relationships, Context, Actions, Audio, Camera  
\*\*Tier 4 — Simulation (1):\*\* Sim  
\*\*Tier 5 — Domain (6):\*\* Architect, Mayor, Strata, Police, Factions, Jobs  
\*\*Tier 6 — Player (2):\*\* Decisions, Saves

\#\# 18.3 — Scene Structure

\`\`\`  
Building (Node2D)  
  ├── BuildingLayout (Sprite2D — 2D cross-section)  
  ├── Hallways (per floor)  
  ├── Rooms (per slot — 3D SubViewport scenes)  
  │     └── Zone nodes → Spot nodes → Interactable scenes  
  ├── ElevatorCars (scenes, move along shafts)  
  ├── Characters (CharacterBody Node2D instances)  
  │     ├── Sprite\_Body (AnimatedSprite2D)  
  │     ├── Sprite\_Hair, Sprite\_Face, Sprite\_Overlay  
  │     ├── Hand\_Left, Hand\_Right (attachment points)  
  │     ├── BubbleContainer (thought/speech/feeling icons)  
  │     ├── NameLabel  
  │     ├── SelectionIndicator  
  │     └── MovementController  
  ├── Camera2D (controlled by Camera autoload)  
  └── HUD (CanvasLayer)  
\`\`\`

\#\# 18.4 — Performance Considerations

EventManager loop: 45 iterations per tick at max population. Keep lookups O(1) via dictionary indexing. Relationship records: 990 pairs at 45 characters — manageable. Aura ticking: occupied rooms only, skip interactables with empty aura\_effects. Storybook: prune aggressively, 40-year cap. Save files: pre-save cleanup, target under 5MB, switch to .res binary at ship time.

\#\# 18.5 — Scale Plan

Staged: 4 (prototype) → 10 → 25 → 45\. Each step reveals different bottlenecks. Don't jump straight to 45\. Profile with Godot's built-in profiler before optimising.

\---

\# 19\. DEBUG & TESTING TOOLS

\*\*EventInspector (F2)\*\* — live overlay showing stats, feelings, states, memory, intents, eligible events \+ weights, relationships, faction sentiments. Build first.

\*\*ForceEvent (F3)\*\* — pick character \+ event, fire immediately. Build second.

\*\*SimRunner\*\* — main game at max speed with rendering disabled. Full pathfinding and transit. Logs to user://logs/. Build at scale testing phase.

\*\*StoryReader\*\* — prose output from SimRunner runs, filterable by character/event/day. Build alongside SimRunner.

\*\*SimLab\*\* — separate scene with hand-crafted characters for controlled testing.

All tools output to copy-pasteable text panels with \[Copy All\] button for pasting into debug chat sessions.

\---

\# 20\. CONTENT PIPELINE

\#\# 20.1 — Scenario Design Toolkit

Dedicated Claude chat workflows for rapid content creation:

\*\*Event Design Chat\*\* — describe a scenario in plain English, receive structured event definitions, action functions, weight modifiers, storybook templates. Checks against existing events to avoid duplication.

\*\*Storybook Template Chat\*\* — input event ID \+ context, receive 3-5 literary text variants with template variables.

\*\*Balance Review Chat\*\* — input SimRunner logs, receive event frequency analysis, stuck character detection, tuning suggestions.

\#\# 20.2 — Event Data Shape

\`\`\`  
"EVENT\_NAME": {  
    "scope": "character" | "building",  
    "trigger\_mode": "rolled" | "auto\_fire",  
    "priority": 0-100 (auto\_fire only),  
    "player\_choice": true/false,  
    "ticker\_worthy": true/false,  
    "bypass\_architect": true/false,  
    "requirements": { condition keys },  
    "weight\_modifiers": \[ modifier entries \],  
    "target\_resolution": { type, filter, scope },  
    "context\_framing": { declarative args } OR "context\_resolver": "function\_name",  
    "call\_action": "action\_function\_name",  
    "outcomes": { stats, target\_stats, feelings, move\_to, faction\_sentiment },  
    "sound": "audio\_key" (optional),  
    "storybook\_templates": \[ text variants with {name}, {target} \],  
    "choices": \[ { label, outcome\_key, tone } \] (player\_choice events only),  
    "auto\_resolve": "outcome\_key" (player\_choice events only),  
    "occasion\_type": "holiday" | "festival" | "gathering" (optional),  
    "calendar\_trigger": { month, day } or "birthday" (optional)  
}  
\`\`\`

\---

\# 21\. PARKING LOT

Ideas acknowledged, not designed, not scheduled. May build, may cut.

\*\*Characters:\*\* dev-crafted bespoke characters with custom sprites. Player nudges (soft influence on weighted roll). Disorders/disabilities/syndromes as special trait rolls. Obsession mechanic (handled emergently via REPEAT). Favourite room variable.

\*\*Rooms:\*\* pawn shop, tattoo parlour (art complexity concern — parked). Boxing ring folded into gym as a dedicated zone. Detective office and mystery/investigation system — parked for a late phase; design intent is film noir tone, clue-roll system, links to gang investigations.

\*\*Systems:\*\* phone/calling system. Store revenue tracking. Full hiring/firing system. Faction wars (gang rivalry). Cliques (non-criminal generated factions). Leaving gangs \+ consequences. Marriage/affairs/divorce event chains. Apartment store closing on low revenue.

\*\*Content:\*\* rare wild events design session. Gangs, crime syndicates, betrayal events. Colourblind mode. Minimap. Camera shake on major events. Particle effects for states (steam, zzz, sweat, hearts). Storybook visual recaps (snapshot moments). Player-created characters appearing as NPCs in other saves.

\*\*Management:\*\* courtroom \+ robot judge. Prison floor. Full eviction appeal process. Store/business ownership by characters.

\*\*Chronicle:\*\* bookmark mechanic. "Stories" shareable format. "Building Stories" dedicated menu. Visual timeline. Story generator framing for marketing.

\---

\# 22\. APPENDIX — CONDITION KEYS

Used in both requirements and weight\_modifiers across all event definitions:

\`\`\`  
stats\_above, stats\_below  
has\_state, has\_feeling, has\_trait, has\_persistent\_state  
has\_targeted\_feeling (with at\_filter)  
time\_of\_day, in\_room, not\_in\_room, in\_home\_room, not\_in\_home\_room  
other\_character\_in\_room  
in\_season, season\_intensity\_above  
relationship\_bond\_above, relationship\_bond\_below  
relationship\_tier\_at\_least, relationship\_tier\_at\_most  
relationship\_familiarity\_above  
has\_directional\_feeling  
object\_impression\_above  
faction\_sentiment\_below  
characters\_with\_faction\_sentiment\_below (min\_count, in\_same\_room)  
has\_child\_with\_state  
not\_in\_faction\_type  
\`\`\`