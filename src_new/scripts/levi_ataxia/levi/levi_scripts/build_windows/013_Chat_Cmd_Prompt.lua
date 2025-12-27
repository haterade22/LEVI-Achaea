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

function zgui.chatSend(channel, text)
  send(channel.." "..text)
end

zgui.chat.citychat:setCmdAction(zgui.chatSend, "ct")
zgui.chat.housechat:setCmdAction(zgui.chatSend, "ht")
zgui.chat.orderchat:setCmdAction(zgui.chatSend, "ot")
zgui.chat.partychat:setCmdAction(zgui.chatSend, "pt")
zgui.chat.marketchat:setCmdAction(zgui.chatSend, "market")