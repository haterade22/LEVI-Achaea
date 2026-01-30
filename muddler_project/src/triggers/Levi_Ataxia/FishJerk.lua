if fishTimer then killTimer(fishTimer) end
fishTimer = tempTimer(1.6,  [[if ataxia.vitals.bal and ataxia.vitals.eq then
                   send("jerk line",false)
                 else
                   enableTrigger("fishBalTrigger")
                   fishBalType="jerk line"
                 end ]])
bashConsoleEcho("fishing", "Hook attempt <jerk>")