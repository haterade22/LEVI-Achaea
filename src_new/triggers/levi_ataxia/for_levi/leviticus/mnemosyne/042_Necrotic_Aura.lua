--[[mudlet
type: trigger
name: Mnemosyne Necrotic Aura
hierarchy:
- Levi_Ataxia
- Ataxia
- Mnemosyne
attributes:
  isActive: 'yes'
  isFolder: 'no'
  isTempTrigger: 'no'
  isMultiline: 'no'
  isPerlSlashGOption: 'no'
  isColorizerTrigger: 'no'
  isFilterTrigger: 'no'
  isSoundTrigger: 'no'
  isColorTrigger: 'no'
  isColorTriggerFg: 'no'
  isColorTriggerBg: 'no'
triggerType: 0
conditonLineDelta: 0
mStayOpen: 0
mCommand: ''
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: ^Necrotic Aura\s+\d+\s+\w+
  type: 1
]]--

-- A row in the BOONS list confirms Necrotic Aura is active: "While you are empowered by
-- an aura of death, your attacks will infect the body of your enemy, inhibiting them from
-- healing." The "aura of death" is the DEATHAURA defence (GMCP-tracked), so the boon turns
-- a standing defence into a damage multiplier against every self-healing denizen. The
-- Infernal basher keeps DEATHAURA up while this is set (ataxiaBasher_infDeathaura,
-- basher/002), and the proc line records `inhibit` on the denizen (trigger
-- denizen_attacks_misc_lines/024). Cleared on run start/end; type BOONS to re-sync.
infNecroticAura = true
