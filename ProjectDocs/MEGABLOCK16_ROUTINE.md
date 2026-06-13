# MegaBlock 16 — Working Routine
*How to run sessions with Claude now that the docs are restructured. Read once; you won't need it after it's habit.*

---

## The one-time setup

1. **Put `CLAUDE.md` in project knowledge.** This is the file every chat reads first.
2. **Paste the custom-instructions block** (`MEGABLOCK16_CUSTOM_INSTRUCTIONS.md`) into the Project's custom-instructions field.
3. **Keep these in project knowledge, load-on-demand** (the chat pulls them when needed): GDD_CORE, GDD_REFERENCE, Architecture Reference, Decisions Log, Event Design Bible, Starter Events, Context Template Guide, Character Roster, Roadmap.
4. **Archive old session notes out of project knowledge.** Keep only the **last 2–3** sessions' notes live. Everything older stays in your Git repo for history but should not be in the files chats load — their content is already absorbed into the reference docs. (Right now: keep Session 17, drop 1–16 from project knowledge.)
5. **The full GDD (`MEGABLOCK16_GDD.md`) is your personal copy.** You don't need it in project knowledge — Core + Reference cover the same ground for chats. Keep it for linear reading.

---

## Starting a new chat — first-prompt templates

You don't need to list documents anymore; the custom instructions + CLAUDE.md handle that. Just say what the session is.

**Dev session (continue the plan):**
> Dev session. Read CLAUDE.md and pick up the top item in the Current Sprint build order. [If continuing something specific:] We're on CONVERSE_SEQ — here's where we left off: …

**Dev session (specific bug):**
> Dev session. Read CLAUDE.md. Bug: [symptom]. Here's the log and the relevant file: …
> (Claude will ask for any other script it needs.)

**Brainstorm session:**
> Brainstorm session. Read CLAUDE.md and GDD_CORE. I want to think through [system/idea]. Don't write code yet.

**Event design:**
> Event design session. Read CLAUDE.md, the Event Design Bible, and Starter Events. I want to design [scenario] into proper event definitions.

That's it. If a chat seems not to have read CLAUDE.md (wrong assumptions about current state), just say "Read CLAUDE.md first."

---

## During the session

- Paste logs/errors freely — that's the debugging loop. Claude diagnoses, then fixes.
- Ask for complete rewrites of changed files when you want clean copy-paste.
- If Claude references a script it hasn't seen, paste it.
- Watch for drift: if responses get vague, wordy, or start contradicting earlier decisions, that's the context-window signal. Wrap up and start fresh.

---

## Ending the session — the fast copy-paste

Say **"wrap up"** (or "let's close out"). Claude runs the wrap-up protocol and hands you, in order:

1. **Updated Current Sprint block** → paste over the old block in `CLAUDE.md`.
2. **Session notes** (structured) → save as `MB16_SESSION_NN_NOTES.md`, add to repo, and put in project knowledge (then drop the now-oldest one to keep ~3 live).
3. **Decisions Log entries** (if any) → paste at the top of the matching section in the Decisions Log.
4. **Surgical doc edits** (if any) → apply the named snippets to GDD_REFERENCE / Roadmap / etc.
5. **Parking-lot items** (if any) → add to GDD_REFERENCE §15.

Most sessions only touch #1 and #2. The others fire only when something locks or a design detail changes.

---

## Where things go (edit-target map)

| When you… | Edit… |
|---|---|
| Finish a session | CLAUDE.md Current Sprint + new session notes |
| Lock an architectural decision | Decisions Log (top of section) |
| Change a game-design detail (a room, a system's rules) | GDD_REFERENCE (and GDD_CORE only if it's a principle/overview change) |
| Add/finish a roadmap item | Roadmap (tick it, move to Done with session number) |
| Add a condition key / action / naming rule | Event Design Bible |
| Design a new event idea | Starter Events |
| Add a storybook template variable | Context Template Guide |
| Add a bespoke character | Character Roster |
| Have an idea with no home yet | GDD_REFERENCE §15 Parking Lot |

Keeping the right thing in the right place is what stops documents drifting out of sync.

---

## Keeping the full GDD in sync (optional)

The full `MEGABLOCK16_GDD.md` is just Core + Reference back to back. You normally edit Core and Reference directly, then regenerate the full copy when you want a clean single-file read. Ask any chat: "concatenate GDD_CORE and GDD_REFERENCE into a full GDD." Or don't bother — reading the two parts is the same thing.

---

## Why it's set up this way (so you don't undo it later)

- **One always-loaded index (CLAUDE.md), everything else on demand.** You were loading ~17 docs and burning a third of the context window before any work. Now each session loads what it needs.
- **Old session notes are archaeology.** Their real content already lives in the reference docs. Carrying them dilutes attention.
- **Current Sprint replaces "read all the notes to find where we are."** It's the single source for current state and is the first thing you update at session end.
- **A canonical-doc table kills duplication.** When two docs disagree, CLAUDE.md's table decides — so the building layout, condition keys, etc. have exactly one home.
