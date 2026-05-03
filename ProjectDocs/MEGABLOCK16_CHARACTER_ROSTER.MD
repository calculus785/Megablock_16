# MegaBlock 16 — Bespoke Character Roster
*Living document. Hand-authored characters with fixed identities.*
*Last updated: Architecture Planning Meeting, Session 3-4*

---

## What This Document Is

Bespoke characters are hand-authored residents with fixed names, traits, stats, and backstories. Unlike generated characters, they are deliberately designed — either for testing specific systems or for adding personality and narrative seeds to the building.

They use the same CharData structure as generated characters. The only difference is that their fields are authored rather than rolled.

---

## How To Add A New Character

Copy the template below. Fill in every field. Add a section under the appropriate category (Test Characters, Narrative Characters, or Special). Upload the updated document to project knowledge.

**When to add bespoke characters:**
- You have a specific personality archetype you want guaranteed in every playthrough
- You need a character to test a specific system (high criminal stats, near-death, etc.)
- You want a narrative seed — a character whose situation is likely to produce interesting stories fast
- You're inspired by a real person, fictional character, or archetype

**When NOT to make them bespoke:**
- The character is just "a bartender" or "a neighbour" with no specific hook
- The archetype will emerge naturally from generation
- You have more than ~10 bespoke characters (too many authored characters crowds out emergence)

---

## How To Use Test Characters

Test characters are the hand-crafted residents of the SimLab scene. When running controlled tests, spawn only these characters — their stats are deliberately set to stress-test specific systems. Because their stats are fixed, bugs are reproducible: same character, same stats, same result.

**Load them by name in SimLab.** Don't randomise their stats during testing. The point is reproducibility.

---

## The Template

```
## [CHARACTER NAME]
**Category:** Test / Narrative / Special
**Role in building:** [job or situation at game start]
**Apartment:** [floor/slot suggestion, or "any"]

### Identity
- Pronouns:
- Sexuality:
- Age: [number — will determine starting life stage]
- Favourite colour: [drives clothing + apartment]
- Interests: [2-4 from the interests list]
- Life arch: [vague descriptor]

### Starting Stats
[Only list stats that deviate significantly from defaults.
Defaults: stress 20, happiness 50, health 80, energy 80,
hunger 20, boredom 10, loneliness 30, cash 200,
criminal_inclination 5, criminal_reputation 0, addiction 0]

### Traits
[3-5 traits. Use trait names from the Traits section of the GDD.]

### Hidden Traits (pre-rolled)
[1-2 traits the player won't see until they emerge through behaviour]

### Starting Feelings
[Any feelings active at game start. Usually empty. Use for specific scenarios.]

### Starting Relationships
[Relationships with other bespoke characters only. Format: Name → tier, bond score, note]

### Backstory
[2-4 sentences. What happened before the game started. Shapes their starting stats.]

### Design Notes
[What system or scenario this character is designed to test or seed.
What stories they're likely to generate. Any quirks to be aware of.]

### Visual Notes
[Silhouette type (A/B/C), skin tone, hair style/colour, clothing colour,
any distinctive features. Rough enough to implement, specific enough to feel right.]
```

---

# TEST CHARACTERS

*Designed for SimLab use. Stats deliberately pushed to stress-test systems.*
*Spawn these 6 together for a full prototype test run.*

---

## SARA VEGA
**Category:** Test — Social/Relationship Systems
**Role in building:** Bartender (floor 1, bar)
**Apartment:** Floor 2, Slot 1

### Identity
- Pronouns: she/her
- Sexuality: bisexual
- Age: 24
- Favourite colour: deep red
- Interests: music, gossip, people-watching
- Life arch: "The Social Connector"

### Starting Stats
- happiness: 65
- loneliness: 10
- boredom: 5
- stress: 25
- cash: 280
- criminal_inclination: 8

### Traits
- FLIRTATIOUS
- GOSSIP
- CHARMING
- SHORT_TEMPERED

### Hidden Traits
- ROMANTIC (emerges after first relationship tier)

### Starting Feelings
- CONTENT_FEELING (mild)

