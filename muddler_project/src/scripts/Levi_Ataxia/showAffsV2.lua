--[[
    V2 Affliction Display

    Updates the V2 tracking window with current target afflictions.
    Binary system: tAffsV2[aff] = true/nil, tAffStacksV2[aff] = count

    Color coding:
    - Red: Lock afflictions
    - Cyan: Stacked (2+ stacks)
    - White: Other afflictions
]]--

-- Affliction categories for V2 display
local v2AffCategories = {
    -- Lock afflictions (critical)
    lock = {"anorexia", "slickness", "asthma", "paralysis", "stupidity"},

    -- Parry bypass / pressure
    pressure = {"nausea", "clumsiness", "weariness"},

    -- Focus-curable mental
    mental = {"impatience", "confusion", "dementia", "paranoia", "hallucinations",
              "dizziness", "epilepsy", "recklessness", "shyness", "stupidity"},

    -- Limb damage
    limbs = {"damagedleftarm", "damagedrightarm", "damagedleftleg", "damagedrightleg",
             "crippledleftarm", "crippledrightarm", "crippledleftleg", "crippledrightleg"},

    -- Other important
    other = {"prone", "sensitivity", "healthleech", "haemophilia", "lethargy",
             "darkshade", "addiction"},

    -- Defenses (shown differently)
    defenses = {"rebounding", "shield"},
}

-- Short names for afflictions
local v2AffShortNames = {
    -- Lock
    anorexia = "ANO", slickness = "SLI", asthma = "AST", paralysis = "PAR", stupidity = "STU",
    -- Pressure
    nausea = "nau", clumsiness = "clu", weariness = "WEA",
    -- Mental
    impatience = "IMP", confusion = "con", dementia = "dem", paranoia = "pnoia",
    hallucinations = "hal", dizziness = "diz", epilepsy = "epi", recklessness = "rec", shyness = "shy",
    -- Limbs
    damagedleftarm = "La2", damagedrightarm = "Ra2", damagedleftleg = "Ll2", damagedrightleg = "Rl2",
    crippledleftarm = "la1", crippledrightarm = "ra1", crippledleftleg = "ll1", crippledrightleg = "rl1",
    -- Other
    prone = "PRONE", sensitivity = "sen", healthleech = "hleech", haemophilia = "hae",
    lethargy = "let", darkshade = "dar", addiction = "add",
    -- Defenses
    rebounding = "REB", shield = "SHD",
}

-- Get color based on affliction type and stack count
local function getV2AffColor(aff)
    -- Get stack count from separate table
    local stackCount = getStackCountV2 and getStackCountV2(aff) or 0

    -- Stacked (2+ stacks)
    if stackCount >= 2 then
        return "cyan"
    end

    -- Lock afflictions
    if table.contains(v2AffCategories.lock, aff) then
        return "red"
    end

    -- Use existing color scheme if available
    if affs_to_colour and affs_to_colour[aff] then
        return affs_to_colour[aff][1]
    end

    -- Default
    return "white"
end

-- Get display text for an affliction
local function getV2AffDisplay(aff)
    local shortName = v2AffShortNames[aff] or string.sub(aff, 1, 3)
    local stackCount = getStackCountV2 and getStackCountV2(aff) or 0

    -- Show stack count if 2+ stacks
    if stackCount >= 2 then
        return shortName .. "x" .. stackCount
    end

    return shortName
end

-- Main display function
function zgui.showTarAffsV2()
    -- Check if window exists
    if not zgui.targetafflictionV2 or not zgui.targetafflictionV2.console then
        return
    end

    -- Check if we have a target
    if type(target) == "number" or not target or target == "" then
        clearUserWindow("targetafflictionV2Display")
        cecho("targetafflictionV2Display", "<gray>[V2] No target")
        return
    end

    -- Check if V2 is enabled and tAffsV2 exists
    if not tAffsV2 then
        clearUserWindow("targetafflictionV2Display")
        cecho("targetafflictionV2Display", "<orange>[V2] tAffsV2 not loaded")
        return
    end

    -- Build the display string
    local str = "<a_brown>[<cyan>V2<a_brown>][<NavajoWhite>" .. target:title() .. "<a_brown>]: "

    -- Ignored afflictions (defenses handled separately)
    local ignoreAffs = {"curseward", "blindness", "deafness"}

    -- Track if we have any lock afflictions
    local lockCount = 0
    local lockAffs = {"anorexia", "slickness", "asthma", "paralysis", "stupidity"}
    for _, aff in ipairs(lockAffs) do
        if tAffsV2[aff] then
            lockCount = lockCount + 1
        end
    end

    -- Show lock status
    if lockCount >= 5 then
        str = str .. "<green>[SOFT LOCK]<reset> "
    elseif lockCount >= 3 then
        str = str .. "<yellow>[" .. lockCount .. "/5]<reset> "
    end

    -- Show defenses first (rebounding/shield)
    for _, aff in ipairs(v2AffCategories.defenses) do
        if tAffsV2[aff] then
            str = str .. "<red>" .. (v2AffShortNames[aff] or aff:sub(1,3)) .. "<reset> "
        end
    end

    -- Show all other afflictions
    for aff, present in pairs(tAffsV2) do
        if present and not table.contains(ignoreAffs, aff) and not table.contains(v2AffCategories.defenses, aff) then
            local color = getV2AffColor(aff)
            local display = getV2AffDisplay(aff)
            str = str .. "<" .. color .. ">" .. display .. "<reset> "
        end
    end

    -- Update the display
    clearUserWindow("targetafflictionV2Display")
    cecho("targetafflictionV2Display", str)
end

-- Auto-update function (call this on prompt or timer)
function zgui.updateTarAffsV2()
    if zgui.targetafflictionV2 and zgui.targetafflictionV2.window and zgui.targetafflictionV2.window:isVisible() then
        zgui.showTarAffsV2()
    end
end

-- Debug function to show raw V2 data
function zgui.debugTarAffsV2()
    if not tAffsV2 then
        cecho("\n<red>[V2 Debug]<reset> tAffsV2 not loaded")
        return
    end

    cecho("\n<cyan>========== V2 Affliction Debug ==========<reset>")
    cecho("\n<cyan>Target:<reset> " .. (target or "None"))

    local count = 0
    for aff, present in pairs(tAffsV2) do
        if present then
            local stacks = getStackCountV2 and getStackCountV2(aff) or 0
            local stackStr = stacks > 0 and (" (x" .. stacks .. " stacks)") or ""
            cecho("\n  <yellow>" .. aff .. "<reset>" .. stackStr)
            count = count + 1
        end
    end

    if count == 0 then
        cecho("\n  <gray>No afflictions tracked<reset>")
    end

    cecho("\n<cyan>==========================================<reset>")
end
