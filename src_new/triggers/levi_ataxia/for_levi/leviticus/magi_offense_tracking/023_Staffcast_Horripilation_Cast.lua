--[[mudlet
type: trigger
name: Staffcast Horripilation Cast
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Mage
- Magi Offense Tracking
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
mFgColor: ''
mBgColor: ''
mSoundFile: ''
colorTriggerFgColor: ''
colorTriggerBgColor: ''
patterns:
- pattern: ^You point .+ at .+ and \w+ screams in pain
  type: 1
]]--

-- OUR STAFFCAST HORRIPILATION WENT OUT. Seen only in the third person, from another Magi (Tabethys,
-- kb/raw/logs/ours/2026-10-28_073547_Tabethys.log:761):
--   Tabethys points an exquisite Mhaldorian staff of sterling silver at a carnivorous lycopod, and he
--   screams in pain as his skin begins to freeze and crack.
-- Our own line is UNCONFIRMED: this pattern is that line in the first person ("You point ... at ...,
-- and he screams in pain"), cut before "as his skin" so it stays on the first wrapped row with a long
-- staff and a long denizen name. The comma is optional (013_Staffcast_Freeze reads it without one).
-- The Magi kite (mnemosyne/018) steps out of the fight room on this line; its lapse watch
-- (K.MISS_MAX) stops the kite if the real line differs. Paste the real line when you see it.
if ataxia and ataxia.mnemosyne and ataxia.mnemosyne.magiKite and ataxia.mnemosyne.magiKite.onCast then
  pcall(ataxia.mnemosyne.magiKite.onCast, "staffcast")
end
