--[[mudlet
type: trigger
name: Fracture Type
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Affs Post Queue - Gated
- Classes K-S
- Knight
- Two-hander
- Battlefury Perceive
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
- pattern: ^\w+ suffers from (\d+) (.+).$
  type: 1
]]--

local amt, loc, col = tonumber(matches[2]), matches[3], ""
local tocol = { ["skull fractures"] = "SF", ["wrist fractures"] = "WF", ["cracked ribs"] = "CR",
	["torn tendons"] = "TT" }
	
if trackingFractures then
	if amt < 2 then
		col = "DimGrey"
	elseif amt < 4 then
		col = "yellow"
	elseif amt < 6 then
		col = "orange"
	else
		col = "red"
	end
  
  ataxiaTemp.fractures[loc:gsub(" ", "")] = amt
  
	deleteLine()
	cecho(" <green>(<"..col..">"..amt.." <white>"..tocol[loc].."<green>)")
end
