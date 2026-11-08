--[[mudlet
type: trigger
name: Doublestab
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes K-S
- Serpent
attributes:
  isActive: 'yes'
  isFolder: 'no'
  isTempTrigger: 'no'
  isMultiline: 'yes'
  isPerlSlashGOption: 'no'
  isColorizerTrigger: 'no'
  isFilterTrigger: 'no'
  isSoundTrigger: 'no'
  isColorTrigger: 'no'
  isColorTriggerFg: 'no'
  isColorTriggerBg: 'no'
triggerType: 0
conditonLineDelta: 1
mStayOpen: 0
mCommand: ''
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: ^You quickly prick (\w+) with your dirk.$
  type: 1
- pattern: '1'
  type: 5
- pattern: ^.*$
  type: 1
]]--

--deleteLine()
--deleteLine()
--cecho("\n<red>[<white>Levi<red>]: DOUBLESTABBED "..string.upper(multimatches[1][2]).." <white>[<orange>"..string.title(svenom1).." <white>+ <orange>"..string.title(svenom2).."<white>]")

local person = multimatches[1][2]
if isTargeted(person) then
	if multimatches[3][1] == "The attack rebounds back onto you!" then
  tarAffed("rebounding")
  table.remove(envenomList, 1)
	 table.remove(envenomListTwo, 1)
	elseif  multimatches[3][1] == "A reflection of " .. person .. " blinks out of existence." then
	 -- A reflection took prick 1, but prick 2 still strikes and lands the venom prick 1 would have
	 -- carried. On the victim's seat Archaeon's prick 1 carries his paralysis
	 -- (kb/raw/logs/2026-11-01_nikita_depthswalker-vs-serpent_win_X8pRorzR.txt:49-50, :101-102,
	 -- :141-142), and when "One of your reflections has been destroyed!" took prick 1, his prick 2
	 -- gave the paralysis (:868-871).
	 -- Prick 1's venom is the second one named: the dirk takes them in order ("You secrete curare"
	 -- before "You secrete xentio") and curare's paralysis line follows prick 2
	 -- (kb/raw/logs/ours/2026-11-07_164635_Saibel.log:449-458), as 011 credits it after a miss.
	 -- This branch recorded nothing, so the next round sent that venom again (2026-11-08 review,
	 -- F36). It is recorded only on prick 2's own line ("Striking like a snake, you prick X a second
	 -- time with your dirk.", Saibel.log:363) and then on the line after it: a rebound or a second
	 -- reflection there means prick 2 delivered nothing (X8pRorzR:713-716).
	 local aff2 = envenomListTwo[1] and venom_to_aff(envenomListTwo[1]) or nil
	 table.remove(envenomList, 1)
   table.remove(envenomListTwo, 1)
   if aff2 and tempLineTrigger then
     local blink = "A reflection of " .. person .. " blinks out of existence."
     local second = "Striking like a snake, you prick " .. person .. " a second time with your dirk."
     tempLineTrigger(1, 1, function()
       if line ~= second then return end
       tempLineTrigger(1, 1, function()
         if line == "The attack rebounds back onto you!" then
           tarAffed("rebounding")
         elseif line ~= blink then
           tarAffed(aff2)
         end
       end)
     end)
   end
	else
    if not affs_to_colour then populate_aff_colours() end
    aff1 = envenomList[1] and venom_to_aff(envenomList[1]) or nil
    aff2 = envenomListTwo[1] and venom_to_aff(envenomListTwo[1]) or nil
    if aff1 then tarAffed(aff1) end
    if aff2 then tarAffed(aff2) end
    --table.remove(envenomList,1)
    --table.remove(envenomListTwo,1)
    if snapscenarioone == true and snapscenariotwo == false then
      if tAffs.hypnoseal == true and tAffs.asthma and tAffs.snapped == false and not tAffs.rebounding then
        tempTimer(0.6,[[send("snap " ..target)]])
      end
    elseif snapscenariotwo == true then
      if tAffs.hypnoseal == true and tAffs.asthma and tAffs.snapped == false and tAffs.clumsiness or tAffs.weariness and tAffs.darkshade and not tAffs.rebounding and tBals.plant == false  then
        tempTimer(0.6,[[send("snap " ..target)]])
      end
    end
    if partyrelay and not ataxia.afflictions.aeon then
      local ptMsg = target..":"
      if aff1 then ptMsg = ptMsg .. " " .. aff1 end
      if aff2 then ptMsg = ptMsg .. " " .. aff2 end
      send("pt " .. ptMsg)
    end
	end
end
