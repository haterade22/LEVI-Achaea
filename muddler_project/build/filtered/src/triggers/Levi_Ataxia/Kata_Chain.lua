ataxia.vitals.kata = tonumber(matches[2])
if ataxiaBasher.enabled then
  if not ataxiaBasher.manual then 
    deleteFull()
  end
else
  selectString(line, 1)
  if ataxia.vitals.kata < 6 then
    fg("chat_bg")
  elseif ataxia.vitals.kata == 12 or ataxia.vitals.kata == 24 then
    fg("orange_red")
    cecho("\n   <red>-= NEED TO CHANGE FORMS =-")
    cecho("\n   <red>-= NEED TO CHANGE FORMS =-")
    
   shikudo_checkForms()
  else
    fg("dark_turquoise")
  end
end