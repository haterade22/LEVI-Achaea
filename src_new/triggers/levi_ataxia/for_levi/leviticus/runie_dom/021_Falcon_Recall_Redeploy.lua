--[[mudlet
type: trigger
name: Falcon Recall Redeploy
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Runie
- RUNIE DOM
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
- pattern: ^You put your fingers to your lips and utter a shrill whistle\.$
  type: 1
]]--

--[[
    FALCON RECALL LEAVES THE BIRD ON US -- PUT IT BACK OUT (user-directed, 2026-08-20).

    "You put your fingers to your lips and utter a shrill whistle." is the reply to
    FALCON RECALL, and the falcon comes back to hand. Nothing in the package ever put it
    out again: `falcon recall` is sent from levilogin (001_Login_Function:200) and from the
    `pass` alias, and that was the end of it -- so after either one the falcon sat on us,
    raking nothing, and the Runewarden basher's free falcon rake had no bird to command.

    THE HYENA HAS DONE THIS CORRECTLY ALL ALONG and the falcon simply never got the same
    treatment -- `hyena recall;order hyena follow me` appears in the login (208, 224), in
    the disengage path (genrunning/003:240) and in its own alias (127_HYENA_FOLLOW). The
    falcon's half of that pairing was missing.

    The falcon needs one extra step the hyena does not: a recalled falcon is an ITEM on us,
    so it has to be DROPPED before it can be ordered. Hence drop -> follow, in that order.

    SENT DIRECTLY, NOT QUEUED. Both are free actions (no balance, no equilibrium -- the same
    reasoning as ORDER FALCON PASSIVE in trigger 376), and anything queued here would be
    wiped by the basher's next `queue addclearfull`, which rebuilds the whole server queue
    every prompt. Two sends rather than one `;`-joined string so the order is guaranteed
    without depending on the configured separator.

    RUNEWARDEN-GATED: "You put your fingers to your lips..." is a generic whistle line and
    other classes whistle for other things. Ordering a falcon we do not own would be a
    rejected command on every one of them.

    10s DEBOUNCE, the idiom trigger 376 already uses for the flipped falcon: `pass` sends
    the recall as part of a chain, and a redeploy racing that chain should happen once.
]]--

if not (ataxia_isClass and ataxia_isClass("runewarden")) then return end

ataxiaTemp = ataxiaTemp or {}
local nowT = (getEpoch and getEpoch()) or os.time()
local last = tonumber(ataxiaTemp.falconRedeployAt) or 0
if (nowT - last) <= 10 then return end
ataxiaTemp.falconRedeployAt = nowT

send("drop falcon")
send("order falcon follow me")

if ataxiaEcho then
	ataxiaEcho("<gold>falcon recalled<reset> -- dropped and ordered to follow.")
end
