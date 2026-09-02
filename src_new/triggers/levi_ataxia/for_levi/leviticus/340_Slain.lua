--[[mudlet
type: trigger
name: Slain
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
- pattern: ^You have slain (.+), retrieving the corpse.$
  type: 1
- pattern: ^The acid has burned through \w+ skull and into \w+ brain, and \w+ dies screaming \w+ pain\.$
  type: 1
]]--

if type(target) == "number" and ataxiaBasher.enabled then
	bashConsoleEcho("denizen", target.." slain!")
	if not ataxiaBasher.manual then
		deleteFull()
	end
	bashStats.slain = bashStats.slain + 1
  ataxiaBasher.shielded = false
	if ataxiaTemp.canJinx then
		ataxiaTemp.canJinx = false
	end
	
	ataxiaTemp.mobhealth = 0

	-- RAGE-FUELLED (Mnemosyne boon): "When slaying a denizen, your next battlerage attack
	-- will cost no resource." Bank the free charge here -- this trigger is already
	-- denizen-gated (numeric target), so it cannot arm off a player kill. Spent by
	-- ataxiaBasher_brSent the moment a rotation commits to a battlerage; until then it
	-- simply sits, exactly as the game's does.
	if mnemRageFuelled then
		ataxiaTemp.brFreeCharge = true
		if ataxiaBasher_dsAlert then
			ataxiaBasher_dsAlert("Rage-Fuelled: next battlerage is FREE", "chartreuse")
		end
	end

	-- OBLIGATE CARNIVORE + HEALING METABOLISM: top the satiation defence up off the corpse we
	-- have just been handed. A kill is the right moment twice over -- a corpse exists, and the
	-- fight is ending rather than peaking, which matters because eating contends with cure-herbs
	-- for the eating balance. Throttled inside `ataxia_carnivoreEat`, and a no-op unless BOTH
	-- boons are held: without Healing Metabolism a corpse is just food and the horn's emergency
	-- path is enough.
	if ataxia_carnivoreTopUp then ataxia_carnivoreTopUp() end
end

if ataxiaBasher.enabled and matches[2] then
	-- ataxiaBasher_areaKey(), never gmcp's area: this is the highest-traffic targetList writer
	-- (every kill), and the Mnemosyne boon "Creville's Legacy" (incurable dementia) makes gmcp
	-- name a hallucinated REAL area for the whole climb. Keying here on that would create a bogus
	-- targetList["the Northern Ithmia"], file tower denizens into a genuine hunting list, and
	-- disagree with search_targets (which reads the "" key) -- so nothing would ever be targeted.
	local area = ataxiaBasher_areaKey()
	ataxiaBasher.targetList = ataxiaBasher.targetList or {}
	if not ataxiaBasher.targetList[area] then
		ataxiaBasher.targetList[area] = {}
	end
	if not table.contains(ataxiaBasher.targetList[area], matches[2])
	   and not ataxiaBasher_isOwnDenizen(matches[2]) then
		ataxiaBasher_addmob(matches[2])
	end
end

