--[[mudlet
type: alias
name: MIND PARALYZE
hierarchy:
- Levi_Ataxia
- Classes
- Monk
- Telepathy
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^mp$
command: ''
packageName: ''
]]--

-- PARALYSE: the spelling the game accepted, and the wiki's MIND PARALYSE. "mind paralyse Claes"
-- went out and "You reach out with your mind and paralyse Claes." came back
-- (kb/raw/logs/2026-10-11_shikudo-vs-runewarden-snb_attacker.txt:1063-1064 sent, :1067 landed).
-- Whether "paralyze" is accepted at all was never seen.
sendAll("queue addclear free mind paralyse " ..target)