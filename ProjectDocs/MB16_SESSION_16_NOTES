MB16 Session 16 — Session Notes
Date: Session 15 continuation
What we did:

Diagnosed stress staying at 0.0 — root cause was no passive stress income, too many stress relief events draining it before conflict thresholds hit
Added passive stat ticks to _on_half_hour():

Sleeping: energy +8, stress -2
Awake: boredom +3, energy -3, stress +1.5, hunger +1.0, need_for_toilet +1, horniness +0.2


Lowered conflict event stress thresholds in events.gd:

INSULT: 50 → 30, ARGUE: 55 → 40, MOCK: 40 → 25, PROVOKE: 60 → 40



What's working:

SHARE_SECRET fires reliably
BETRAY_SECRET fires and correctly pushes FURIOUS on the original sharer
Secret pipeline confirmed working via forced F3 testing
INSULT fired in the new cast run (Anton Osei)
Trait evolution working — REGULAR evolved for Mateo Singh at bar_visits = 15

Still not firing reliably:

MOCK, COLD_SHOULDER, PROVOKE — stress is climbing but still being drained by social/drink events before hitting thresholds
Recommendation: bump stress passive to 2.0/half hour AND drop MOCK to 15, INSULT to 20

BETRAY_SECRET redesign (parked):

Current behaviour: immediate rivalry on original sharer
Desired: rivalry only fires when secret gossips back to original sharer through the network
Requires gossip propagation system first — flagged for later this session or next

New generated cast (second run):
Anton Osei (VIOLENT, STUBBORN, SHORT_TEMPERED), Jared Park (WEAK_BLADDER, STUBBORN, GOSSIP), Elara Tanaka (VIOLENT, MORNING_PERSON, HOMEBODY)
Interesting observations from logs:

INSULT fired (Anton Osei on Kai) early in run 1 — conflict events can fire, just rare
BETRAY_SECRET working correctly with FURIOUS propagation
Sara Vega is a serial secret-sharer again — shared with multiple characters rapidly
Jared Park (GOSSIP trait) immediately active in social events
Mira↔Mateo romantic pipeline completed naturally in run 2, including ASK_OUT accepted
Marcus Webb developed strong bond with Mateo Singh quickly (flirt reciprocated)
REGULAR trait evolved organically for Mateo Singh — first evolved trait seen in a new cast

Next priorities (Phase 4 remaining):

Bump stress income + lower MOCK/INSULT thresholds further to get conflict events firing reliably
AVOID_CHARACTER intent
Gossip propagation (transfer storybook entries between characters)
BETRAY_SECRET redesign (post-gossip-propagation)
Enemy-making event sequences (HEATED_ARGUMENT_SEQ, PHYSICAL_FIGHT_SEQ)