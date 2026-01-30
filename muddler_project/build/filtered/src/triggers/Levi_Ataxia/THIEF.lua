target = matches[2]
moveCursor(0,getLineCount())
deleteFull()
cecho("\n<white>(((((((((((((((((((( " .. matches[2] .. " ))))))))))))))))))))\n ((((((((((((((( YOU WERE SNAPPED! A THIEF? )))))))))))))))")


if isAnsiFgColor(5) then
send("curing prioaff impatience")
send("cq all;touch shield")
myaeon = true
tempTimer(3,[[myaeon = false]])
end
