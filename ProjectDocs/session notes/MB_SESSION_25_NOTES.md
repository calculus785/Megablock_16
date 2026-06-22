Session Notes — Session 25
Type: Dev session
Completed:

Diagnosed and fixed gossip starvation (low memorable-entry pool early game — working as intended, not a bug, just needed more in-game days) and secret-sharing dead code (SHARE_SECRET_BEAT/BETRAY_SECRET_BEAT never wired into beat pool despite action functions existing).
Built arc tracking from scratch: current_arc_id (int, -1 sentinel), current_arc_data (live working dict), story_arcs (closed arcs array) on CharData. Clock.total_ticks added as monotonic counter (get_total_days() was too coarse for arc timestamps — multiple arcs open/close within one day).
Established the arc dividing-line principle: "does the original motivation still exist after this happens?" — interrupts append to current arc (motivation survives), FLEE_AVOIDED force-closes and opens new (motivation replaced). This will generalize to future interrupt-like systems (jealousy, cold phase).
Full log format overhaul executed via Claude Code (file scope: sim.gd, actions.gd, memory.gd, state_driver.gd, feeling_driver.gd) — [T<tick> A<arc_id>] prefix, ~22 keywords, RELCHANGE split per-character. Caught and fixed a real ordering bug (BASEROLL/NEEDROLL/SEQINTERRUPT printing before arc transition, tagging wrong arc) via a second Claude Code pass using a deferred-print pattern rather than reordering arc logic.

Key decisions this session:

Bond gate for SHARE_SECRET_BEAT: 5 (down from initial 20 — was a lottery-odds stack of low base weight + high bond requirement).
Arc entry shape: arc_id, base_event, opened_tick, closed_tick, event_keys — no summary/fragment text (that's Phase 8/11).
current_arc_id and current_arc_data kept as separate fields, not collapsed — naming clarity over byte savings.
Claude Code is now the right tool for large mechanical multi-file passes; chat is better for design decisions and small surgical diffs. Worth defaulting to this split going forward.