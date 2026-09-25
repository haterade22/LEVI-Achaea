--- trigger_lib.lua -- read a trigger's patterns, wrap a line the way Achaea does, and evaluate a
--- pattern against one PHYSICAL line (v4.7.351).
---
--- Not a test file (the runner only discovers test_*.lua); load it with dofile.
---
--- WHY THIS EXISTS. Three triggers shipped in v4.7.336-347 matched text that could never arrive in
--- one piece: the user's server wraps at 119-124 columns, the lines were longer, and each pattern
--- either ran past the break or straddled it. Every test passed, because the tests read the trigger
--- FILE for a phrase -- and the phrase was often in the file's own comment. These helpers test the
--- PATTERN against the line as it actually reaches Mudlet.
---
--- The evaluator is deliberately small. It understands exactly the shapes this package uses for
--- line-start matching -- literals, escaped literals, `\d+ \w+ \S+` (optionally captured), `.{m,n}`,
--- a `(?:...){m,n}` group, and a trailing `$` -- and it RAISES on anything else, so a pattern it
--- cannot judge fails loudly instead of passing quietly.

local L = {}

-- Every `- pattern:` in a trigger's YAML header, with its type. Handles single-quoted patterns
-- that YAML folded across lines ('' is an escaped quote inside them).
function L.patterns(path)
  local f = assert(io.open(path), "no such trigger: " .. tostring(path))
  local src = f:read("*a"); f:close()
  local header = src:match("^(.-)%]%]%-%-") or src
  local out, lines = {}, {}
  for ln in (header .. "\n"):gmatch("([^\n]*)\n") do lines[#lines + 1] = (ln:gsub("\r$", "")) end
  local i = 1
  while i <= #lines do
    local raw = lines[i]:match("^%- pattern: (.*)$")
    if raw then
      if raw:sub(1, 1) == "'" then
        -- Closed once the text after the opening quote, with '' escapes removed, ends in a quote.
        local function closed(b)
          local body = b:sub(2):gsub("''", "")
          return body:sub(-1) == "'"
        end
        local buf = raw
        while not closed(buf) and i < #lines do
          i = i + 1
          buf = buf .. " " .. (lines[i]:gsub("^%s+", ""))
        end
        raw = (buf:sub(2, -2):gsub("''", "'"))
      end
      local typ = tonumber((lines[i + 1] or ""):match("^%s*type:%s*(%d+)"))
      out[#out + 1] = { pat = raw, type = typ }
    end
    i = i + 1
  end
  return out
end

-- Achaea's word wrap: break at the last space that keeps a row within `width` columns.
function L.wrap(line, width)
  local rows, cur = {}, ""
  for word in line:gmatch("%S+") do
    local cand = (cur == "") and word or (cur .. " " .. word)
    if #cand <= width then cur = cand
    else rows[#rows + 1] = cur; cur = word end
  end
  rows[#rows + 1] = cur
  return rows
end

-- ---------------------------------------------------------------------------------------------
-- A tiny regex evaluator for line-START patterns (type 1, beginning with ^).
-- ---------------------------------------------------------------------------------------------
local CLASS = { d = "%d", w = "[%w_]", S = "%S", s = "%s" }

local function parse(p, i, stop)
  local toks = {}
  while i <= #p do
    local c = p:sub(i, i)
    if stop and c == stop then return toks, i end
    local tok
    if c == "\\" then
      local n = p:sub(i + 1, i + 1)
      if CLASS[n] then tok = { class = CLASS[n] } else tok = { lit = n } end
      i = i + 2
    elseif c == "(" then
      local inner, j
      if p:sub(i + 1, i + 2) == "?:" then inner, j = parse(p, i + 3, ")")
      else inner, j = parse(p, i + 1, ")") end
      assert(p:sub(j, j) == ")", "unbalanced group in " .. p)
      tok = { group = inner }
      i = j + 1
    elseif c == "." then
      tok = { class = "." }
      i = i + 1
    elseif c == "$" then
      tok = { eol = true }
      i = i + 1
    elseif c:match("[%[%]%*%?%|%^{}]") then
      error("trigger_lib: unsupported regex syntax '" .. c .. "' in " .. p)
    else
      tok = { lit = c }
      i = i + 1
    end
    -- quantifier
    local q = p:sub(i, i)
    if q == "+" then tok.min, tok.max = 1, 10000; i = i + 1
    elseif q == "*" then tok.min, tok.max = 0, 10000; i = i + 1
    elseif q == "?" then tok.min, tok.max = 0, 1; i = i + 1
    elseif q == "{" then
      local a, b, j = p:match("^{(%d+),(%d+)}()", i)
      assert(a, "unsupported quantifier in " .. p)
      tok.min, tok.max = tonumber(a), tonumber(b); i = j
    else tok.min, tok.max = 1, 1 end
    toks[#toks + 1] = tok
  end
  return toks, i
end

local match -- forward

-- Can `tok` match ONE unit at `pos`? Returns the list of possible end positions.
local function one(tok, s, pos)
  if tok.lit then
    if s:sub(pos, pos) == tok.lit then return { pos + 1 } end
    return {}
  elseif tok.class then
    local ch = s:sub(pos, pos)
    if ch == "" then return {} end
    if tok.class == "." or ch:match("^" .. tok.class .. "$") then return { pos + 1 } end
    return {}
  elseif tok.group then
    local ends = {}
    match(tok.group, 1, s, pos, function(e) ends[#ends + 1] = e end)
    return ends
  end
  return {}
end

-- Enumerate every end position of `toks[k..]` from `pos`, calling `emit(end)`.
function match(toks, k, s, pos, emit)
  if k > #toks then return emit(pos) end
  local tok = toks[k]
  if tok.eol then
    if pos == #s + 1 then return match(toks, k + 1, s, pos, emit) end
    return
  end
  -- repeat tok between min and max times, greedy, backtracking
  local function rep(count, p)
    if count >= tok.min then match(toks, k + 1, s, p, emit) end
    if count >= tok.max then return end
    for _, e in ipairs(one(tok, s, p)) do
      if e > p then rep(count + 1, e) end
    end
  end
  rep(0, pos)
end

-- Does the pattern match this ONE physical line (as Mudlet would see it)?
function L.matches(pat, typ, line)
  -- Mudlet's numbering (tools/convert_to_muddler.py PATTERN_TYPE_MAP): 0 substring, 1 regex,
  -- 2 startOfLine, 3 exactMatch. v4.7.351 had 3 as "starts with" -- corrected v4.7.352.
  if typ == 0 then return line:find(pat, 1, true) ~= nil end
  if typ == 2 then return line:sub(1, #pat) == pat end
  if typ == 3 then return line == pat end
  assert(typ == 1, "unknown trigger pattern type " .. tostring(typ))
  if pat:sub(1, 1) ~= "^" then
    error("trigger_lib: only ^-anchored regex patterns are supported, got " .. pat)
  end
  local toks = parse(pat, 2)
  local found = false
  match(toks, 1, line, 1, function() found = true end)
  return found
end

-- Does ANY pattern of the trigger match this physical line?
function L.anyMatches(pats, line)
  for _, p in ipairs(pats) do
    if L.matches(p.pat, p.type, line) then return true end
  end
  return false
end

return L
