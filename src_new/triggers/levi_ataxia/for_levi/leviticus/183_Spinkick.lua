--[[mudlet
type: trigger
name: Spinkick
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- MONK 1
- Monk
- Start Shikudo
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
- pattern: ^Whirling around, you bring the ball of your foot (crashing|smashing) into the (temple|ribs) of (\w+).$
  type: 1
]]--

local limb_map = {
 ["temple"] = "head",
 ["ribs"] = "torso"
 }
if isTarget(matches[4]) then
 if matches[3] == "temple" then
  if not tarAff["prone"] then
	 gotAff("prone")
	end
 end
 limbhit(limb_map[matches[3]], "shikudo", "spinkick"..limb_map[matches[3]])
 monk.shikudo.limb_hit(limb_map[matches[3]], "spinkick")
end
