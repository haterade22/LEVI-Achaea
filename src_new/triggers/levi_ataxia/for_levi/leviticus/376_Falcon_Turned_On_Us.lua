--[[mudlet
type: trigger
name: Falcon Turned On Us
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Basher
- Bashing
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
- pattern: ^A razor-beaked falcon dives at you, raking your face with its talons\.$
  type: 1
- pattern: ^A razor-beaked falcon rips out a chunk of your flesh with its beak\.$
  type: 1
]]--

--[[
    OUR OWN FALCON IS ATTACKING US (live 2026-07-30) -- the Runewarden twin of the
    daemonic hyena turning on its owner (trigger 372).

    Unlike the hyena, "falcon" IS already on ataxiaBasher.ownDenizens (seeded in
    002_Check_For_Any_Missing_Variables), so the basher never targeted it -- something
    else flipped it (an AoE clipping it, or a tower effect). Either way the response is
    the same and it is FREE: ORDER FALCON PASSIVE costs no balance and no equilibrium,
    so it can go out on any round, including one where we are gated.

    Both of the falcon's attack lines are covered. Against a real foe they read
    "...dives at a revolting ghoul, raking his face..." / "...rips out a chunk of a
    wraith's flesh..."; only the second-person forms name US, so these anchored
    patterns cannot fire on a normal rake.

    10s debounce (the hyena's): a flipped pet keeps clawing every few seconds and one
    order is enough, but if it somehow re-engages we re-issue rather than give up.
]]--

if ataxiaBasher and ataxiaBasher.enabled then
	if not ataxiaTemp.falconPassiveAt or (getEpoch() - ataxiaTemp.falconPassiveAt) > 10 then
		ataxiaTemp.falconPassiveAt = getEpoch()
		send("order falcon passive", false)
		if ataxiaEcho then
			ataxiaEcho("<red>Your falcon is attacking YOU<reset> -- ordered passive (free, no balance).")
		end
	end
end
