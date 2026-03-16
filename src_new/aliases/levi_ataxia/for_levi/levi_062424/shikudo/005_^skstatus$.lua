--[[mudlet
type: alias
name: ^skstatus$
hierarchy:
- Levi_Ataxia
- Classes
- Monk
- Shikudo
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^skstatus$
command: ''
packageName: ''
]]--

cecho("\n<white>--- Shikudo Status ---")
cecho("\n<cyan>Form: " .. (ataxia.vitals.form or "nil") .. " | Kata: " .. (ataxia.vitals.kata or 0))
cecho("\n<cyan>Target: " .. (target or "nil"))
local _h = (lb and lb[target] and lb[target].hits) or {}
cecho("\n<yellow>Limbs - H:" .. (_h["head"] or 0) .. " LL:" .. (_h["left leg"] or 0) .. " RL:" .. (_h["right leg"] or 0))
cecho("\n<yellow>Prone: " .. tostring(tAffs.prone) .. " | Windpipe: " .. tostring(tAffs.damagedwindpipe or tAffs.crushedthroat))
cecho("\n<green>Dispatch Ready: " .. tostring(shikudo.checkDispatchReady()))