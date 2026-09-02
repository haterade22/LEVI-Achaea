--[[mudlet
type: trigger
name: Mnemosyne Spirit Rend Confirmed
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Mnemosyne
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
- pattern: ^You violently propel your kai energy at .+, enfeebling
  type: 1
]]--

-- Enfeeble CONFIRMED, live-captured 2026-09-02:
--
--   "You violently propel your kai energy at a haskrovska vine, enfeebling him."
--
-- The boon's 60s denizen cooldown starts from THIS line, not from the send -- a command the
-- server ate or refused has not spent it, and stamping on send would lock the ability out for a
-- full minute over a round that never happened (the Kai Choke reasoning, v4.7.122).
--
-- The pattern stops before the pronoun. The game picks "him"/"her"/"it" from the denizen's
-- gender -- "a haskrovska vine" is a plant and still took "him" -- so matching one of them would
-- work until the first mob the game genders differently. Nothing in Achaea else says "propel your
-- kai energy at ... enfeebling", so the fragment is distinctive without it.
--
-- Self-proving, like the choke burst: the line only prints when the ability actually landed, so it
-- also (re)sets the flag and a missed BOONS row cannot desync us.
-- HIGHLIGHTED HERE rather than in a second trigger under `highlighting/` (user-requested,
-- 2026-09-02). Two triggers on one line is how you get two handlers drifting apart, and this one
-- already owns the match. `chartreuse` bold is this package's attack-LANDED colour (the Arc and
-- Thunderclap-bisect fire lines), which is exactly what this is: halving a denizen's current
-- health is the single biggest hit the Monk round can land.
selectString(line, 1)
fg("chartreuse")
setBold(true)
deselect()
resetFormat()

if ataxiaBasher_spiritRendConfirm then
  ataxiaBasher_spiritRendConfirm()
end
