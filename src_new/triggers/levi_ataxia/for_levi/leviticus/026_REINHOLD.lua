--[[mudlet
type: trigger
name: REINHOLD
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- MINE ALL MINE
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
- pattern: ^You draw forth a card depicting Reinhold, the Baker and (.+) fully formed into your palm.$
  type: 1
]]--

local food = matches[2]
if food:find("cake") then 
send("cq all;eat cake")
elseif food:find("bowl") then
send("cq all;eat bowl")
elseif food:find("steak") then
send("cq all;eat steak")
elseif food:find("drumstick") then
send("cq all;eat drumstick")
end

--string.find(food,"something")