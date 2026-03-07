if ataxiaNDB._honoursPerson and ataxiaNDB.players[ataxiaNDB._honoursPerson] and ataxiaNDB.players[ataxiaNDB._honoursPerson].city ~= getNDBCity then
  ataxiaNDB.players[ataxiaNDB._honoursPerson].city = getNDBCity
  cecho("\n<green>Updated city for "..ataxiaNDB._honoursPerson..".")
end

if ataxiaNDB._mark then
  if not ataxiaNDB_isMark(ataxiaNDB._honoursPerson) then
    cecho("\n<red>Updated as being mark: "..ataxiaNDB._mark..".")
    ataxiaNDB.players[ataxiaNDB._honoursPerson].mark = ataxiaNDB._mark
  end
else
  if ataxiaNDB_isMark(ataxiaNDB._honoursPerson) then
    cecho("\n<red>This person is no longer in the mark.")
    ataxiaNDB.players[ataxiaNDB._honoursPerson].mark = nil
  end
end

if ataxiaNDB._dauntless then
  if not ataxiaNDB.players[ataxiaNDB._honoursPerson].dauntless then
    cecho("\n<cyan>Updated as being Dauntless.")
    ataxiaNDB.players[ataxiaNDB._honoursPerson].dauntless = true
  end
else
  if ataxiaNDB.players[ataxiaNDB._honoursPerson].dauntless then
    cecho("\n<cyan>This person is no longer Dauntless.")
    ataxiaNDB.players[ataxiaNDB._honoursPerson].dauntless = nil
  end
end

if ataxiaNDB._armyRank > 0 then
  if ataxiaNDB_armyRank(ataxiaNDB._honoursPerson) < ataxiaNDB._armyRank then
    cecho("\n<yellow>Updated army rank to Rank "..ataxiaNDB._armyRank..".")
    ataxiaNDB.players[ataxiaNDB._honoursPerson].armyRank = ataxiaNDB._armyRank

    if ataxiaNDB._armyRank >= 3 then
      cecho("<red> - This person is attackable for sanctions.")
    end
  end
else
  if ataxiaNDB_armyRank(ataxiaNDB._honoursPerson) > 0 then
    cecho("\n<yellow>This person is no longer in the army.")
    ataxiaNDB.players[ataxiaNDB._honoursPerson].armyRank = nil
  end
end


ataxiaNDB._armyRank = nil
ataxiaNDB._mark = nil
ataxiaNDB._dauntless = nil
getNDBCity = nil
ataxiaNDB._honoursPerson = nil
disableTrigger("Get Player Information")
disableTrigger("Additional Information NDB")
