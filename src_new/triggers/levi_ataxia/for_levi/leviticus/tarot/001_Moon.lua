--[[mudlet
type: trigger
name: Moon
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes K-S
- Occultist
- Tarot
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
- pattern: ^As you fling the Moon tarot at (\w+), it turns an ominous, sickly red, before striking \w+ in the head.$
  type: 1
]]--

local moons = {"stupidity", "masochism", "hallucinations", "hypersomnia", "confusion", "epilepsy","claustrophobia", "agoraphobia"}
if not moonAff then
	for i=1, #moons do
		if not haveAff(moons[i]) then
			tarAffed(moons[i])
			if applyAffV3 then applyAffV3(moons[i]) end
			break
		end
	end
else
	tarAffed(moonAff)
	if applyAffV3 then applyAffV3(moonAff) end
	moonAff = false
end

	if readAuraAffs and readAuraAffs.count then
		readAuraAffs.count = readAuraAffs.count + 1
	end	