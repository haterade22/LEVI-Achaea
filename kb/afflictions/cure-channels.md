---
topic: cure-channels
confidence: CONFIRMED unless tagged
sources:
  - kb/raw/help/13.7.2_afflictions-and-what-cures-them.txt
  - kb/raw/help/13.7.1_curatives-and-what-they-cure.txt
  - kb/raw/guides/lock-types.txt
last_verified: 2026-10-10
---

# Cure channels

A **channel** is a way of curing that has its own balance. Two cures on the same balance
compete with each other, and an affliction that **blocks** a channel shuts off everything
cured through it. See [README.md](README.md) for the overall model.

| Channel | Command | Curatives | Blocked by | What it cures (HELP 13.7.2) |
|---|---|---|---|---|
| **Eat** | `EAT <herb>` | kelp/aurum, ginseng/ferrum, goldenseal/plumbum, lobelia/argentum, prickly ash/stannum, bellwort/cuprum, bloodroot/magnesium, pear/calcite, ginger/antimony | **anorexia** | Most afflictions: one per eat, from that herb's group ([catalog](catalog.md)) |
| **Apply** | `APPLY <salve> [to <part>]` | epidermal, mending, restoration, caloric | **slickness** | anorexia, blindness, deafness, stuttering (epidermal); crippled limbs, ablaze (mending); damaged/mangled limbs, concussion, internal trauma (restoration); freezing (caloric) |
| **Smoke** | `SMOKE <pipe>` | elm/cinnabar, valerian/realgar | **asthma** | aeon, deadening (elm); disloyalty (old name disfigurement), hellsight, mana leech, slickness (valerian) |
| **Sip** | `SIP <elixir>` | health, mana, immunity, ... | (none listed) | voyria (immunity) |
| **Focus** | `FOCUS` | (none) | **impatience** | anorexia, or a mental affliction (lock guide) |
| **Tree** | `TOUCH TREE` | tree tattoo | **paralysis** | one random affliction |
| **Writhe** | `WRITHE` | (none) | (none listed) | entangled, transfixed, webbed |
| **Clot** | `CLOT` | (none) | (none listed) | bleeding (SSC: `CURING USECLOT`, `CURING CLOTAT <amount>`) |
| **Compose** | `COMPOSE` | (none) | (none listed) | fear |
| **Scrub** | `SCRUB` | (none) | must be at a water location | stinky |
| **Swim** | (move into deep water) | (none) | needs water | ablaze ("may also be resolved by finding an available source of water to swim in") |

## Shared balances (CONFIRMED in code, not in HELP)

- **Eating is shared with moss/potash.** Healing by moss and curing by herb compete for the
  same eat. This is the reason the PvE bash curing profile exists
  (`ataxia/008_Bash_Curing_Profile.lua`).
- **Salves are shared between limb mending/restoration and the traumas** (concussion,
  mildtrauma, serioustrauma). The same profile parks those at 20 so limbs come first while bashing.
- **The four fractures are NOT salve cures** (corrected 2026-10-23, v4.7.449). `crackedribs`,
  `skullfractures`, `wristfractures` and `torntendons` are cured by `APPLY HEALTH TO <spot>`, the
  health elixir (CONFIRMED, `AFFLICTION SHOW`, [skullfractures](../raw/live/affliction_show/skullfractures.txt)).
  - One application removes ONE stack: "You take some elixir from a stone vial and rub it into
    your head." / "The pain in your head lessens somewhat." took `skullfractures (3)` to `(2)`
    (CONFIRMED, user log 2026-10-23).
  - SSC applies health for them only above 70% health ("Will cure fractures above 70%", CURING
    STATUS; `CURING HEALTHAFFSABOVE`). See [server-side-curing](../curing/server-side-curing.md).
  - `skullfractures` lengthens the elixir recovery and gives periodic nausea; `crackedribs` cuts
    elixir healing and gives periodic sensitivity. A big stack therefore cures slowly, and the
    nausea costs a ferrum every few seconds (CONFIRMED, user log 2026-10-23).
  - They most likely share the elixir balance with health sips (UNCONFIRMED).
  - They are STACK afflictions: `ataxia.afflictions` holds a number. With Death's Demise the
    Mnemosyne sweep waits in the cleared room until they are cured (`mnemosyne/008`
    `M._fractureHold`, 20 s stall release).
- **A herb and its mineral are interchangeable** and use the same balance. SSC's
  `CURING FALLBACK ON` uses the other when you run out of one.

## Two cures for one affliction

- **Slickness** can be eaten (bloodroot/magnesium) **or** smoked (valerian/realgar). The smoke
  needs no anorexia-free window, but asthma blocks it. Locking slickness therefore takes
  both anorexia and asthma, which is why softlock has three afflictions and not two.
- **Anorexia** is cured by applying epidermal **or** by FOCUS. Slickness blocks the salve and
  impatience blocks focus. Truelock adds impatience for exactly this reason.

## Where the code models this

| Concept | Code |
|---|---|
| Target herb groups (tracking) | `curingTable` in `curing/002_Wide_Groups.lua` (live), with `curingTableV3` as fallback (`affliction_tracking_core/007`) |
| Target smoke/salve cures | `smokeCureTableV3`, `salveCureTableV3` (`affliction_tracking_core/007`). The application line names the SPOT, not the salve, so `salveCureTableV3` is keyed by spot (body, skin, head, limbs) and lists everything a salve there cures, in our priority order; one application branches to ONE cure (v4.7.404). Triggers 391 (body/skin), 392 (head), 393 (body restoration timing), 395 (limbs), 153 (health elixir on fractures) |
| Our cure order | `ataxia_defaultCuringPrios()` (`ataxia/001`), bash delta in `ataxia/008` |
| Lock checks | `.claude/databases/locks.yaml`, `.claude/classes/lock_types.md` |
