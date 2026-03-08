--[[mudlet
type: trigger
name: Cyclone (impatience)
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Affs Post Queue - Gated
- Classes K-S
- Sylvan
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
- pattern: '^Summoning forth energy that you have gathered, you conjure forth a terrible cyclone of wind, picking up the disorientated
    form of (\w+) and whipping (her|him) about in a frenzy, dashing (her|him) against any available surfaces.$  '
  type: 1
]]--

if isTargeted(matches[2]) then
	tarAffed("impatience")

	if sylvan_overcharge then
		tarBonusAff("asthma")
	end	
end