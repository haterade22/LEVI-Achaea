# Agent Instructions for LEVI-Achaea Combat System

This file contains critical instructions for AI agents working on the combat system.

---

## Before Coding Offensive Systems

**You MUST read these files first:**

1. **[classes/lock_types.md](classes/lock_types.md)** - All lock type definitions
   - Softlock, Venomlock, Truelock/Hardlock
   - Focuslock (mental affliction stacking)
   - Riftlock, Salvelock (limb-based)
   - Sleeplock, Aeonlock (timing/control-based)

2. **[classes/<target_class>.md](classes/)** - Class-specific kill routes
   - Kill route prerequisites and steps
   - Gating requirements for key afflictions
   - Class-specific lock affliction

3. **[classes/README.md](classes/README.md)** - Affliction stacking by herb
   - Which afflictions share cure balances
   - Class-specific lock affliction table

---

## Lock Types Quick Reference

| Lock | Afflictions | Escape |
|------|-------------|--------|
| **Softlock** | asthma + anorexia + slickness | Focus → eat bloodroot → eat kelp |
| **Venomlock** | + paralysis | Focus → eat bloodroot |
| **Truelock** | + impatience + class aff | None without help |
| **Focuslock** | mental aff stacking | Hope Focus cures anorexia |
| **Riftlock** | 2 broken arms + slick + asthma | Smoke valerian → mend → rift |
| **Aeonlock** | aeon + asthma + kelp stack | Must cure asthma first |

---

## Before Coding Defensive Systems

Read the **attacker's class documentation** for:
- Kill routes to counter
- Gating requirements for dangerous afflictions
- Priority cure recommendations
- Class-specific lock affliction to prevent

---

## Affliction Stacking Quick Reference

Stack afflictions that share the same cure herb:

| Herb | Afflictions |
|------|-------------|
| **Kelp** | asthma, clumsiness, sensitivity, weariness, healthleech |
| **Ginseng** | addiction, haemophilia, lethargy, nausea, scytherus |
| **Goldenseal** | impatience, stupidity, dizziness, epilepsy, depression |
| **Bloodroot** | paralysis, slickness |
| **Lobelia** | recklessness, vertigo, masochism, guilt |
| **Ash** | confusion, dementia, hallucinations, paranoia |

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

## Key Files Reference

| Path | Purpose |
|------|---------|
| `.claude/classes/lock_types.md` | Comprehensive lock definitions |
| `.claude/classes/README.md` | Class index and combat concepts |
| `.claude/classes/<class>.md` | Per-class kill routes and mechanics |
| `CLAUDE.md` | Main project documentation |
