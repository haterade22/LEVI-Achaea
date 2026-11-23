--[[mudlet
type: trigger
name: Mnemosyne Death
hierarchy:
- Levi_Ataxia
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
- pattern: ^You have been slain by (.+?)\.?$
  type: 1
]]--

local killer = matches[2]

local function realDeath()
  -- Only report if a Mnemosyne run is in progress (M._inRun). If the event's own
  -- death line differs from Achaea's generic slain message, add its pattern here.
  if ataxia.mnemosyne._inRun() then
    ataxia.mnemosyne.reportDeath(killer)
  end

  -- Stop the auto-explorer when slain -- independent of telemetry (the sweep runs
  -- off ataxiaBasher.inMnemosyne, not the tracked run). No-op if not sweeping.
  if ataxia.mnemosyne.exploreOnDeath then
    ataxia.mnemosyne.exploreOnDeath(killer)
  end
end

-- WRATH AND RIGHTEOUSNESS (v4.7.512): with the boon ready, this line may be its save and not a
-- death. The swarm holds both steps until the state shows which (009, S.deathHold); a save
-- records no death and the sweep goes on.
local S = ataxia.mnemosyne.swarm
if not (S and S.deathHold and S.deathHold("mnemosyne", realDeath)) then
  realDeath()
end
