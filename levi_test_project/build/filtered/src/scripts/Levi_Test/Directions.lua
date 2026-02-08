function dir_toShort(dir)
  local directions = {
    n = "north",
    ne = "northeast",
    e = "east",
    se = "southeast",
    s = "south",
    sw = "southwest",
    w = "west",
    nw = "northwest",
    u = "up",
    d = "down",
    ["in"] = "in",
    ["out"] = "out",
  }
  for short, long in pairs(directions) do
    if long == dir then
      return short
    end
  end
  return "???"
end

function dir_toLong(dir)
  local directions = {
    n = "north",
    ne = "northeast",
    e = "east",
    se = "southeast",
    s = "south",
    sw = "southwest",
    w = "west",
    nw = "northwest",
    u = "up",
    d = "down",
    ["in"] = "in",
    ["out"] = "out",
  }
  return (directions[dir] and directions[dir] or "???")
end