--[[mudlet
type: alias
name: Aff Display
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- Ataxia-DownloadThis
- Ataxia
- Combat Aliases
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^t(f|n) affshow$
command: ''
packageName: ''
]]--

if not ataxiagui.tarAffsWindow then
	ataxiagui.tarAffsWindow = Geyser.Label:new({
		x = "60%", y = 5,
		width = "40%", height = 60,
	}, ataxiagui.bottomContainer)
	ataxiagui.tarAffsWindow:setStyleSheet([[border-image: url("]]..ataxiagui_dir..[[ataxiaBorder.png")]])
	
	ataxiagui.tarAffsConsole = Geyser.MiniConsole:new({
		x = "63%", y = 50,
		width = "34%", height = 50,
		color = "black",
	}, ataxiagui.bottomContainer)
end

if matches[2] == "f" then
	ataxiagui.tarAffsWindow:hide()
	ataxiagui.tarAffsConsole:hide()
	ataxiaTemp.showingAffs = false
else
	ataxiagui.tarAffsWindow:show()
	ataxiagui.tarAffsConsole:show()
	ataxiaTemp.showingAffs = true
	displayTargetAffs()
end