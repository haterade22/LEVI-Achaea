ataxia_boxEcho("LITANY INCOMING - SHIELD SHIELD SHIELD!", "NavajoWhite:DarkSlateGrey")
send("queue addclear free touch shield",false)

if ataxia.settings.raid and ataxia.settings.raid.enabled then
  if not ataxia.retardation then
    sendAll("pt LITANY INCOMING! TOUCH SHIELD!", "pt CANCEL TUMBLES IF FORCED","pt LITANY INCOMING! TOUCH SHIELD!", "pt CANCEL TUMBLES IF FORCED",false)
  end
end