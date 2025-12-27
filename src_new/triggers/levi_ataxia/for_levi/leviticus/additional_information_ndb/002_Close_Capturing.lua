--[[mudlet
type: trigger
name: Close Capturing
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Ataxia NDB
- Additional Information NDB
attributes:
  isActive: 'yes'
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
- pattern: ''
  type: 7
]]--

if honoursPerson and ataxiaNDB.players[honoursPerson] and ataxiaNDB.players[honoursPerson].city ~= getNDBCity then 
  ataxiaNDB.players[honoursPerson].city = getNDBCity
  cecho("\n<green>Updated city for "..honoursPerson..".")
end

if NDBIsMark then
  if not ataxiaNDB_isMark(honoursPerson) then
    cecho("\n<red>Updated as being mark: "..NDBIsMark..".")
    ataxiaNDB.players[honoursPerson].mark = NDBIsMark
  end
else
  if ataxiaNDB_isMark(honoursPerson) then
    cecho("\n<red>This person is no longer in the mark.")
    ataxiaNDB.players[honoursPerson].mark = nil
  end
end

if NDBARank > 0 then
  if ataxiaNDB_armyRank(honoursPerson) < NDBARank then
    cecho("\n<yellow>Updated army rank to Rank "..NDBARank..".")
    ataxiaNDB.players[honoursPerson].armyRank = NDBARank
    
    if NDBARank >= 3 then
      cecho("<red> - This person is attackable for sanctions.")
    end
  end
else
  if ataxiaNDB_armyRank(honoursPerson) > 0 then
    cecho("\n<yellow>This person is no longer in the army.")
    ataxiaNDB.players[honoursPerson].armyRank = nil
  end
end


NDBARank = nil
NDBIsMark = nil
getNDBCity = nil
honoursPerson = nil
disableTrigger("Get Player Information")
disableTrigger("Additional Information NDB")