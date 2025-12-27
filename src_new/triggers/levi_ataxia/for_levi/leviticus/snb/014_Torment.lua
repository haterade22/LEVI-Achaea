--[[mudlet
type: trigger
name: Torment
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Affs Post Queue - Gated
- Classes K-S
- Knight
- SnB
attributes:
  isActive: 'yes'
  isFolder: 'no'
  isTempTrigger: 'no'
  isMultiline: 'yes'
  isPerlSlashGOption: 'no'
  isColorizerTrigger: 'no'
  isFilterTrigger: 'no'
  isSoundTrigger: 'no'
  isColorTrigger: 'no'
  isColorTriggerFg: 'no'
  isColorTriggerBg: 'no'
triggerType: 0
conditonLineDelta: 1
mStayOpen: 0
mCommand: ''
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: ^You invest necromantic energies into .+ preparing to torment the heathens.$
  type: 1
- pattern: ^You slice into (\w+) with .+\.$
  type: 1
]]--

if not ataxiaTemp.ignoreShield then
	moveCursor(0, getLineNumber())
	if not tAffs.healthleech then tarAffed("healthleech") elseif tAffs.healthleech then
  tarAffed("confusion")end
   if partyrelay then send("pt "..target..": healthleech")
   elseif partyrelay and tAffs.healthleech then send("pt "..target..": confusion")
  
  end
	moveCursorEnd()
end
ataxiaTemp.ignoreShield = nil

tinvest = true