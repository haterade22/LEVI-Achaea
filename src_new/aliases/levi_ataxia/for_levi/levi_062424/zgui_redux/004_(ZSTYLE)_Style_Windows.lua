--[[mudlet
type: alias
name: (ZSTYLE) Style Windows
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
regex: '^zstyle(?: (\w+))?$'
command: ''
packageName: ''
]]--

if matches[2] then
  local showThis = string.lower(matches[2])
  local foundIt = false
  for k,v in pairs(zgui.styles) do
    if k == showThis then
      foundIt = true
      zgui.useStyle = showThis
      zgui.restyle()
    end
  end
  if not foundIt then
    cecho("\n<purple> -No <white>\["..showThis.."\]<purple> Found \n")
  end
else
  cecho("\n<purple> --------------------------------------------------------")
  cecho("\n<purple>      GUI Styler\n")
  cecho("\n<purple> Styles Already Installed:")
  for k,v in pairs(zgui.styles) do
    cecho("\n<white> -"..k.."<purple> = "..zgui.styles[k].."<gray>\(\)")
  end 
  cecho("\n\n<purple> -To Switch Styles Type:")
  cecho("\n<white>    zstyle greygroove")
  cecho("\n<white>    zstyle greeninset")
  cecho("\n<purple> --------------------------------------------------------\n")
end