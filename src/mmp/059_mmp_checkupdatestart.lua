-- unnamed > For Levi > mudlet-mapper > Mudlet Mapper > Check for map updates > Check for updates > mmp_checkupdatestart

function mmp_checkupdatestart(...)
  if mmp.checkforupdatetimer then killTimer(mmp.checkforupdatetimer) end
  mmp.checkforupdatetimer = tempTimer(math.random(3, 10), mmp.checkforupdate)
end

function mmp.changeUpdateMap()
  if mmp.settings.updatemap then
    mmp.echo("Will check for new map updates from your MUD.")
    enableTimer"Check for updates periodically"
    mmp_checkupdatestart()
  else
    mmp.echo("Won't check for new map updates from your MUD.")
    disableTimer"Check for updates periodically"
	if mmp.checkforupdatetimer then killTimer("mmp.checkforupdatetimer") end
  end
end