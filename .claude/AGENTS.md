# Agent Instructions for LEVI-Achaea Combat System

## Pitfalls learned 2026-07-31 / 2026-08-01

- **Mudlet `type: 3` is EXACT WHOLE LINE.** A type-3 pattern that is a FRAGMENT never fires,
  silently. Two triggers shipped dead this way, one of them a boss safety inert for 60+
  releases. Fragments are `type: 2` (line start) or `type: 0` (anywhere). Enum: 0 substring,
  1 regex, 2 begin-of-line, 3 exact, 4 lua, 5 spacer, 6 colour, 7 prompt.
- **When you make a READ global, audit the WRITE globally.** Rage-Fuelled put its check in one
  predicate used by 37 call sites, but wired the spend only where an existing line happened to
  be replaced -- seven rotations then read a charge they never cleared. **A migration that
  works by replacing an existing line silently skips every site that never had that line.**
- **Spend/consume logic belongs at a wrapped consumption point, not at each `return`.**
  Multi-exit functions guarantee an eventual miss.
- **Transient state goes on `ataxiaTemp`, never `ataxia`.** `ataxia` is serialized wholesale
  and `deepMerge` lets a disk value overwrite unconditionally, so a run-scoped guard stored
  there survives a reload while the non-persisted globals it guards do not -- defeating itself
  on exactly the path it exists for.
- **A passing test in the wrong `describe` is invisible.** It inflates the count, exercises the
  right function, and proves nothing about the block it claims to cover. When a helper name
  recurs across blocks in a file, anchor edits on something unique to the block.
- **Appending to a test file means moving the teardown.** Several files end with shared-state
  restoration; describes appended after it run with the teardown already applied.
- **Unit-testing primitives in isolation proves nothing about composition.** `brFree`,
  `rageAfford` and `brSent` each had passing tests while the callers leaked the charge.
- **Check the resource type first for any new AoE.** Equilibrium / word-balance / pet-order /
  free-queue abilities RIDE alongside the swing; balance ones REPLACE it. Two crowd abilities
  shipped days apart are wired oppositely for exactly this reason.
- **Look for an existing damage-type branch before building a new one.** A suppression affix is
  the same question a mob-resistance toggle already asks.
- **Match the effect TEXT, not the affix NAME -- but pin only the frame.** Affix names vary per
  member; the sentence carries the datum. The sentence varies too ("damage you deal" vs
  "damage dealt"), so leave the middle loose.
- **Verify counts, never `grep -c` them.** Claimed 40 rageAfford sites (really 37) and 28 boon
  flags (really 29 -- the naive grep returns 31 because two `mnem*` flags are affixes).

## Before Coding Offensive Systems

**You MUST read these files first:**

1. **[classes/lock_types.md](classes/lock_types.md)** - All lock type definitions (Softlock, Venomlock, Truelock, Focuslock, Riftlock, Salvelock, Sleeplock, Aeonlock)
2. **[classes/<target_class>.md](classes/)** - Class-specific kill routes, gating requirements, lock afflictions
3. **[classes/README.md](classes/README.md)** - Affliction stacking by herb, class-specific lock affliction table

## Before Coding Defensive Systems

Read the **attacker's class documentation** in `.claude/classes/<class>.md` for kill routes to counter, gating requirements, priority cure recommendations, and class-specific lock afflictions to prevent.

---

## Combat Systems Quick Reference