### Starting Relationships
- Dylan Marsh → ACQUAINTANCE, bond +15, regular at her bar
- Charlie K → FRIENDLY, bond +25, she finds him funny and slightly alarming

### Backstory
Sara moved into MegaBlock 16 on day one and immediately took the bartender job from the robot. She knows everyone's business within a week. She can make friends with anyone, which is useful, because she also makes enemies just as fast.

### Design Notes
Primary purpose: stress-test the relationship system and gossip propagation. Sara should rapidly accumulate relationships, spread information across the building, and generate romantic drama. She's the hub character — most social chains will pass through her at some point. Watch for relationship tier progression and gossip event chains. Triggers SHORT_TEMPERED events when high stress meets insults.

### Visual Notes
Silhouette B, warm brown skin, dark curly hair pulled back, red clothing (matches favourite colour), confident posture expression default.

---

## DYLAN MARSH
**Category:** Test — Crime/Police Systems
**Role in building:** Unemployed (at game start)
**Apartment:** Floor 2, Slot 2

### Identity
- Pronouns: he/him
- Sexuality: heterosexual
- Age: 28
- Favourite colour: black
- Interests: gambling, underground fighting, music
- Life arch: "The Downward Spiral"

### Starting Stats
- stress: 72
- happiness: 20
- cash: 45
- criminal_inclination: 75
- criminal_reputation: 30
- addiction: 35
- boredom: 65
- loneliness: 55

### Traits
- CRIMINAL_HEART
- GAMBLER
- SHORT_TEMPERED
- VIOLENT
- ADDICT_PRONE

### Hidden Traits
- MANIPULATIVE (emerges after 3+ manipulation events)

### Starting Feelings
- ANXIOUS (moderate)
- CRAVING (moderate)

### Starting Relationships
- Sara Vega → ACQUAINTANCE, bond +15, she tolerates him at the bar
- Charlie K → FRIEND, bond +40, only person who doesn't judge him

### Backstory
Dylan owes money to people he shouldn't owe money to. He moved into MegaBlock 16 because it was the cheapest place he could find and his last apartment ended badly. He intends to get clean and get a job. He has intended this before.

### Design Notes
Primary purpose: stress-test crime/police pipeline. Dylan's stats are set to make STEAL, THREATEN, DEAL, and eventually GANG events highly eligible. His low cash will push rent crisis events and eviction risk. His high addiction makes RELAPSE and CRAVING events frequent. Test target: witness → report → investigation → arrest chain. Also tests how grief propagates if he dies (few people will care much).

### Visual Notes
Silhouette A, pale skin, dark messy hair, dark clothing, slight hunch in posture sprite. Often has ANXIOUS feeling bubble.

---

## MIRA OKAFOR
**Category:** Test — Loner/Object Impression Systems
**Role in building:** Librarian (floor 1, library)
**Apartment:** Floor 3, Slot 1

### Identity
- Pronouns: she/her
- Sexuality: aromantic, asexual
- Age: 35
- Favourite colour: dark green
- Interests: books, art, philosophy, architecture
- Life arch: "The Quiet Observer"

