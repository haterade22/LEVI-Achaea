--[[mudlet
type: trigger
name: Ruku Clumsiness Healthleech
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- MONK 1
- Monk
- Shikudo Triggers
- Shikudo
- Calls
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
- pattern: ^The staff connects to the (left|right) arm with a resounding crack, the limb flopping uselessly\.$
  type: 1
]]--

selectCurrentLine() fg("a_yellow") bg("black") 
replace("" ..target.. " [RUKU: Clumsiness | Healthleech]")

if tAffs.clumsiness then
send("pt " ..target..": clumsiness healthleech")
			tarAffed("healthleech")
			if applyAffV3 then applyAffV3("healthleech") end
			tarAffed("clumsiness")
			if applyAffV3 then applyAffV3("clumsiness") end
elseif not tAffs.clumsiness then
  			send("pt " ..target..": clumsiness")
			tarAffed("clumsiness")
			if applyAffV3 then applyAffV3("clumsiness") end
end		
