--[[mudlet
type: trigger
name: Wade Stone Tailored Offering
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
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
packageName: ''
patterns:
- pattern: You cast the wade stone across the river Mnemosyne
  type: 0
- pattern: tailored to (.+?) [Bb]oons
  type: 1
]]--

-- THE WADE STONE TELLS YOU WHAT THE NEXT OFFER WILL BE, captured 2026-09-01:
--
--   "You cast the wade stone across the river Mnemosyne, each skip across the ephemeral waters
--    elliciting soft ripples as you sense that your next boon offering shall be tailored to
--    Legendary Boons."
--
-- THE CATEGORY IS CAPTURED, NOT ENUMERATED (user: "Regex the Legendary to capture anything --
-- Offence, Defence, Utility, etc"). `(.+?)` up to " Boons" takes whatever word the game puts
-- there, including one we have never seen and one that is two words. Listing the categories we
-- happen to know is how you get a trigger that works until the next category ships -- the same
-- reasoning as the damage-suppression affixes (v4.7.186) and the fleeing-boss departure line
-- (v4.7.272), both of which were burned by enumerating instead of parsing.
--
-- TWO PATTERNS BECAUSE THE LINE WRAPS. It is ~190 characters, so Achaea's server-side wrap at
-- the player's WIDTH hands Mudlet two physical lines and no single pattern can span the break
-- (v4.7.286). One fragment sits at the START of the sentence, one at the END where the category
-- is, and the body colours whichever line it landed on. A different width only ever costs an
-- uncoloured middle row, never the match.
--
-- THE END FRAGMENT IS AS SHORT AS IT CAN BE, and that is not tidiness. It was first written as
-- `next boon offering shall be tailored to (.+?) Boons` -- fifty characters, which is fifty
-- characters of wrap surface. Tested against the tail on its own ("tailored to Legendary Boons.")
-- it did NOT match, so a break falling inside that clause would have lost the category silently
-- while the line still looked highlighted. `tailored to <x> Boons` is the shortest fragment that
-- still carries the capture, and nothing else in Achaea says it. A wrap landing inside even that
-- is possible; then only the echo is lost and the start fragment still marks the line.
--
-- Note the game's own spelling, "elliciting". Deliberately not matched on: neither fragment goes
-- anywhere near it, so a future fix to that typo cannot break this trigger. (Same care as the
-- parry line, where the game writes "maneouvre".)
--
-- `gold` bold, per the user's request for a bold yellow/gold -- and it is the colour this package
-- already uses for a heading worth stopping on (the bonuses panel's section titles and its
-- OFFENSE total). Verified present in `007_Custom_Colour_Table.lua`, which WHOLESALE REPLACES
-- Mudlet's palette, so a plausible-but-absent name would throw at render time.
selectString(line, 1)
fg("gold")
setBold(true)
deselect()
resetFormat()

-- The category, when this was the fragment that carried it. Echoed rather than merely coloured
-- because the highlight tells you the line HAPPENED and the echo tells you the ANSWER -- and the
-- answer is the reason to read the line at all: it decides whether this dive is worth taking now.
if matches and matches[2] and matches[2] ~= "" then
  local what = matches[2]:gsub("^%s+", ""):gsub("%s+$", "")
  cecho("\n<gold>(MNEM): <reset>next boon offering is tailored to <gold>" .. what .. "<reset>.\n")
end
