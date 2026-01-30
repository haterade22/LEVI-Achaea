--[[mudlet
type: script
name: 'EDIT ME: Restyle GUI Colors'
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- ZulahGUI - Saonji Edit
- zGUI Redux
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

function zgui.restyle()
  zgui.styles = {  
     -- https://doc.qt.io/qt-5/stylesheet-reference.html (more info)                      
                                     --rgba(RED, GREEN, BLUE, Transparency)
    ["greygroove"] = "background-color:rgba(0,0,0,0%); border: 5px groove grey;",
    ["greengroove"] = "background-color:rgba(0,0,0,100%); border: 5px groove green;",
    
    ["dimgreyinset"] = "background-color:rgba(20,20,20,100%); border: 5px inset dimgray;",
    ["greyinset"] = "background-color:rgba(0,0,0,100%); border: 10px inset grey;",
    ["greeninset"] = "background-color:rgba(0,0,0,100%); border: 5px inset green;",
    ["chaosinset"] = "background-color:rgba(0,40,100,100%); border: 5px inset purple;",
    ["chaosincet"] = "background-color:rgba(0,40,100,100%); border: 5px inset yellow;",
    
    ["greydouble"] = "background-color:rgba(0,0,0,0%); border: 5px double grey;",
    ["greendouble"] = "background-color:rgba(0,0,0,50%); border: 5px double green;",    
    ["golddouble"] = "background-color:rgba(0,0,0,50%); border: 5px double gold;",
    
    ["darkmode"] = "background-color:rgba(5,5,5,100%); border: 2px groove rgba(10,10,10,100%);",
}

--------------------------------------------------------------------
-- Which Style To Start With?  
  if not zgui.useStyle then 
  
  zgui.useStyle = "darkmode" end
  
----------------------------------------------------------------------------------------------------------------------------------------
  setBorderColor("0","0","0")  -- Change this if you attach windows to side borders and want to color the background of those borders
                               -- setBorderColor("218","218","218") -- Mudlet Default Menu Grey
                               -- setBorderColor("RED","GREEN","BLUE")
                               
                               
----------------------------------------------------------------------------------------------------------------------------------------                               
  for k,v in pairs(zgui.styles) do
    if zgui.useStyle == k then
      zgui.adjLabelstyle = v
    end
  end   
  
  for i=1, #zgui.modules, 1 do
    zgui[zgui.modules[i]]()
  end  
----------------------------------------------------------------------------------------------------------------------------------------
end