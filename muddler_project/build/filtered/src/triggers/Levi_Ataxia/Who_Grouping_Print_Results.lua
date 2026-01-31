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
