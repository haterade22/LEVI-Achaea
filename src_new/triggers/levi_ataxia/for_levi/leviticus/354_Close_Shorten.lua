--[[mudlet
type: trigger
name: Close Shorten
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Basher
- Bashing
- Room Info Shortener
attributes:
  isActive: 'yes'
  isFolder: 'no'
  isTempTrigger: 'no'
  isMultiline: 'no'
  isPerlSlashGOption: 'no'
  isColorizerTrigger: 'no'
  isFilterTrigger: 'no'
  isSoundTrigger: 'no'
  isColorTrigger: 'no'
  isColorTriggerFg: 'no'
  isColorTriggerBg: 'no'
triggerType: 0
conditonLineDelta: 0
mStayOpen: 0
mCommand: ''
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: ^.+(exit|exits).+.$
  type: 1
- pattern: ''
  type: 7
]]--

if roomDeleting then
	deleteLine()

	cecho("\n<cyan>(<a_darkcyan>v"..gmcp.Room.Info.num.."<cyan>) <DarkKhaki>"..gmcp.Room.Info.name..".\n")
	local denizens = {}
	for num, mob in pairs(ataxia.denizensHere) do
		table.insert(denizens, mob:title())
	end
	if denizens[1] then
		cecho("\n<a_darkgreen>Denizens: <a_brown>"..table.concat(denizens, ", ")..".")
	end
	if ataxia.playersHere[1] then
		cecho("\n<purple>Players : <a_green>"..table.concat(ataxia.playersHere, ", ")..".")
	end
	
	cecho("\n<NavajoWhite>[Exits] : <goldenrod>"..room_exitstr..".")
end


roomDeleting = false
setTriggerStayOpen("Room Info Shortener",0)
disableTrigger("Room Info Shortener")