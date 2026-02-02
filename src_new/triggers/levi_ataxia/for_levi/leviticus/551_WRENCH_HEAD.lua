--[[mudlet
type: trigger
name: WRENCH HEAD
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Affs Post Queue - Gated
- Classes K-S
- Monk
- Tekura Limbs
- Kicks
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
- pattern: ^Grabbing hold of the head of (\w+), you savagely wrench it down and forward, driving your knee up to meet it with
    a sickening crack.$
  type: 1
]]--

if isTargeted(matches[2]) and not ataxiaTemp.ignoreShield then
	moveCursor(0, getLineNumber())
	tarAffed("epilepsy")
	if applyAffV3 then applyAffV3("epilepsy") end
  
  epiparty = true
   tempTimer(30, [[epiparty = false]])
   
   if epiparty then
   tempTimer(3, [[tarAffed("epilepsy"); if applyAffV3 then applyAffV3("epilepsy") end]])
   end

	moveCursorEnd()
   if partyrelay then send("pt "..target..": epilepsy")
      end
end
ataxiaTemp.ignoreShield = nil