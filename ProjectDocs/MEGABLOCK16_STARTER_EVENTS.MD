# MegaBlock 16 — Starter Event List
*Living document. Events described in plain English, ready for implementation.*
*Refer to the Event Design Bible for data shapes and naming conventions.*
*Last updated: Architecture Planning Meeting, Session 3-4*

---

## How To Use This Document

Each event is described with enough detail to implement directly in `events.gd`. During dev sessions, work through this list top-to-bottom within each category.

During Event Design Chat sessions, use this document as a starting reference — new events designed in those chats get added here before implementation.

**Format per event:**
- **ID** — ALL_CAPS_SNAKE_CASE
- **Scope** — character or building
- **Magnitude** — minor/moderate/major/huge
- **Trigger** — rolled or auto_fire
- **Plain English** — what happens
- **Requirements** — what must be true
- **Key outcomes** — what changes
- **Storybook** — 2-3 template examples
- **Chains to** — what events this naturally leads to
- **Notes** — design intent, system tested

Events marked with ★ are player_choice events.
Events marked with ⚡ are auto_fire events.
Events marked with 📰 are ticker_worthy.

---

# SOLO EVENTS (Any Location)

These fire for a character alone or regardless of who else is present. The bread and butter of the simulation — they fill downtime with internal life.

---

### THINK_ABOUT
**Scope:** character | **Magnitude:** minor | **Trigger:** rolled
**What happens:** Character recalls a long-term memory. The memory's tone (fond, resentful, neutral) modifies their current feelings.
**Requirements:** has at least 1 long-term memory
**Key outcomes:** feeling push based on memory tone. times_recalled increments on the memory.
**Storybook:**
- "{name} thought about {target}. The memory was {tone}."
- "{name} couldn't stop thinking about what happened with {target}."
- "It crossed {name}'s mind again. {target}. That day."
**Chains to:** THINK_ABOUT again (REPEAT), VISIT_CHARACTER (intent queued if fond), CONFRONT (intent if resentful)
**Notes:** Core memory system driver. Should fire frequently. Weight boosted by loneliness, boredom, grief. Weight reduced by high energy, being in social room.

---

### REST
**Scope:** character | **Magnitude:** minor | **Trigger:** rolled
**What happens:** Character sits down and does nothing for a beat.
**Requirements:** energy below 60
**Key outcomes:** energy +5, stress -3, boredom +5
**Storybook:**
- "{name} sat down for a moment."
- "{name} needed a minute."
**Chains to:** SLEEP (if energy still low), WANDER (if boredom climbs)
**Notes:** Simple energy recovery. High base weight so characters don't run themselves ragged.

---

### WANDER
**Scope:** character | **Magnitude:** minor | **Trigger:** rolled
**What happens:** Character decides to go to a different room for no particular reason.
**Requirements:** not sleeping, boredom above 25
**Key outcomes:** move_to random eligible room, boredom -10
**Storybook:**
- "{name} wandered out of {room}. No destination in mind."
- "{name} got restless and left."
**Chains to:** Room-arrival reactive event, hallway proximity events
**Notes:** The exploration driver. Gets characters moving so room-based events can fire. Weight boosted heavily by boredom.

---

### SLEEP
**Scope:** character | **Magnitude:** minor | **Trigger:** rolled
**What happens:** Character goes home and sleeps. Locked for sleep duration.
**Requirements:** energy below 30 OR time_of_day is "night", in_home_room or is_homeless
**Key outcomes:** energy +50, stress -10, hunger +15, need_for_toilet +20. Character locked (sleeping state) for ~6 in-game hours.
**Storybook:**
- "{name} went to bed."
- "{name} collapsed into bed. It had been a long day."
**Chains to:** WAKE_UP
**Notes:** If homeless, fires at sleep_spot interactables instead of apartment. Weight massively boosted at night + low energy.

---

### WAKE_UP
**Scope:** character | **Magnitude:** minor | **Trigger:** auto (fires when sleep timer ends)
**What happens:** Character wakes up. Sleeping state cleared.
**Requirements:** is_sleeping is true, sleep timer expired
**Key outcomes:** clear sleeping state, push morning feelings based on stats (well-rested if energy high, groggy if still low)
**Storybook:**
- "{name} woke up."
- "{name} opened their eyes. Another day in the block."
**Chains to:** GO_TO_BATHROOM, EAT, WANDER
**Notes:** Gateway event for the day. Feeling push sets the tone.

---

### DAYDREAM
**Scope:** character | **Magnitude:** minor | **Trigger:** rolled
**What happens:** Character zones out. Internal monologue moment.
**Requirements:** boredom above 40, not in sequence
**Key outcomes:** boredom -8, happiness +3 OR -3 (weighted by current feelings)
**Storybook:**
- "{name} stared at nothing for a while."
- "{name} drifted off somewhere in their head."
- "For a few minutes, {name} wasn't really here."
**Chains to:** THINK_ABOUT (if memory surfaces during daydream)
**Notes:** Atmosphere event. Makes characters feel internal. Weight boosted by RECLUSIVE trait.

---

### LOOK_IN_MIRROR
**Scope:** character | **Magnitude:** minor | **Trigger:** rolled
**What happens:** Character looks at themselves in the mirror in their apartment.
**Requirements:** in_home_room, has mirror interactable
**Key outcomes:** small happiness delta based on attractiveness stat and current feelings. High attractiveness + good mood = CONFIDENT push. Low attractiveness + bad mood = MISERABLE push.
**Storybook:**
- "{name} looked at themselves in the mirror."
- "{name} studied their reflection. They weren't sure what they saw."
**Chains to:** None directly. Seeds feeling states that drive later events.
**Notes:** Subtle self-perception event. Tests feeling push based on stat combinations.

---

