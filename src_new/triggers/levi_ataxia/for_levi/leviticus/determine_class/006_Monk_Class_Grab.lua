--[[mudlet
type: trigger
name: Monk Class Grab
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Curing Stuff
- Priority Management
- Determine Class
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
- pattern: ^(\w+) whips .+ in a tight arc, sweeping it at your head\.$
  type: 1
- pattern: ^(\w+) spins a full rotation, bringing .+ around in a blur to crash into your
  type: 1
- pattern: ^(\w+) whips .+ in a controlled arc, bringing the length of the weapon to crash into your
  type: 1
- pattern: ^(\w+) whips .+ at the side of your neck\.$
  type: 1
- pattern: ^(\w+) lashes out with a high kick at your
  type: 1
- pattern: ^(\w+) lashes out with a straight kick at you\.$
  type: 1
- pattern: ^(\w+) flows around you like water
  type: 1
- pattern: ^(\w+) reaches out with \w+ mind, tightening its grip around you
  type: 1
- pattern: ^(\w+) delivers a powerful uppercut to your
  type: 1
- pattern: ^Dropping into a lower stance, (\w+) sweeps .+ at your \w+ thigh\.$
  type: 1
- pattern: ^Dropping back into a low crouch, (\w+) whips .+ at your \w+ thigh\.$
  type: 1
- pattern: ^Snapping back into a ready stance, (\w+) whips .+ in a wide arc at your head\.$
  type: 1
- pattern: ^With pinpoint precision, (\w+) thrusts .+ at your throat\.$
  type: 1
- pattern: ^Snapping \w+ leg out to its full extent, (\w+) drives a heel into your
  type: 1
- pattern: ^Snapping \w+ arms out in front of \w+, (\w+) delivers a lightning-fast thrust
  type: 1
- pattern: ^Spinning on one foot (\w+) drives .+ with a lightning-fast thrust\.$
  type: 1
- pattern: ^Continuing \w+ kata, (\w+) spins .+ in \w+ hands before driving it in a swift thrust
  type: 1
- pattern: ^Continuing \w+ kata, (\w+) drives .+ into your
  type: 1
]]--

-- Shikudo uses staves; Tekura uses bare fists/kicks.
-- Staff attacks contain weapon references in the line text.
-- Once identified as Shikudo, never downgrade to Monk (kicks are shared).
local attacker = matches[2]
if line:find("whips") or line:find("staff") or line:find("thrust")
   or line:find("kata") or line:find("sweeps") then
  classDetect.setAttackerClass(attacker, "Shikudo")
elseif classDetect.state.attackerName
   and classDetect.state.attackerName:lower() == attacker:lower()
   and classDetect.state.attackerClass == "Shikudo" then
  -- Already identified as Shikudo — kick is just part of their toolkit
  classDetect.resetCombatTimeout()
else
  classDetect.setAttackerClass(attacker, "Monk")
end
