--[[mudlet
type: trigger
name: Depression Fully Stacked!
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes A-J
- Depthwalker
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
- pattern: ^A look of total despair crosses the face of (\w+).$
  type: 1
]]--

if isTargeted(matches[2]) then
	selectString(line,1)
	fg("black")
	bg("red")
	setBold(true)
	resetFormat()
	-- The depression capstone gives depression + anorexia + masochism (468's
	-- capstone branch records the same). It used to also re-add hypochondria
	-- and nausea, which the target may already have cured -- a phantom
	-- hypochondria then hid LOCK's "rebuild the impatience source" branch
	-- (v4.7.372, deep review).
	tarAffed("depression", "anorexia", "masochism")
end