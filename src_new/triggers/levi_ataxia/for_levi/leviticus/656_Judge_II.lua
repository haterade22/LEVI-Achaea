--[[mudlet
type: trigger
name: Judge II
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
- pattern: ^([A-Z][a-z]+) swings the crackling mace about h(?:is|er) head, gathering momentum as s?he bears down on you\.$
  type: 1
- pattern: ^([A-Z][a-z]+)'s mace begins to make a high-pitched keening sound as it rapidly spins over h(?:is|er) head\. You
    have only moments left to escape before you are judged\!$
  type: 1
]]--

cecho("<blue>\n\nBehead / Cleave! BEHEAD / CLEAVE!\n<red>Behead / Cleave! BEHEAD / CLEAVE!\nBehead / Cleave! BEHEAD / CLEAVE!\n\n")
ataxia_setWarning("You are being cleaved",  2.5)	