### CRY
**Scope:** character | **Magnitude:** minor | **Trigger:** rolled
**What happens:** Character cries alone.
**Requirements:** happiness below 20 OR has_feeling GRIEVING or HEARTBROKEN, ideally in_home_room
**Key outcomes:** stress -15, happiness +5 (catharsis), push EXHAUSTED_FEELING
**Storybook:**
- "{name} cried. Nobody was around to see."
- "{name} let it out. Finally."
- "It happened quietly. {name} didn't make a sound."
**Chains to:** THINK_ABOUT (memory surfaces), REST
**Notes:** 📰 ticker_worthy only if the character is the player character or a followed character. Catharsis — the stat improvement is the design point. Crying helps.

---

# SOCIAL EVENTS (Any Room With Other Characters)

---

### GREET
**Scope:** character | **Magnitude:** minor | **Trigger:** rolled
**What happens:** Character greets another character in the same room. First contact event.
**Requirements:** other_character_in_room, no_existing_relationship with target OR familiarity below 5
**Key outcomes:** familiarity +5, bond +2. Creates RelationshipRecord if first meeting.
**Storybook:**
- "{name} introduced themselves to {target}."
- "{name} and {target} met for the first time."
**Chains to:** CHAT, AWKWARD_SILENCE
**Notes:** The relationship seed. Every pair starts here. Weight boosted by CHARMING, FLIRTATIOUS. Reduced by RECLUSIVE.

---

### CHAT
**Scope:** character | **Magnitude:** minor | **Trigger:** rolled
**What happens:** Two characters have a casual conversation.
**Requirements:** other_character_in_room, relationship_familiarity_above 3
**Key outcomes:** bond +3, loneliness -8 for both, boredom -5
**Storybook:**
- "{name} and {target} talked for a while."
- "{name} chatted with {target} about nothing in particular."
**Chains to:** DEEP_CONVERSATION (if bond climbs), GOSSIP (if GOSSIP trait), ARGUE (if rivalry high)
**Notes:** The social workhorse. Should fire constantly. Builds relationships slowly and reliably. High base weight.

---

### DEEP_CONVERSATION
**Scope:** character | **Magnitude:** moderate | **Trigger:** rolled
**What happens:** Characters have a meaningful conversation. Vulnerability, shared experience.
**Requirements:** relationship_bond_above 30, other_character_in_room, time_of_day ["evening", "night"]
**Key outcomes:** bond +10, trust +8, loneliness -20 for both, push GRATEFUL or AFFECTIONATE
**Storybook:**
- "{name} and {target} talked until the lights dimmed. Something shifted between them."
- "It started as small talk. It didn't stay that way."
- "{target} told {name} something they'd never told anyone."
**Chains to:** THINK_ABOUT (memory of conversation), relationship tier progression
**Notes:** Key relationship accelerator. Evening/night requirement gives it a "late night talk" feel. Exclude robots. Tests trust mechanics.

---

### GOSSIP
**Scope:** character | **Magnitude:** minor | **Trigger:** rolled
**What happens:** Character shares a short-term memory with another character. The target now knows about the event.
**Requirements:** has_trait GOSSIP (or base weight with GOSSIP boost), other_character_in_room, has short-term memory with tone "interesting" or "shocking"
**Key outcomes:** target gains secondhand memory entry. Bond +2 (shared info builds connection). Source memory marked as "shared."
**Storybook:**
- "{name} told {target} about what happened with {subject}."
- "{name} leaned in and shared something they probably shouldn't have."
**Chains to:** Target may THINK_ABOUT the gossip subject. Target may CONFRONT the gossip subject. Information network expands.
**Notes:** The information propagation system. This is how characters learn about events they didn't witness. Crucial for the building feeling alive.

---

### COMPLIMENT
**Scope:** character | **Magnitude:** minor | **Trigger:** rolled
**What happens:** Character says something nice to another character.
**Requirements:** other_character_in_room, relationship_bond_above 0
**Key outcomes:** target happiness +5, bond +4, push HAPPY on target. If FLIRTATIOUS trait, push FLIRTY instead.
**Storybook:**
- "{name} said something kind to {target}. It landed."
- "{target} smiled at what {name} said."
**Chains to:** FLIRT (if both have compatible sexuality + high enough bond)
**Notes:** Gentle positive social event. Tests targeted feeling pushes. CHARMING trait boosts weight.

---

### INSULT
**Scope:** character | **Magnitude:** minor | **Trigger:** rolled
**What happens:** Character says something hurtful to another character.
**Requirements:** other_character_in_room, relationship_bond_below 0 OR has_feeling FURIOUS or BITTER
**Key outcomes:** target happiness -8, bond -6, rivalry +3. Push HUMILIATED on target. Push FURIOUS on target if they have SHORT_TEMPERED.
**Storybook:**
- "{name} said something cutting to {target}."
- "{target} didn't see it coming. {name}'s words hit hard."
**Chains to:** ARGUE, CONFRONT (target queues intent), CRY (if target alone later)
**Notes:** Seeds conflict chains. Weight boosted by SHORT_TEMPERED, FURIOUS feeling, low bond.

---

### ARGUE
**Scope:** character | **Magnitude:** moderate | **Trigger:** rolled
**What happens:** Two characters have a heated argument. Both get stressed.
**Requirements:** other_character_in_room, rivalry above 10 OR both have FURIOUS feeling, relationship_bond_below 40
**Key outcomes:** stress +15 both, bond -8, rivalry +5, push FURIOUS on both. Witnesses in room get short-term memory (observation: argument).
**Storybook:**
- "{name} and {target} argued. It got loud."
- "Nobody in the {room} pretended not to hear {name} and {target} going at it."
- "It started about nothing. It stopped being about nothing fast."
**Chains to:** 📰 PHYSICAL_FIGHT (if both FURIOUS + VIOLENT trait), APOLOGISE, AVOID_CHARACTER (intent)
**Notes:** Witness mechanic is key — bystanders form memories and opinions. Tests witness → gossip → reputation chain.

---

