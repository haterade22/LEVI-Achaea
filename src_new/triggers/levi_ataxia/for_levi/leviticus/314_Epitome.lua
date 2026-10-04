--[[mudlet
type: trigger
name: Epitome
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
attributes:
  isActive: 'no'
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
- pattern: ^(\w+) moves with the grace of the wind, \w+ stance the epitome of perfection beneath the flurry of blows\.$
  type: 1
]]--
-- DISABLED v4.7.376: duplicate of 703_Epitome on the same line (both fired, both threw on an
-- unassigned `epitomiser`). 703 is the fixed owner.

-- Highlight the line
selectString(line, 1)
fg("orange_red")
setBold(true)
resetFormat()

-- Alert with box echo
ataxia_boxEcho("EPITOMISE - " .. epitomiser:upper() .. " - SWITCH TARGETS (6s)", "NavajoWhite:a_darkmagenta")

-- Alert party
send("pt " .. epitomiser .. " used EPITOMISE - switch targets for 6 seconds!")

-- Set timer for when Epitomise ends
if ataxiaTemp.epitomiseTimer then
  killTimer(ataxiaTemp.epitomiseTimer)
end

ataxiaTemp.epitomiseTimer = tempTimer(6, [[
  ataxia_boxEcho("EPITOMISE ENDED - Resume attacking!", "green:a_darkgreen")
  cecho("\n<green>-= " .. "]] .. epitomiser .. [[" .. "'s EPITOMISE has ended! =-")
  killTimer(ataxiaTemp.epitomiseTimer)
  ataxiaTemp.epitomiseTimer = nil
]])
