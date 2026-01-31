--[[mudlet
type: trigger
name: Gritting
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
- pattern: ^You slice into the (.+) of (\w+) with (.+).$
  type: 1
- pattern: '1'
  type: 5
- pattern: ^Gritting your teeth, you prepare to fight on through the afflictions which would keep you from your foe.$
  type: 1
]]--

local person = multimatches[1][3]

if isTargeted(person) then
  targetIshere = true
  tAffs.shield = false

	ataxiaTemp.ignoreShield = false
	
    lastLimbAttack = "snbSlice"
      if partyrelay then send("pt "..target..": "..affstruck)
      end
	
end

