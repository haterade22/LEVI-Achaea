if zgui.map.current ~= "Wilderness" then
  zgui.map[zgui.map.current]:hide()
end
zgui.map.current = "Wilderness"
zgui.map["Wilderness"]:show()