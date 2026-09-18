--[[mudlet
type: trigger
name: Flight Truth
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
- pattern: flies up to your level from below.
  type: 0
- pattern: swoops down from the skies to land beside you.
  type: 0
- pattern: You are not flying, my friend.
  type: 0
]]--

-- THREE LINES THAT EACH PROVE THE RECOVERY HOVER'S PREMISE FALSE (v4.7.321, live-captured from a
-- death, 2026-09-18):
--
--   A dream horror flies up to your level from below.               -- a flyer FOLLOWED us up
--   A dream horror swoops down from the skies to land beside you.   -- it came down: we are grounded
--   You are not flying, my friend.                                  -- the refusal of our LAND
--
-- The hover holds every attack for up to 60s on the premise that the sky is untouchable. In the
-- death we were knocked out of it at 12:10:37 and sat on the ground being mauled with every attack
-- held until 12:11:29, then re-hovered into a web that refused the fly, and died.
--
-- ACCELERATORS, NOT THE GUARD. The recovery tick now checks the premise itself every tick, denizen-
-- agnostically (gmcp "Flying above", company in Char.Items, an unconfirmed fly). These lines only
-- make the exit immediate for the wordings we have seen. Substrings on the TAIL of each line so an
-- arbitrary-length denizen name cannot break them; the classification lives in S.onFlightTruth
-- (009), where the suite can see it.
local S = ataxia and ataxia.mnemosyne and ataxia.mnemosyne.swarm
if S and S.onFlightTruth then S.onFlightTruth(line) end
