--[[mudlet
type: trigger
name: Increase Burning
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Mage
- General
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
- pattern: ^You fan the heat of (\w+)'s body into consuming flame\.$
  type: 1
]]--

-- Only our target's burn (v4.7.420). The pattern captured no name, so this line added a burn to
-- `target` whoever it named: our spell on another enemy in a group fight counted on our target.
-- The neighbouring triggers (015_Dehydrate, 019, 021_Freeze, 021_Spell_Outcomes) all check the
-- name. A weary dehydrate's burning stack prints ONE fan line (Tabethys's log, kb/CONFLICTS.md
-- Resolved 2026-10-19), so since v4.7.429 this trigger is the only count of a dehydrate's burn (015
-- no longer counts it). Which OTHER casts print it (moderate fire, firelash, emanation...) is #37.
if matches[2] ~= target then return end

magi.offense = magi.offense or {}
magi.offense.state = magi.offense.state or {}
magi.offense.state.burns = math.min((magi.offense.state.burns or 0) + 1, 5)
tburns = magi.offense.state.burns -- backward compat
tarAffed("burning")
if magi.offense.resoEcho then
  magi.offense.resoEcho("Fire", "Burning " .. magi.offense.state.burns .. "/5", matches[2])
end
