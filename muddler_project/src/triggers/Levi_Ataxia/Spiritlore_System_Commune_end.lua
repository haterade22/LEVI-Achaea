echo("\n")
if shaman.spiritlore.autobind then
	if shaman.settings.postcommune ~= nil then
		send(shaman.settings.postcommune)
	end
	shaman.tetherandattune()
	shaman.spiritlore.autobind=false
end