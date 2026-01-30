--[[mudlet
type: trigger
name: Highlight Attack
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Runie
- DWB
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
- pattern: ^You skilfully whirl (.+) toward the (\w+) (\w+) of (\w+)\.$
  type: 1
- pattern: ^You whip (.+) toward the (\w+) of (\w+)\.$
  type: 1
- pattern: ^You skilfully whirl a (.+) toward the (\w+) of (\w+)\.$
  type: 1
- pattern: ^You whip (.+) toward the (\w+) (\w+) of (\w+)\.$
  type: 1
- pattern: ^You skilfully whirl a Braincrusher flail toward \w+, slamming the balls of metal into \w+\.$
  type: 1
]]--

selectString(line,1)
setBold(true)
fg("royal_blue")
deselect()
resetFormat()

selectString(line,2)
setBold(true)
fg("royal_blue")
deselect()
resetFormat()

selectString(line,3)
setBold(true)
fg("royal_blue")
deselect()
resetFormat()

selectString(line,4)
setBold(true)
fg("royal_blue")
deselect()
resetFormat()

selectString(line,5)
setBold(true)
fg("royal_blue")
deselect()
resetFormat()




