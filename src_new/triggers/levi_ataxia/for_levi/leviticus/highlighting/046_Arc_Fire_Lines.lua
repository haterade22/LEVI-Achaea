--[[mudlet
type: trigger
name: Arc Fire Lines
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
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
- pattern: ^You swing your weapon in a wide arc to hit everyone within your reach\.$
  type: 1
- pattern: ^Your weapon carves through the air with deadly accuracy, slicing open all
    it touches as its keen edge passes by\.$
  type: 1
]]--

-- ARC's fire lines, captured live 2026-08-10 (user):
--
--   You swing your weapon in a wide arc to hit everyone within your reach.
--   Your weapon carves through the air with deadly accuracy, slicing open all it touches
--   as its keen edge passes by.
--
-- TWO LINES, AND THEY ARE NOT INTERCHANGEABLE. The first is the ACTION -- "your weapon",
-- no reference to what kind -- so it prints whatever we are wielding. The second is the
-- EFFECT, and "its keen edge" is edged-weapon wording: a Dual Blunt or blunt-2H knight
-- almost certainly prints something else, which we have not captured. So only the first
-- is used as proof that arc fired; both are highlighted.
--
-- Getting that backwards would put a false "arc never fires" warning in front of every
-- blunt knight, which is exactly the sort of confident-and-wrong signal that wastes an
-- evening. When a line names a weapon PROPERTY, assume the other specs word it differently
-- until seen.
--
-- Anchored regex (type 1), not exact-match type 3: two triggers shipped dead before
-- v4.7.170 because type 3 requires the WHOLE line to match and nothing says these are not
-- suffixed in some contexts.
--
-- CHARTREUSE BOLD is the established "damage actually happening" colour in this package --
-- the hyena maul and falcon rake landings (367 / 370) and the bisect Thunderclap swing
-- (035). Arc is the same category of event: our own room-wide swing, worth spotting
-- mid-scroll. Deliberately NOT the orange_red the older AoE nukes use (culling blade 018,
-- rampage 033) -- that family is grandfathered only, since the user reserves orange.

-- PROOF OF LIFE (see ataxiaBasher_knightArc, basher/002). Arc has no cooldown and no
-- in-flight replay, so before this there was nothing anywhere that knew whether it had
-- ever actually fired -- and v4.7.244 extended it from Infernal to three knights that have
-- never run it. `arcOk` is that proof; it short-circuits the never-fired warning for good.
if matches[1]:find("wide arc", 1, true) then
  ataxiaTemp = ataxiaTemp or {}
  ataxiaTemp.arcOk = true
  ataxiaTemp.arcTries = nil
end

selectString(line, 1)
setBold(true)
fg("chartreuse")
deselect()
resetFormat()