### ★ APOLOGISE
**Scope:** character | **Magnitude:** moderate | **Trigger:** rolled
**What happens:** Character apologises to someone they've wronged.
**Requirements:** relationship has recent negative interaction (argument, insult in last 3 days), bond between -40 and +60 (won't apologise to mortal enemies, doesn't need to for best friends)
**Key outcomes:** bond +12, rivalry -5, stress -8 for actor. Target rolls acceptance: accept (bond +8 more, push GRATEFUL) or reject (bond -5, push BITTER on actor).
**Player choice:** "Apologise sincerely" (warm, bond +15) / "Apologise reluctantly" (neutral, bond +8) / "Don't apologise" (abort, no change)
**Storybook:**
- "{name} apologised to {target}. {target} {accepted/didn't accept}."
- "It took {name} three days to say sorry. {target} had been waiting."
**Chains to:** DEEP_CONVERSATION (if accepted), NURSING_GRUDGE feeling on target (if rejected)
**Notes:** ★ Player choice event. Tests tonal responses — same outcome, different relationship delta based on tone.

---

### CONFRONT
**Scope:** character | **Magnitude:** moderate | **Trigger:** rolled
**What happens:** Character confronts someone about a specific grievance (stored in memory).
**Requirements:** has_targeted_feeling NURSING_GRUDGE or BITTER at target, target in same room
**Key outcomes:** stress +10 for both, bond delta depends on target response. Grudge feeling cleared on actor regardless (they said their piece).
**Storybook:**
- "{name} cornered {target}. There was something that needed saying."
- "{name} finally said what they'd been holding in about {target}."
**Chains to:** ARGUE (if target responds badly), APOLOGISE (if target responds well), DEEP_CONVERSATION (rare, if both bond high)
**Notes:** Tests targeted feelings driving event eligibility. The grudge-to-confrontation-to-resolution chain is one of the core drama loops.

---

### ★ FLIRT
**Scope:** character | **Magnitude:** moderate | **Trigger:** rolled
**What happens:** Character makes a romantic advance.
**Requirements:** relationship_bond_above 20, compatible sexuality, other_character_in_room, exclude_robots
**Key outcomes:** bond +5, push FLIRTY on actor. Target rolls response: reciprocate (push FLIRTY on target, bond +8) or reject (push HUMILIATED on actor, bond -3).
**Player choice:** "Flirt warmly" / "Flirt playfully" / "Don't flirt"
**Storybook:**
- "{name} tried something. A look, a comment. {target} {noticed/didn't notice}."
- "{name} flirted with {target}. It was {smooth/clumsy/obvious}."
**Chains to:** ASK_OUT (if reciprocated + bond climbs), THINK_ABOUT (actor thinks about target later)
**Notes:** ★ Player choice. Gateway to romantic chain. Weight boosted by FLIRTATIOUS, HIGH_LIBIDO, ROMANTIC traits. Smooth/clumsy determined by CHARMING trait presence.

---

### ★ ASK_OUT
**Scope:** character | **Magnitude:** major 📰 | **Trigger:** rolled
**What happens:** Character formally asks another out. Event-gated tier transition to ROMANTIC_INTEREST.
**Requirements:** relationship_bond_above 60, compatible sexuality, has_targeted_feeling FLIRTY or INFATUATED_WITH at target, other_character_in_room
**Key outcomes:** If accepted: both move to ROMANTIC_INTEREST tier, push ELATED + EXCITED on both. If rejected: push HEARTBROKEN on actor, bond -15.
**Player choice:** "Ask confidently" / "Ask nervously" / "Don't ask"
**Storybook:**
- "{name} asked {target} out. The {room} held its breath."
- "{name} did it. They actually asked. {target} said {yes/no}."
- "It had been building for days. {name} finally said it out loud."
**Chains to:** DATE (intent queued if accepted), CRY (if rejected), THINK_ABOUT
**Notes:** ★ Player choice. 📰 Ticker worthy. This is a major relationship milestone. Tests event-gated tier transitions. Witnesses get strong memory entries.

---

### PHYSICAL_FIGHT
**Scope:** character | **Magnitude:** major 📰 | **Trigger:** rolled
**What happens:** Two characters fight physically.
**Requirements:** both have FURIOUS feeling, same room, at least one has VIOLENT trait or criminal_inclination above 40
**Key outcomes:** health -5 to -20 (roll), stress +25 both, bond -20, rivalry +15. Loser gets HUMILIATED, winner gets COCKY. Witnesses get SHOCKED memory. Police notified if witness rolls REPORT_TO_POLICE.
**Storybook:**
- "{name} hit {target}. The {room} went quiet."
- "It happened fast. {name} and {target}. Blood on the floor."
- "Someone was always going to throw the first punch."
**Chains to:** REPORT_TO_POLICE (witness), NURSING_GRUDGE (loser), INTERVENE (if third character present with high bond to either)
**Notes:** 📰 Major violence event. Tests witness → police pipeline. Health damage is real — accumulated fights can kill. Winner/loser determined by health + energy comparison with random variance.

---

# HALLWAY EVENTS (Transit / Proximity)

---

### NOD_IN_PASSING
**Scope:** character | **Magnitude:** minor | **Trigger:** proximity reactive
**What happens:** Two characters pass each other in a hallway and acknowledge each other.
**Requirements:** both in same hallway, both in transit, familiarity above 5
**Key outcomes:** familiarity +1. That's it. Tiny but cumulative.
**Storybook:**
- "{name} and {target} passed each other in the hall."
**Chains to:** Nothing. This is texture.
**Notes:** Lightest possible event. Doesn't interrupt transit. Shows characters know each other exists.

---

### HALLWAY_CHAT
**Scope:** character | **Magnitude:** minor | **Trigger:** proximity reactive
**What happens:** Two characters stop in the hallway to talk briefly.
**Requirements:** both in same hallway, relationship_bond_above 15, neither in a rush (no critical intents)
**Key outcomes:** bond +2, loneliness -3, boredom -3. Both characters' transit pauses briefly.
**Storybook:**
- "{name} stopped {target} in the hallway. They talked for a minute."
- "{name} and {target} ran into each other. The elevator could wait."
**Chains to:** CHAT (if both decide to go to same room)
**Notes:** Tests proximity reactive system. Brief pause, not full transit interruption.

---

