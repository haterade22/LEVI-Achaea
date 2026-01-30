--[[mudlet
type: trigger
name: Print Results
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Ataxia NDB
- Who Grouping
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
- pattern: Total
  type: 2
]]--

deleteLine()
cecho("\n<white>  People who are grouped:\n")

for where, who in spairs(whogroups) do
  if #who > 1 then
    if where ~= "unknown" then
      cecho("\n<white> - (<a_darkgreen>"..where:title().."<white>): <DimGrey>"..table.concat(who, ", ")..".")
    end
  end
end

cecho("\n\n<NavajoWhite>  People on their own:\n")
for where, who in spairs(whogroups) do
  if #who == 1 then
    if where ~= "unknown" then
      cecho("\n<white> - (<a_brown>"..where:title().."<white>): <DimGrey>"..table.concat(who, ", ")..".")
    end
  end
end

cecho("\n\n<red>  Unknown location: <DodgerBlue>"..table.concat(whogroups.unknown, ", ")..".\n\n")
whogroups = nil
setTriggerStayOpen("Who Grouping", 0)
disableTrigger("Who Grouping")
