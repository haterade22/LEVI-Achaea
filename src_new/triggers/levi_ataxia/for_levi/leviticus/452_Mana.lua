--[[mudlet
type: trigger
name: Mana
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes A-J
- Alchemist
- Get Humour Levels
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
- pattern: ^(His|Her) mana is at (\d+) out of (\d+).$
  type: 1
]]--

setTriggerStayOpen("Get Humour Levels", 0)
local cm, mm = tonumber(matches[3]), tonumber(matches[4])
tEval.mp = math.floor((cm/mm)*100)

local hpb = math.floor(tEval.hp/5)
local mpb = math.floor(tEval.mp/5)

deleteLine()

local hmc = {sanguine = "", melancholic = "", phlegmatic = "", choleric = ""}
for humour, colour in pairs(hmc) do
	if tEval[humour] < 2 then
		hmc[humour] = "DimGrey"
	elseif tEval[humour] < 4 then
		hmc[humour] = "yellow"
	elseif tEval[humour] < 6 then
		hmc[humour] = "orange"
	else
		hmc[humour] = "red"
	end
end

cecho("\n<sienna>[ <firebrick>S : <"..hmc.sanguine..">"..tEval.sanguine.."<sienna> | <purple>P : <"..hmc.phlegmatic..">"..tEval.phlegmatic..
	"<sienna> | <yellow>C : <"..hmc.choleric..">"..tEval.choleric.."<sienna> | <LightSkyBlue>M : <"..hmc.melancholic..">"..tEval.melancholic..
	"<sienna> ]")


cecho("\n<a_red>HP: <SeaGreen>[<green>"..string.rep("=", hpb)..string.rep(" ", 20-hpb).."<SeaGreen>] <red>"..tEval.hp.."%")
cecho("\n<a_blue>MP: <DeepSkyBlue>[<a_blue>"..string.rep("=", mpb)..string.rep(" ", 20-mpb).."<DeepSkyBlue>] <DodgerBlue>"..tEval.mp.."%")