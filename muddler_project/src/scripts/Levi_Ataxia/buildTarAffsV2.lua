--[[
    V2 Affliction Tracking Window

    Shows target afflictions using the V2 certainty-based tracking system.
    Displays certainty levels and stack counts.

    Certainty levels:
    - 0 = Absent (not shown)
    - 1 = Uncertain (dimmed)
    - 2 = Confirmed (normal)
    - 3 = 2 stacks, 1 uncertain
    - 4 = 2 confirmed stacks
    - etc.
]]--

function zgui.buildTarAffsV2()
    zgui.targetAffsV2Size = zgui.targetAffsV2Size or 9

    -- Create the affliction Adjustable Container (draggable/lockable window)
    zgui.targetafflictionV2 = zgui.targetafflictionV2 or {}

    zgui.targetafflictionV2.window = Adjustable.Container:new({
        name = "zgui.targetafflictionV2.window",
        x = "50%", y = 0,
        width = "50%",
        height = "15%",
        adjLabelstyle = zgui.adjLabelstyle,
        buttonstyle = [[
            QLabel{ border-radius: 5px; background-color: rgba(140,140,140,100%);}
            QLabel::hover{ background-color: rgba(160,160,160,50%);}
        ]],
        buttonFontSize = 10,
        buttonsize = 15,
    }, main)
    zgui.targetafflictionV2.window:changeMenuStyle("dark")

    -- Create the container inside the adjustable window
    zgui.targetafflictionV2.container = Geyser.Container:new({
        name = "zgui.targetafflictionV2.back",
        x = 0, y = 0,
        width = "100%",
        height = "100%",
    }, zgui.targetafflictionV2.window)

    -- Create the MiniConsole for displaying afflictions
    zgui.targetafflictionV2.console = Geyser.MiniConsole:new({
        name = "targetafflictionV2Display",
        x = 0, y = 0,
        autoWrap = true,
        width = "100%",
        height = "100%",
        color = "black",
    }, zgui.targetafflictionV2.container)

    setFontSize("targetafflictionV2Display", zgui.targetAffsV2Size)
    zgui.targetafflictionV2.window:show()

    -- Register module
    if not table.contains(zgui.modules, "buildTarAffsV2") then
        table.insert(zgui.modules, "buildTarAffsV2")
    end

    cecho("\n<cyan>[V2 Tracking Window]<reset> Created! Use zgui.showTarAffsV2() to update.")
end

-- Helper to toggle window visibility
function zgui.toggleTarAffsV2()
    if zgui.targetafflictionV2 and zgui.targetafflictionV2.window then
        if zgui.targetafflictionV2.window:isVisible() then
            zgui.targetafflictionV2.window:hide()
        else
            zgui.targetafflictionV2.window:show()
        end
    else
        zgui.buildTarAffsV2()
    end
end

-- Helper to set font size
function zgui.setTarAffsV2Size(size)
    zgui.targetAffsV2Size = size or 9
    if zgui.targetafflictionV2 and zgui.targetafflictionV2.console then
        setFontSize("targetafflictionV2Display", zgui.targetAffsV2Size)
    end
end
