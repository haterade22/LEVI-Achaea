---
topic: afflictions-and-cures
status: core
confidence: mixed (tagged per claim)
sources:
  - kb/raw/help/13.7.2_afflictions-and-what-cures-them.txt
  - kb/raw/help/13.7.1_curatives-and-what-they-cure.txt
  - kb/raw/help/conditional-afflictions-for-the-achaean-forms.txt
  - kb/raw/guides/lock-types.txt
  - kb/raw/guides/active-and-passive-cures-with-fire-lines.txt
last_verified: 2026-10-10
---

# Afflictions and cures: the core model

Achaean combat comes down to one loop. **Someone gives an affliction. The person who has it
tries to cure it. Each side reacts to what the other just did.** Everything else (locks, limb
breaks, kill conditions) is built on this loop.

This page explains the loop. The details are in:

| Page | Answers |
|---|---|
| [catalog.md](catalog.md) | Every affliction: how it is cured, and what our code does with it (generated) |
| [cure-channels.md](cure-channels.md) | The cure balances, and which afflictions block which channel |
| [class-cures.md](class-cures.md) | Each class's own cures (active and passive), what stops them, and the lines that show them |
| [locks.md](locks.md) | Lock definitions, and how each one is escaped |
| [../curing/curatives.md](../curing/curatives.md) | Every herb, mineral, elixir and salve |
| [../curing/server-side-curing.md](../curing/server-side-curing.md) | The game's own curing system (SSC) and how we drive it |

---

## 1. The loop from both sides

```
          WE GIVE                                   WE GET
  attack/venom lands on target              GMCP Char.Afflictions.Add
            |                                          |
  tarAffed() -> V3 tracker                  ataxia.afflictions[aff] = true
  (we GUESS the target's affs:              (we KNOW our affs -- the server
   illusions, misses, shrugs)                tells us, except hidden ones)
            |                                          |
  TARGET RESPONDS                           WE RESPOND
  - eats/applies/smokes a cure              - SSC cures in priority order
    -> herb cure line -> V3 removes           (curing priority, curingsets)
       one of that herb's affs              - our code overrides: prioaff,
  - class cure (fitness, shrugging...)        swaps, lock-breakers, tree,
    -> passive_active triggers               focus, PvE bash curing profile
  - passive heal (~10s, voyria first)
            |                                          |
  we pick the next affliction:              the attacker picks the next
  what will STICK, given what blocks        affliction based on what we
  their cures                               cannot cure
```

**The asymmetry matters more than anything else on this page.** Our own afflictions are known:
GMCP reports them (`004_Aff_gains_losses.lua` `gotAff`). The only exceptions are hidden
afflictions (`?` in the prompt), and the Truthseeker boon removes even those. The target's
afflictions are only ever guessed. A target eating ginseng tells us they cured *one* of
ginseng's afflictions, never which one. That is why target tracking is a branching probability
engine (V3, `memory/affliction-tracking.md`) and not a set of flags.

## 2. Afflictions are cured through channels

Each cure uses a **balance**, and an affliction can **block a channel**. That is the whole idea
of locking: give the afflictions that block the channels which cure the others. The table below
is CONFIRMED from HELP 13.7.2 and the lock guide; details are in [cure-channels.md](cure-channels.md).

| Channel | Command | Balance | Blocked by |
|---|---|---|---|
| Herb / mineral | EAT | herb (eating) | **anorexia** |
| Salve | APPLY | salve | **slickness** |
| Pipe | SMOKE | smoke | **asthma** |
| Elixir | SIP | sip | (none listed) |
| Focus | FOCUS | focus | **impatience** |
| Tree tattoo | TOUCH TREE | tree | **paralysis** |
| Writhe | WRITHE | (takes time) | (none listed) |
| Class cure | varies | balance / eq | class-specific, see [class-cures.md](class-cures.md) |
| Passive heal | (automatic, ~10s) | none | cures **voyria** before anything else |

The blockers cure each other in a cycle, which is why softlock is just these three:

