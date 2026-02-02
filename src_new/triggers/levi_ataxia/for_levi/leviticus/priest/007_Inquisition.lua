--[[mudlet
type: trigger
name: Inquisition
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes K-S
- Priest
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
- pattern: ^You draw (\w+) into your gaze, lowering your brow and glaring at \w+ with righteous fury. Pointing at \w+ with
    a single raised finger, you recite a list of (\w+)'s transgressions, condemning \w+ actions and words. A blaze of holy
    fire surges around you as you dictate \w+ sentence.$
  type: 1
- pattern: ^Pointing at \w+ with a single raised finger, \w+ recites a list of (\w+)'s transgressions, condemning \w+ actions
    and words. A blaze of holy fire surges about \w+ as \w+ dictates (\w+)'s sentence.$
  type: 1
]]--

if isTargeted(matches[2]) then
	if haveAff("spiritburn") and haveAff("guilt") then
		tarAffed("inquisition")
		if applyAffV3 then applyAffV3("inquisition") end
		ataxia_boxEcho(target:upper().." HAS BEEN INQUISITIONED!", "LightSkyBlue")
		if inquisTimer then killTimer(inquisTimer); inquisTimer = nil end
		inquisTimer = tempTimer(20, [[ erAff("inquisition"); inquisTimer = nil ; if removeAffV3 then removeAffV3("inquisition") end]])
	end
end

