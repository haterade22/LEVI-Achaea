--[[mudlet
type: trigger
name: Torment SnB
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- INFERNAL
- SNB Attack Report
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
- pattern: ^You invest necromantic energies into Valafar, a crimson-tinged hellforged longsword, preparing to torment the
    heathens\.$
  type: 1
- pattern: '1'
  type: 5
- pattern: ^You slice into \w+ with Valafar, a crimson-tinged hellforged longsword\.$
  type: 1
]]--

tarAffed("healthleech")
if applyAffV3 then applyAffV3("healthleech") end
 if partyrelay then send("pt "..target..": healthleech") 
    end