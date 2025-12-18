-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Levi  Scripts > Leviticus > AzzysEnemyManagement > Enemy Management > add dem baddies



function EnemyCity(person, city)
   local possibleenemies = db:fetch(ndb.db.people, {db:eq(ndb.db.people.city, city)})
   for i,d in ipairs(possibleenemies) do
    if possibleenemies[i].name == person and possibleenemies[i].city == city then
      table.insert(dembaddies.enemies, person)
    end
   end
   --display(dembaddies.enemies)
end

function SetAndReportEnemies()
  send("unenemy all")
  for i,d in ipairs(dembaddies.enemies) do
    enemystring = enemystring .. d .. ", "
    send("enemy "..d)
  end
  send("pt Enemies"..enemystring)
end