### AWKWARD_HALLWAY_ENCOUNTER
**Scope:** character | **Magnitude:** minor | **Trigger:** proximity reactive
**What happens:** Two characters who dislike each other pass in the hallway.
**Requirements:** both in same hallway, relationship_bond_below -10
**Key outcomes:** stress +3 both, push ANXIOUS on the one with lower confidence.
**Storybook:**
- "{name} and {target} passed each other. Neither looked up."
- "The hallway wasn't wide enough for both of them."
**Chains to:** THINK_ABOUT (dwelling on the encounter), AVOID_CHARACTER intent
**Notes:** Tests negative relationships in transit. Atmospheric. Builds tension without escalation.

---

### BUMP_INTO
**Scope:** character | **Magnitude:** minor | **Trigger:** proximity reactive
**What happens:** Two characters physically bump into each other in the hallway.
**Requirements:** both in same hallway, both in transit, random chance (low weight)
**Key outcomes:** branch by relationship. Strangers: GREET opportunity. Friends: bond +1, laugh. Enemies: stress +5, push FURIOUS if SHORT_TEMPERED.
**Storybook:**
- "{name} bumped into {target} coming around the corner."
- "They collided. {name} said sorry. {target} {laughed/didn't}."
**Chains to:** GREET (strangers), ARGUE (enemies), nothing (friends)
**Notes:** Physical comedy potential. The same event plays completely differently depending on the relationship.

---

### EAVESDROP
**Scope:** character | **Magnitude:** minor | **Trigger:** proximity reactive
**What happens:** Character overhears a conversation happening in a nearby room while passing through the hallway.
**Requirements:** in hallway, adjacent room has 2+ characters currently in CHAT or ARGUE event
**Key outcomes:** actor gains short-term memory (observation) about the overheard topic. If argument: stress +3. If gossip: gains secondhand information.
**Storybook:**
- "{name} overheard something through the wall."
- "Walking past the {room}, {name} caught a few words. Enough."
**Chains to:** GOSSIP (actor now knows something), CONFRONT (if overheard content involves them)
**Notes:** Information leaks through walls. Tests memory propagation through architectural proximity rather than direct social contact.

---

# BAR EVENTS

---

### VISIT_BAR
**Scope:** character | **Magnitude:** minor | **Trigger:** rolled
**What happens:** Character decides to go to the bar.
**Requirements:** not in bar, boredom above 20 OR loneliness above 40 OR stress above 50, time_of_day ["day", "evening", "night"]
**Key outcomes:** intent queued: go to bar. Boredom -5 (anticipation).
**Storybook:**
- "{name} headed to the bar."
- "{name} needed a drink. Or just somewhere to be."
**Chains to:** Room arrival events in bar
**Notes:** Intent-based movement. Character queues the visit, pathfinds there, room-arrival events fire on entry.

---

### ORDER_DRINK
**Scope:** character | **Magnitude:** minor | **Trigger:** rolled
**What happens:** Character orders a drink at the bar. Interacts with bartender (human or robot).
**Requirements:** in_room "bar", room_has_interactable "bar_counter"
**Key outcomes:** cash -5, stress -8, happiness +5, addiction +2 (if ADDICT_PRONE, +5 instead). If bartender is human character: bond +1 with bartender.
**Storybook:**
- "{name} ordered a drink. The {bartender} poured without asking what."
- "{name} sat at the bar. The drink appeared."
**Chains to:** ORDER_DRINK again (REPEAT → DRUNK state), CHAT with nearby character, DRINK_ALONE
**Notes:** Core bar activity. REPEAT mechanic: 3+ consecutive ORDER_DRINK pushes TIPSY state, 5+ pushes DRUNK state. DRUNK modifies weights for ARGUE, FLIRT, CRY, CONFESS.

---

### DRINK_ALONE
**Scope:** character | **Magnitude:** minor | **Trigger:** rolled
**What happens:** Character drinks alone in the bar. No interaction sought.
**Requirements:** in_room "bar", happiness below 35 OR loneliness above 60
**Key outcomes:** stress -5, loneliness +5 (drinking alone makes it worse), push MISERABLE if already has LONELY_FEELING
**Storybook:**
- "{name} drank alone. Nobody sat next to them."
- "The bar was full. {name} was still alone in it."
**Chains to:** CRY (if happiness drops further), CHAT (if another character approaches them)
**Notes:** Atmospheric sad event. The storybook text is doing heavy lifting here.

---

### PLAY_POOL_SEQ (Sequence)
**Scope:** character | **Magnitude:** moderate | **Trigger:** rolled
**What happens:** Two characters play pool. 3-beat sequence: rack → play → outcome.
**Requirements:** in_room "bar", room_has_interactable "pool_table", other_character_in_room, relationship_familiarity_above 5
**Key outcomes:** winner gets happiness +15, boredom -25, push COCKY. Loser gets happiness -5, push FRUSTRATED. Bond +5 either way (shared activity). Rivalry +3.
**Storybook (per beat):**
- Beat 1: "{name} racked the balls. {target} chalked a cue."
- Beat 2: "The game was {close/one-sided}."
- Beat 3 (winner): "{name} won. They tried not to look too smug."
- Beat 3 (loser): "{target} lost. They put the cue down a little too hard."
**Chains to:** PLAY_POOL_SEQ again (rematch intent if COMPETITIVE), ARGUE (if loser has SHORT_TEMPERED + HUMILIATED), BREAK_POOL_CUE (rare, if VIOLENT + FURIOUS)
**Notes:** The flagship sequence. Tests full sequence mechanics: beat progression, weighted outcomes, winner/loser branching, trait-modified weights.

---

