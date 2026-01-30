--[[mudlet
type: trigger
name: MAGGOTS
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes K-S
- INFERNAL
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
- pattern: ^You sense through your malignant connection to your infestation that (\w+) has been cursed with (\w+).$
  type: 1
]]--

if isTargeted(matches[2]) then
	tarAffed(matches[3])
  tarAffedConfirmed(matches[3])
   confirmAffV2(matches[3])
 if partyrelay then send("pt "..target..": "..matches[3])
      end
end
