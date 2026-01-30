--[[mudlet
type: trigger
name: Behead/Cleave
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Misc Tracking
- Warnings
- Warnings
- Instakills
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
- pattern: ^[A-Z][a-z]+ raises (\w+) .+ over (\w+) head and begins to swing it in a wide circle, gaining speed as \w+ goes\.$
  type: 1
- pattern: ^([A-Z][a-z]+) raises an? .+ over you to pass judgement on your sins, and it begins to crackle with righteous fire\.$
  type: 1
- pattern: ^[A-Z][a-z]+ moves into the deeply mournful yet glorious tones of a funeral mass, directing the performance\.$
  type: 1
- pattern: ^[A-Z][a-z]+ masterfully adds heavier, darker tones to h(?:is|er) song, which rises and falls with a melancholy
    rhythm\.$
  type: 1
- pattern: ^[A-Z][a-z]+ begins to bear down on you with (\w+) .+\.$
  type: 1
]]--

cecho("<blue>\n\nBehead / Cleave! BEHEAD / CLEAVE!\nBehead / Cleave! BEHEAD / CLEAVE!\nBehead / Cleave! BEHEAD / CLEAVE!\n\n")
ataxia_setWarning("behead incoming",  2.5)	