### BREAK_POOL_CUE
**Scope:** character | **Magnitude:** moderate 📰 | **Trigger:** rolled
**What happens:** Character breaks the pool cue in frustration.
**Requirements:** in_room "bar", has_feeling FURIOUS or FRUSTRATED, has_trait VIOLENT or criminal_inclination above 50
**Key outcomes:** pool_cue interactable replaced with broken_pool_cue. Witnesses get SHOCKED memory. criminal_reputation +5. Pool table unusable until repaired.
**Storybook:**
- "{name} snapped the pool cue over their knee. The bar went quiet."
- "Nobody was playing pool anymore. {name} made sure of that."
**Chains to:** REPORT_TO_POLICE (witness), ARGUE with bartender, KICKED_OUT_OF_BAR
**Notes:** 📰 Tests breaking system. Spawns broken variant interactable. Pool table becomes unusable (tests interactable state).

---

### BAR_FIGHT (Sequence)
**Scope:** character | **Magnitude:** major 📰 | **Trigger:** rolled
**What happens:** A full fight breaks out in the bar. 2-beat sequence: escalation → outcome.
**Requirements:** 2+ characters in bar with FURIOUS feeling, rivalry above 15 between them
**Key outcomes:** health damage to both, property damage possible (random interactable in bar broken), witnesses get strong negative memories, police notified if witness reports
**Storybook:**
- Beat 1: "It started with a shove. Then {name} swung."
- Beat 2: "By the time it was over, {result}. The bartender was already calling it in."
**Chains to:** REPORT_TO_POLICE, KICKED_OUT_OF_BAR, NURSING_GRUDGE, THINK_ABOUT (witnesses)
**Notes:** 📰 Higher magnitude than PHYSICAL_FIGHT because it happens in a public venue with witnesses and property damage. Tests multiple witness reactions simultaneously.

---

### CONFESS_SECRET
**Scope:** character | **Magnitude:** moderate | **Trigger:** rolled
**What happens:** Character confesses something personal to another character at the bar. Alcohol-fuelled vulnerability.
**Requirements:** in_room "bar", has_state DRUNK or TIPSY, relationship_bond_above 25, time_of_day "night"
**Key outcomes:** trust +15, bond +8. Actor pushes memory tagged "confession." Target gains strong memory of the confession.
**Storybook:**
- "{name} told {target} something they'd never said out loud before."
- "Three drinks in, {name} started talking. Really talking."
- "The bar was closing. {name} was still going. {target} was still listening."
**Chains to:** DEEP_CONVERSATION, THINK_ABOUT (both characters recall later), GOSSIP (target might share the secret — GOSSIP trait boosts this heavily)
**Notes:** The bar's unique emotional function. Drunk + night + bond threshold = vulnerability. If the target has GOSSIP trait, the secret spreads. Drama.

---

# LIBRARY EVENTS

---

### VISIT_LIBRARY
**Scope:** character | **Magnitude:** minor | **Trigger:** rolled
**What happens:** Character decides to go to the library.
**Requirements:** not in library, boredom above 30, interests include "books" OR "art" OR "philosophy" (weight boost, not requirement)
**Key outcomes:** intent queued: go to library.
**Storybook:**
- "{name} headed to the library."
**Chains to:** Room arrival events in library
**Notes:** Characters with matching interests visit more often. Others still can.

---

### READ_BOOK
**Scope:** character | **Magnitude:** minor | **Trigger:** rolled
**What happens:** Character reads a book in the library.
**Requirements:** in_room "library", room_has_interactable "bookshelf"
**Key outcomes:** boredom -20, stress -10, happiness +5. Object impression of bookshelf +3 per read.
**Storybook:**
- "{name} found a book and disappeared into it."
- "{name} read for hours. The building kept going without them."
**Chains to:** READ_BOOK again (REPEAT — characters who love reading will chain this), THINK_ABOUT (the book sparks a related memory)
**Notes:** Core library activity. REPEAT mechanic: tracks consecutive reads. At 3+ consecutive, push INSPIRED feeling. At 5+, push CONTENT_FEELING. Tests object impression accumulation.

---

### ADMIRE_STATUE
**Scope:** character | **Magnitude:** minor | **Trigger:** rolled
**What happens:** Character notices and admires the library statue.
**Requirements:** in_room "library", room_has_interactable "statue", object_impression of statue below 60 (diminishing returns — once familiar, stops being novel)
**Key outcomes:** happiness +3, push INSPIRED (brief), object impression +5.
**Storybook:**
- "{name} stopped in front of the statue. Something about it."
- "{name} looked at the statue like they were seeing it for the first time."
**Chains to:** THINK_ABOUT (if the statue reminds them of someone), ADMIRE_STATUE again (diminishing returns)
**Notes:** Tests object impressions and the diminishing-novelty system. Interest tags: "art", "architecture" boost weight.

---

### QUIET_MOMENT_TOGETHER
**Scope:** character | **Magnitude:** minor | **Trigger:** rolled
**What happens:** Two characters sit in comfortable silence in the library. No conversation, just presence.
**Requirements:** in_room "library", other_character_in_room, relationship_bond_above 40
**Key outcomes:** loneliness -10 both, bond +3, trust +2. No feelings pushed — the absence of a feeling push IS the design.
**Storybook:**
- "{name} and {target} sat near each other. Neither spoke. Neither needed to."
- "They didn't talk. They didn't have to."
**Chains to:** DEEP_CONVERSATION (sometimes silence opens the door)
**Notes:** Beautiful quiet event for established relationships. Tests that bond-building doesn't always need drama. The library's signature emotional tone.

---

### STUDY_TOGETHER
**Scope:** character | **Magnitude:** minor | **Trigger:** rolled
**What happens:** Two characters read or study together in the library.
**Requirements:** in_room "library", other_character_in_room, relationship_bond_above 15
**Key outcomes:** boredom -15 both, bond +4, familiarity +2. Both get object impression boost for bookshelf.
**Storybook:**
- "{name} and {target} studied together. Someone turned a page too loudly."
- "They sat across from each other, books open, occasionally looking up."
**Chains to:** CHAT (whispered), QUIET_MOMENT_TOGETHER
**Notes:** Social variant of READ_BOOK. Builds bonds through shared activity without the intensity of direct conversation.

---

# CAFE EVENTS

---

