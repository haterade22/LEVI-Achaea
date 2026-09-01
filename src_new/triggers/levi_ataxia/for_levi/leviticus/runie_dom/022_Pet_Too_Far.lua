--[[mudlet
type: trigger
name: Pet Too Far To Command
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
- pattern: ^Your (\w+) is too far away for you to command like that\.$
  type: 1
]]--

--[[
    THE PET HAS STRAYED -- RECALL IT (user-directed, 2026-09-01).

        "Your falcon is too far away for you to command like that."

    The bird wanders off, and from then on every command aimed at it is refused. For a
    Runewarden that silently kills the basher's FREE falcon rake for the rest of the fight:
    the rake costs no balance, so nothing else notices it is gone, and there is no fire line
    to be missing -- there is simply a refusal nobody was reading.

    THIS ONLY SENDS THE RECALL. `<pet> recall` produces "You put your fingers to your lips and
    utter a shrill whistle.", which trigger 021 already answers with `drop <pet>` +
    `order <pet> follow me` -- the redeploy a recalled pet needs because it comes back TO HAND
    (v4.7.284). Duplicating the drop here would fight that trigger's own debounce and send the
    pair twice. One new fact, one new trigger; the existing chain does the rest.

    THE PET IS TAKEN FROM THE LINE, NOT FROM OUR CLASS -- the game names the animal, so there
    is nothing to infer. But acting on it is gated on RECALL SYNTAX WE HAVE ACTUALLY SEEN:
    `falcon recall` is sent from `login/001_Login_Function:200` and the `pass` alias, and
    `hyena recall` from the login (208, 224), `genrunning/003:240` and `127_HYENA_FOLLOW`.
    Both are proven. A Paladin's eagle is deliberately NOT handled -- its keyword has never
    been captured, and "the line named it" is not evidence that `eagle recall` parses. That is
    the same line trigger 021 draws, for the same reason: never guess an in-game command.

    An unknown animal WARNS ONCE rather than staying silent, because "this pet has no recall
    wired" and "this line never fires" are indistinguishable otherwise -- the Arc proof-of-life
    reasoning (v4.7.245). Once per session, since a refusal repeats every round it is provoked.

    SENT DIRECTLY, NOT QUEUED: a recall is free (no balance, no equilibrium), and anything
    queued here would be wiped by the basher's next `queue addclearfull`.

    10s DEBOUNCE on its own key. The refusal fires once per attempted command, and the basher
    attempts the rake EVERY ROUND -- so without this we would send a recall per round, and the
    recall/drop/order chain would never get the two or three seconds it needs to finish.

    NOTHING TO ROLL BACK. `ataxiaBasher.falconRakeReady` is cleared by the FIRE line (trigger
    370), never on send, so a refused rake has not burned its cooldown and the next round
    retries on its own. Checked rather than assumed -- the battlerage rejection path (trigger
    329) exists precisely because that is not always true.
]]--

local pet = matches and matches[2] and matches[2]:lower() or nil
if not pet then return end

-- Recall syntax proven in-tree. Anything else is a command we would be inventing.
local RECALLABLE = { falcon = true, hyena = true }

ataxiaTemp = ataxiaTemp or {}
local nowT = (getEpoch and getEpoch()) or os.time()

if not RECALLABLE[pet] then
	if not ataxiaTemp.petFarUnknownWarned then
		ataxiaTemp.petFarUnknownWarned = true
		if ataxiaEcho then
			ataxiaEcho("<gold>" .. pet .. "<reset> is too far to command, and no recall command is "
				.. "confirmed for it -- recall it manually.")
		end
	end
	return
end

if (nowT - (tonumber(ataxiaTemp.petFarRecallAt) or 0)) <= 10 then return end
ataxiaTemp.petFarRecallAt = nowT

send(pet .. " recall")

if ataxiaEcho then
	ataxiaEcho("<gold>" .. pet .. " strayed<reset> -- recalling (021 redeploys it).")
end
