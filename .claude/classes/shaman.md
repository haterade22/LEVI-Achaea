# Shaman

## Metadata
- **Type**: Base Class
- **Combat Style**: Affliction
- **Difficulty**: Hard
- **Lock Affliction**: Paralysis (already in lock - no special blocker needed)

## Skills
```
Vodun: Voodoo doll manipulation for afflictions
Curses: Direct curse afflictions and debuffs
Spiritlore: Spirit binding and shamanic powers
```

## Kill Routes

### Primary Kill: Truelock (lock / group / bleed modes)
```yaml
type: affliction
summary: Stack afflictions via curse/swiftcurse/jinx faster than target can cure, then finish

prerequisites:
  - Doll is fashioned automatically on first non-group attack ("fashion doll of <target>", 028:665)
    — no separate BIND step; it takes eq, offense starts next press.

steps:
  1: "Doll auto-fashions (fashion doll of <target>)"
  2: "Stack truelock affs: asthma + anorexia + slickness + impatience + paralysis (TRUELOCK_AFFS, 028:171)"
  3: "computeStrategy → 'classlock' if class lock aff missing, else 'finish' (028:220-272)"
  4: "Finish: party callout 'pt TRUELOCK on <t> -- EXECUTE', then jinx sleep sleep (if prone/canJinx)"
  5: "  or 'curse <target> plague invoke soulscourge' (marak) / 'curse <target> plague' (028:680-694)"

required_afflictions:
  - asthma: "blocks smoking"
  - anorexia: "blocks eating"
  - slickness: "blocks applying"
  - paralysis: "blocks tree"
  - impatience: "blocks focus"

notes: "Shaman doesn't need extra lock aff - paralysis in lock is sufficient (paralysis is base lock)"
```

### Alternative Kill: Tzantza (tzantza mode, `shtz`)
```yaml
type: affliction
summary: Stack mental afflictions, then execute with the tzantza curse

steps:
  1: "tzantza_build: swiftcurse/jinx/curse mental affs until getTzantzaAffs() >= 6 (028:264-271)"
  2: "tzantza_execute: 'jinx amnesia tzantza <target>' (canJinx)"
  3: "  or 'swiftcurse <target> tzantza' (charge>1)"
  4: "  or 'curse <target> tzantza invoke soulscourge vodun bind' (marak) (028:942-955)"
```

### Alternative Kill: Bleed / Damage (bleed & damage modes)
```yaml
type: affliction+damage
summary: Haemophilia-first pressure with passive bleed (teraile) and aggressive bloodlet

steps:
  1: "bleed mode: haemophilia-first lock, teraile bleeds on each curse, bloodlet fires aggressively (028:842-904)"
  2: "damage mode: haemophilia → bloodlet → coagulation(bleed>=200)→slickness → pressure curse + soulscourge (028:909-937)"
```

## Offensive Abilities
```yaml
# Vodun
fashion:
  skill: Vodun
  balance: eq
  effect: "Create a vodun doll for target (auto on first non-group attack, no separate BIND step)"
  syntax: "fashion doll of <target>"
  notes: "Fires automatically once per new target; takes eq, offense begins next press (028:663-666)"

# Curses — three delivery methods with distinct speeds and gating
curse:
  skill: Curses
  balance: eq (~2.2s)
  effect: "Apply one curse + optional invoke bonus action; charges jinx for next balance"
  syntax: "curse <target> <curse> [invoke <ability>]"
  notes: "PRIMARY delivery. Only a regular curse charges jinx (swiftcurse does not). (028:760)"

swiftcurse:
  skill: Curses
  balance: eq (~0.8s)
  effect: "Fast single curse — filler between cooldowns"
  syntax: "swiftcurse <target> <curse>  (bare 'swiftcurse' recharges)"
  notes: "Gated by curseCharge > 1; does NOT charge jinx (028:740-755)"

jinx:
  skill: Curses
  balance: eq (~2.3s)
  effect: "Deliver TWO curses in one balance (on different cure paths)"
  syntax: "jinx <curse1> <curse2> <target>"
  notes: "Gated by ataxiaTemp.canJinx, charged only by a prior regular curse (028:747, 811)"

# Curseward counter
breach:
  skill: Curses
  balance: eq
  effect: "Strip target's curseward — always top priority when present"
  syntax: "curse <target> breach"
  notes: "Fires before any other strategy when target has curseward (028:672-675)"
```

## Modes
Offense is mode-driven; `setMode` selects, `computeStrategy` derives the strategy each balance (028:1118-1128, 220-272).

