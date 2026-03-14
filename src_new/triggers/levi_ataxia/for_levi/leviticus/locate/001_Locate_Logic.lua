--[[mudlet
type: trigger
name: Locate Logic
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- MINE ALL MINE
- Locate
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
- pattern: ^You see that (\w+) is at (.+)\.$
  type: 1
]]--

-- Skip when bulk locate scan is running (handled by locate_relay triggers)
if (LocateSystem and LocateSystem.running) or (LocateWorld and LocateWorld.running) then return end

mmp.locateAndEcho(matches[3], matches[2])
if locateon == true then
  local targetName = matches[2]
  local roomName = matches[3]
  local t = mmp.searchRoomExact(roomName)
  local roomId = ""
  if next(t) then
    local k, v = next(t)
    roomId = " (" .. (type(k) == "number" and k or v) .. ")"
  end

  -- Wait for faemirror result before sending tell
  local function sendLocateReply(companionInfo)
    local msg = targetName .. " is at " .. roomName .. roomId
    if companionInfo then
      msg = msg .. " " .. companionInfo
    end
    send("tell " .. locateperson .. " " .. msg)
    locateon = false
  end

  -- Clean up any previous faemirror triggers/timers
  if locateFaemirrorTrigger then killTrigger(locateFaemirrorTrigger) end
  if locateFaemirrorBlank then killTrigger(locateFaemirrorBlank) end
  if locateFaemirrorTimer then killTimer(locateFaemirrorTimer) end

  -- Trigger: faemirror shows people
  locateFaemirrorTrigger = tempRegexTrigger("^As you gaze into a mirror of fae perception, you see the shadow of (\\d+) (?:person|people) alongside", function()
    local count = matches[2]
    if locateFaemirrorBlank then killTrigger(locateFaemirrorBlank) end
    if locateFaemirrorTimer then killTimer(locateFaemirrorTimer) end
    locateFaemirrorTrigger = nil
    locateFaemirrorBlank = nil
    locateFaemirrorTimer = nil
    sendLocateReply("[" .. count .. " with them]")
  end)

  -- Trigger: faemirror blank (alone)
  locateFaemirrorBlank = tempRegexTrigger("^The surface of a mirror of fae perception remains blank", function()
    if locateFaemirrorTrigger then killTrigger(locateFaemirrorTrigger) end
    if locateFaemirrorTimer then killTimer(locateFaemirrorTimer) end
    locateFaemirrorTrigger = nil
    locateFaemirrorBlank = nil
    locateFaemirrorTimer = nil
    sendLocateReply("[alone]")
  end)

  -- Timeout fallback (2s) in case no faemirror
  locateFaemirrorTimer = tempTimer(2, function()
    if locateFaemirrorTrigger then killTrigger(locateFaemirrorTrigger) end
    if locateFaemirrorBlank then killTrigger(locateFaemirrorBlank) end
    locateFaemirrorTrigger = nil
    locateFaemirrorBlank = nil
    locateFaemirrorTimer = nil
    sendLocateReply(nil)
  end)
else
  locateon = false
end