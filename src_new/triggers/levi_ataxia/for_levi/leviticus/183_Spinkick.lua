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
-- v4.7.414: rebuilt. Every call in this body was dead or wrong, so it threw on every spinkick:
-- isTarget() and limbhit() exist nowhere, tarAff is not a table (tarAff[...] errors), and
-- gotAff("prone") is OUR OWN affliction handler (it reads gmcp.Char.Afflictions.Add), so a temple
-- spinkick would have recorded prone on us, not the target. 580/581 record spinkick from the
-- damage line; this keeps only the (guarded) hand-off to an external monk.shikudo, if one exists.
local limb_map = {
 ["temple"] = "head",
 ["ribs"] = "torso"
 }
if isTargeted(matches[4]) then
 if monk and monk.shikudo and monk.shikudo.limb_hit then monk.shikudo.limb_hit(limb_map[matches[3]], "spinkick") end
end
