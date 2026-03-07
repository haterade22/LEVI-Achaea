--[[mudlet
type: script
name: Chat Cmd Prompt
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- ZulahGUI - Saonji Edit
- zGUI Redux
- Build Windows
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

function ataxia.chatSend(channel, text)
  send(channel.." "..text)
end

ataxia.chat.citychat:setCmdAction(ataxia.chatSend, "ct")
ataxia.chat.housechat:setCmdAction(ataxia.chatSend, "ht")
ataxia.chat.orderchat:setCmdAction(ataxia.chatSend, "ot")
ataxia.chat.partychat:setCmdAction(ataxia.chatSend, "pt")
ataxia.chat.marketchat:setCmdAction(ataxia.chatSend, "market")