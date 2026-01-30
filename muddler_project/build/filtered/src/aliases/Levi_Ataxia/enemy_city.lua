enemycity = matches[2]:title()
enemystring = ": "
targetindex = 0
dembaddies.enemies = {}
expandAlias("qwc")
enableTrigger("copy qwc trigger")

tempTimer(3, [[SetAndReportEnemies()]])
tempTimer(4, [[disableTrigger("copy qwc trigger")]])
 