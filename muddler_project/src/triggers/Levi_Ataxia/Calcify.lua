local line = matches[1]

-- Scintilla / Emanation Earth hit (from staffcast or emanation)
if line:find("intangible wave of power strikes forth") then
  local tgt = matches[2]
  if tgt == target then
    magi.offense.ptRelay(target .. ": Emanation Earth")
    magi.offense.debugEcho("Emanation Earth hit on " .. target)
  end

-- Calcify skull complete
elseif line:find("bones seem to shift beneath the skin stretched across") then
  local tgt = matches[2]
  if tgt == target then
    magi.offense.state.calcifiedSkull = true
    tarAffed("calcifiedskull")
    magi.offense.ptRelay(target .. ": Calcified Skull!")
    magi.offense.debugEcho("Calcified skull on " .. target)
    -- Also update legacy tracking
    magi.calcifying_head = false
  end

-- Calcify torso
elseif line:find("calcification setting in across the torso") then
  local tgt = matches[2]
  if tgt == target then
    magi.offense.state.calcifiedTorso = true
    tarAffed("calcifiedtorso")
    magi.offense.ptRelay(target .. ": Calcified Torso!")
    magi.offense.debugEcho("Calcified torso on " .. target)
  end

-- Calcify torso fades
elseif line:find("calcified torso .+ returns to normal") then
  local tgt = matches[2]
  if tgt == target then
    magi.offense.state.calcifiedTorso = false
    erAff("calcifiedtorso")
    magi.offense.debugEcho("Calcified torso faded on " .. target)
  end

-- Calcify skull fades
elseif line:find("calcified skull .+ returns to normal") then
  local tgt = matches[2]
  if tgt == target then
    magi.offense.state.calcifiedSkull = false
    erAff("calcifiedskull")
    magi.offense.debugEcho("Calcified skull faded on " .. target)
  end
end
