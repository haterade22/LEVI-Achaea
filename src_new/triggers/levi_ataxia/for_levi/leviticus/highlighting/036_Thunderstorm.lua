--[[mudlet
type: trigger
name: Thunderstorm
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Highlighting
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
- pattern: ^Wind swells about your form as you build a tremendous galvanic charge
  type: 1
- pattern: ^A clap of thunder presages the unleashed storm
  type: 1
]]--

--[[
    SHIN THUNDERSTORM, captured live 2026-08-01. Two lines:

      "Wind swells about your form as you build a tremendous galvanic charge. Power surges
       through your limbs, ... releasing bolts of lightning in every direction."   <- our cast
      "A clap of thunder presages the unleashed storm, forks of brilliant lightning lashing
       out from your perfect form to strike with rage at all opponents."           <- it lands

    Two states, the hyena/falcon convention: the cast is dark_sea_green (intent, nothing has
    happened yet), the strike is chartreuse BOLD (the damage actually happening). Never the
    orange family -- reserved.

    The STRIKE also confirms the cooldown, restamping it from the landed moment rather than
    leaving the send-side guess to stand.

    NOTE the near-miss with the Thunderclap bisect line, which also mentions a clap of
    thunder: that one reads "...a clap of thunder HERALDING YOUR STRIKE." and is anchored on
    "Lightning follows the path of" (highlighting/035). These two cannot cross-match --
    different openings, different tails -- but they are close enough to be worth saying so.
]]--

local landed = line:find("^A clap of thunder presages") ~= nil

selectString(line, 1)
if landed then setBold(true) end
fg(landed and "chartreuse" or "dark_sea_green")
deselect()
resetFormat()

if landed and ataxiaBasher_bmThunderstormConfirm then
	ataxiaBasher_bmThunderstormConfirm()
end
