--[[mudlet
type: trigger
name: Efreeti/Purge
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes K-S
- Magi
- Destroy-related
attributes:
  isActive: 'no'
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
- pattern: ^(\w+) bursts into flame as a fiery efreeti spins into \w+.$
  type: 1
- pattern: ^A line of golden flame leaps forth, lashing about (\w+) and searing \w+ to the bone.$
  type: 1
]]--

if isTargeted(matches[2]) then
	deleteLine()
	cecho("\n<a_brown>[<"..affs_to_colour.burns[1]..">"..affs_to_colour.burns[2].."<a_brown>] <CadetBlue>"..matches[1])
	
	if not haveAff("dehydrate") then
		tAffs.burns = 1
	else
		if not tAffs.burns or tAffs.burns <= 1 then
			tAffs.burns = 1
		end
	end
  if ataxia_isClass("Magi") then
	 cecho(" <DimGrey>[<red>"..tAffs.burns.."/5<DimGrey>]")
  end
end