| System | Namespace | Dispatch | Key File(s) |
|--------|-----------|----------|-------------|
| **Serpent** | `serp_*` globals | `ek` → `serp_ekanelia_offense()` | `serpent/002_Serpent_Offense.lua` |
| **Shaman** | `shamanOffense` | `zz`/`sr` → `shamanOffense.dispatch()` | `shaman/028_Shaman_Offense.lua` |
| **DWC Infernal** | `infernalDWC` | `zz` → `infernalDWCVivisect()` | `dwc/001_Infernal_DWC_Vivisect.lua` |
| **Blademaster** | `blademaster` | `bmd`/`bmdq`/`bmbs` → `blademaster.run()` | `blademaster/005_CC_BM_Ice.lua` |
| **Apostate** | `apostate` | `ll`/`corr` → `apostate.dispatch()` | `apostate/015_CC_Apostate.lua` |
| **Psion** | `psion` | `zz` → `psion.dispatch()` | `psion/001_Levi_Psion_Logic.lua` |
| **Shikudo V1/V2** | `shikudo`/`shikudov2` | `shikudo.dispatch()` | `shikudo/001_Shikudo.lua` |
| **Shikudo Lock** | `shikudoLock` | `shikudolock()` | `shikudo/007_CC_Shikudo_Lock.lua` |
| **DWB Runie** | `dwbRunie` | `dwbRunie.dispatch()` | `dwb_runie/001_DWB_Runie_Logic.lua` |
| **Magi** | `magi.offense` | `zz`/`xx`/`vv`/`cc`/`sr`/`mm` | `mage/004_Magi_Offense.lua` |
| **Tekura 6L** | `tekura6` | `tk6()` | `tekura/002_Tekura_6Limb_Offense.lua` |
| **Snipe** | `snipe` | `snt` → `snipe.fire()` | `snipe/001_Snipe_System.lua` |
| **Basher** | `ataxiaBasher` | Prompt-driven | `genrunning/004_Autobashing_Functions.lua` |

All script paths relative to `src_new/scripts/levi_ataxia/levi/levi_scripts/`.

**For detailed system docs**, see the corresponding memory files:
- Serpent → `memory/serpent.md` | Shaman → `memory/shaman.md` | Magi → `memory/magi.md`
- Apostate → `memory/apostate.md` | Blademaster → `memory/blademaster.md` | Tekura → `memory/tekura.md`
- Snipe → `memory/snipe.md` | DWB Runie → `memory/dwb-runie.md` | SLC → `memory/slc.md`
- Basher → `memory/basher.md` | Basher Overhaul → `memory/basher-overhaul.md` | Affliction Tracking → `memory/affliction-tracking.md`
- Bug Patterns → `memory/bug-patterns.md` | Codebase Structure → `memory/codebase-structure.md`

---

## Class-Specific Lock Afflictions

| Classes | Lock Aff | Blocks |
|---------|----------|--------|
| Knights, Monk, Serpent, Sentinel, Blademaster, Elemental Lords | Weariness | Passive cures |
| Apostate, Pariah, Bard, Priest | Voyria | Sip healing |
| Magi, Sylvan | Haemophilia | Blood cures |
| Alchemist | Stupidity | Transmutation |
| Depthswalker | Recklessness | Shadow cures |
| Psion | Confusion | Mental cures |

---

## Lock Types Quick Reference

| Lock | Afflictions | Escape |
|------|-------------|--------|
| **Softlock** | asthma + anorexia + slickness | Focus → eat bloodroot → eat kelp |
| **Venomlock** | + paralysis | Focus → eat bloodroot |
| **Truelock** | + impatience + class aff | None without help |
| **Focuslock** | mental aff stacking | Hope Focus cures anorexia |
| **Aeonlock** | aeon + asthma + kelp stack | Must cure asthma first |

---

## Code Header Template

When creating/modifying offensive Lua files, include:

```lua
--[[
  OFFENSIVE SYSTEM - <Class Name>

  REQUIRED READING before modifying:
  - .claude/classes/lock_types.md (lock definitions)
  - .claude/classes/<class>.md (class mechanics)

  Lock progression: Softlock → Venomlock → Truelock
  See lock_types.md for affliction requirements and escape routes.
]]--
```

---

## Setup Wizard Coding Conventions

When modifying `leviSetup` (misc_scripts/020_Setup_Wizard.lua):
- Follow the existing `cecho()` color pattern (dark_orchid headers, green values, light_slate_blue labels)
- Namespace: `leviSetup` — all functions under this table
- Dispatch: `leviSetup.dispatch(cmd, rest)` from `ataxia setup` alias

---

## Key Files Reference

| Path | Purpose |
|------|---------|
| `.claude/classes/lock_types.md` | Comprehensive lock definitions |
| `.claude/classes/README.md` | Class index and combat concepts |
| `.claude/classes/<class>.md` | Per-class kill routes and mechanics (26 classes) |
| `CLAUDE.md` | Main project documentation |
| `docs/ai-includes/agent-teams.md` | Multi-agent team coordination guide |

---

## Basher Pitfalls (learned the hard way)

