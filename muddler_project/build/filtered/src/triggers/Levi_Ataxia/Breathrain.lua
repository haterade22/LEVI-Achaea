ataxia_boxEcho("BREATHRAIN INCOMING - SHIELD SHIELD SHIELD!", "NavajoWhite:DarkSlateGrey")
send("queue addclear free touch shield",false)

if ataxia.settings.raid and ataxia.settings.raid.enabled then
  if not ataxia.retardation then
    sendAll("pt BREATHRAIN INCOMING! TOUCH SHIELD!", "pt BREATHRAIN INCOMING! TOUCH SHIELD!", false)
  end
end