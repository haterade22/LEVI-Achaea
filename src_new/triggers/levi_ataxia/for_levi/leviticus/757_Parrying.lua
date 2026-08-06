--[[mudlet
type: trigger
name: Parrying
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Self Limb Tracking
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
- pattern: ^You will now attempt to parry attacks to your (.+).$
  type: 1
- pattern: ^You will now attempt to intercept and counter attacks coming at your (.+).$
  type: 1
]]--

ataxia.parrying.limb = matches[2]:lower()

-- The parry has LANDED, so the anti-spam guard has done its job -- free it now rather than
-- serving out the rest of the fallback timer (v4.7.221). That timer only exists for a
-- confirm that never arrives; holding the guard until it expires is what made the auto-parry
-- adapt at best every other swing against a fast mob. Kill the fallback too, or it fires
-- later and clears the guard belonging to a newer send.
parryAttempted = false
if ataxiaTemp and ataxiaTemp.parryCdT then
  pcall(killTimer, ataxiaTemp.parryCdT)
  ataxiaTemp.parryCdT = nil
end