--[[mudlet
type: trigger
name: TC Probe Complete
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Totem
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
mFgColor: ''
mBgColor: ''
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: It weighs about
  type: 0
]]--

-- Set flag instead of calling onProbeComplete() directly.
-- The prompt handler will process results AFTER all probe output lines
-- (including the empowered line that comes after this) have been received.
if totemChecker and totemChecker.state and totemChecker.state.active
   and totemChecker.state.phase == "probing" then
  totemChecker.state.probeDataReceived = true
end
