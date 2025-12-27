--[[mudlet
type: trigger
name: Berceuse sent them to sleep!
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Bard
- Bard
- Harmonics
- Berceuse
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
- pattern: ^(\w+)\'s eyes close suddenly as (s|)he falls asleep\.$
  type: 1
- pattern: ^(\w+) drifts away into the soft music of the Berceuse\, abandoning (\w+)self to its soporific tones\.$
  type: 1
]]--

if multimatches[1][2]:lower() == target:lower() then



	  tarAffed("prone")
		tarAffed("sleep")

	end


