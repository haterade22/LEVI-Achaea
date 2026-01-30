function zgui.chatSend(channel, text)
  send(channel.." "..text)
end

zgui.chat.citychat:setCmdAction(zgui.chatSend, "ct")
zgui.chat.housechat:setCmdAction(zgui.chatSend, "ht")
zgui.chat.orderchat:setCmdAction(zgui.chatSend, "ot")
zgui.chat.partychat:setCmdAction(zgui.chatSend, "pt")
zgui.chat.marketchat:setCmdAction(zgui.chatSend, "market")