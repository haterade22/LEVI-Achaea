if tAffs.mildtrauma or tAffs.serioustrauma then
  if ataxiaTemp.fractures.crackedribs == 0 or ataxiaTemp.fractures.crackedribs == nil then
    ataxiaTemp.fractures.crackedribs = 2
    twohanded_torsoHit()
  else
   
    ataxiaTemp.fractures.crackedribs = math.min(7, ataxiaTemp.fractures.crackedribs + 2)
    twohanded_torsoHit()
  end

elseif ataxiaTemp.fractures.crackedribs == 0 or ataxiaTemp.fractures.crackedribs == nil then
    ataxiaTemp.fractures.crackedribs = 1
    twohanded_torsoHit()
else
    ataxiaTemp.fractures.crackedribs = math.min(7, ataxiaTemp.fractures.crackedribs + 1)
    twohanded_torsoHit()
end
if partyrelay then send("pt "..target..": "..ataxiaTemp.fractures.crackedribs.. " crackedribs") end
