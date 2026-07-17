--[[mudlet
type: trigger
name: Mnemosyne Run Pause
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
- pattern: ^You whisper to the Mnemosyne and beseech that it grow still for a time\.$
  type: 1
]]--

-- Pausing (not ending) the current run: the next wade re-enters the SAME wade, so onRunStart
-- must resume rather than start a fresh run. See ataxia.mnemosyne.onRunPause (mnemosyne/004).
ataxia.mnemosyne.onRunPause()
