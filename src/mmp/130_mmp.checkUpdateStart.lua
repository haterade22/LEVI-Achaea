-- unnamed > For Levi > Levi_062424 > mudlet-mapper_24 > Mudlet Mapper > Check for map updates > Check for updates > mmp.checkUpdateStart

function mmp.checkUpdateStart(...)
  if mmp.checkforupdatetimer then killTimer(mmp.checkforupdatetimer) end
  mmp.checkforupdatetimer = tempTimer(math.random(3, 10), mmp.checkforupdate)
end

function mmp.changeUpdateMap()
  if mmp.settings.updatemap then
    mmp.echo("Will check for new map updates from your MUD.")
    enableTimer"Check for updates periodically"
    mmp.checkUpdateStart()
  else
    mmp.echo("Won't check for new map updates from your MUD.")
    disableTimer"Check for updates periodically"
	if mmp.checkforupdatetimer then killTimer("mmp.checkforupdatetimer") end
  end
end