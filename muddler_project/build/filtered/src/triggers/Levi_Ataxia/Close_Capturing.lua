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