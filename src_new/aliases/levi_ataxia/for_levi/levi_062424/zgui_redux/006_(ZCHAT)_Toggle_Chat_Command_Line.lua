--[[mudlet
type: alias
name: (ZCHAT) Toggle Chat Command Line
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- LeviticusREG
- ZulahGUI - Saonji Edit
- zGUI Redux
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^zchat$
command: ''
packageName: ''
]]--

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