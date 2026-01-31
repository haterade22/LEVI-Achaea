tpinshot = true
tempTimer(30, [[tpinshot = false]])

  cecho("\n")
  ataxia_boxEcho(matches[2].." PINSHOT !!!", "black:orange")
  cecho("\n")
  
  PinshotTimer0 = tempTimer(0,[[cecho("<orange>\n[PINSHOT]: <yellow>hindered movement on <red>"..target.." <yellow>for <white>21 seconds...\n") PinshotTimer0 = nil]])
  PinshotTimer6 = tempTimer(6,[[cecho("<orange>\n[PINSHOT]: <yellow>hindered movement on <red>"..target.." <yellow>for <white>15 seconds...\n") PinshotTimer6 = nil]])
  PinshotTimer11 = tempTimer(11,[[cecho("<orange>\n[PINSHOT]: <yellow>hindered movement on <red>"..target.." <yellow>for <white>10 seconds...\n") PinshotTimer11 = nil]])
  PinshotTimer16 = tempTimer(16,[[cecho("<orange>\n[PINSHOT]: <yellow>hindered movement on <red>"..target.." <yellow>for <white>5 seconds...\n") PinshotTimer16 = nil]])
  PinshotTimer = tempTimer(21,[[cecho("<orange>\n[PINSHOT]: <red>"..target.." <salmon>no longer<yellow> hindered by pinshot!!!\n") PinshotTimer = nil]])
