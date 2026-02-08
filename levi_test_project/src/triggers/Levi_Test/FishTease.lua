if fishTimer then killTimer(fishTimer) end
fishTimer = tempTimer(1.9,  [[if ataxia.vitals.bal and ataxia.vitals.eq then
                   send("tease line",false)
                 else
                   enableTrigger("fishBalTrigger")
                   fishBalType="tease line"
                 end ]])
bashConsoleEcho("fishing", "Hook attempt <able>")