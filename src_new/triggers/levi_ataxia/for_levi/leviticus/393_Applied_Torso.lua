--[[mudlet
type: trigger
name: Applied Torso
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Remove Afflictions
- Groups
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
- pattern: ^(\w+) takes some salve from a vial and rubs it on \w+ torso.$
  type: 1
- pattern: ^(\w+) takes some salve from a vial and rubs it on \w+ body\.$
  type: 1
]]--

if isTargeted(matches[2]) then
  -- restore passive cures if needed
  if passiveFailsafe then restorePassiveCure() end

  -- slickness and bloodfire always applied
  erAff("slickness")
  erAff("bloodfire")

  -- Central crushedthroat check (head apply could have been pending)
  if ataxiaTemp.crushedCheck and ataxiaTemp.crushedCheck.pending then
      local now = os.clock()
      if now - ataxiaTemp.crushedCheck.lastApply < 1.2 then
          if haveAff("crushedthroat") then
              erAff("crushedthroat")
          end
          killTimer(ataxiaTemp.crushedCheck.timer)
          ataxiaTemp.crushedCheck.pending = false
          ataxiaTemp.crushedCheck.timer = nil
          target_salveBal(1.1)
      end
  end

  local salvetimer = false

  -- Hypothermia logic
  if haveAff("hypothermia") then
      if haveAff("timeflux") then
          tempTimer(6.5, function()
              erAff("hypothermia")
              ataxia_boxEcho("they cured hypothermia", "DodgerBlue")
          end)
          salvetimer = 6.5
      else
          tempTimer(3.5, function()
              erAff("hypothermia")
              ataxia_boxEcho("they cured hypothermia", "DodgerBlue")
          end)
          salvetimer = 3.5
      end

  -- Scalded + Calcified Torso
  elseif haveAff("scalded") and haveAff("calcifiedtorso") and tLimbs.T <= 199 then
      tempTimer(6.5, function()
          erAff("calcifiedtorso")
          target_resetLimb("torso")
          ataxia_boxEcho("they cured Torso Damage", "DodgerBlue")
      end)
      salvetimer = 6.5
  elseif haveAff("scalded") and haveAff("calcifiedtorso") and tLimbs.T >= 200 then
      tempTimer(6.5, function()
          erAff("calcifiedtorso")
          tLimbs.T = 100
          ataxia_boxEcho("they cured ******* Lvl 2 Torso *****", "DodgerBlue")
      end)
      salvetimer = 6.5

  -- Calcified torso only (no scald)
  elseif haveAff("calcifiedtorso") and not haveAff("scalded") and tLimbs.T <= 199 then
      tempTimer(4, function()
          erAff("calcifiedtorso")
          target_resetLimb("torso")
          ataxia_boxEcho("they cured Torso Damage", "DodgerBlue")
      end)
      salvetimer = 3.5
  elseif haveAff("calcifiedtorso") and not haveAff("scalded") and tLimbs.T >= 200 then
      tempTimer(4, function()
          erAff("calcifiedtorso")
          tLimbs.T = 100
          ataxia_boxEcho("they cured ******* Lvl 2 Torso *****", "DodgerBlue")
      end)
      salvetimer = 3.5

  -- Normal torso break checks
  elseif tLimbs.T >= 98 and tLimbs.T < 200 then
      tempTimer(4, function()
          target_resetLimb("torso")
      end)
      salvetimer = 3.5
  elseif tLimbs.T >= 200 then
      tempTimer(4, function()
          tLimbs.T = 100
      end)
      salvetimer = 3.5
  end

  -- Apply salve balance if any timer was set
  if salvetimer ~= false then
      target_salveBal(salvetimer)
  end

  -- Target still present
  targetIshere = true
end