std = "lua51"
max_line_length = false

-- Mudlet API globals
globals = {
  -- Core Mudlet functions
  "send", "sendAll", "sendGMCP",
  "cecho", "decho", "hecho", "echo",
  "cechoLink", "dechoLink", "echoLink",
  "cechoPopup", "dechoPopup", "echoPopup",
  "feedTriggers", "expandAlias",
  "tempTimer", "killTimer",
  "tempTrigger", "tempRegexTrigger", "tempExactMatchTrigger",
  "tempAlias", "tempKey",
  "killTrigger", "killAlias",
  "enableTrigger", "disableTrigger",
  "enableAlias", "disableAlias",
  "enableTimer", "disableTimer",
  "enableKey", "disableKey",
  "enableScript", "disableScript",
  "exists", "isActive",
  "raiseEvent", "registerAnonymousEventHandler", "registerNamedEventHandler",
  "killAnonymousEventHandler",
  "getMudletHomeDir", "getProfilePath",
  "createStopWatch", "startStopWatch", "stopStopWatch", "resetStopWatch", "getStopWatchTime",
  "getEpoch", "getTime", "getTimestamp",
  "downloadFile", "postHTTP", "getHTTP",
  "appendBuffer", "copy", "paste", "selectString", "selectSection",
  "setBold", "setItalics", "setUnderline", "setStrikeOut",
  "setFgColor", "setBgColor", "resetFormat",
  "moveCursor", "moveCursorEnd", "getLineCount", "getLineNumber",
  "getCurrentLine", "getLastLineNumber",
  "wrapLine", "setWindowWrap", "getWindowWrap", "getColumnCount", "getRowCount",
  "display", "debugc",
  "showNotification",
  "playSoundFile", "stopSounds",
  "closeUserWindow", "hideWindow", "showWindow",
  "openUrl", "setClipboardText",
  "getOS",

  -- Mapper functions
  "createMapper", "centerview",
  "addRoom", "createRoomID", "setRoomArea",
  "getRoomName", "getRoomArea", "getRoomCoordinates", "getRoomExits",
  "getAreaRooms", "getAreaTable", "getAreaTableSwap",
  "searchRoom", "getPath", "speedwalk",
  "setRoomChar", "getRoomChar",
  "setRoomEnv", "getRoomEnv",
  "setRoomWeight", "getRoomWeight",
  "addSpecialExit", "clearSpecialExits", "getSpecialExits",
  "lockRoom", "roomLocked", "setExit",
  "getRoomsByPosition", "roomExists",
  "setRoomIDbyHash", "getRoomIDbyHash",
  "getRoomHashByID", "setRoomName",
  "setAreaName", "deleteArea", "addAreaName",
  "setRoomCoordinates", "setGridMode",
  "getCustomLines", "addCustomLine", "removeCustomLine",
  "getMapLabels", "addMapEvent", "removeMapEvent",
  "setMapZoom", "getMapZoom",

  -- GUI functions
  "Geyser", "Adjustable",
  "setBorderColor", "setBorderTop", "setBorderBottom", "setBorderLeft", "setBorderRight",
  "setAppStyleSheet",
  "createLabel", "createMiniConsole", "createGauge", "createCommandLine",
  "setLabelStyleSheet", "setBackgroundColor",
  "moveWindow", "resizeWindow", "setWindowWrap",
  "setMiniConsoleFontSize", "setFont", "setFontSize",
  "getMainWindowSize", "getUserWindowSize",

  -- LEVI system namespaces
  "ataxia", "ataxiagui", "ataxiaNDB", "ataxiaTemp", "ataxiaTables", "ataxiaBasher",
  "mmp", "target", "pariah", "ataxiaVersion",

  -- Mudlet implicit variables
  "matches", "multimatches", "line",
  "speedWalkDir", "speedWalkPath", "speedWalkCounter",
  "gmcp",
}

-- Standard library extensions that Mudlet adds
read_globals = {
  "table", "string", "io", "os", "math",
  "lfs", "rex", "yajl",
  "json_to_value", "utf8",
}

-- Exclude generated/build directories
exclude_files = {
  "muddler_project/",
  "levi_test_project/",
  "my_package_project/",
  "packages/",
  "tools/legacy/",
  "old_structure_backup/",
}
