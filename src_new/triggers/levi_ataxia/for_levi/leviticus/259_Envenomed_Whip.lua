--[[mudlet
type: trigger
name: Envenomed Whip
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Serpent
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
- pattern: (You secrete \w+ and deftly bring Elentari's Scourge to your mouth, letting the venom drip upon it.)
  type: 1
]]--

deleteLine()
--deleteLine()

if svenom1 == "curare" then Deadeyes1 = "paralysis" end
if svenom1 == "voyria" then Deadeyes1 = "voyria" end
if svenom1 == "xentio" then Deadeyes1 = "clumsiness" end
if svenom1 == "larkspar" then Deadeyes1 = "dizziness" end
if svenom1 == "aconite" then Deadeyes1 = "stupidity" end
if svenom1 == "euphorbia" then Deadeyes1 = "illness" end
if svenom1 == "eurypteria" then Deadeyes1 = "recklessness" end
if svenom1 == "kalmia" then Deadeyes1 = "asthma" end
if svenom1 == "vernalius" then Deadeyes1 = "weariness" end
if svenom1 == "prefarar" then Deadeyes1 = "sensitivity" end
if svenom1 == "slike" then Deadeyes1 = "anorexia" end
if svenom1 == "addiction" then Deadeyes1 = "addiction" end
if svenom1 == "masochism" then Deadeyes1 = "masochism" end
if svenom1 == "dementia" then Deadeyes1 = "dementia" end
if svenom1 == "vertigo" then Deadeyes1 = "vertigo" end
if svenom1 == "gecko" then Deadeyes1 = "slickness" end
if svenom1 == "darkshade" then Deadeyes1 = "darkshade" end
 
if svenom2 == "curare" then Deadeyes2 = "paralysis" end
if svenom2 == "voyria" then Deadeyes2 = "voyria" end
if svenom2 == "xentio" then Deadeyes2 = "clumsiness" end
if svenom2 == "larkspar" then Deadeyes2 = "dizziness" end
if svenom2 == "aconite" then Deadeyes2 = "stupidity" end
if svenom2 == "euphorbia" then Deadeyes2 = "illness" end
if svenom2 == "eurypteria" then Deadeyes2 = "recklessness" end
if svenom2 == "kalmia" then Deadeyes2 = "asthma" end
if svenom2 == "vernalius" then Deadeyes2 = "weariness" end
if svenom2 == "prefarar" then Deadeyes2 = "sensitivity" end
if svenom2 == "slike" then Deadeyes2 = "anorexia" end
if svenom2 == "addiction" then Deadeyes2 = "addiction" end
if svenom2 == "masochism" then Deadeyes2 = "masochism" end
if svenom2 == "dementia" then Deadeyes2 = "dementia" end
if svenom2 == "vertigo" then Deadeyes2 = "vertigo" end
if svenom2 == "gecko" then Deadeyes2 = "slickness" end
if svenom2 == "darkshade" then Deadeyes2 = "darkshade" end

--cecho("\n<red>[<white>Levi<red>]: ENVENOMED "..string.upper(multimatches[1][2]).." <white>[<orange>"..string.title(svenom1).." <white>+ <orange>"..string.title(svenom2).."<white>]")

--cecho("\n<red>[<white>Levi<red>]: ENVENOMED "..string.upper(multimatches[1][2]).." <white>[<orange>"..string.title(svenom1).." <white>+ <orange>"..string.title(svenom2).."<white>]")
--cecho("\n<red>[<white>Levi<red>]: ENVENOMED "..string.upper(matches[2]).." <white>[<orange>"..string.title(svenom1).." <white>+ <orange>"..string.title(svenom2).."<white>]")
cecho("\n<red>[<white>Levi<red>]: HITTING <white>[<orange>"..string.title(Deadeyes2).."<white>]")
