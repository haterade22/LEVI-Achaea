local ch, mh = tonumber(matches[3]), tonumber(matches[4])
tEval.hp = math.floor((ch/mh)*100)
deleteLine()