- **asthma** is cured by EATING kelp/aurum, so anorexia protects it.
- **anorexia** is cured by APPLYING epidermal (or FOCUS), so slickness protects it.
- **slickness** is cured by EATING bloodroot/magnesium or SMOKING valerian/realgar, so anorexia
  and asthma protect it.

Add **paralysis** (blocks the tree) for a venomlock and **impatience** (blocks focus) for a
truelock. The class-specific afflictions in [class-cures.md](class-cures.md) shut the last doors.

## 3. Herb groups: one eat, several possible cures

Each herb cures one affliction from a fixed group, in the server's order. The mineral in the
same row is an exact substitute that uses the same balance. The groups are in
[catalog.md](catalog.md), and our code holds them in `curingTable`
(`curing/002_Wide_Groups.lua`). That table was reconciled against live `WHATCURES` output in
v4.7.371-372.

Why this matters:
- **Stacking.** Give several afflictions from ONE herb group and every eat cures only one of
  them (the "kelp stack"). This keeps asthma stuck for an aeonlock.
- **Tracking.** When the target eats goldenseal, V3 branches over which goldenseal affliction
  went. The candidates are weighted 4/2/1 by position in the list, so **the order of
  `curingTable` matters**. New entries are appended for that reason.

## 4. How the TARGET responds (what our offense must anticipate)

1. **Curatives.** Herb, salve, smoke and sip lines are tracked by the V3 cure handlers.
2. **Class active cures** use balance or equilibrium and are stopped by one affliction each
   (for example fitness by weariness, shrugging by weariness, bloodboil by haemophilia). Our
   triggers live in `src_new/triggers/.../passive_active/`. **Seeing the cure line also proves
   the blocking affliction was absent**, so the trigger removes it from V3 as well. Every row
   is in [class-cures.md](class-cures.md).
3. **Passive heals** cure one affliction about every 10 seconds, and **voyria first**. Voyria
   therefore buys a window to stack another affliction before reapplying it. The triggers
   model this as "voyria if tracked, else one random".
4. **Tree and focus** are random or mental cures, blocked by paralysis and impatience.

This is why each class has a "lock affliction" (`.claude/classes/lock_types.md`): the one
that shuts *their* extra cure.

## 5. How WE respond (what our curing must get right)

- **SSC does the curing.** We set its priorities. `ataxia_defaultCuringPrios()` is the PvP
  table, and `ataxia_bashCuringPrios()` is a PvE delta held in a separate `bash` curingset.
  Lower numbers are cured first. 26 means never cure (blindness, deafness and insomnia are
  kept as defences). Both values are shown per affliction in [catalog.md](catalog.md).
- **Every priority write goes through `ataxia_sendCuringPriority()`.** It throttles writes and
  protects the bash set (CLAUDE.md, "Server-Side Curing").
- **Temporary overrides** use `CURING PRIOAFF`, which writes nothing permanent. Examples: the
  confused + disrupted fix (`curing/004`) and the anti-class swaps
  (`algedonic_defense_1.0/001_Anti_Priorities.lua`).
- **Lock-breaking** uses class cures and the tree when SSC would wait. See the lessons in
  CLAUDE.md ("Silent gates": fitness is blocked by weariness, and a component that defers to
  it must check it can actually run).

## 6. Known gaps and open questions

These are tracked in [../CONFLICTS.md](../CONFLICTS.md). In short:
- HELP 13.7.2 is **stale or short in places**. It said hypochondria is cured by kelp, and live
  `WHATCURES` (2026-10-10) says lobelia/argentum, as our code already did. It lists
  "Disfigurement" where the code tracks `disloyalty`. It omits about 50 afflictions our priority table handles. **Live
  `WHATCURES <aff>` output beats any HELP file.**
- Druid/Sylvan **Grove Cure** has no trigger (its line is uncaptured) and no blocker.

**Best next pastes:** `WHATCURES <aff>` and `AFFLICTION SHOW <aff>` for every affliction in
the "not in HELP 13.7.2" table of [catalog.md](catalog.md), then `HELP CURES` and `HELP HEAL`.
