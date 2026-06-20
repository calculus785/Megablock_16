Session Notes (MB16_SESSION_24_NOTES.md)
What we built: Completed the full 6-step base event layer.

Step 2: get_events_by_base_category() (events.gd), _roll_base_category() with data-driven weight/boost tables, ROLL stage filtering in _run_pipeline(). Centralized rng instance added to Sim, seeded in _ready(), swept into _weighted_roll(), _echo(), _roll_sequence_branch().
Step 3: current_motivation field on CharData ({type, need} shape), set on every base roll, cleared on empty pool / cooldown / CALLOUT decline.
Step 4: _resolve_fulfill_need() — sorts stats by urgency (high_is_bad / low_is_bad), tries matching events in urgency order, falls back to full pool. Added minimum urgency threshold (20) after testing showed near-zero-urgency stats still getting funneled into single events.
Step 5: Memory.push_intent() now rejects non-critical pushes at soft cap (3), returns bool. Sim._on_tick() skips the full pipeline when queue is at cap.
Step 6: _check_callout_accept() — base 60 + bond×0.3 − busy_penalty×queued_intents + stat/trait modifiers, clamped 5–95. Wired into both the base-roll SOCIALIZE path (_run_pipeline) and hallway proximity conversations (_run_hallway_check). Decline writes a minor, non-memorable storybook entry via _echo_callout_decline().
VISIT_BAR / VISIT_CAFE given dual base_category (["visit", "socialize"]) so lonely characters with no in-room target still have somewhere to go.
SHY and ANTISOCIAL traits added — SHY wants connection but struggles (moderate CALLOUT penalty both directions, can be overcome by loneliness); ANTISOCIAL doesn't want it (strong decline, no actor penalty since they don't try).

What's working: Confirmed across 4 separate test runs at 10x/30x. Two-layer roll firing correctly. NEEDROLL picks sensible stats (hungry → fridge, tired → bed). SOCIALIZE routes to bar/cafe when no one's around. CALLOUT fires on both base-roll socialize attempts and hallway encounters, with believable accept/decline spread. Bond and stat modifiers visibly shifting odds (Sara/Kai climbed to FRIENDLY tier through repeated positive CONVERSE_SEQ outcomes).
Bugs fixed (root cause):

Characters ordering drinks/socializing at near-zero need urgency — _resolve_fulfill_need was matching on the lowest-ranked stat in the loop even when its urgency was negligible, because the threshold check only guarded the first (highest) stat. Fixed by adding the same threshold check inside the loop with a break (urgencies are sorted descending, so once one fails the gate, all remaining do too).
Most conversations were bypassing CALLOUT entirely because hallway proximity conversations fire through a separate _run_hallway_check path that never got the gate. Fixed by adding the same _check_callout_accept / decline-echo logic there, gated on event_def.has("sequence_key") so only conversation-locking events require acceptance.

Files modified:

events.gd — get_events_by_base_category() helper, VISIT_BAR/VISIT_CAFE base_category arrays
sim.gd — rng instance, base_cat_weights/boosts, fulfill_need_stats, callout vars/templates, _roll_base_category(), _resolve_fulfill_need(), _check_callout_accept(), _echo_callout_decline(), ROLL stage rewrite, CALLOUT gate in _run_pipeline and _run_hallway_check, intent cap check in _on_tick
memory.gd — INTENT_SOFT_CAP constant, push_intent() now returns bool with cap rejection
char_data.gd — current_motivation field
traits.gd — SHY, ANTISOCIAL added

Next priorities: Arc tracking stamps (flagged early, never circled back — small, do it before moving on). Then debug tools suite, log format overhaul first since every future session benefits from better logs.