--[[mudlet
type: trigger
name: Throwingaxe 2
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- slc
- Sentinel Limb Attacks
attributes:
  isActive: 'yes'
  isFolder: 'no'
  isTempTrigger: 'no'
  isMultiline: 'yes'
  isPerlSlashGOption: 'no'
  isColorizerTrigger: 'no'
  isFilterTrigger: 'no'
  isSoundTrigger: 'no'
  isColorTrigger: 'no'
  isColorTriggerFg: 'no'
  isColorTriggerBg: 'no'
triggerType: 0
conditonLineDelta: 1
mStayOpen: 0
mCommand: ''
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: ^(\w+) cocks back \w+ arm and throws .+ at your (.+)\.$
  type: 1
- pattern: '1'
  type: 5
]]--

-- multimatches[1] is {full, attacker, limb} for a 2-group pattern, so [4] was ALWAYS nil --
-- even on a matching line this set slc_last_limb to nil. Every sibling gets this right
-- (001 uses [2] for one group; 005/007/009 use [3] for two).
--
-- The pattern above also demanded the literal "a throwing axe" while the attested line names
-- the weapon ("...throws a claw-etched handaxe of steel and ash at your <limb>", 44 of 51
-- hits in the sentinel log) -- the same defect fixed in determine_class/022. So the SLC feed
-- for the Sentinel's most common attack was dead at both ends. `\w+ arm` also admits "their".
slc_last_limb = multimatches[1][3]