# Setup wizard (leviSetup): the reference that was in CLAUDE.md

> Moved verbatim from `CLAUDE.md` on 2026-11-13 (`docs/adrs/002-knowledge-delivery-tiers.md`). Until then every session loaded this text. It is not yet reconciled with the other documents of this subject: where they disagree, check the code or the game source, then correct the wrong one.

### Setup Wizard (leviSetup)
In-game configuration wizard accessed via `ataxia setup`.

**Key File**: `src_new/scripts/levi_ataxia/levi/ataxia/misc_scripts/020_Setup_Wizard.lua`

**Namespace**: `leviSetup` — all functions under this table, dispatched via `leviSetup.dispatch(cmd, rest)`. Note: the internal Lua namespace was intentionally kept as `leviSetup` (internal only); only the user-facing alias changed from `levi setup` to `ataxia setup`.

**Commands**:
| Command | Purpose |
|---------|---------|
| `ataxia setup` | Main menu |
| `ataxia setup class` | Set/auto-detect class |
| `ataxia setup separator` | Command separator |
| `ataxia setup weapons` | Weapon IDs |
| `ataxia setup basher` | Basher settings (flee, gold pack, shield swap) |
| `ataxia setup sipping` | Health/mana sip thresholds |
| `ataxia setup tracking` | Affliction tracking status (V3 is always on) |
| `ataxia setup combat` | Party relay, auto-loot, gag clot |
| `ataxia setup gui` | Toggle GUI on/off |
| `ataxia setup ndb` | NDB highlight colours |
| `ataxia setup install` | Guided install walkthrough (atinstall/abinstall/aninstall) |
| `ataxia setup status` | One-page settings overview |
| `ataxia setup guide` | Configuration guides (ataxia/basher/ndb) |
| `ataxia setup reporting` | Mnemosyne run tracker (token, auto on/off, test) |
| `ataxia setup earrings [auto]` | Travel earrings: `auto` sends EARRINGS and saves every partner |

**Earrings are paired with PLAYERS, and pairings change (v4.7.488).** `ataxia setup earrings auto`
saves every `Earring#N ... is paired with <Name>.` row (with or without `(M)`) as
`ataxia.settings.user.artefacts.earrings[<name>] = "earringN"`, and REPLACES the table:
`leviSetup.earringMerge` drops an entry whose earring has a new partner or whose partner is not
listed; an empty scan changes nothing. A fixed list of 9 names dropped 5 of 11 earrings before.
The travel aliases are temporary aliases made by `leviSetup.earringAliases()` (at
`ataxia system loaded`, and after each scan or manual set): `h` + the first 3 letters of a
partner, never for a prefix two partners share or one in `leviSetup.EARRING_RESERVED` (`orn`,
the horn alias). There is no catch-all `^h...$` alias, because it would take words other
aliases own. Test: `test_earring_auto.lua`.