### Reload-safety: login-only globals crash the always-live path
Many combat globals are created **only inside `levilogin()`** (`login/001_Login_Function.lua`), which fires on the "logged in" event. A **package reinstall/reload (SYSUPDATE) does NOT re-fire login**, so those globals stay nil — and always-live code (prompt triggers, `gmcp.Char.Vitals` handlers, the attack loop) then indexes/arithmetics them and crashes. Confirmed victims: `bashStats`, `battleRage_Timers`, `tBals`, `shape` (an Earth Lord magma-seethe trigger did `shape = shape + 1`).

**Rule:** any global a prompt/combat trigger or the bashing path reads must have a **load-time (module-scope) idempotent init** — `X = X or <default>` at the top of a script that loads at package load (see the block at the top of `basher/001_Bashing_Functions.lua`). Use `or` so a live value survives mid-session; use the **full shape** when subfields are indexed (`tBals.timers`), not bare `{}`. To find siblings, grep `levilogin` for its assignments and check each against unguarded index/arith on an always-live path — don't trust that "it's set at login."

### Battlerage double-call: pre-call arming eats the real fire
`ataxiaBasher_magiBashing` (and any class whose autobash loop pre-calls its bashing function for setup) is invoked **twice per cycle** — once discarded (stormhammer/GUI prep in `genrunning/004`), once for the real send. This was harmless while the class used `standardBattlerage` (a pure read), but a **custom `*Battlerage` that ARMS cooldowns on fire** will arm them on the discarded pre-call, so the real call returns `""` and **no battlerage is ever sent**. Fix: the pre-call must run setup ONLY (e.g. `ataxiaBasher_magiStormPrep()`), never the battlerage.

### eq/balance timers: nil stopwatch aborts the EQUILIBRIUM trigger
`stopStopWatch(nil)` throws. On a fresh session the eq/bal stopwatch globals are nil, so `endEQTimer`/`endBalTimer` threw and aborted the EQUILIBRIUM trigger **before `EQHighlight()` ran** — the on-screen eq/bal bars silently vanished. Guard stopwatch stops with `if <id> then ... end`.

