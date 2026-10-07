--[[mudlet
type: trigger
name: Can Jinx
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Class Stuff
- Jinx
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
- pattern: Your malign power may be unleashed in the form of a jinx against your victim
  type: 2
]]--

-- START OF LINE, NOT EXACT (v4.7.387). The pattern was an exact match ending in a full stop; the
-- user's paste of the live line has none ("...a jinx against your victim"), and an exact match
-- that disagrees by one character never fires -- which leaves the charge unspent until
-- "Your malign power dissipates back to normal levels." Start-of-line matches it either way.
--
-- THE LINE PROVES THRICE CURSED (v4.7.387). "Your swiftcurses now build jinx charges": without the
-- boon only a regular CURSE charges a jinx, and the swiftcurse bashtype never sends one. So in the
-- tower, as a Shaman on that bashtype, this line is the boon working -- it re-latches
-- `mnemThriceCursed` the way every self-proving boon line does (in the tower only, v4.7.351). That
-- matters because a reimport forgets the flag and `_relatchBoons` asks only once per run: the user
-- watched a charge build and dissipate with the boon held. A manual `curse` typed in the tower
-- latches it falsely, which costs nothing -- the charge it built is then spent by a jinx instead of
-- wasting away.

ataxiaTemp.jinxCharge = ataxiaTemp.jinxCharge or 0
ataxiaTemp.jinxCharge = ataxiaTemp.jinxCharge + 1
ataxiaTemp.canJinx = true

if ataxiaBasher and ataxiaBasher.inMnemosyne and ataxia_isClass and ataxia_isClass("Shaman") then
	local bt = shaman and shaman.spiritlore and shaman.spiritlore.bashType or "swiftcurse"
	if bt == "swiftcurse" then mnemThriceCursed = true end
end

if ataxiaBasher.enabled and not ataxiaBasher.manual then
	deleteFull()
end

