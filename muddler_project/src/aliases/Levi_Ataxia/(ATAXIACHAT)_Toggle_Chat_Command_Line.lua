if not ataxia.chat then ataxia.buildChat() end

if not ataxia.chat.useCmdLine then
 ataxia.chat.useCmdLine = true
 ataxia.chat.allchat:enableCommandLine()
 ataxia.chat.citychat:enableCommandLine()
 ataxia.chat.orderchat:enableCommandLine()
 ataxia.chat.partychat:enableCommandLine()
 ataxia.chat.marketchat:enableCommandLine()
 ataxia.chat.housechat:enableCommandLine()
else
 ataxia.chat.useCmdLine = false
 ataxia.chat.allchat:disableCommandLine()
 ataxia.chat.citychat:disableCommandLine()
 ataxia.chat.orderchat:disableCommandLine()
 ataxia.chat.partychat:disableCommandLine()
 ataxia.chat.marketchat:disableCommandLine()
 ataxia.chat.housechat:disableCommandLine()
end