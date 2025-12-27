--[[mudlet
type: trigger
name: SLEIZAK RELEASE
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes K-S
- Double Slash
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
- pattern: ^The sleizak rune glitters bright upon (.*).$
  type: 1
]]--

  tarAffed("weariness")
  if not tAffs.nausea then
  tarAffed("nausea")
  if partyrelay then send("pt "..target..": nausea")
      end
  else 
    tarAffed("voyria")
     if partyrelay then send("pt "..target..": voyria")
      end
    end
    