### VISIT_CAFE
**Scope:** character | **Magnitude:** minor | **Trigger:** rolled
**What happens:** Character decides to go to the cafe.
**Requirements:** not in cafe, hunger above 30 OR boredom above 20 OR loneliness above 30
**Key outcomes:** intent queued: go to cafe.
**Storybook:**
- "{name} headed to the cafe."
**Chains to:** Room arrival events in cafe
**Notes:** The cafe is the casual social hub. Hunger and loneliness are both valid drivers.

---

### ORDER_FOOD
**Scope:** character | **Magnitude:** minor | **Trigger:** rolled
**What happens:** Character orders food at the cafe.
**Requirements:** in_room "cafe", hunger above 20
**Key outcomes:** cash -8, hunger -40, happiness +5, push WELL_FED. If cafe worker is human: bond +1 with worker.
**Storybook:**
- "{name} ordered something. It was warm and that was enough."
- "{name} ate. Not gourmet, but it didn't have to be."
**Chains to:** CHAT (if another character nearby), SIT_ALONE
**Notes:** Hunger management + small social opportunity. If cash below 8: event fails, push ANXIOUS + intent to FIND_CHEAP_FOOD or STEAL.

---

### ORDER_COFFEE
**Scope:** character | **Magnitude:** minor | **Trigger:** rolled
**What happens:** Character gets a coffee.
**Requirements:** in_room "cafe", energy below 60 OR boredom above 30
**Key outcomes:** cash -3, energy +10, stress -3, boredom -5.
**Storybook:**
- "{name} got a coffee. The day could begin now."
**Chains to:** CHAT, DAYDREAM (sitting with coffee)
**Notes:** Small energy boost without sleeping. Cheaper than food. The cafe's baseline activity.

---

### SIT_ALONE_CAFE
**Scope:** character | **Magnitude:** minor | **Trigger:** rolled
**What happens:** Character sits alone in the cafe, watching people.
**Requirements:** in_room "cafe", boredom above 15
**Key outcomes:** boredom -10, loneliness -3 (passive social environment helps), stress -5
**Storybook:**
- "{name} sat in the corner and watched the cafe move around them."
- "{name} didn't want to talk. Just wanted to be near people."
**Chains to:** EAVESDROP (overhear another table), CHAT (someone approaches), THINK_ABOUT
**Notes:** Introvert's social event. Being near people without talking to them still reduces loneliness slightly.

---

### SHARE_MEAL
**Scope:** character | **Magnitude:** minor | **Trigger:** rolled
**What happens:** Two characters eat together at the cafe.
**Requirements:** in_room "cafe", other_character_in_room, relationship_bond_above 20
**Key outcomes:** hunger -30 both, cash -6 (they split it), bond +5, loneliness -15 both.
**Storybook:**
- "{name} and {target} ate together. The food wasn't the point."
- "Lunch with {target}. {name} couldn't remember the last time someone sat with them."
**Chains to:** DEEP_CONVERSATION, CHAT, GOSSIP
**Notes:** The cafe's signature social event. Shared meals build bonds faster than conversation alone. Tests shared activity + stat recovery combination.

---

### SPILL_DRINK
**Scope:** character | **Magnitude:** minor | **Trigger:** rolled (rare)
**What happens:** Character spills their drink. Minor comedy/embarrassment.
**Requirements:** in_room "cafe" or "bar", has just completed ORDER_DRINK or ORDER_COFFEE
**Key outcomes:** happiness -3, push HUMILIATED (brief). If another character witnesses: witness rolls reaction (laugh → bond -2 + rivalry +1, help clean up → bond +3).
**Storybook:**
- "{name} knocked their drink over. The whole cafe noticed."
- "It went everywhere. {name} pretended it didn't."
**Chains to:** Nothing major. Texture event. Witness reactions seed tiny relationship deltas.
**Notes:** Comedy event. Tests witness reaction branching. Low weight — should feel like an accident, not a constant.

---

# APARTMENT EVENTS

---

### DECORATE_APARTMENT
**Scope:** character | **Magnitude:** minor | **Trigger:** rolled
**What happens:** Character places or rearranges a decoration in their apartment.
**Requirements:** in_home_room, has item in apartment_storage with "decoratable" tag
**Key outcomes:** item moved from storage to apartment spot. happiness +5, stress -3. Object impression of placed item +5.
**Storybook:**
- "{name} moved things around. The apartment felt a little more like home."
- "{name} put up {item}. It changed the room."
**Chains to:** ADMIRE_DECORATION (later, when impression grows)
**Notes:** Tests apartment item placement system. Favourite_color items get extra happiness boost.

---

### NOISY_NEIGHBOUR
**Scope:** character | **Magnitude:** minor | **Trigger:** rolled
**What happens:** Character hears noise from an adjacent apartment. Stress event.
**Requirements:** in_home_room, time_of_day "night", adjacent apartment has character with active ARGUE, PHYSICAL_FIGHT, PLAY_MUSIC, or PARTY event
**Key outcomes:** stress +8, happiness -3, push FURIOUS if NEAT_FREAK or already stressed.
**Storybook:**
- "{name} could hear everything through the wall. Again."
- "The walls were thin. {name} already knew that."
**Chains to:** CONFRONT (queue intent to confront neighbour), NOISE_COMPLAINT (report to Mayor), THINK_ABOUT (resentment builds)
**Notes:** Tests apartment adjacency logic. Requires knowing which apartments share walls. Seeds neighbour conflicts.

---

### COOK_MEAL
**Scope:** character | **Magnitude:** minor | **Trigger:** rolled
**What happens:** Character cooks at home instead of going to the cafe.
**Requirements:** in_home_room, hunger above 25, has apartment interactable "kitchen" or "stove"
**Key outcomes:** hunger -50, cash -3 (cheaper than cafe), happiness +8, boredom -5. Small fire risk if RECKLESS or FORGETFUL trait (extremely low weight side roll).
**Storybook:**
- "{name} cooked for themselves. It wasn't bad."
- "{name} made something in the kitchen. The whole floor could smell it."
**Chains to:** COOK_FOR_SOMEONE (if another character at high bond is visiting apartment)
**Notes:** Tests apartment interactable use. Cheaper than cafe eating but requires being home. The cooking smell could be a minor aura that makes visitors hungry.

