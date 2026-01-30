--[[mudlet
type: trigger
name: BattleRage Special 2
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Basher
- Bashing
- Basher Lines
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
- pattern: ^Warmth spreads up your arm as you gesture at (.+), filling \w+ with foolish bloodlust\.$
  type: 1
]]--

ataxiaBasher.shielded = false
ataxiaTemp.ignoreCrits = false
bashStats.attacks = bashStats.attacks + 1


if gmcp.Char.Status.class == "Shaman" then
battleRage_Timers.special2 = tempTimer(20, [[battleRage_Timers.special2 = nil]])
  if not ataxia.afflictions.aeon then
    if partyrelay then
      send("pt Battlerage - Recklessness given to " ..target)
    end
  end
end




if type(target) == "number" and ataxiaBasher.enabled then
	bashConsoleEcho("battlerage", "Used Special2 battlerage")
	if not ataxiaBasher.manual then
		deleteFull()
	end
end

