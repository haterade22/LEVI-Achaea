--[[mudlet
type: script
name: convertAdj.Init
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- ZulahGUI - Saonji Edit
- zGUI Redux
- Extra Code
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
eventHandlers:
- sysLoadEvent
- sysInstall
]]--

-- convert Adjustable.Containers to UserWindows and back
-- v0.1
-- Note: saving if UserWindow won't bring back as UserWindow if reloading
-- by Edru 7th October 2020

convertAdj = convertAdj or {}
function Adjustable.Container:onDoubleClick()
  self.isUserWindow = self.isUserWindow or false
  if not self.isUserWindow then
    self.userwindow = self.userwindow or Geyser.UserWindow:new({name = self.name.."userWindow"})
    self.userwindow:show()
    self.userwindow:setTitle(self.name)
    self.userwindow:move(self:get_x(), self:get_y())
    self.userwindow:resize(self:get_width(), self:get_height())
    self:changeContainer(self.userwindow)
    self:move(0,0)
    self:resize("100%", "100%")
    self:lockContainer("standard")
  else
    registerAnonymousEventHandler("sysWindowMousePressEvent", "convertAdj.sendToPosition", true)
    convertAdj.container = self
    self.userwindow:hide_impl()
  end
  self.isUserWindow = self.isUserWindow == false and true or false 
end

function convertAdj.Init()
  Adjustable.Container:doAll(function(self) self.adjLabel:setDoubleClickCallback(function(event) self:onDoubleClick() end)end)
  local newWrapper = Adjustable.Container.new
  local saveWrapper = Adjustable.Container.save
  
  function Adjustable.Container:new(cons, container)
    local me = newWrapper(self, cons, container)
    me.adjLabel:setDoubleClickCallback(function(event) me:onDoubleClick() end)
    return me
  end
  
  function Adjustable.Container:save(slot, dir)
    if self.isUserWindow then
      local tempWindowName = self.windowname
      self.windowname = "main"
      self:setAbsolute(true, true)
      self:unlockContainer()
      saveWrapper(self, slot, dir)
      self:lockContainer()
      self.windowname = tempWindowName
      self:setPercent(true, true)
    else
      saveWrapper(self, slot, dir)
    end
    return true
  end
  
end

function convertAdj.sendToPosition(event, button, x, y, windowname)
    local self = convertAdj.container
    local newContainer = Geyser
    if windowname ~= "main" then
        newContainer = Geyser.windowList[windowname.."Container"].windowList[windowname]
    end
    self:resize(self:get_width(), self:get_height())
    self:move(x, y)
    self:changeContainer(Geyser)
    self:setPercent(true, true)
    self:unlockContainer()
    self:show()
    convertAdj.container = nil
end