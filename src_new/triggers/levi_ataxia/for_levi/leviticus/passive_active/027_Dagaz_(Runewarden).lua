--[[mudlet
type: trigger
name: Dagaz (Runewarden)
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Remove Afflictions
- Groups
- Passive/Active
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
- pattern: ^A rune like a rising sun upon the ground flares, bathing (\w+) with healing magic\.$
  type: 1
]]--

-- DAGAZ (Runelore) -- the Runewarden passive heal: on its own ~12s timer the rune flares
-- and cures ONE affliction for free (see passiveCooldownTimingsV3.passive_dagaz,
-- affliction_tracking_core/007:1136).
--
-- The capture is `(\w+)`, so this ONE line covers both sides:
--   * an ENEMY Runewarden's rune  -> name is their name  -> model it in the V3 target tracker
--   * OUR rune                    -> name is literally "you"
-- Until v4.7.171 only the first case was written. `isTargeted("you")` is false unless you
-- happen to be targeting someone called "You", so on our own proc this trigger fired and did
-- nothing at all -- not even the highlight below. The self branch is what was missing.
local name = matches[2]
local class = (ataxiaNDB_getClass(name) or "Unknown")

local voyriaBlock = ((pariah and pariah.state and pariah.state.latencyTimer) and true or false)

if isTargeted(name) and class == "Runewarden" then
  if haveAff("voyria") and not voyriaBlock then
    onClassCureV3({"voyria"})
  else
    ataxiaTemp.randomCure = 1
    onClassCureV3(nil, 1)
  end
  if startPassiveCooldownV3 then startPassiveCooldownV3("passive_dagaz") end
  selectString(line,1)
  fg("NavajoWhite")
  resetFormat()
  targetIshere = true

elseif name:lower() == "you" then
  -- OUR dagaz fired. Highlight only (v4.7.171): a free cure we did not spend a balance on
  -- is worth SEEING in combat spam, but there is nothing useful to record. Our own
  -- affliction state is authoritative-from-GMCP and self-correcting -- lostAff()
  -- (004_Aff_gains_losses:243-302) already nils the entry and raises "aff cured" -- so a
  -- "dagaz cured one" signal would add no bookkeeping. (The real gap is that nothing knows
  -- whether OUR passive is ready; passiveCooldownsV3 is entirely enemy-side. Left open.)
  --
  -- medium_sea_green, deliberately NOT spring_green: that already means parry-success /
  -- our-proc (highlighting/027, /015) and the two must not be confusable mid-fight.
  selectString(line, 1)
  setBold(true)
  fg("medium_sea_green")
  deselect()
  resetFormat()
end
