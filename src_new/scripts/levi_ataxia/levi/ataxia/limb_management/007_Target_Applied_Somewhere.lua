--[[mudlet
type: script
name: Target Applied Somewhere
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Ataxia
- Combat
- Offensive Things
- Limb Management
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

function target_curedLimb(limb)

  if haveAff("mangled"..limb) then
    erAff("mangled"..limb)
    tAffs["damaged"..limb] = true
  else
    erAff("damaged"..limb)
    tBals.salve = true
    if tBals.timers.salve then killTimer(tBals.timers.salve); tBals.timers.salve = nil end
    if limb ~= "head" and limb ~= "torso" then
      tAffs["broken"..limb] = true
    end
	end
end

function target_salveBal(num)
  local offSalve = num - 0.25
  if tBals.timers.salve then killTimer(tBals.timers.salve) end
  tBals.salve = false
  tBals.timers.salve = tempTimer(offSalve, [[ tBals.salve = true; tBals.timers.salve = nil ]])
end

function target_resetLimb(limb)
  lb.resetLimb(target, limb)
end

function target_appliedTo(where)
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

  -- Arms logic
  if where == "arms" then
      if ataxiaTemp.mendingWait then
          ataxia_Echo("Looks like the last apply was mending.")
          killTimer(ataxiaTemp.mendingWait)
          ataxiaTemp.mendingWait = nil
          killTimer(ataxiaTemp.checkBreak)
          ataxiaTemp.checkBreak = nil
          target_salveBal(1.1)

          if haveAff("brokenleftarm") then
              erAff("brokenleftarm")
          else
              erAff("brokenrightarm")
          end
      end

      if haveAff("damagedleftarm") or haveAff("mangledleftarm") then
          ataxiaTemp.mendingWait = tempTimer(2, function() ataxiaTemp.mendingWait = nil end)
          ataxiaTemp.checkBreak = tempTimer(3.7, function()
              target_curedLimb("leftarm")
              target_resetLimb("left arm")
          end)
          target_salveBal(4)

      elseif haveAff("damagedrightarm") or haveAff("mangledrightarm") then
          ataxiaTemp.mendingWait = tempTimer(2, function() ataxiaTemp.mendingWait = nil end)
          ataxiaTemp.checkBreak = tempTimer(3.7, function()
              target_curedLimb("rightarm")
              target_resetLimb("right arm")
          end)
          target_salveBal(4)

      elseif haveAff("brokenleftarm") then
          erAff("brokenleftarm")
          target_salveBal(1.1)
      else
          erAff("brokenrightarm")
          target_salveBal(1.1)
      end

  -- Legs logic
  else
      if ataxiaTemp.mendingWait then
          ataxia_Echo("Looks like the last apply was mending.")
          killTimer(ataxiaTemp.mendingWait)
          ataxiaTemp.mendingWait = nil
          killTimer(ataxiaTemp.checkBreak)
          ataxiaTemp.checkBreak = nil
          target_salveBal(1.1)

          if haveAff("brokenleftleg") then
              erAff("brokenleftleg")
          else
              erAff("brokenrightleg")
          end
      end

      if haveAff("damagedleftleg") or haveAff("mangledleftleg") then
          ataxiaTemp.mendingWait = tempTimer(2, function() ataxiaTemp.mendingWait = nil end)
          ataxiaTemp.checkBreak = tempTimer(3.7, function()
              target_curedLimb("leftleg")
              target_resetLimb("left leg")
          end)
          target_salveBal(4)

      elseif haveAff("damagedrightleg") or haveAff("mangledrightleg") then
          ataxiaTemp.mendingWait = tempTimer(2, function() ataxiaTemp.mendingWait = nil end)
          ataxiaTemp.checkBreak = tempTimer(3.7, function()
              target_curedLimb("rightleg")
              target_resetLimb("right leg")
          end)
          target_salveBal(4)

      elseif haveAff("brokenleftleg") then
          erAff("brokenleftleg")
          target_salveBal(1.1)
      else
          erAff("brokenrightleg")
          target_salveBal(1.1)
      end
  end
end

