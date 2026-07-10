--[[mudlet
type: trigger
name: Not Performing - Recompose
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes A-J
- Bard
- Bard Rework
- Performance Tracking
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
- pattern: You can hardly manipulate a grand performance when you are not in fact performing
  type: 1
]]--

-- The bash performance has lapsed (this error fires when something tries to use a
-- performance we no longer have). Re-compose it (helper wields the lyre first, then
-- composes bashCompose and re-arms the 15-min timer) if we're bashing as a bard.
bardperformance = false
if gmcp.Char.Status.class == "Bard" and ataxiaBasher and ataxiaBasher.enabled and ataxiaBasher_bardCompose then
	ataxiaBasher_bardCompose()
end
