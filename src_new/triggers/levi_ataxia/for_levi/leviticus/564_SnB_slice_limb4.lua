--[[mudlet
type: trigger
name: SnB slice limb4
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Affs Post Queue - Gated
- Classes K-S
- Knight
- SnB
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
- pattern: ^You slice into the (.+) of (\w+) with (.+).$
  type: 1
- pattern: '1'
  type: 5
- pattern: ^(\w+) attempts to defend against your attack but you bat (\w+) weak attempt aside.$
  type: 1
]]--

local person = multimatches[1][3]
local maybemiss = multimatches[3][1]

if isTargeted(person) then
if not wearicheck and haveAff("weariness") then
erAff("weariness")
end
  targetIshere = true
  tAffs.shield = false

	ataxiaTemp.ignoreShield = false
if gmcp.Char.Status.class == "Runewarden" then
    if next(envenomList) then
			moveCursor(0, getLineNumber()-1)
			tarAffed(envenomList[1])
     local affstruck = envenomList[1]
			table.remove(envenomList, 1)
			moveCursorEnd()
       if partyrelay then send("pt "..target..": "..affstruck)
      end
    end
  end
	if gmcp.Char.Status.class == "Infernal" then
    if invest ~= "agony" then
    envenomList = {}
    else
		if next(envenomList) then
			moveCursor(0, getLineNumber()-1)
			tarAffed(envenomList[1])
     local affstruck = envenomList[1]
			table.remove(envenomList, 1)
			moveCursorEnd()
       if partyrelay then send("pt "..target..": "..affstruck)
         end
		    end
	   end
    end
  lastLimbAttack = "snbSlice"
  end

if swordneed[1] == "combination "..target.." slice "..targetlimb.." gecko "..shieldneed[1]..";shieldstrike "..target.." low" or "combination "..target.." slice gecko "..shieldneed[1]..";shieldstrike "..target.." low"
then
paraslick = true
else paraslick = false
end
