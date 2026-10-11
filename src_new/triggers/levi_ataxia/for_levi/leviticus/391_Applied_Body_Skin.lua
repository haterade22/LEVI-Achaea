--[[mudlet
type: trigger
name: Applied Body/Skin
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Remove Afflictions
- Groups
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
- pattern: ^(\w+) takes some salve from a vial and rubs it on \w+ (skin|body).$
  type: 1
]]--

-- ONE APPLICATION, ONE CURE (v4.7.404). The line names the spot but not the salve, so the
-- tracker branches over everything a salve on that spot can cure (salveCureTableV3,
-- affliction_tracking_core/007). This trigger used to ERASE anorexia, itching, selarnia and
-- frostbite on every body application, on top of that branching -- so a target who applied
-- mending for a burn was also "cured" of the anorexia they still had, and the offense spent a
-- slike re-giving it. Only PROOFS are erased outright now: an application is impossible while
-- slick or while bloodfire burns, so having applied proves both absent.
if isTargeted(matches[2]) then
  tdeliverance = false
  if passiveFailsafe then restorePassiveCure() end
  -- V2 tracking support
  if matches[3] == "body" then
    if onTargetSalveBodyV2 then onTargetSalveBodyV2(matches[2]) end
  else
    if onTargetSalveSkinV2 then onTargetSalveSkinV2(matches[2]) end
  end

  erAff("slickness")
  erAff("bloodfire")

  if matches[3] == "body" then
    -- 393 also matches "...on his body" and owns the RESTORATION cures with delayed timing
    -- (hypothermia, calcified torso, torso damage). When one of those is up the application is
    -- taken to be that restoration (both outrank everything else on the body in SSC's order), so
    -- this trigger does not ALSO cure something -- one application, one cure.
    if not (haveAff("hypothermia") or haveAff("calcifiedtorso")) then
      if onSalveCureV3 then onSalveCureV3("body") end
    end

    magi.offense = magi.offense or {}
    magi.offense.state = magi.offense.state or {}
    magi.offense.state.burns = math.max((magi.offense.state.burns or 0) - 1, 0)
    tburns = magi.offense.state.burns
    selectCurrentLine() fg("slate_grey")
    cecho(" <DimGrey>[<red>"..tburns.."/5<DimGrey>]")
  elseif not haveAff("hypothermia") then
    -- Skin = caloric. Hypothermia blocks the cold cures (unchanged rule).
    if onSalveCureV3 then onSalveCureV3("skin") end
  end
  targetIshere = true
end
