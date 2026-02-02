--[[mudlet
type: trigger
name: Doublestrike Second Hit
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Affs Post Queue - Gated
- Classes K-S
- Sentinel
- Skirmishing
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
- pattern: ^Turning with the motion of your strike, you come back around and slam the haft of your weapon into the temple
    of (\w+).$
  type: 1
- pattern: You feel something crunch under the force of your blow.
  type: 3
]]--

if line:find("crunch") then
  tarAffed("epilepsy")
  if applyAffV3 then applyAffV3("epilepsy") end
elseif isTargeted(matches[2]) then
	tarAffed("impatience")
	if applyAffV3 then applyAffV3("impatience") end
end

