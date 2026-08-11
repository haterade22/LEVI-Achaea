--[[mudlet
type: trigger
name: Denizen Stun Boon AoE
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Basher
- Bashing
- Basher Lines
- Denizen Attacks / Misc Lines
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
- pattern: ^An echo of the Great Bard forms in the wake of your strike, ensnaring all presence with His stunning charisma\.$
  type: 1
]]--

-- Mnemosyne boon proc (fires "in the wake of your strike"): an AoE STUN on EVERY denizen
-- in the room ("ensnaring all presence"). Any-source stun capture into the denizen-state
-- layer -- like our Daze cast (trigger 019) but room-wide, not just the current target.
-- No persistent flag needed: the boon doesn't change WHICH attack we use, only procs stun.
-- dsSetAff self-guards non-numeric ids, so this is PvP-inert (players are never tracked).
if ataxiaBasher and ataxiaBasher.enabled and ataxiaBasher_dsSetAff then
  local denizens = (ataxia and ataxia.denizensHere) or {}
  local n = 0
  for id in pairs(denizens) do
    if tonumber(id) then
      ataxiaBasher_dsSetAff(tonumber(id), "stun")
      n = n + 1
    end
  end
  if n > 0 and ataxiaBasher_dsAlert then
    ataxiaBasher_dsAlert("STUN (AoE) on " .. n .. " denizen(s) -- Great Bard echo boon", "magenta")
  end
end

-- HIGHLIGHT IT (v4.7.251, user-directed). The console echo alone is easy to lose in a busy
-- round -- it prints below the line it describes, among the damage numbers. MAGENTA to match
-- the colour dsAlert already uses for this same event, so the line and its echo read as one
-- thing rather than two unrelated notices.
selectString(line, 1)
setBold(true)
fg("magenta")
deselect()
resetFormat()