### Starting Stats
- happiness: 58
- loneliness: 12 (low — she genuinely doesn't feel lonely)
- boredom: 3 (she's never bored with her own company)
- stress: 15
- energy: 75
- cash: 310

### Traits
- RECLUSIVE
- LONER
- MOTIVATED
- FORGETFUL

### Hidden Traits
- HYPOCHONDRIAC (emerges under stress)

### Starting Feelings
- CONTENT_FEELING (strong)

### Starting Relationships
- None at game start (first meeting with everyone)

### Backstory
Mira has worked in libraries her whole adult life. She applied for the librarian job at MegaBlock 16 the day it was posted. She chose her apartment based on how far it is from the bar. She knows the name of every plant in the library and considers them better company than most people she's met. This is not strictly true, but she believes it.

### Design Notes
Primary purpose: test the LONER trait's cap mechanic (soft cap at BEST_FRIEND, 5% override). Mira should accumulate object impressions faster than any other character (high matching interests). Her low loneliness should mean she resists social events that high-loneliness characters seek. Test: does she actually stay solo? Does boredom ever pull her toward social events despite LONER? Also useful for library schedule event testing.

### Visual Notes
Silhouette B, deep brown skin, natural hair loose, dark green clothing, small reading glasses, neutral-to-content default expression.

---

## VANCE ROURKE
**Category:** Test — Elderly/Death/Grief Systems
**Role in building:** Retired (no job, lives on savings)
**Apartment:** Floor 3, Slot 2

### Identity
- Pronouns: he/him
- Sexuality: heterosexual (widower)
- Age: 37 (near elderly threshold of 35, will transition early)
- Favourite colour: navy blue
- Interests: history, cooking, card games, people-watching
- Life arch: "The Last Chapter"

### Starting Stats
- health: 55 (declining)
- happiness: 45
- stress: 30
- energy: 55
- loneliness: 70 (his wife died 2 years ago)
- cash: 520 (retirement savings)
- boredom: 50

### Traits
- OPTIMISTIC
- STUBBORN
- FORGETFUL
- FUNNY

### Hidden Traits
- HYPOCHONDRIAC (has always been, never admitted it)

### Starting Feelings
- GRIEVING (faint, persistent — wife's death)
- LONELY_FEELING (moderate)

### Starting Relationships
- Mira Okafor → FRIENDLY, bond +30, they play cards sometimes
- Sara Vega → FRIENDLY, bond +35, she reminds him of someone

### Backstory
Vance moved his whole life into a single apartment when his wife of 14 years died. He chose MegaBlock 16 because it was loud enough to feel like company without requiring him to talk to anyone. He's older than he looks and feels older than he is. He gives good advice. He rarely follows it himself.

### Design Notes
Primary purpose: test elderly life stage transition, death systems, and grief propagation. Vance's low health and older age mean he'll likely be the first natural death in the SimLab. His high loneliness makes him seek social events despite low energy. Test: does his storybook accumulate meaningful memories before he dies? Does grief propagate correctly to Sara and Mira when he goes? STUBBORN trait means high patience counter — test the intent queue with him.

### Visual Notes
Silhouette A, weathered olive skin, grey-white hair, navy clothing, slight limp movement type when health drops below 40.

---

## YUKI TANAKA
**Category:** Test — Romantic/Relationship Tier Progression
**Role in building:** Cafe worker (floor 1, cafe)
**Apartment:** Floor 2, Slot 3

### Identity
- Pronouns: they/them
- Sexuality: pansexual
- Age: 22
- Favourite colour: yellow
- Interests: cooking, music, fashion, social media
- Life arch: "The Hopeless Romantic"

### Starting Stats
- happiness: 62
- loneliness: 68 (high — desperately wants connection)
- stress: 28
- horniness: 65 (high — drives romantic event eligibility)
- boredom: 40
- cash: 190

### Traits
- ROMANTIC
- OPTIMISTIC
- HIGH_LIBIDO
- FLIRTATIOUS

### Hidden Traits
- JEALOUS_TYPE (emerges when a PARTNER relationship forms with someone else)

### Starting Feelings
- LONELY_FEELING (strong)
- HOPEFUL (mild)

### Starting Relationships
- Sara Vega → FRIENDLY, bond +28, they chat during Sara's breaks

### Backstory
Yuki moved into MegaBlock 16 after a long-distance relationship ended. They believe in love in the way that people who've been hurt still believe in it — loudly and defensively. They will fall for someone within the first week. Whether that's good for anyone involved is another question.

### Design Notes
Primary purpose: stress-test romantic tier progression (ASK_OUT → PARTNER → DEEPLY_BONDED → MARRIED chain). Yuki's stats are designed to make romantic events highly eligible and escalate quickly. Their JEALOUS_TYPE hidden trait should emerge organically when a rival relationship forms. Test the event-gated tier transitions carefully with Yuki — they're the most likely to hit the full romantic chain in a prototype run.

### Visual Notes
Silhouette B, light skin with warm undertone, short bright yellow-streaked hair, yellow clothing accents, often has FLIRTY or HOPEFUL feeling bubble.

---

## JEROME BANKS
**Category:** Test — Job/Management Systems
**Role in building:** Maintenance worker (Strata-assigned, basic labour role)
**Apartment:** Floor 2, Slot 4

### Identity
- Pronouns: he/him
- Sexuality: heterosexual
- Age: 31
- Favourite colour: orange
- Interests: fitness, mechanics, DIY, sports
- Life arch: "The Honest Grind"

### Starting Stats
- stress: 38
- happiness: 52
- energy: 85
- cash: 160
- job_satisfaction: 35 (starting low — tests quit_job threshold)
- boredom: 45

### Traits
- MOTIVATED
- STUBBORN
- BY_THE_BOOK
- NEAT_FREAK

### Hidden Traits
- SHORT_TEMPERED (emerges under sustained high stress)

### Starting Feelings
None.

### Starting Relationships
- Dylan Marsh → COOL, bond -5, Dylan tried to get him involved in something shady once

### Backstory
Jerome has worked maintenance jobs his whole life. He's good at them. He doesn't love them. He moved to MegaBlock 16 thinking it might be a step toward something else, though he's not sure what. He keeps his apartment immaculate. He wishes other people would do the same with the hallways.

### Design Notes
Primary purpose: test the Jobs system — shift assignment, job_satisfaction tracking, QUIT_JOB eligibility. Jerome's satisfaction starts low enough that with a few bad shifts he could quit, triggering the robot-replacement flow. His BY_THE_BOOK trait makes him likely to report crimes he witnesses — test the police pipeline from witness through to report. NEAT_FREAK means high stress from messy rooms — test aura effects on stats.

### Visual Notes
Silhouette A, dark brown skin, close-cropped hair, orange work shirt, strong build silhouette, neutral-serious default expression.

---

# NARRATIVE CHARACTERS

*Designed for storytelling. Added to the building during regular play, not just testing.*
*These are the characters that feel handcrafted rather than generated.*

---

## CHARLIE K
**Category:** Special / Narrative
**Role in building:** Pest control / Janitor (essential role, initially robot-held)
**Apartment:** Floor B1 (the sewers — he prefers it down there)

### Identity
- Pronouns: he/him
- Sexuality: heterosexual (obsessively, tragically)
- Age: 20
- Favourite colour: green (the colour of the mould he considers a pet)
- Interests: music, rats, cheese, cats, cleaning (his own peculiar definition of it)
- Life arch: "The Wildcard"

### Starting Stats
- happiness: 55 (surprisingly okay with his situation)
- stress: 20 (genuinely unbothered by things that should bother him)
- health: 60 (the things he's eaten should have killed him)
- energy: 90 (inexhaustible in baffling ways)
- boredom: 5 (never bored, always occupied with something inadvisable)
- loneliness: 80 (desperately lonely, specifically for one person who doesn't know he exists)
- cash: 12 (at any given time)
- criminal_inclination: 45 (not malicious — just flexible about rules)
- addiction: 70 (paint fumes, cat food, other things not meant for human consumption)
- intelligence: 15 (custom stat — optional, park if stat list is locked)

### Traits
- ADDICT_PRONE
- FUNNY (unintentionally, consistently)
- RECKLESS
- LOYAL (bespoke weight modifier: bond_above 30 = dramatically boosted self-sacrifice events)
- OBSESSIVE (targeted at one character: The Object of His Affection — see below)
- SURPRISINGLY_CAPABLE (bespoke hidden trait — occasionally rolls events far above his apparent skill level)

### Hidden Traits
- SECRETLY_TALENTED (musical — emerges if he finds a piano or instrument interactable)
- GOOD_HEART (emerges during crisis events — he helps without thinking)

### Starting Feelings
- LONELY_FEELING (intense, targeted at The Object of His Affection)
- CONTENT_FEELING (baseline, coexisting with loneliness — he doesn't understand this about himself)

### Starting Relationships
- Sara Vega → FRIENDLY, bond +25, she gives him food sometimes without asking questions
- Dylan Marsh → FRIEND, bond +40, they understand each other on a level neither could articulate
- The Object of His Affection → ROMANTIC_INTEREST, bond +85 (one-sided — she has him at NEUTRAL or COOL)

### Backstory
Charlie has always lived slightly outside the normal rules of human society, not through malice but through a fundamental disconnect between how the world works and how Charlie thinks it works. He applied for the pest control job by showing up with a bag of rats he'd already caught and releasing them in the management floor to demonstrate the problem and his solution simultaneously. The Mayor robot hired him on the spot. He has claimed the sewers as his apartment because he says it's "cosy" and the rent is zero. He is correct on both counts.

The Object of His Affection is a specific generated or bespoke character designated before the playthrough begins — someone Charlie fixates on completely. She is not aware of the depth of his feelings. He has written her letters. He has never sent them because he is not fully sure how letters work.

### Design Notes

Charlie is the wildcard. He exists to generate unpredictable stories and to test the edges of every system.

**What he tests specifically:**
- Obsession mechanic (REPEAT × many = OBSESSING, targeted feeling escalation)
- Addiction system (high addiction stat + ADDICT_PRONE trait = frequent CRAVING/RELAPSE events)
- Criminal events without malicious intent (he steals food, not out of crime but hunger)
- The sewer sleep spots (he's the main user, validates homeless system without eviction)
- Low cash rent crisis without actually being homeless (he doesn't pay rent — nobody's noticed yet)
- Surprisingly capable outcomes (designed to occasionally produce storybook moments where Charlie accidentally does something impressive)

**Stories Charlie naturally generates:**
- Elaborate failed attempts to impress The Object of His Affection
- Accidentally becoming involved in Dylan's criminal activities without understanding what he's doing
- Finding a stray cat and becoming deeply attached to it (if cat interactable is added)
- Being the unexpected emotional support during crises (GOOD_HEART hidden trait)
- Eating something nobody should eat and being completely fine
- Forming a genuine friendship with Vance over cards because neither of them has anywhere better to be
- Writing a song that is objectively terrible but somehow moves Sara to tears

**Important notes for implementation:**
- Charlie's cash should reset to approximately 12 after any event that gives him money. He spends it immediately on things that cannot be explained.
- His apartment is the sewer. This is not a bug. Do not fix it.
- The Object of His Affection's identity should be decided per-playthrough — designate one generated female character before starting. Her complete indifference to Charlie is more tragic and more funny than active rejection.
- SURPRISINGLY_CAPABLE should fire rarely (weight: 0.5) but when it does, it should produce a storybook entry that is completely at odds with everything else Charlie does. "Charlie fixed the elevator in twenty minutes using only a bent fork. Nobody saw him do it. He doesn't mention it."

### Visual Notes
Silhouette A, pale skin, dark unkempt hair that looks like it was cut with a knife (it was), green shirt (always the same green shirt), slight hunch, wide-eyed default expression somewhere between delighted and confused. Often has CRAVING or LONELY_FEELING bubble but also frequently CONTENT_FEELING. These coexist. That's the point.

---

# PLANNED CHARACTERS (To Design Later)

Archetypes worth adding as bespoke characters. Not yet designed — placeholder list.

- **The Corrupt Cop** — human police officer, CORRUPT trait, tests police system edge cases
- **The Gang Leader** — high criminal stats, leadership quality, seeds the gang formation system
- **The Doctor** — arrives when hospital unlocks, high health skill, seeds medical event chains
- **The Journalist** — high gossip/observation, writes about building events, unique storybook perspective
- **The Star-Crossed Lover** — starts with a DEEPLY_BONDED relationship to someone incompatible (different life arch, imminent death, rival faction), seeds tragedy
- **The Mayor's Secret** — a generated character who is secretly the son/daughter of the Mayor robot (impossible, but Charlie believes it firmly and acts accordingly)

---

# APPENDIX — STAT DEFAULTS REFERENCE

For quick reference when writing character stats. Only list deviations from these defaults in character entries.

```
stress:                 20
happiness:              50
health:                 80
energy:                 80
hunger:                 20
boredom:                10
loneliness:             30
horniness:              20
need_for_toilet:        0
grief:                  0
global_reputation:      50
attractiveness:         50
cash:                   200
criminal_inclination:   5
criminal_reputation:    0
addiction:              0
job_satisfaction:       50 (if employed)
```