--[[mudlet
type: trigger
name: Sword And Shield Lost
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Basher
- Bashing
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
- pattern: ^You must be wielding both a sword and a shield to execute such an assault\.$
  type: 1
]]--

--[[
    DISARMED MID-BASH (live 2026-07-30). The Sword-and-Board COMBINATION needs both hands
    filled; once something knocks a weapon loose, EVERY subsequent round is rejected with
    this line and the basher just keeps re-queuing an attack that cannot execute -- the
    same shape as the broken-arms refusal, but this one we can fix outright rather than
    wait out.

    Re-wield both hands and re-assert GRIP, which is the defence that resists the disarm
    in the first place (losing it is why we got disarmed at all). WIELD costs no balance,
    so this can go out on any round.

    Sent DIRECTLY, not queued: the basher rebuilds its command every prompt with
    `queue addclearfull`, which would wipe a queued recovery before it ever ran. Same
    reasoning as the hyena/falcon passive orders (triggers 372/376).

    The sword uses the configured weapon id when there is one (`ataxia setup weapons`,
    slot `longsword`); ataxia.getWeapon falls back to the literal "longsword", and plain
    "shield" is the idiom already used at login (login/001:138).

    5s debounce so a burst of rejected rounds cannot stack a pile of wields.
]]--

if not (ataxiaTemp.rewieldAt and (getEpoch() - ataxiaTemp.rewieldAt) < 5) then
	ataxiaTemp.rewieldAt = getEpoch()
	local sword = (ataxia and ataxia.getWeapon and ataxia.getWeapon("longsword")) or "longsword"
	local sp = (ataxia and ataxia.settings and ataxia.settings.separator) or ";"
	send("wield " .. sword .. sp .. "wield shield" .. sp .. "grip", false)
	if ataxiaEcho then
		ataxiaEcho("<red>Disarmed<reset> -- re-wielding " .. sword .. " + shield and re-gripping.")
	end
end
