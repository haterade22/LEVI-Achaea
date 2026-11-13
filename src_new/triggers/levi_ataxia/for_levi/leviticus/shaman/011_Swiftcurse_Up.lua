--[[mudlet
type: trigger
name: Swiftcurse Up
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes K-S
- Shaman
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
- pattern: You weave your fingers together, calling upon the swiftcurse to aid you.
  type: 3
]]--

-- A stand-in until the game's count: trigger 012 ("The swiftcurse is empowered with another N
-- curses.") is the real writer. The wiki gives ten curses; a skull pendant (swiftcurse) adds 2/4/6
-- (docs/artefacts-reference.md:445-447), read from our own artefact list (misc_scripts/033). It was
-- a fixed 14, which fitted no level (v4.7.494). Nothing counts a charge down yet: open.
curseCharge = 10 + (ataxia_artefactSize and ataxia_artefactSize("swiftcurse", "add", 0) or 0)
swiftcursing = false

if ataxiaBasher.enabled and found_target then
  -- Attack dispatch now handled by unified tryAttack() gate in prompt handler
  if not ataxiaBasher.manual then
    deleteFull()
  end
end

