--[[mudlet
type: trigger
name: Traced Logograph
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes K-S
- Pariah
- Misc
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
- pattern: ^Your knife moves in perfect harmony with your mind as you trace the image of (.+) before (.+)\, the logograph
    outlined in crimson fire\.$
  type: 1
- pattern: ^Your knife moves in perfect harmony with your mind as you trace the image of (.+) before (.+), the logograph bursting
    into crimson fire as you complete your epitaph\.$
  type: 1
]]--

if ataxiaBasher.enabled then
  ataxiaBasher.shielded = false
end

if matches[2] == "the rotting nest" then pariah.lastLogograph = "nest" end
if matches[2] == "the striking serpent" then pariah.lastLogograph = "serpent" end
if matches[2] == "the leaping jackal" then pariah.lastLogograph = "jackal" end
if matches[2] == "the hungering scarab" then pariah.lastLogograph = "scarab" end
if matches[2] == "the savage bear" then pariah.lastLogograph = "bear" end
if matches[2] == "the balanced scales" then pariah.lastLogograph = "scales" end
if matches[2] == "the shining sun" then pariah.lastLogograph = "sun" end
if matches[2] == "the skein" then pariah.lastLogograph = "skein" end
if matches[2] == "the striking scorpion" then pariah.lastLogograph = "scorpion" end





--the savage bear
if pariah.lastLogograph == nil then
local logSearch = matches[2]
for _, logo in pairs({"serpent", "bear", "sun", "nest", "scales", "skein", "scarab", "jackal", "scorpion"}) do
  if logSearch:find(logo) then
    pariah.lastLogograph = logo
    break
  end
end
if logoTimer then killTimer(logoTimer) end
logoTimer = tempTimer(6, [[ logoTimer = nil; pariah.lastLogograph = nil ]])    
end
