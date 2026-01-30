--[[mudlet
type: trigger
name: Execute two
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Misc Tracking
- Warnings
- Warnings
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
- pattern: Holding your head up
  type: 2
- pattern: ^Holding your head up, (\w+) snaps (?:his|her) wrist, sending (?:his|her) whip to wrap around your neck\. (?:He|She)
    casually places (?:his|her) foot upon the small of your back and jerks the whip viciously backwards so that it bites deeply
    into your throat\. Blood streams down from your shattered windpipe as you gasp uselessly for air\.$
  type: 1
]]--

ataxia_setWarning(multimatches[2][2].." still executing you", 2)