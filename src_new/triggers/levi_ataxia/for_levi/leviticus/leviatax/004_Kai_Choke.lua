--[[mudlet
type: trigger
name: Kai Choke
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- MONK
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
- pattern: Your face contorted in a twisted grimace
  type: 0
- pattern: you clench your fists to crush the life out of
  type: 0
]]--

-- KAI CHOKE, cast line. Live-captured 2026-09-17:
--
--   "Your face contorted in a twisted grimace, you clench your fists to crush the life out of
--    your foe."
--
-- THE OLD PATTERN COULD NEVER FIRE IN PvE. It was
-- `^...crush the life out of (\w+)\.$` -- ONE word before the period, which is a player's name
-- ("Grulk") and never a denizen's. Against a denizen the game says **"your foe"**: two words, so
-- `(\w+)\.$` fails and the whole anchored line fails with it. Exactly the v4.7.313 tempo-trigger
-- bug, in a different file: **a trigger written for a one-word player name is a trigger that has
-- never fired in PvE.**
--
-- TWO SUBSTRING FRAGMENTS, not one anchored regex (the 080_Spirit_Rend_Confirmed convention):
-- Achaea wraps server-side at the player's WIDTH (v4.7.286), and this is a long line, so a wrap
-- would break a single spanning pattern silently. Either fragment alone is enough; neither reaches
-- the name, so a player name, "your foe" and a titled denizen all land.
--
-- THE RELAY IS NOW PvP-ONLY, AND THAT IS A DELIBERATE NARROWING. Fixing the pattern makes this
-- trigger fire for the first time in PvE -- where the Monk basher chokes on a cooldown every time
-- two denizens share a room -- and an unchanged relay would have started spamming the party with
-- "Kai Choked 12345" on every bash round. A numeric `target` is a denizen (the `type(target) ==
-- "number"` idiom this package uses to keep PvE abilities out of PvP and vice versa), so the
-- callout keeps its original audience and its original meaning.
--
-- HIGHLIGHTED HERE rather than in a second trigger under `highlighting/` (the 080 rule, user-
-- requested): two triggers on one line is how you get two handlers drifting apart, and this one
-- already owns the match. `chartreuse` bold is this package's attack-LANDED colour.
selectString(line, 1)
fg("chartreuse")
setBold(true)
deselect()
resetFormat()

-- A WRAPPED LINE MATCHES BOTH FRAGMENTS, ON TWO PHYSICAL LINES. Highlighting each is correct --
-- both halves are the same event and both should be coloured -- but the relay must go out ONCE,
-- so it is throttled. Without this the fragment split would double every party callout.
local nowT = (getEpoch and getEpoch()) or os.time()
ataxiaTemp = ataxiaTemp or {}
if (nowT - (tonumber(ataxiaTemp.kaiChokeSaidAt) or 0)) < 1 then return end
ataxiaTemp.kaiChokeSaidAt = nowT

if partyrelay and target and not ataxia.afflictions.aeon and type(target) ~= "number" then
  send("pt Kai Choked " ..target)
end