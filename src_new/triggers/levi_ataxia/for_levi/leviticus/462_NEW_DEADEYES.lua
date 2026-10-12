--[[mudlet
type: trigger
name: NEW DEADEYES
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes A-J
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
conditonLineDelta: 2
mStayOpen: 1
mCommand: ''
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: ^Summoning up the curse of (\w+), you stare at (\w+), giving \w+ the evil eye\.$
  type: 1
]]--

-- v4.7.416, from an Apostate's own commands (Mystor's log, 2026-10-11) and the Apostate review:
--  * ONE target check now covers every branch. Before, only the first branch checked it, so a stare
--    at someone else recorded clumsiness, stupidity, sicken... on OUR target, and cleared his curseward.
--  * "sensitivity" is excluded from the generic branch, so a deaf target's branch (the eye strips
--    deafness instead) is reachable; it was dead code.
--  * SICKEN gives manaleech first, then slickness once manaleech is up (never paralysis), and the
--    party relay now says which.
tarInsomnia = tarInsomnia or true
deadaff = matches[2]

local eye, who = matches[2], matches[3]
if not isTargeted(who) then return end

local gave = eye
if eye ~= "clumsy" and eye ~= "stupid" and eye ~= "sicken" and eye ~= "dizzy" and eye ~= "vomiting"
  and eye ~= "reckless" and eye ~= "plague" and eye ~= "bleed" and eye ~= "breach" and eye ~= "sleep"
  and eye ~= "paralysis" and eye ~= "sensitivity" then
  tarAffed(eye)
elseif eye == "clumsy" then
  tarAffed("clumsiness")
elseif eye == "stupid" then
  tarAffed("stupidity")
elseif eye == "sensitivity" and not tAffs.deafness then
  tarAffed("sensitivity")
elseif eye == "sensitivity" and tAffs.deafness then
  erAff("deafness")
  gave = "deafness stripped"
elseif eye == "dizzy" then
  tarAffed("dizziness")
elseif eye == "plague" then
  tarAffed("voyria")
elseif eye == "sicken" and not tAffs.manaleech then
  tarAffed("manaleech")
  gave = "manaleech"
elseif eye == "sicken" and tAffs.manaleech then
  tarAffed("slickness")
  gave = "slickness"
elseif eye == "vomiting" then
  tarAffed("nausea")
elseif eye == "reckless" then
  tarAffed("recklessness")
elseif eye == "paralysis" then
  tarAffed("paralysis")
elseif eye == "sleep" then
  tarAffed("hypersomnia")
elseif eye == "bleed" then
  tarAffed("haemophilia")
end
erAff("curseward")

if eye == "sleep" and tAffs.hypersomnia and tarInsomnia == true then tarInsomnia = tempTimer(10, [[tarInsomnia = true; tarInsomnia = false]]) end

if partyrelay then
  deadeye_buffer = deadeye_buffer or {}
  table.insert(deadeye_buffer, gave)
  if deadeye_timer then killTimer(deadeye_timer) end
  deadeye_timer = tempTimer(0, function()
    if deadeye_buffer and #deadeye_buffer > 0 then
      send("pt " .. target .. ": " .. table.concat(deadeye_buffer, " "))
      deadeye_buffer = {}
    end
    deadeye_timer = nil
  end)
end
