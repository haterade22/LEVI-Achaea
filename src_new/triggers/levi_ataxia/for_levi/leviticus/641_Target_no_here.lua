--[[mudlet
type: trigger
name: Target no here?
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
- pattern: You cannot see that being here.
  type: 3
- pattern: Ahh, I am truly sorry, but I do not see anyone by that name here.
  type: 3
- pattern: You detect nothing here by that name.
  type: 3
]]--

-- The game prints these three lines when a command names someone who is not here. The line does
-- not say which command it answers. Our own commands get it too: in the 2026-11-07 spar, the
-- Serpent round's "order adder kill <target>" got a not-found reply in 39 of 39 rounds (no adder
-- was out), and 18 of those replies are these three texts. Each one marked the target gone. The
-- 1.4 s TargetOutOfRoom timer then erased afflictions she still had and reset V3 twice, while she
-- stood in the room and cured.
-- GMCP gives the players in the room (ataxia.playersHere, update_stuff/001). While that list holds
-- the target, we read the refusal as an answer about some other name (in the spar, the adder), so
-- we change nothing. In that spar the room showed Saibel "here, hidden" when the fight began, and
-- the Serpent offence (which sends only to a listed target, serpent/002) sent all 39 rounds.
-- This reading can be wrong. If GMCP lists a target that our commands cannot see (a hidden player,
-- kb/CONFLICTS.md #38), the refusal is about the target, and now no cure-guess timer starts.
-- GMCP RemovePlayer (update_stuff/001) still starts that timer when the target leaves.
-- When the list does not hold the target, keep the old reading: the target is gone.
-- The name compare is the one isTargeted (016) uses: case is ignored, and either name may start
-- the other (`t sai` and a listed "Saibel"). It does not call updateTarget, so it changes nothing.
local function targetListedHere()
  if type(target) ~= "string" or target == "" or type(ataxia) ~= "table"
    or type(ataxia.playersHere) ~= "table" then
    return false
  end
  local want = target:lower()
  for _, name in ipairs(ataxia.playersHere) do
    if type(name) == "string" and name ~= "" then
      local have = name:lower()
      if have:sub(1, #want) == want or want:sub(1, #have) == have then return true end
    end
  end
  return false
end

if targetListedHere() then return end

targetIshere = false
enableTimer("TargetOutOfRoom")