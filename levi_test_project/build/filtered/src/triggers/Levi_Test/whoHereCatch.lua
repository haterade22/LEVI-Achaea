local tempI = 0
for k,v in pairs(mmp.pdb_lastupdate) do
	tempI = tempI + 1
	zgui.whoRoomList[tempI] = k
end	
tempI = 0
disableTrigger("whoHereCatch")