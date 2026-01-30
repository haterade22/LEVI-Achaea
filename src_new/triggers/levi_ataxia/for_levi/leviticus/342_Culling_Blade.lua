--[[mudlet
type: trigger
name: Culling Blade
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Basher
- Bashing
- Basher Lines
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
- pattern: ^The energy rips into (.+) in a detonation of power.$
  type: 1
- pattern: You swing the culling blade in a great arc, black energy leaping from the blade.
  type: 3
]]--

ataxiaBasher.shielded = false
ataxiaTemp.ignoreCrits = false
if line ~= "You swing the culling blade in a great arc, black energy leaping from the blade." then
	bashStats.attacks = bashStats.attacks + 1
end

ataxiaTemp.bladeCooldown = tempTimer(24, [[ataxiaTemp.bladeCooldown = nil]])

if type(target) == "number" and ataxiaBasher.enabled then
	if line ~= "You swing the culling blade in a great arc, black energy leaping from the blade." then
		bashConsoleEchom("PEW", "CULLED "..matches[2], "red", "a_darkred")
	end

	if not ataxiaBasher.manual then
		deleteFull()
	end
end

