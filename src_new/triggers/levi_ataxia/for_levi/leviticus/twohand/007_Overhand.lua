--[[mudlet
type: trigger
name: Overhand
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- slc
- Knight Limb Attacks
- TwoHand
attributes:
  isActive: 'yes'
  isFolder: 'no'
  isTempTrigger: 'no'
  isMultiline: 'yes'
  isPerlSlashGOption: 'no'
  isColorizerTrigger: 'no'
  isFilterTrigger: 'no'
  isSoundTrigger: 'no'
  isColorTrigger: 'no'
  isColorTriggerFg: 'no'
  isColorTriggerBg: 'no'
triggerType: 0
conditonLineDelta: 1
mStayOpen: 0
mCommand: ''
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: ^(\w+) brings ([^\.]+) down upon you with a brutal overhand blow\.$
  type: 1
- pattern: '1'
  type: 5
]]--

local warhammers = {"warhammer", "hammer", "Warhammer","Hammer"}
local blades = {"sword", "Sword", "blade", "Blade"}

for i in pairs(warhammers) do
 if string.find(multimatches[1][3], warhammers[i]) then
  slc.overhand_weapon = "hammer"
 end
end

for i in pairs(blades) do
 if string.find(multimatches[1][3], blades[i]) then
  slc.overhand_weapon = "blade"
 end
end

slc_last_limb = "head"
