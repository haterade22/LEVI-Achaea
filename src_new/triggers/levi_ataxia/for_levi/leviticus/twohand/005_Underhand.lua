--[[mudlet
type: trigger
name: Underhand
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
  isColorizerTrigger: 'yes'
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
- pattern: ^(\w+) explodes upward from a low crouch, driving ([^\.]+) toward your (.+?)\.$
  type: 1
- pattern: '1'
  type: 5
]]--

local warhammers = {"warhammer", "hammer", "Warhammer","Hammer"}
local blades = {"sword", "Sword", "blade", "Blade"}

for i in pairs(warhammers) do
 if string.find(multimatches[1][3], warhammers[i]) then
  slc.underhand_weapon = "hammer"
 end
end

for i in pairs(blades) do
 if string.find(multimatches[1][3], blades[i]) then
  slc.underhand_weapon = "blade"
 end
end

slc_last_limb = multimatches[1][4]

