if zgui.map.current ~= "Mapper" then
  zgui.map[zgui.map.current]:hide()
end
zgui.map.current = "Mapper"
zgui.map["Mapper"]:show()