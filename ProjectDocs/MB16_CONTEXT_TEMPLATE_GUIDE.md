# MB16 — Context Template Variable Guide
*Reference for writing storybook templates and event text.*
*All variables are injected by Context.build_frame() before echo.*

---

## Actor Variables (the character the event fires on)

| Variable | she/her | he/him | they/them |
|---|---|---|---|
| `{name}` | Sara Vega | Marcus Webb | Kai Lindqvist |
| `{they}` | she | he | they |
| `{them}` | her | him | them |
| `{their}` | her | his | their |
| `{theirs}` | hers | his | theirs |
| `{themself}` | herself | himself | themself |
| `{They}` | She | He | They |
| `{Them}` | Her | Him | Them |
| `{Their}` | Her | His | Their |
| `{Theirs}` | Hers | His | Theirs |
| `{Themself}` | Herself | Himself | Themself |

---

## Verb Conjugation Helpers (actor)

| Variable | she/he (singular) | they (plural) | Usage |
|---|---|---|---|
| `{s}` | s | (empty) | `{name} sit{s} down` |
| `{es}` | es | (empty) | `{name} watch{es} the door` |
| `{have_has}` | has | have | `{name} {have_has} a feeling` |
| `{are_is}` | is | are | `{They} {are_is} tired` |
| `{were_was}` | was | were | `{name} wasn't sure what {they} {were_was} looking for` |

---

## Target Variables (who the event is directed at)

| Variable | she/her | he/him | they/them |
|---|---|---|---|
| `{target}` | Sara Vega | Marcus Webb | Kai Lindqvist |
| `{target_they}` | she | he | they |
| `{target_them}` | her | him | them |
| `{target_their}` | her | his | their |
| `{target_theirs}` | hers | his | theirs |
| `{target_themself}` | herself | himself | themself |
| `{Target_they}` | She | He | They |
| `{Target_them}` | Her | Him | Them |
| `{Target_their}` | Her | His | Their |
| `{Target_theirs}` | Hers | His | Theirs |
| `{Target_themself}` | Herself | Himself | Themself |

---

## Target Verb Conjugation Helpers

| Variable | she/he (singular) | they (plural) |
|---|---|---|
| `{target_s}` | s | (empty) |
| `{target_es}` | es | (empty) |
| `{target_have_has}` | has | have |
| `{target_are_is}` | is | are |
| `{target_were_was}` | was | were |

---

## Location Variable

| Variable | Example output |
|---|---|
| `{room}` | the bar, the café, the library, their apartment |

Room type → display name mappings:
- `bar` → "the bar"
- `cafe` → "the café"
- `library` → "the library"
- `grocery` → "the grocery"
- `apartment` → "their apartment"
- `gym` → "the gym"
- `cinema` → "the cinema"
- `laundry` → "the laundry"
- `rooftop` → "the rooftop"
- `lobby` → "the lobby"
- `police_station` → "the police station"
- `management` → "the management floor"

---

## Fallbacks

- If target is unknown or null: `{target}` → `"someone"`, target pronouns → they/them
- If room has no mapping: `{room}` → raw room_id (e.g. `"custom_f2_s3"`)

---

## Usage Examples

```
# Pronoun-safe solo event
"{name} caught {themself} smiling. {target}. That was why."
"{name} wasn't sure what {they} {were_was} looking for."
"That was enough for one day. {name} slept."

# Verb conjugation
"{name} sit{s} at the bar. The drink appears."
"{name} watch{es} the room. Everyone had somewhere to be."
"{They} {are_is} tired."
"{name} {have_has} heard a thing. {target} got the full version."

# Two-character event
"{name} stopped {target} in the hallway. {They} talked for a minute."
"{target} didn't expect the compliment. {name} gave it anyway."
"{name} told {target} something real. {Target_they} listened."

# Location
"{name} wandered out of {room}. No destination in mind."
"The {room} was quiet. {name} was exactly where {they} needed to be."
```

---

## Notes for Template Writers

- Capitalised variants (`{They}`, `{Their}` etc.) are for sentence starts only
- `{target}` is always the display name — use `{target_they}` etc. for pronouns
- Templates are picked randomly from the array — write 2-4 variants per event
- Keep templates under ~15 words where possible — they read better in the storybook
- Avoid starting every template with `{name}` — vary sentence structure
- Templates should work for ALL pronoun sets — test mentally with she/he/they before saving
