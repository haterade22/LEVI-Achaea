--[[mudlet
type: trigger
name: TERT CHARGE
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Runie
- RUNIE DOM
attributes:
  isActive: 'yes'
  isFolder: 'no'
  isTempTrigger: 'no'
  isMultiline: 'no'
  isPerlSlashGOption: 'no'
  isColorizerTrigger: 'no'
  isFilterTrigger: 'no'
  isSoundTrigger: 'no'
  isColorTrigger: 'no'
  isColorTriggerFg: 'no'
  isColorTriggerBg: 'no'
triggerType: 0
conditonLineDelta: 0
mStayOpen: 0
mCommand: ''
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: ^The (\w+) rune upon .+ flashes as you strike (\w+).$
  type: 1
- pattern: ^The (\w+) rune flashes upon (\w+) as you channel energy into it.$
  type: 1
]]--

--send("empower priority set kena isaz sleizak")
--send("empower priority set isaz sowulu tiwaz")

if not ataxiaTemp.ignoreShield then
	moveCursor(0, getLineNumber())
if matches[2] == "inguz" then tarAffed("paralysis"); if applyAffV3 then applyAffV3("paralysis") end
elseif matches[2] == "sleizak" then
tarAffed("weariness")
if applyAffV3 then applyAffV3("weariness") end
send("pt " ..target.. ": nausea")
if not wearicheck then wearicheck = true
wearicheck = tempTimer(4, [[ wearicheck = nil ]])

end
elseif matches[2] == "loshre" then tarAffed("addiction"); if applyAffV3 then applyAffV3("addiction") end
end
	moveCursorEnd()

end
ataxiaTemp.ignoreShield = nil