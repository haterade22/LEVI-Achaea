targetlostfrost = false --tAffs.nocaloric
timmolation = false
magi.firestorm = false
tAffs.burns = 0
tburns = 0


function MagiMain()

    local sep = ";"
    local str = ""

    str = "stand;wield staff569815 shield;"


    if tAffs.shield then
        str = str..sep.."cast erode at " ..target.. " shield"
        elseif tburns >= 2 and tAffs.conflagration
            then if targetHealth <= 25 then
            str = str..sep.."cast stormhammer at " ..target
            --str = str..sep.."elemental destroy " ..target
        else 
            if magi.resonance.fire == 0 then
            str = str..sep.."cast firelash at " ..target
        elseif magi.resonance.fire == 3 then
            str = str..sep.."cast emanation at " ..target.. " fire"
        else
            str = str..sep.."cast magma at " ..target
            end
        end
        
   elseif not tAffs.waterbond and not tAffs.blistered and timmolation == false and not tAffs.paralysis and not tAffs.anorexia and not magi.calcifying_head then
         
      if magi.resonance.fire == 2 then
        str = str..sep.."cast fulminate at " ..target
      else
        str = str..sep.."staffcast horripilation " ..target
      end
      
  elseif not tAffs.scalded then
      str = str..sep.."cast magma at " ..target

  elseif magi.calcify_resto then
     if magi.resonance.fire == 3 then
      str = str..sep.."cast emanation at " ..target.. " fire"
      else
          if targetlostfrost == true  then
            if magi.resonance.water == 0 then
              str = str..sep.."cast dehydrate at " ..target
            elseif magi.resonance.earth == 1 then
             str = str..sep.."cast magma at " ..target
           elseif magi.resonance.air < 3 then
             str = str..sep.."cast fulminate at " ..target
            end
         else
            if magi.resonance.fire == 0 then
              str = str..sep.."cast firelash at " ..target
           elseif magi.resonance.fire == 3 then
              str = str..sep.."cast emanation at " ..target.. " fire"
           else
              str = str..sep.."cast magma at " ..target
        end
     end
end

  elseif magi.firestorm == false then
    if magi.resonance.air >= 2 and magi.resonance.fire >= 2 then
       str = str..sep.."cast firestorm"
    else
       str = str..sep.."cast fulminate at " ..target
    end
    
  elseif magi.resonance.earth == 2 and not magi.shalestorm then
    str = str..sep.."cast shalestorm at " ..target
    
  elseif tburns >= 2 then
    if magi.resonance.fire >= 2 and magi.resonance.air >= 2 then
      str = str..sep.."cast conflagrate at " ..target
    else
      str = str..sep.."cast fulminate at " ..target
    end
    
  elseif magi.resonance.earth >= 3 and not magi.calcifying_head then
    if timmolation == false then
      str = str..sep.. "staffcast scintilla at " ..target
    else
      str = str..sep.."cast emanation at " ..target.. " earth"
    end
    
  elseif magi.resonance.earth < 3 then
    if not tAffs.clumsiness then
      str = str..sep.."cast bombard at " ..target
    else
      str = str..sep.."cast mudslide at " ..target
    end
    
  elseif magi.resonance.air < 3 then
    str = str..sep.."cast fulminate at " ..target
  else
    str = str..sep.."cast emanation at " ..target.. " air"
  end
    send("queue addclear freestand " ..str.. ";assess " ..target)
  end

function isFocusLocked()
    if tAffs.asthma and tAffs.slickness and tAffs.anorexia then
      return true
    else
      return false
    end
  end

function MagiLock()
    local sep = ";"
    local str = ""

    str = "stand;wield staff569815 shield;"


  if tAffs.shield then
        str = str..sep.."cast erode at " ..target.. " shield"
  end
    
  if targetHealth <= 30 then 
    str = str..sep.."cast stormhammer at " ..target
    end
        
  if not tAffs.waterbond and not tAffs.blistered and timmolation == false and not tAffs.paralysis and not tAffs.anorexia and not tAffs.asthma then
            if magi.resonance.fire == 2 then
            str = str..sep.."cast fulminate at " ..target
            else
            str = str..sep.."staff cast horripilation at " ..target
      end
      
  elseif tAffs.fronze then
      if tAffs.hypothermia or isFocusLocked() or targetHealth < 60 then
            str = str..sep.."cast glaciate at " ..target
            else
            str = str..sep.."cast hypothermia at " ..target
            end
      
  elseif isFocusLocked() then
      if not tAffs.paralysis then
               if magi.resonance.earth == 1 then
            str = str..sep.."cast mudslide at " ..target
               else
            str = str..sep.."cast fulminate at " ..target
               end
      elseif not tAffs.prone then
         str = str..sep.."vibe destabilise disorientation"
         else
         str = str..sep.."cast mudslide at " ..target
      end
  elseif magi.resonance.air == 3 then
        str = str..sep.."cast emanation at " ..target.. " air"
      elseif magi.resonance.water == 2 and tAffs.asthma and magi.resonance.water == 2 then
        str = str..sep.."cast mudslide at " ..target
      --elseif magi.resonance.earth >= 2 and not magi.shalestorm and not tarAff["kalmia"] then
      --  addToCommand("cast shalestorm at &tar")
      elseif magi.resonance.earth == 3 then
        str = str..sep.."cast emanation at " ..target.. " earth"
      elseif magi.resonance.water < 2 then
        str = str..sep.."cast dehydrate at " ..target
      elseif magi.resonance.earth == 1 and magi.resonance.air == 0 then
        str = str..sep.."cast bombard at " ..target
      elseif magi.resonance.earth < 1 then
        str = str..sep.."cast magma at " ..target
      elseif magi.resonance.air < 3 then
        if magi.resonance.earth == 1 then
          str = str..sep.."cast bombard at " ..target
        else
         str = str..sep.."cast fulminate at " ..target
        end    
  end
  send("queue addclear freestand " ..str.. ";assess " ..target) 
end  