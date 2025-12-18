-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Levi  Scripts > ZulahGUI - Saonji Edit > zGUI Redux > Build Windows > buildEnemy

function zgui.buildEnemy()
  zgui.enemySize = zgui.enemySize or 9
  zgui.enemy = {}

  --Create the enemy Adjustable
  zgui.enemy.window = Adjustable.Container:new({
    name = "zgui.enemy.window",
    x = 0, y = 0,
    width = "50%",
    height = "50%",  
    adjLabelstyle = zgui.adjLabelstyle,
    buttonstyle=[[
      QLabel{ border-radius: 5px; background-color: rgba(140,140,140,100%);}
      QLabel::hover{ background-color: rgba(160,160,160,50%);}
    ]],
    buttonFontSize = 10,
    buttonsize = 15,          
  },main)
  zgui.enemy.window:changeMenuStyle("dark")

  --Create the enemy container
  zgui.enemy.container = Geyser.Container:new({
    name = "zgui.enemy.back",
    x = 0, y = 0,
    width = "100%",
    height = "100%",        
  },zgui.enemy.window)  

  --Create the enemy Console
  zgui.enemy.console = Geyser.MiniConsole:new({
    name = "enemyDisplay",
    x = 0, y = 0,
    autoWrap = true,
    width = "100%",
    height = "100%",
    color="black",
  },zgui.enemy.container) 

  setFontSize("enemyDisplay", zgui.enemySize)
  --zgui.enemy.window:setTitle("Enemies","gray")
  zgui.enemy.window:show()
  
  if not table.contains(zgui.modules, "buildEnemy") then
    table.insert(zgui.modules, "buildEnemy")
  end  
end