---

### ★ COOK_FOR_SOMEONE
**Scope:** character | **Magnitude:** moderate | **Trigger:** rolled
**What happens:** Character cooks a meal for a guest in their apartment.
**Requirements:** in_home_room, other_character_in_room, relationship_bond_above 40
**Key outcomes:** hunger -50 both, bond +10, trust +5, push GRATEFUL on guest. Cash -5.
**Player choice:** "Cook something special" (warm, bond +12) / "Keep it simple" (neutral, bond +8)
**Storybook:**
- "{name} cooked for {target}. They ate at the kitchen counter because there wasn't a table."
- "Nobody had cooked for {target} in a long time. {name} changed that."
**Chains to:** DEEP_CONVERSATION (over dinner), THINK_ABOUT (memory of the meal)
**Notes:** ★ Player choice. Intimate domestic event. Tests apartment visits + shared activities in private space.

---

### LATE_NIGHT_STARE
**Scope:** character | **Magnitude:** minor | **Trigger:** rolled
**What happens:** Character stands at their apartment window looking out at nothing.
**Requirements:** in_home_room, time_of_day "night", happiness below 40 OR loneliness above 50 OR has_feeling GRIEVING
**Key outcomes:** stress -3, loneliness +3 (bittersweet), push brief CONTENT_FEELING if happiness above 30, push MISERABLE if below.
**Storybook:**
- "{name} stood at the window. The city was still going."
- "Late. Quiet. {name} watched the lights and didn't think about anything."
- "The window was cold. {name} pressed their forehead against it."
**Chains to:** THINK_ABOUT, CRY, SLEEP
**Notes:** Pure atmosphere. One of those events that makes the storybook feel like literature. Tests time_of_day + mood combination requirements.

---

### INVITE_OVER
**Scope:** character | **Magnitude:** minor | **Trigger:** rolled
**What happens:** Character invites another character to their apartment.
**Requirements:** in_home_room OR in same room as target, relationship_bond_above 30, target not already in actor's apartment
**Key outcomes:** target queues intent to visit actor's apartment. Loneliness -5 (anticipation).
**Storybook:**
- "{name} asked {target} to come over."
- "{name} told {target} they should hang out later. {target} said yes."
**Chains to:** Target visits apartment → CHAT, DEEP_CONVERSATION, COOK_FOR_SOMEONE, WATCH_TV
**Notes:** Tests intent queue on the TARGET character. The invitation creates future content.

---

# BUILDING EVENTS

---