### GMCP field shapes (2026-07-23 audit — see [[gmcp-backlog]])
- **`gmcp.Char.Name` is an OBJECT `{name, fullname}`, not a string** — compare `gmcp.Char.Name.name`. A string-vs-table compare silently never matches (bug: Stormhammer could self-target; Magi-coord self-check never fired).
- **`Char.Items` item `attrib` is a flag-SET string** (`m`=monster, `d`=dead, `t`=takeable, `x`=should-not-be-targeted/loyal) — test membership (`attrib:find("x")`), never whole-string equality. Brittle exact matches leaked loyal NPCs + corpses into `denizensHere`.
- **Knight weapon spec: use `ataxia.vitals.knight == "X"`** (parsed unprefixed by `ataxia_Vitals_Update`), NOT positional `charstats[3]/[4] == "Spec: X"` (order isn't guaranteed: RW at `[3]`, Infernal at `[4]`). **`levilogin` gotcha:** it resets `ataxia.vitals = {}` and runs wield branches SYNCHRONOUSLY before the parser repopulates `knight` — seed it from live `charstats` first (login does an inline `^Spec: (.+)$` scan). Same trap for any parser-derived `ataxia.vitals.*` read inside `levilogin`.
- **GMCP consumers**: passive server-data handlers live in `misc_scripts/030_GMCP_Consumers.lua` (reload-safe kill-before-register). Register new ones there.

---

## Game Lines vs Optimistic State (learned the hard way)

The v4.7.165–169 legend-deck work and the live-log audit that followed it turned up the same
family of fault over and over: client-side belief running ahead of what the game had actually
said. Each entry below generalises a shipped fix; none of them is a style preference.

### A resource counter that defaults to FULL is not evidence
`ldm.initDeck` seeds every card it has never seen at its **max**, so a deck that has never
been `LDECK LIST`ed reports full charges for everything. The Mnemosyne card layer read
"Xylthus: 3" and drew into a wall, echoing "3 charge(s) left" on a card the game refused in
the same breath. It stayed hidden because the feed that would have corrected the count was
itself broken: `ldm.matchFullName` (`legend_deck/003_Legend_Deck_Functions.lua:579`) took
`fullName:match("^(%S+)")`, so `"Xylthus, the Outcast"` yielded the token `"Xylthus,"` —
with the comma — which matches no key, so `ldm.deck[card].charges` was never updated from
the game at all. Cards whose key is the first bare word (Maran, Matic, Covenant) worked,
which is exactly why nobody noticed.

**Rule:** treat the game's refusal line as ground truth and an optimistic local counter as a
hint. A counter whose unknown state is "full" must never be the sole gate on a spend — wire
the refusal line first and let it zero the counter (`ataxiaBasher_mnemLdeckRejected`,
`basher/010_Mnemosyne_Legend_Deck.lua:350`, off trigger
`legenddeck_cards/008_LDeck_No_Charges.lua`). Corollary: a key-resolution helper that
silently returns nil turns every downstream guard into a no-op, so unit-test it against the
punctuated names, not the easy ones.

### Stamp on the confirmation line — and a lapse is not a confirmation
v4.7.165 recorded the affliction a card plants at *build* time, in the same queued line as
the battlerage that cashes it in. When the draw failed the stamp was a lie and Etch spent 25
rage on a phantom stun — twice in one 90-second log, while the rotation was rage-starved.
The affliction is now recorded in `ataxiaBasher_mnemLdeckConfirm` (`basher/010:317`), fed by
the game's own draw lines, so the exploiting battlerage fires on the *following* round
against a denizen that really carries it.

v4.7.166 then re-opened the same hole from the other end: the pending-window lapse path
called Confirm, so an *unacknowledged* draw stamped the affliction anyway. A lapse means "we
do not know", which is not "it landed" — `ataxiaBasher_mnemLdeckLapse` (`basher/010:335`)
holds the card's interval and releases the replay, and stamps nothing.

**Rule:** never let an optimistic state stamp authorise a resource spend in the same round.
Confirmation, lapse and rejection are three different facts about the world and need three
different functions; sharing one is how the fix re-introduces the bug.

### Every owned timer-free rotation needs a fire line AND a refusal line
Runewarden Etch was the one ability in `RW_BR` (`basher/002_Class_Bashing.lua:1458`) with no
fire-line trigger, so its in-flight pick had nothing to release it: after the queued etch
actually fired, the next two rebuilds re-queued the *same* etch and the server rejected both
("You must wait a short time before you can use a battlerage ability again.") — two wasted
cycles back to back. `375_Runewarden_Etch_Landed.lua` captures the fire text and calls
`ataxiaBasher_rwConfirm("etch")`; the mirror is `329_Battlerage_Global_Cooldown.lua`, which
now clears the in-flight hold on **every** owned rotation, because a *rejected* battlerage
did not land and replaying the held pick is exactly wrong.

Better still, the game names the ability coming off cooldown outright — `You can use Collide
again.` and `Your Collide ability could be used again but you lack the necessary Rage.` (the
same event seen through an empty rage bar). Every owned rotation instead *guessed*, with a
send-side epoch stamp plus a hardcoded `cd`, which is wrong in both directions: too slow when
a boon or gear shortens the real cooldown, too fast when a stamped pick never executed. Those
lines are now consumed class-agnostically in `basher/011_Battlerage_Ready_Lines.lua`
(trigger `328`), verb captured from the line, unknown verbs ignored.

**Rule:** an ability holding an in-flight replay needs both a fire line to confirm it and a
refusal line to cancel it. With neither it burns cycles invisibly. Where the server emits a
ready or refusal line, prefer it to any client-side timer.

### Refusal lines are state data, not noise
Three were unhandled or handled destructively in a single log. `You cannot do that because
both of your arms must be whole and unbound.` (`344_Broken_Arms.lua`) fired an *unthrottled*
`diag` — and nothing in the package parses our own DIAGNOSE output, so the only effect was
six lines of console spam at the worst possible moment, three times in 0.8s. What the line is
actually worth is an authoritative "the queued round did not execute", so it now rolls back
every owned rotation's in-flight replay. `Both of your legs must be free and unhindered to do
that.` had no handler at all (`345_Broken_Legs_Block.lua`), and its expensive victim is not a
lost swing but **`leap`**: the swarm escape ladder moves with `stand;leap <dir>`, so a silent
refusal stalled the low-HP escape until the move timeout expired — the handler now rolls the
replay back *and* calls `M._disarmMove()` so the explorer re-decides on the next tick. `You
must be wielding both a sword and a shield to execute such an assault.` was the worst of the
three, because nothing re-wielded and so every subsequent round was refused forever; it is the
one where the rollback alone is not enough, and `377_Sword_And_Shield_Lost.lua` sends the
repair (`wield <sword>;wield shield;grip`, 5s debounce).

**Rule:** for each refusal line, ask two questions — what state does it prove, and who else
was waiting on that command? The answer is usually a rollback plus a wake-up for some other
machine, never a diagnostic dump.

### A convenience-widening match needs an explicit deny list from day one
`ataxiaBasher.ownDenizens` matches by case-insensitive substring, which is precisely what
lets the single keyword `falcon` cover "a razor-beaked falcon" and every variant. The same
widening silently shielded **"a slope-backed hyena"** — a real, killable denizen — behind the
`hyena` keyword seeded for the Infernal pet, and `ataxiaBasher_purgeOwnFromTargets` deleted
it from the learned target list across every area. `ataxiaBasher.notOwnDenizens` is the
escape hatch, checked **first** and winning over the pet keywords
(`basher/001_Bashing_Functions.lua:348`). Note how it was seeded: by **backfill**
(`002_Check_For_Any_Missing_Variables.lua:172`), not a fresh-install default, because
existing saves already carried the bare keyword and a default would have fixed nobody who
actually hit the bug. Narrowing the seed to `daemonic hyena` was rejected for the same
reason — it helps only new installs, and does nothing for the next collision.

**Rule:** any convenience-widening match — substring, prefix, fuzzy, first-word — ships with
an explicit deny list and a user command to extend it. The widening that serves the 95% is
exactly what makes the 5% fail invisibly. And when the bad state is already persisted in
users' saves, fix it with a backfill; a changed default reaches only new installs.

### An optimistic flag needs a third input: "this can never happen"
The Mnemosyne recovery hover keeps `S.flying` optimistically true until a flight line
confirms — a deliberate guard, because stupidity can eat a queued `fly`. Then a denizen
dragged us out of the air ("A tentacle shoots up from the ground, wraps itself around you,
and drags you back to earth.") and the confirmation never arrived, so the hover re-sent `fly`
every tick while the tentacle yanked us straight back down, holding us attack-**gated** at
crash HP with the swarm still on us until `RECOVER_MAX` expired — strictly worse than never
having flown. `S.onDraggedDown` (`mnemosyne/009_Swarm_Tactics.lua:807`, trigger
`mnemosyne/050_Dragged_From_Sky.lua`) latches `S.grounded`, which `S._canFly` (`009:481`)
honours alongside `mnemDeluge`, so both the escape ladder's outdoor branch and the fly-kite
fall through to the grounded route.

**Rule:** a flag cleared only by its confirmation line has two inputs (confirm, time-out) and
needs three — the line that says the thing can *never* happen. Scope that third input to the
right lifetime: `grounded` is per-ripple (`S.onRipple` clears it, `009:877`) because the
denizen that dragged us lives on this ripple, and the next ripple is a different room set.

### Prefer the game's own fire text to an affliction-name lookup
`Your <limb> breaks with a loud crack.` had no handler anywhere — ~25 of them in 90 seconds
of one live log. `ataxia_brokenLimbFound` (`self_limb_tracking/002_Track_The_Damage.lua:326`)
only branches on the `damaged*`/`mangled*` affliction families, so a level-1 break never reset
the accumulator: damage kept climbing past the real break, `ataxia_selfHitsToBreak` pinned at
0, the threshold latched `critical` forever, and every one-shot reaction latch stayed set.
Trigger `038_Limb_Broken_L1.lua` uses the game's own words, which name the limb **and** the
side, and needs no GMCP key, no SSC affliction name and no telemetry.

**Rule:** when the game names the thing directly, capture its fire text rather than inferring
the state from an affliction-name lookup. It sidesteps the whole `crippled*` vs `broken*` vs
`damaged*` naming question instead of picking a side in it.

---

## Quality Gates (Hooks)

Hooks in `.claude/hooks/` run automatically and block operations that fail validation:

| Hook | Blocks on |
|------|-----------|
| `lint-before-commit.sh` | Lua syntax errors in staged `.lua` files (runs `luac -p`) |
| `protect-config.sh` | Write/Edit to `.claude/settings*.json` files |
| `block-git-bypass.sh` | Dangerous git flags (`--no-verify`, `--force`, `--hard`) |
| *(inline)* | Concurrent `muddle.bat` or `convert_to_muddler.py` processes |

When blocked (exit 2), fix the issue and retry. Never attempt to bypass hooks.
