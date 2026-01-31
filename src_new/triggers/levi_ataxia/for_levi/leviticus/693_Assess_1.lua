--[[mudlet
type: trigger
name: Assess
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Misc Tracking
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
- pattern: ^You glance over (\w+) and see that \w+ health is at (\d+)\/(\d+)
  type: 1
- pattern: ^Gazing upon (\w+), you establish that \w+ has (\d+) health remaining of (\d+)
  type: 1
]]--

local t, hp, mhp = matches[2], tonumber(matches[3]), tonumber(matches[4])
 php = math.floor((hp/mhp)*100)
local hpb = math.floor(php/5)

if not isTargeted(t) then return end
ataxiaTemp.lastAssess = php


if type(target) == "string" then
	if isTargeted(t) then
		deleteLine()
		cecho("\n<red> +[<NavajoWhite>"..target.."<red>] HP: <SeaGreen>[<green>"..string.rep("=", hpb)..string.rep(" ", 20-hpb).."<SeaGreen>] <red>"..php.."% -- <NavajoWhite>"..hp.."/"..mhp.." ")
		if ataxia_isClass("magi") then
			magi_setBreakpoint(mhp)
			magi_setDestroy(php)
		end
    
    if php <= 49.99 and (ataxia_isClass("Druid") or ataxia_isClass("monk")) then
      ataxia_boxEcho("TARGET IS IN INSTAKILL RANGE", "NavajoWhite:chat_bg")
    end
    
	end
end
