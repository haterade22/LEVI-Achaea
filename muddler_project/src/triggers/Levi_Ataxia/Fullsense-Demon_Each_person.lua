mmp.locateAndEchoSide(matches[3], matches[2])

fullSensePeople[matches[3]] = fullSensePeople[matches[3]] or {}
table.insert(fullSensePeople[matches[3]], matches[2])
table.sort(fullSensePeople[matches[3]])
deleteLine()