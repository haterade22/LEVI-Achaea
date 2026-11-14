--[[mudlet
type: trigger
name: Hamstring
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes A-J
- Blademaster
- Striking
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
- pattern: ^Ducking behind \w+, you strike at (\w+)'s hamstring with a rigid, practised grip.$
  type: 1
- pattern: ^Ducking behind \w+\, \w+ strikes at (\w+)'s hamstring with a rigid, practised grip.$
  type: 1
]]--

if isTargeted(matches[2]) then
		-- The game's 10 s, and 15 s for OUR strike with the eagle feather (v4.7.501,
		-- ataxia_ourHamstringSeconds, 017). Pattern 1 is our strike, pattern 2 another
		-- Blademaster's, whose artefacts we do not know. The old timer set tAffs.hamstring = nil,
		-- which V3 overwrote on its next sync, so hamstring never expired (v4.7.405).
		local ours = matches[1]:find(", you strike at ", 1, true) ~= nil
		local secs = ours and ataxia_ourHamstringSeconds and ataxia_ourHamstringSeconds() or nil
		ataxia_tarAffTimed("hamstring", secs)

		-- Update BM dispatch timestamp for hamstring tracking
		if blademaster and blademaster.onHamstringApplied then
			blademaster.onHamstringApplied(secs)
		end

if not ataxia.afflictions.aeon and partyrelay then
  send("pt " ..target..": Hamstring")
end
end