--[[mudlet
type: alias
name: RESET
hierarchy:
- Levi_Ataxia
- General
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^res$
command: ''
packageName: ''
]]--

slow = 0
-- v4.7.456: `expandAlias("pdo")` stood here. No alias "pdo" exists (in the package or in git
-- history), so Mudlet sent the word to the game: "I cannot fathom the meaning of "pdo"." three
-- times a kill in the 2026-10-27 group log.
shape = 0
parriedlimb = "none"
tAffs = {blindness = true, deafness = true, shield = false, rebounding = true, curseward = true}
if resetStatesV3 then resetStatesV3() end
ataxia_Echo("Reset target afflictions.")
affcount = 0
can_enlighten = false
engaged = false
ataxiaTemp.parriedLimb = "none"
mindlocked = false
corrupted = false
truelock = false
softlock = false
hardlock = false
daeggerhunt = false
freshblood = false
pm = 100
php = 100
targetHealth = 100
tAffs.bleed = 0
mindinvert = false
spiritinvert = false
bodyinvert = false
blast_count = 0
magi.offense = magi.offense or {}
magi.offense.state = magi.offense.state or {}
magi.offense.state.burns = 0
tburns = 0
