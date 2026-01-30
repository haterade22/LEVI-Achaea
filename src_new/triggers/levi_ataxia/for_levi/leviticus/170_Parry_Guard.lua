--[[mudlet
type: trigger
name: Parry/Guard
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
- pattern: ^(\w+) parries the attack with a deft manoeuvre\.$
  type: 1
- pattern: ^(\w+) moves into your attack, knocking your blow aside before viciously countering with a strike to your head\.$
  type: 1
- pattern: ^(\w+) steps into the attack, grabs your arm, and throws you violently to the ground\.$
  type: 1
]]--

--if last hit was a limb then set parry
if table.contains(monk.shikudo.limb_table, monk.shikudo.limbs_hit[#monk.shikudo.limbs_hit]) then
	monk.shikudo.target_parry = monk.shikudo.limbs_hit[#monk.shikudo.limbs_hit]
	tparry = monk.shikudo.target_parry 
	cecho("<red>\n TARGET IS PARRYING " ..tparry)
	raiseEvent("target_window_change")
	if not table.contains(monk.shikudo.parrying, monk.shikudo.limbs_hit[#monk.shikudo.limbs_hit])  then
	 monk.shikudo.parrying[#monk.shikudo.parrying+1] = monk.shikudo.limbs_hit[#monk.shikudo.limbs_hit]
	end
end