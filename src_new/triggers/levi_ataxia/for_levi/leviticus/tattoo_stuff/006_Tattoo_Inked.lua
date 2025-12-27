--[[mudlet
type: trigger
name: Tattoo Inked
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Misc Triggers
- Tattoo Stuff
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
- pattern: ^As the (\w+) tattoo's shape is codified on the .+ of yourself, the last of the ink leaves the air and you pause
    for a moment to admire your handiwork.$
  type: 1
- pattern: ^You impulsively scribe a (\w+) tattoo onto your (.+) with surprising dexterity.$
  type: 1
]]--

local tat = matches[2]:lower()
tat = tat:title()

if table.contains(crucialTattoos, tat) then
	send("touch "..tat)
	table.remove(crucialTattoos, table.index_of(crucialTattoos, tat))
end

if crucialTattoos and #crucialTattoos > 0 then
	cecho("\n<LightSlateGrey> "..utf8.char(186).."----------------------------------------------------"..utf8.char(186))
	cecho("\n<LightSlateBlue>   Still missing: <NavajoWhite>"..table.concat(crucialTattoos, ", ").."<LightSlateBlue>.")
	cecho("\n<LightSlateGrey> "..utf8.char(186).."----------------------------------------------------"..utf8.char(186))
elseif #crucialTattoos == 0 then
	ataxiaEcho("All tattoos are done!")
end