if ataxia.vitals.bal and ataxia.vitals.eq then
   send("reel line", false)
else
   enableTrigger("fishBalTrigger")
   fishBalType="reel line"
end
bashConsoleEcho("fishing", "Can reel fish.")