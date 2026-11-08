--[[mudlet
type: trigger
name: Flayed Sileris
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
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
- pattern: ^You flay the metallic coating from \w+\.$
  type: 1
- pattern: ^You try to flay a non-existent sileris coating from (\w+)\.$
  type: 1
- pattern: ^A death adder lunges for the throat of (\w+), fangs sinking through \w+ fang barrier defence\.$
  type: 1
- pattern: ^The protective coating covering the skin of (\w+) is ripped away (?:along )?with \w+ protections\.$
  type: 1
- pattern: ^The protective coating covering the skin of (\w+) sloughs off\.$
  type: 1
- pattern: ^You flay away (\w+)'s shield defence\.$
  type: 1
- pattern: ^You flay away (\w+)'s aura of rebounding defence\.$
  type: 1
]]--

-- Only the target's coating. The two coating lines name whose coating went, and they did not
-- capture it, so anyone's coating loss erased our target's fangbarrier and sileris (the offence
-- then bit or impulsed into a live coating). kb/raw/logs/ours/2026-10-27_135412_Tabethys.log:
-- 9524-9526, Minkai's coating sloughs off while the target is Belaziel, and both are erased.
-- The rip reaches our seat in two forms: "ripped away with their protections"
-- (kb/raw/logs/ours/2026-11-07_164635_Saibel.log:308, after our flay) and "ripped away along with
-- his protections" (kb/raw/logs/ours/2026-11-03_080944_Lauryyn.log:74, after Gavai's flay of
-- Grulk). Only the first form was read.
-- "You flay the metallic coating from X." captures no name and stays as it was.
-- The death adder line is left as it is: "fangs sinking into his fang barrier defence"
-- (kb/raw/logs/2026-11-03_shikudo-group-alias.txt:3570) left Xylarys's coating up, and Gavai's
-- flay ripped it at 3880 with no new coating between.
if matches[2] and not isTargeted(matches[2]) then return end

erAff("fangbarrier")
erAff("sileris")