--[[mudlet
type: alias
name: Snipe
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- LeviticusREG
- Leviticus
- General
- TARGETTING
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^snt(?: (.+))?$
command: ''
packageName: ''
]]--

-- Parse arguments: snt | snt <dir> | snt <Name> | snt <Name> <dir>
local args = matches[2]
local snipeTarget = target
local snipeDir = nil

if args and args ~= "" then
    args = args:trim()
    local parts = args:split(" ")

    if #parts == 1 then
        local arg = parts[1]:lower()
        -- Check if it is a short direction (n, ne, etc.)
        if dir_toLong(arg) ~= "???" then
            snipeDir = arg
        -- Check if it is a long direction (north, northeast, etc.)
        elseif dir_toShort(arg) ~= "???" then
            snipeDir = dir_toShort(arg)
        else
            -- It is a target name
            target = parts[1]:title()
            snipeTarget = target
        end
    elseif #parts == 2 then
        -- snt <Name> <dir>
        target = parts[1]:title()
        snipeTarget = target
        local dirArg = parts[2]:lower()
        if dir_toLong(dirArg) ~= "???" then
            snipeDir = dirArg
        elseif dir_toShort(dirArg) ~= "???" then
            snipeDir = dir_toShort(dirArg)
        else
            snipe.echo("<red>Unknown direction: " .. parts[2])
            return
        end
    else
        snipe.echo("<red>Usage: snt [target] [direction]")
        return
    end
end

if not snipeTarget or snipeTarget == "" then
    snipe.echo("<red>No target set. Use: snt <name> [direction]")
    return
end

snipe.execute(snipeTarget, snipeDir)
