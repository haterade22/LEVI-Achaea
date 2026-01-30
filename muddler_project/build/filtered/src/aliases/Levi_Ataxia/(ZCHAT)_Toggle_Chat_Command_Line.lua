if not zgui.chat then zgui.buildChat() end

if not zgui.chat.useCmdLine then
 zgui.chat.useCmdLine = true
 zgui.chat.allchat:enableCommandLine()
 zgui.chat.citychat:enableCommandLine()
 zgui.chat.orderchat:enableCommandLine()
 zgui.chat.partychat:enableCommandLine()
 zgui.chat.marketchat:enableCommandLine()
 zgui.chat.housechat:enableCommandLine()
else
 zgui.chat.useCmdLine = false
 zgui.chat.allchat:disableCommandLine()
 zgui.chat.citychat:disableCommandLine()
 zgui.chat.orderchat:disableCommandLine()
 zgui.chat.partychat:disableCommandLine()
 zgui.chat.marketchat:disableCommandLine()
 zgui.chat.housechat:disableCommandLine()
end