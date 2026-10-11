--[[mudlet
type: script
name: KB Capture
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Misc Scripts
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

-- KB CAPTURE -- record the game's own answers for the knowledge base (v4.7.396).
--
-- User: "do a system to do affliction show <aff>, capture the output and put it into a local
-- database". The KB (kb/ in the repo) is built from what the GAME says, so this module asks the
-- game and writes the answers down WORD FOR WORD. It does not parse them: the repo does that
-- (tools/kb_capture_import.py), where a parser can be tested and fixed without going back
-- in-game. Capture here, understand there.
--
-- How a capture works:
--   * Commands go out ONE AT A TIME, the next only after the previous answer has ended. An answer
--     ends at the next PROMPT (isPrompt()) or after CAPTURE_TIMEOUT, whichever comes first.
--   * Every line between the send and that prompt is recorded, so a busy room can add noise. The
--     importer skips lines that are clearly not part of the answer; run it somewhere quiet.
--   * Each answer is APPENDED to <profile>/kb_capture.txt as soon as it ends, so stopping halfway
--     (or a disconnect) keeps everything captured so far.
--   * Output is GAGGED while capturing (several hundred lines otherwise), with a progress echo.
--     It refuses to start while the basher is on, because a gag would hide the fight.
--
-- Which afflictions: every name our code knows (curing priorities and cure tables), plus the ones
-- in HELP 13.7.2 that the code does not use. Stack suffixes (burning5) are dropped. A name the game
-- does not know is still worth asking: the refusal tells us our name differs from the game's.
--
-- Commands (alias `kbcapture`, aliases/configs/025):
--   kbcapture              status
--   kbcapture afflictions  AFFLICTION LIST, then AFFLICTION SHOW + WHATCURES for every name we know
--                          AND every name the game's list holds (about 400 commands, ~8 min)
--   kbcapture <cmd | cmd>  capture any command(s), separated by "|"  (e.g. kbcapture help cures | help heal)
--                          NOT ";": Mudlet splits typed input on its command separator before any
--                          alias runs, so `kbcapture a;b` captured only `a` and sent `b` to the game
--                          uncaptured (2026-10-10).
--   kbcapture stop         stop after the current answer

ataxiaKB = ataxiaKB or {}
ataxiaTemp = ataxiaTemp or {}

ataxiaKB.CAPTURE_TIMEOUT = 4    -- seconds to wait for an answer's closing prompt
ataxiaKB.GAP = 0.6              -- seconds between one answer ending and the next send
ataxiaKB.FILE = "kb_capture.txt"

-- In HELP 13.7.2 but not keys in our code (or keyed differently there).
ataxiaKB.EXTRA_AFFS = {
  "ablaze", "bleeding", "drowning", "freezing", "stinky", "temperedhumours",
}

local function add(set, name)
  if type(name) ~= "string" then return end
  name = name:lower():gsub("%d+$", "")
  if name ~= "" and name:match("^[a-z]+$") then set[name] = true end
end

-- Every affliction name we can find, sorted (so a run is repeatable and resumable by eye).
function ataxiaKB.affNames()
  local set = {}
  if type(ataxia_defaultCuringPrios) == "function" then
    local ok, prios = pcall(ataxia_defaultCuringPrios)
    if ok and type(prios) == "table" then
      for k in pairs(prios) do add(set, k) end
    end
  end
  for _, tbl in ipairs({ curingTable, curingTableV3, salveCureTableV3 }) do
    if type(tbl) == "table" then
      for _, list in pairs(tbl) do
        if type(list) == "table" then
          for _, a in ipairs(list) do add(set, a) end
        end
      end
    end
  end
  if type(smokeCureTableV3) == "table" then
    for _, a in ipairs(smokeCureTableV3) do add(set, a) end
  end
  for _, a in ipairs(ataxiaKB.EXTRA_AFFS) do add(set, a) end
  local out = {}
  for k in pairs(set) do out[#out + 1] = k end
  table.sort(out)
  return out
end

-- The command list for `kbcapture afflictions`.
function ataxiaKB.afflictionCommands(names)
  local cmds = { "affliction list" }
  for _, a in ipairs(names or ataxiaKB.affNames()) do
    cmds[#cmds + 1] = "affliction show " .. a
    cmds[#cmds + 1] = "whatcures " .. a
  end
  return cmds
end

-- The names in an AFFLICTION LIST answer: one capitalised word per line, after the dashed rule.
-- The full list (203 on 2026-10-10) holds 79 afflictions our code never names, so a run that
-- asked only about our own names could never learn about them.
function ataxiaKB.parseAfflictionList(lines)
  local out, started = {}, false
  for _, l in ipairs(lines or {}) do
    if l:find("^%-%-%-%-") then
      started = true
    elseif started then
      local name = l:match("^%s*(%a+)%s*$")
      if name then out[#out + 1] = name:lower() end
    end
  end
  return out
end

-- After AFFLICTION LIST is answered, queue SHOW + WHATCURES for every listed name not queued yet.
-- Returns how many names were added.
function ataxiaKB.extendFromList(st, lines)
  st.queued = st.queued or {}
  if not next(st.queued) then
    for _, c in ipairs(st.queue) do st.queued[c] = true end
  end
  local added = 0
  for _, name in ipairs(ataxiaKB.parseAfflictionList(lines)) do
    local show = "affliction show " .. name
    if not st.queued[show] then
      st.queue[#st.queue + 1] = show
      st.queue[#st.queue + 1] = "whatcures " .. name
      st.queued[show] = true
      added = added + 1
    end
  end
  return added
end

-- One answer, as written to the file. The markers are what the importer splits on.
function ataxiaKB.formatBlock(cmd, lines, stamp, timedOut)
  local out = { "##### KBCAPTURE " .. stamp .. " | " .. cmd .. (timedOut and " | TIMEOUT" or "") }
  for _, l in ipairs(lines) do out[#out + 1] = l end
  out[#out + 1] = "##### END"
  return table.concat(out, "\n") .. "\n"
end

function ataxiaKB.path()
  return getMudletHomeDir() .. "/" .. ataxiaKB.FILE
end

local function write(text)
  local f = io.open(ataxiaKB.path(), "a")
  if not f then return false end
  f:write(text)
  f:close()
  return true
end

local function stamp()
  return os.date("!%Y-%m-%dT%H:%M:%SZ")
end

local function echo(msg)
  if ataxiaEcho then ataxiaEcho("KB capture: " .. msg) end
end

-- Capture state lives on ataxiaTemp: it is transient, and anything under `ataxia` is saved to
-- disk (a restored "running" flag with no timer behind it would wedge the next run).
local function state()
  ataxiaTemp.kbcap = ataxiaTemp.kbcap or { queue = {}, i = 0 }
  return ataxiaTemp.kbcap
end

local function cleanup(st)
  if st.trig then killTrigger(st.trig); st.trig = nil end
  if st.timer then killTimer(st.timer); st.timer = nil end
end

local sendNext

-- Close the current answer: write it, then schedule the next command.
local function finish(timedOut)
  local st = state()
  if not st.cmd then return end
  cleanup(st)
  write(ataxiaKB.formatBlock(st.cmd, st.lines, st.stamp, timedOut))
  if st.extendFromList and st.cmd == "affliction list" then
    local added = ataxiaKB.extendFromList(st, st.lines)
    if added > 0 then echo("the game lists " .. added .. " affliction(s) our code does not name; asking about those too ("
      .. #st.queue .. " commands in all).") end
  end
  st.done = st.done + 1
  st.cmd, st.lines = nil, nil
  if st.done % 20 == 0 and st.i < #st.queue then
    echo(st.done .. "/" .. #st.queue .. " captured...")
  end
  tempTimer(ataxiaKB.GAP, sendNext)
end

-- A line arrived while capturing. Exposed for the tests.
-- The FIRST line of the answer, for commands whose answer has a known shape. Until one of these
-- arrives, a prompt does not close the answer. The first live run (2026-10-10) lost two answers
-- this way: a room line ("the corpse of a giant crow turns to dust") arrived with its own prompt,
-- closed the block, and the real answer then landed in the gap before the next command.
ataxiaKB.EXPECT = {
  { "^affliction show ", { "^Affliction:", "^There is no such affliction" } },
  { "^whatcures ", { "^The affliction '", "^That is not a known affliction" } },
}

function ataxiaKB.expectFor(cmd)
  for _, e in ipairs(ataxiaKB.EXPECT) do
    if cmd:lower():find(e[1]) then return e[2] end
  end
  return nil
end

local MORE = "^%[Type MORE if you wish to continue reading"

local function rearmTimeout(st)
  if st.timer then killTimer(st.timer) end
  st.timer = tempTimer(ataxiaKB.CAPTURE_TIMEOUT, function()
    st.timer = nil
    finish(true)
  end)
end

function ataxiaKB.onLine(text, prompt)
  local st = state()
  if not st.cmd then return end
  if prompt then
    -- A prompt before any answer is the prompt for something older; keep waiting for ours.
    -- A prompt after a MORE page belongs to that page: the next page is on its way.
    if st.morePending then st.morePending = false; return end
    if #st.lines > 0 and (st.answered or not st.expect) then finish(false) end
    return
  end
  st.lines[#st.lines + 1] = text
  if st.expect and not st.answered then
    for _, pat in ipairs(st.expect) do
      if text:find(pat) then st.answered = true; break end
    end
  end
  if text:find(MORE) then
    -- Long answers (AFFLICTION LIST) are paged. Ask for the next page and keep recording.
    st.morePending = true
    send("more", false)
    rearmTimeout(st)
  end
  if st.gag and deleteLine then deleteLine() end
end

sendNext = function()
  local st = state()
  if st.stopping or st.i >= #st.queue then
    st.running = false
    echo((st.stopping and "stopped" or "done") .. ": " .. st.done .. " answer(s) written to "
      .. ataxiaKB.path() .. ". In the repo, run: python tools/kb_capture_import.py")
    st.stopping = false
    return
  end
  st.i = st.i + 1
  st.cmd, st.lines, st.stamp = st.queue[st.i], {}, stamp()
  st.expect, st.answered, st.morePending = ataxiaKB.expectFor(st.cmd), false, false
  st.trig = tempRegexTrigger("^", function()
    ataxiaKB.onLine(line, isPrompt and isPrompt() or false)
  end)
  rearmTimeout(st)
  send(st.cmd, false)
end

-- Start capturing `cmds`. Returns false (and says why) when it cannot.
function ataxiaKB.start(cmds, opts)
  local st = state()
  if st.running then echo("already running (" .. st.done .. "/" .. #st.queue .. "). kbcapture stop"); return false end
  if ataxiaBasher and ataxiaBasher.enabled then
    echo("the basher is on. Turn it off first: capture gags output, which would hide a fight.")
    return false
  end
  if type(cmds) ~= "table" or #cmds == 0 then echo("nothing to capture."); return false end
  st.queue, st.i, st.done = cmds, 0, 0
  st.running, st.stopping = true, false
  st.gag = not (opts and opts.gag == false)
  st.extendFromList = (opts and opts.extendFromList) or false
  st.queued = {}
  echo("capturing " .. #cmds .. " command(s), about " .. math.ceil(#cmds * 1.2 / 60)
    .. " min. Output is hidden until it finishes. kbcapture stop to end early.")
  sendNext()
  return true
end

function ataxiaKB.stop()
  local st = state()
  if not st.running then echo("not running."); return end
  st.stopping = true
  echo("stopping after the current answer.")
end

function ataxiaKB.status()
  local st = state()
  if st.running then
    echo("running: " .. st.done .. "/" .. #st.queue .. " (now: " .. tostring(st.cmd) .. ").")
  else
    echo("idle. File: " .. ataxiaKB.path() .. ". Known affliction names: " .. #ataxiaKB.affNames() .. ".")
  end
end
