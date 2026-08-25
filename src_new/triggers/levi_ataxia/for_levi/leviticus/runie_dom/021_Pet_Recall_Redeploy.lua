--[[mudlet
type: trigger
name: Pet Recall Redeploy
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
    A RECALLED PET IS AN ITEM ON US -- PUT IT BACK OUT (user-directed, 2026-08-20).

    "You put your fingers to your lips and utter a shrill whistle." is the reply to
    FALCON RECALL and to HYENA RECALL alike, and the animal comes back TO HAND. It is not
    deployed again until it is DROPPED and ordered to follow:

        runewarden:  drop falcon ; order falcon follow me
        infernal:    drop hyena  ; order hyena follow me

    Nothing in the package ever did that. `falcon recall` is sent from levilogin
    (001_Login_Function:200) and the `pass` alias; `hyena recall` from the login (208, 224),
    the disengage path (genrunning/003:240) and 127_HYENA_FOLLOW. Every one of those either
    stopped at the recall or went straight to `order <pet> follow me` -- an order aimed at an
    animal still sitting in our inventory. So the pet stayed on us, and for a Runewarden the
    basher's FREE falcon rake had no bird to command.

    v4.7.283 shipped this for the falcon alone and asserted the hyena needed no drop, on the
    reasoning that the existing `hyena recall;order hyena follow me` pairings would surely
    have included one if it did. That was inference from the absence of code, and it was
    wrong -- corrected here on the user's word. It is precisely the trap v4.7.281 wrote down:
    THOSE SITES WERE COPIED FROM A SIBLING THAT WAS EQUALLY INCOMPLETE.

    CLASS-KEYED, and the two are listed explicitly rather than via ataxia_isClass("knight"),
    which is true for all three knights. PALADIN IS DELIBERATELY ABSENT: the eagle's item
    keyword has never been captured, and guessing an in-game command is how you ship a
    rejected one on every recall.

    SENT DIRECTLY, NOT QUEUED. Both are free actions (no balance, no equilibrium -- the same
    reasoning as ORDER FALCON PASSIVE in trigger 376), and anything queued here would be
    wiped by the basher's next `queue addclearfull`, which rebuilds the whole server queue
    every prompt. Two sends rather than one `;`-joined string so the order is guaranteed
    without depending on the configured separator.

    10s DEBOUNCE, the idiom trigger 376 already uses: `pass` sends the recall inside a chain
    and the login sends one at connect, so a redeploy racing either should happen once.
]]--

local pet
if ataxia_isClass and ataxia_isClass("runewarden") then
	pet = "falcon"
elseif ataxia_isClass and ataxia_isClass("infernal") then
	pet = "hyena"
end
if not pet then return end

ataxiaTemp = ataxiaTemp or {}
local nowT = (getEpoch and getEpoch()) or os.time()
if (nowT - (tonumber(ataxiaTemp.petRedeployAt) or 0)) <= 10 then return end
ataxiaTemp.petRedeployAt = nowT

send("drop " .. pet)
send("order " .. pet .. " follow me")

if ataxiaEcho then
	ataxiaEcho("<gold>" .. pet .. " recalled<reset> -- dropped and ordered to follow.")
end
