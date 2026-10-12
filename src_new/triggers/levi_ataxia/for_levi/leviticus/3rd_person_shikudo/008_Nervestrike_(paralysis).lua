--[[mudlet
type: trigger
name: Nervestrike (paralysis)
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Third Person
- 3rd Person Shikudo
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
- pattern: ^Horror overcomes the face of (\w+) as \w+ body locks in paralysis\.
  type: 1
]]--

-- v4.7.415: nervestrike's own effect line. Mystor's logs (2026-10-11) show it after every nervestrike,
-- light ones included (46 of 46). The strike trigger (563) records paralysis only when a damage line
-- prints, so a light or absorbed nervestrike was never recorded. 563 sets ignoreThirdPerson when it
-- fires, so a normal hit is still recorded once.
if isTargeted(matches[2]) then
  if not ignoreThirdPerson then
    tarAffed("paralysis")
  else
    ignoreThirdPerson = nil
  end
end
