function zgui.showRoomInfo()
  clearUserWindow("roomInfoDisplay")
  local areaName, roomName = mmp.cleanAreaName(gmcp.Room.Info.area), mmp.cleanroomname(gmcp.Room.Info.name)
  cecho("roomInfoDisplay", " <NavajoWhite>"..roomName:title().." - "..areaName.." <DodgerBlue>(v<NavajoWhite>"..gmcp.Room.Info.num.."<DodgerBlue>)")
  cecho("roomInfoDisplay", "\n<brown>  [<orange>"..room_exitstr.."<brown>]\n")
  --Indoors Display 
    cecho("roomInfoDisplay", (table.contains(gmcp.Room.Info.details, "indoors") and " <cadet_blue>[indoors]" or "<chat_bg>[indoors]"))  
  --Monolith Display
    cecho("roomInfoDisplay", (ataxiaTemp.monolith and " <LightSkyBlue>[mono]" or " <chat_bg>[mono]"))
  --Lightwall Display 
    cecho("roomInfoDisplay", (ataxia.lightwall and " <orange>[light]" or " <chat_bg>[light]"))
end