--[[mudlet
type: trigger
name: Camus Bite Highlight
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Highlighting
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
- pattern: You sink your fangs into
  type: 2
- pattern: '^.{0,60}injecting just the proper amount of \w+\.$'
  type: 1
- pattern: ^just the proper amount of \w+\.$
  type: 1
- pattern: ^the proper amount of \w+\.$
  type: 1
- pattern: ^proper amount of \w+\.$
  type: 1
]]--

-- OUR VENOM BITE (v4.7.384, user: "Highlight this attack as our attack (orange or something
-- bright)"), the Serpent basher's swing under Serpent's Maw / Toxicologist:
--
--   You sink your fangs into a greater earth elemental, injecting just the proper amount of camus.
--
-- Start of line for the first row. When a long denizen name makes the server wrap it, the break
-- can land anywhere in the tail, so there is one anchored pattern per place it can start, down to
-- "proper amount of <venom>." (Shorter than that -- "of camus." -- is too generic to match safely.)
-- Every venom, not just camus: it is our bite either way.
--
-- `chartreuse` bold: this package's attack-LANDED colour (Kai Choke, Spirit Rend, the thunderstorm
-- strike). The orange family is reserved by `tools/check_colours.py`.
--
-- Highlight only. The PvP venom tracking stays in serpent/009_Bite.
selectString(line, 1)
fg("chartreuse")
setBold(true)
deselect()
resetFormat()
