# Agent Instructions for LEVI-Achaea Combat System

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

## Quality Gates (Hooks)

Hooks in `.claude/hooks/` run automatically and block operations that fail validation:

| Hook | Blocks on |
|------|-----------|
| `lint-before-commit.sh` | Lua syntax errors in staged `.lua` files (runs `luac -p`) |
| `protect-config.sh` | Write/Edit to `.claude/settings*.json` files |
| `block-git-bypass.sh` | Dangerous git flags (`--no-verify`, `--force`, `--hard`) |
| *(inline)* | Concurrent `muddle.bat` or `convert_to_muddler.py` processes |

When blocked (exit 2), fix the issue and retry. Never attempt to bypass hooks.
