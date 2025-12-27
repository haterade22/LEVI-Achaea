--[[mudlet
type: script
name: GMCP DEFS
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- ZulahGUI - Saonji Edit
- zGUI Redux
- Defences
- GMCP Def Functions
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

gmcp_defs = gmcp_defs or {}
 
function gmcp_def_event_list(event)
    local def = ""
    if gmcp.Char.Defences.List then
        gmcp_defs = {}
        for k, v in pairs(gmcp.Char.Defences.List) do
            def = gmcp_def_parse(v.name)
            gmcp_defs[#gmcp_defs+1] = def
        end
    end
    zgui.showDefs()
end
 
registerAnonymousEventHandler("gmcp.Char.Defences.List", "gmcp_def_event_list")
 
function gmcp_def_event_add(event)
    local gmcp_limbs = {"parry right leg", "parry left leg", "parry left arm", "parry right arm", "parry head", "parry torso", "parry right", "parry left", "parry centre"}
    local def = ""
    if gmcp.Char.Defences.Add then
        def = gmcp.Char.Defences.Add.name
        def = gmcp_def_parse(def)
        if table.contains(gmcp_limbs, def) then
            for k,v in pairs(gmcp_limbs) do
                if table.contains(gmcp_defs, v) then
                    table.remove(gmcp_defs, table.index_of(gmcp_defs, v))
                end
            end
        end
        if string.match(def, "shield") then
            --cecho("DEF|<green> " ..string.upper(def).."\n")
            raiseEvent("got def", def)
        end
        gmcp_defs[#gmcp_defs+1] = def
    end
    zgui.showDefs()
end
 
registerAnonymousEventHandler("gmcp.Char.Defences.Add", "gmcp_def_event_add")
 
function gmcp_def_event_remove(event)
    local def = ""
    if gmcp.Char.Defences.Remove then
        def = gmcp.Char.Defences.Remove[1]
        def = gmcp_def_parse(def)
        if string.match(def, "shield") then
            --cecho("DEF|<red> " ..string.upper(def).."\n")
            raiseEvent("lost def", def)
        end
        if table.contains(gmcp_defs, def) then
            table.remove(gmcp_defs, table.index_of(gmcp_defs, def))
        end
    end
    zgui.showDefs()
end
 
registerAnonymousEventHandler("gmcp.Char.Defences.Remove", "gmcp_def_event_remove")
 
function gmcp_def_parse(def)
    local base_def = nil
    local limb = nil
    limb = string.match(def, "%a+ %((.-)%)")
    if limb then
        base_def = string.match(def, "(%a+) %(.-%)")
        if base_def == "parrying" or base_def == "guarding" or base_def == "clawparrying" then
            return "parry "..limb
        else
            return def
        end
    else
        return def
    end
end