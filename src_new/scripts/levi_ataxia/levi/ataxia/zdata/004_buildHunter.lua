--[[mudlet
type: script
name: buildHunter
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Basher
- ataxia.data
- ataxia.data
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Ataxia-DownloadThis > Basher > ataxia.data > ataxia.data > buildHunter

function ataxia.data.buildHunter()
  ataxia.data.hunter = {}

  --Create the hunter Adjustable with position saving
  ataxia.data.hunter.window = Adjustable.Container:new({
    name = "zgui.hunter.window",
    x = 0, y = 0,
    width = "50%",
    height = "50%",
    adjLabelstyle = "background-color:rgba(0,40,100,100%); border: 5px inset purple;",
    buttonstyle=[[
      QLabel{ border-radius: 5px; background-color: rgba(140,140,140,100%);}
      QLabel::hover{ background-color: rgba(160,160,160,50%);}
    ]],
    buttonFontSize = 10,
    buttonsize = 15,
    -- Lock styling - border turns green when locked
    lockStyle = "border: 3px solid green;",
    lockedBorderColor = "green",
  },main)

  --Create the hunter container
  ataxia.data.hunter.container = Geyser.Container:new({
    name = "ataxia.data.hunter.back",
    x = 0, y = 0,
    width = "100%",
    height = "100%",
  },ataxia.data.hunter.window)

  --Create the hunter Console
  ataxia.data.hunter.console = Geyser.MiniConsole:new({
    name = "hunterDisplay",
    x = 0, y = 0,
    autoWrap = false,
    width = "100%",
    height = "100%",
    color="black",
    scrollBar = true,
  },ataxia.data.hunter.container)

  setFontSize("hunterDisplay", 9)
  ataxia.data.hunter.window:setTitle("Hunting Scrolls","gray")

  -- Load saved position if it exists
  if ataxia.data.hunter.window.loadPosition then
    ataxia.data.hunter.window:loadPosition()
  end

  ataxia.data.hunter.window:show()
end

-- Toggle lock state for hunting scrolls window
function ataxia.data.hunterToggleLock()
  if not ataxia.data.hunter or not ataxia.data.hunter.window then
    ataxia.data.echo("Hunter window not open")
    return
  end

  if ataxia.data.hunter.window.locked then
    ataxia.data.hunter.window:unlockContainer()
    ataxia.data.echo("Hunting Scrolls: <green>UNLOCKED<reset> - drag to reposition")
  else
    ataxia.data.hunter.window:lockContainer()
    ataxia.data.hunter.window:savePosition()
    ataxia.data.echo("Hunting Scrolls: <red>LOCKED<reset> - position saved")
  end
end

-- Save position without locking
function ataxia.data.hunterSavePosition()
  if ataxia.data.hunter and ataxia.data.hunter.window then
    ataxia.data.hunter.window:savePosition()
    ataxia.data.echo("Hunting Scrolls position saved")
  end
end