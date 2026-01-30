local epitomiser = matches[2]

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
