--[[mudlet
type: trigger
name: Masochism
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Third Person
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
- pattern: ^The face of (\w+) contorts in horrified revulsion.$
  type: 1
- pattern: ^(\w+) smiles as \w+ rams \w+ fist into \w+ jaw\.$
  type: 1
- pattern: ^(\w+) drives a clenched fist into \w+ gut\.$
  type: 1
- pattern: ^(\w+) uses \w+ right foot to stomp on \w+ left as hard as possible\.$
  type: 1
]]--

-- Masochism makes the target hurt itself. Each pattern above is one of those lines. Until the
-- 2026-11-07 spar only the revulsion and jaw lines were read, and the jaw line only with "her".
-- In that spar, 3 of the 5 masochism lines recorded nothing: "Saibel drives a clenched fist into
-- her gut." (twice) and "Saibel uses her right foot to stomp on her left as hard as possible."
-- Each came 0.02-0.42 s after one of our masochism impulses. The male form is "Archaeon uses his
-- right foot to stomp on his left ..." (kb/raw/logs/2026-11-01_nikita_depthswalker-vs-serpent_win_X8pRorzR.txt:6502).
if isTargeted(matches[2]) then
	tarAffed("masochism")
  confirmAffV2("masochism")
end

if gmcp.Char.Status.class == "Apostate" then
  if bloodworm() == true then
    killTimer(tostring(wormTimer))
    wormTimer = tempTimer(7.5, [[wormtick()]])
   
  end
end




function wormtick()
  if bloodworm() == true then
    if tAffs.masochism and not tAffs.deafness then
      tarAffed("dizziness")
      confirmAffV2("dizziness")
    else
      killTimer(tostring(wormTimer))
	    wormTimer = tempTimer(7.5, [[wormtick()]])
    end
  end
end