| Mode | Alias | Purpose |
|------|-------|---------|
| group | `shgroup` | Reactive gap-filling for group truelock (swiftcurse-first, speed) |
| lock | `shlock` | Solo lock progression with invoke support (curse→jinx→swift cycle) |
| bleed | `shbleed` | Haemophilia-first lock, teraile passive bleed + aggressive bloodlet |
| damage | `shdmg` | Pure haemophilia/bleed damage pressure |
| tzantza | `shtz` | Mental-aff stack → tzantza execute |

Utility aliases: `shstatus` (status), `shreset` (reset to group), `shspirits` (spirit-binding guide) (028:1211-1268).

## Invoke Abilities (bonus action on a curse)
Selected by `selectInvoke` priority; each requires a bound combat spirit (028:599-650).
```yaml
bloodlet:    { spirit: teraile, effect: "haemophilia + start bleeding",  syntax: "invoke bloodlet <target>" }
coagulation: { spirit: aspar,   effect: "convert bleed>=200 into an affliction", syntax: "invoke coagulation <aff>" }
relapse:     { spirit: syvis,   effect: "force aff to relapse after cure (paralysis is #1 target; skipped vs tree)", syntax: "invoke relapse <aff>" }
soulscourge: { spirit: marak,   effect: "mana damage", syntax: "invoke soulscourge" }
soulrend:    { spirit: maligus, effect: "higher mana damage; gated on manaleech/confusion/shyness/paranoia/dementia", syntax: "invoke soulrend" }
```

## Spiritlore — Required Combat Spirit Profile
```yaml
# Spirits are NOT commanded to attack; they enable the invoke bonus actions above.
# Managed via 'sp create combat binds ...' / 'sp combat'; queried with shaman.spiritisbound().
# On startup the offense warns if any required binding is missing (028:1076-1091).
required_bindings: [marak, teraile, aspar, syvis, maligus]
create: "sp create combat binds marak teraile aspar syvis maligus attunes marak teraile maligus tether anthius"
load:   "sp combat"
guide:  "shspirits"   # prints the profile + current bound/missing state (028:1240-1268)
```

## Passive Cures
```yaml
# Shaman has no notable passive cures
# They rely on standard curing
```

## Limb Strategy
```yaml
enabled: false
notes: "Shaman offense is pure affliction/lock/bleed — no limb-damage logic exists in the code (028)."
```

## Bashing (PvE)
```yaml
# ataxiaBasher_shamanBashing (002_Class_Bashing.lua:727-792)
bash_type: swiftcurse   # default; set via `aconfig bashtype <type>` (shaman.spiritlore.bashType)
curse_used: bleed
rotation:
  - "hp < 60%: 'stand;wield shield;invoke regeneration' (self-heal)"
  - "swiftcurse (charge>1): 'swiftcurse <target> bleed'; else recharge with bare 'swiftcurse'"
  - "arius bashType (arius bound): 'invoke roar <target>'"
  - "else canJinx: 'jinx bleed bleed <target>'; else 'curse <target> bleed'"
battlerage:
  - "invoke korkma <3rd target>: crowd-control on 3+ mobs (001_Bashing_Functions.lua:1013-1015)"
```

## Fighting Against This Class
```yaml
priority_cures:
  - asthma: "Restore smoking ability"
  - slickness: "Restore salve application"
  - anorexia: "Restore eating ability"
  - paralysis: "Restore tree usage"
  - impatience: "Restore focus ability"

dangerous_abilities:
  - vodun_doll: "Remote affliction application"
  - swiftcurse: "Fast 0.8s curse stacking (gated by curse charges)"
  - jinx: "Two afflictions in one balance"
  - relapse: "Forces a cured aff (usually paralysis) to return"
  - bloodlet_bleed: "Haemophilia + accumulating bleed (teraile), coagulated into affs"

avoid:
  - "Letting them get your hair/blood for doll"
  - "Letting curse stacks accumulate"
  - "Ignoring spirits"

recommended_strategy: |
  Destroy or steal their vodun doll if possible.
  Don't give them hair/blood for binding.
  Prioritize curing lock afflictions.
  Track their curse applications.
  Kill bound spirits if they're doing significant damage.
  Keep rebounding up to slow curse application.
```

## Implementation Notes
```
Triggers to watch for:
- "fashions a small doll" - they created a doll (auto-fashioned; no separate bind step)
- Curse / swiftcurse / jinx affliction messages
- Bleed accumulation (haemophilia + teraile passive bleed)

GMCP considerations:
- Track gmcp.Char.Afflictions for current affs
- No direct GMCP for doll status
- Track curse applications via messages

Edge cases:
- Doll must be fashioned and bound to work
- Hair/blood can be obtained various ways
- Some curses have cooldowns
- Spirits have limited duration
- Doll can be destroyed or stolen
- Binding persists until doll destroyed
```
