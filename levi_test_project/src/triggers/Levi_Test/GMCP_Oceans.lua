if zgui.map.current ~= "Ocean" then
  zgui.map[zgui.map.current]:hide()
end
zgui.map.current = "Ocean"
zgui.map["Ocean"]:show() 