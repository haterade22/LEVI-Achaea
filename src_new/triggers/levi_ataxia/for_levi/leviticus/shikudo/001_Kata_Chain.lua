--[[mudlet
type: trigger
name: Kata Chain
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Class Stuff
- Monk
- Shikudo
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
mFgColor: '#24717d'
mBgColor: '#000000'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: ^You are now maintaining a kata chain of (\d+) actions.$
  type: 1
]]--

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