### POWER_OUTAGE
**Scope:** building 📰 | **Magnitude:** major | **Trigger:** Architect scheduled
**What happens:** The building loses power for several hours. Rooms go dark, elevator stops, emergency lighting only.
**Requirements:** building_mood_is not "chaotic" (don't pile on), Architect cooldown passed
**Key outcomes:** elevator disabled for 4 in-game hours. All characters get stress +10. Characters in elevator get TRAPPED_IN_ELEVATOR sequence. SCARED feeling pushed on characters with PARANOID trait.
**Storybook:**
- "The lights went out. All of them. At once."
**Chains to:** TRAPPED_IN_ELEVATOR_SEQ, HELP_NEIGHBOUR (some characters check on others), STEAL (opportunistic crime in the dark)
**Notes:** 📰 Building event. Tests elevator breakdown + recovery, building-wide stat push, and how characters with different traits respond to the same crisis. Strata autoload dispatches repair.

---

### ELEVATOR_BREAKDOWN
**Scope:** building 📰 | **Magnitude:** moderate | **Trigger:** Architect scheduled
**What happens:** One elevator breaks down. Anyone inside gets trapped.
**Requirements:** Architect cooldown passed, at least one elevator functional (don't break both)
**Key outcomes:** one elevator disabled. Occupants locked in TRAPPED_IN_ELEVATOR_SEQ. Strata dispatches repair. All characters who need that elevator route through stairs or the other elevator.
**Storybook:**
- "Elevator {number} stopped between floors. The lights inside flickered."
**Chains to:** TRAPPED_IN_ELEVATOR_SEQ, pathfinding reroute for all affected characters
**Notes:** 📰 Tests elevator breakdown + repair cycle. Tests pathfinding fallback to stairs. Tests Strata robot dispatch.

---

### ⚡ RIOT_BREAKS_OUT
**Scope:** building 📰 | **Magnitude:** huge | **Trigger:** auto_fire
**What happens:** Multiple angry characters erupt into collective violence.
**Requirements:** characters_with_faction_sentiment_below: {"faction": "police", "threshold": -50, "min_count": 4, "in_same_room": true}
**Key outcomes:** all involved characters get stress +30, health risk, property damage to room interactables. Police dispatched (all officers). Multiple witness memories created. Massive faction sentiment shifts.
**Storybook:**
- "It started with shouting. It didn't stay as shouting."
- "Four of them. Then six. Then it didn't matter how many."
**Chains to:** MASS_ARREST, PROPERTY_DAMAGE, INJURY events, THINK_ABOUT (building-wide trauma), news ticker dominates for the day
**Notes:** ⚡📰 Auto-fire. The biggest event in the game. Tests auto-fire pipeline, Architect approval gate, mass witness processing, police dispatch, and building-wide aftermath. Should be rare — 1-2 per playthrough at most.

---

# WITNESS & RESPONSE EVENTS

---

### WITNESS_EVENT
**Scope:** character | **Magnitude:** minor | **Trigger:** automatic (fires for bystanders when a moderate+ event occurs in their room)
**What happens:** Character sees something happen. Writes short-term memory.
**Requirements:** in same room as a moderate or higher magnitude event, not a participant
**Key outcomes:** short-term memory written (observation category), with tone (shocked, amused, concerned, disgusted depending on event type)
**Storybook:**
- "{name} saw the whole thing."
- "{name} was there when it happened."
**Chains to:** GOSSIP (share what they saw), REPORT_TO_POLICE, CONFRONT (if the event involves someone they care about)
**Notes:** Not manually designed per-event — this fires automatically as part of the ECHO stage for any event that has witnesses. The tone is derived from the event's category.

---

### ★ REPORT_TO_POLICE
**Scope:** character | **Magnitude:** moderate | **Trigger:** rolled
**What happens:** Character who witnessed a crime decides to report it.
**Requirements:** has short-term memory with tag "crime_witnessed", memory is recent (last 2 days)
**Key outcomes:** case filed in Police autoload. Actor gets stress -5 (relief). criminal gets criminal_reputation +10. Police investigation begins.
**Player choice:** "Report it" / "Stay quiet" / "Let it go"
**Storybook:**
- "{name} went to the police station. They told them everything."
- "{name} reported what they saw. Whether anything would come of it was another question."
**Chains to:** INVESTIGATION (Police autoload), potential ARREST
**Notes:** ★ Player choice. Tests witness → report → investigation → arrest pipeline. Weight modified by CORRUPT (suppresses), BY_THE_BOOK (boosts), relationship to criminal (high bond suppresses — you don't rat on friends).

---

# NEED-BASED EVENTS

---

### GO_TO_BATHROOM
**Scope:** character | **Magnitude:** minor | **Trigger:** rolled
**What happens:** Character uses the bathroom. Interrupts most activities.
**Requirements:** need_for_toilet above 60
**Key outcomes:** need_for_toilet reset to 0. Brief lock (character unavailable for 1 tick).
**Storybook:**
None. This event does not write to storybook. It's mechanical.
**Chains to:** Nothing. Pure maintenance.
**Notes:** No storybook entry by design. Not every event is a story. Weight scales with need_for_toilet. At 90+ it becomes a non-clearable critical intent.

---

### CANT_AFFORD_FOOD
**Scope:** character | **Magnitude:** moderate | **Trigger:** rolled
**What happens:** Character tries to eat but can't afford it.
**Requirements:** hunger above 60, cash below 5
**Key outcomes:** hunger stays high, stress +15, happiness -10, push ANXIOUS. Intent queued: STEAL_FOOD or BEG.
**Storybook:**
- "{name} couldn't afford to eat. They sat down and tried not to think about it."
- "The cafe was right there. {name} didn't have enough."
**Chains to:** STEAL (crime), BEG (homeless event), FIND_WORK (intent)
**Notes:** Economic pressure event. Seeds crime chains and homelessness spirals. Tests the "can't afford → crime or work" decision tree.

---

# APPENDIX — EVENT CHAIN MAP

Key chains showing how events connect. Read left to right.

```
GREET → CHAT → DEEP_CONVERSATION → THINK_ABOUT → VISIT_CHARACTER
                ↓
              GOSSIP → target THINK_ABOUT → CONFRONT → ARGUE → FIGHT
                                                        ↓
                                                    APOLOGISE → accept/reject

INSULT → ARGUE → PHYSICAL_FIGHT → REPORT_TO_POLICE → INVESTIGATION → ARREST
  ↓                    ↓
NURSING_GRUDGE     WITNESS_EVENT → GOSSIP → building-wide knowledge

FLIRT → ASK_OUT → DATE → PARTNER tier → PROPOSE → MARRIED
  ↓
REJECTED → HEARTBROKEN → CRY → THINK_ABOUT (obsess)

VISIT_BAR → ORDER_DRINK → REPEAT → DRUNK → CONFESS_SECRET → GOSSIP spreads it
                                     ↓
                                   FIGHT, FLIRT (boosted weights while drunk)

CANT_AFFORD_FOOD → STEAL → WITNESS → REPORT → ARREST → JAIL → HOMELESS
                    ↓
                  FORM_GANG (if criminal stats high enough)

POWER_OUTAGE → TRAPPED_IN_ELEVATOR → PANIC / BOND (forced proximity)
               → STEAL (darkness)
               → HELP_NEIGHBOUR (crisis brings people together)
```

---

# APPENDIX — EVENTS BY SYSTEM TESTED

Quick reference for dev sessions — which events test which systems.

```
RELATIONSHIPS:     GREET, CHAT, DEEP_CONVERSATION, COMPLIMENT, INSULT,
                   ARGUE, APOLOGISE, FLIRT, ASK_OUT
MEMORY:            THINK_ABOUT, GOSSIP, CONFESS_SECRET, EAVESDROP
INTENT QUEUE:      VISIT_BAR, VISIT_LIBRARY, VISIT_CAFE, INVITE_OVER,
                   SLEEP, GO_TO_BATHROOM
SEQUENCES:         PLAY_POOL_SEQ, BAR_FIGHT, TRAPPED_IN_ELEVATOR_SEQ
INTERACTABLES:     READ_BOOK, ADMIRE_STATUE, BREAK_POOL_CUE,
                   DECORATE_APARTMENT, ORDER_DRINK, ORDER_FOOD
FEELINGS:          CRY, DAYDREAM, LATE_NIGHT_STARE, LOOK_IN_MIRROR
TRAITS:            BREAK_POOL_CUE (VIOLENT), GOSSIP (GOSSIP trait),
                   CONFESS_SECRET (DRUNK state), SPILL_DRINK (comedy)
PROXIMITY:         NOD_IN_PASSING, HALLWAY_CHAT, AWKWARD_HALLWAY_ENCOUNTER,
                   BUMP_INTO, EAVESDROP
POLICE:            REPORT_TO_POLICE, PHYSICAL_FIGHT (witness chain)
FACTIONS:          RIOT_BREAKS_OUT
ARCHITECT:         POWER_OUTAGE, ELEVATOR_BREAKDOWN
PLAYER CHOICE:     APOLOGISE, FLIRT, ASK_OUT, COOK_FOR_SOMEONE,
                   REPORT_TO_POLICE
AUTO-FIRE:         RIOT_BREAKS_OUT
ECONOMY:           CANT_AFFORD_FOOD, ORDER_DRINK, ORDER_FOOD, ORDER_COFFEE
```