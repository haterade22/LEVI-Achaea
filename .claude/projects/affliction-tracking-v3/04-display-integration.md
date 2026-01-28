# V3 Display Integration

## Limb Counter Window

The V3 affliction tracking system integrates with the Limb Counter window to display affliction probabilities with color-coded feedback.

### File: `001_Limb_Counter_Window.lua`

Location: `src_new/scripts/levi_ataxia/levi/levi_scripts/windows/001_Limb_Counter_Window.lua`

## Display Format

### V3 Enabled Display

```
Target: Aegoth
[LOCK:67%] PAR:100 AST:75 CLU:50
[V3: 4 branches]

Limb Counter
    head: 0
   torso: 0
...
```

### Components

1. **Lock Probability** - Shows probability of having all 4 lock afflictions
2. **Affliction List** - Individual afflictions with probabilities
3. **Branch Count** - Number of active world states

## Color Coding

Afflictions are colored based on probability:

| Color | Probability | Meaning |
|-------|-------------|---------|
| Green | 90%+ | Stuck (confirmed) |
| Yellow | 60-89% | Likely present |
| Orange | 50-59% | Probably present |
| (Hidden) | <50% | Not shown (uncertain) |

## Display Threshold

Afflictions only display when probability >= 50%:

```lua
for aff, prob in pairs(allProbs) do
    if prob >= 0.5 and not ignoreAffs[aff] then
        -- Display this affliction
    end
end
```

This prevents cluttering the display with uncertain afflictions.

## Affliction Abbreviations

```lua
local shortNames = {
    anorexia = "ANO", slickness = "SLI", asthma = "AST", paralysis = "PAR",
    clumsiness = "CLU", nausea = "NAU", weariness = "WEA", stupidity = "STU",
    sensitivity = "SEN", healthleech = "HLE", haemophilia = "HAE",
    addiction = "ADD", impatience = "IMP", rebounding = "REB", shield = "SHD",
    prone = "PRONE", confusion = "CON", dementia = "DEM", paranoia = "PNO",
    hallucinations = "HAL", dizziness = "DIZ", epilepsy = "EPI", recklessness = "REC",
    shyness = "SHY", lethargy = "LET", darkshade = "DAR"
}
```

## Probability Display Format

- **100% certain**: Shows just the abbreviation (e.g., `PAR`)
- **Less than 100%**: Shows abbreviation + percentage (e.g., `AST:75`)

```lua
local display = shortName
if prob < 1.0 then
    display = shortName .. ":" .. math.floor(prob * 100)
end
```

## Lock Probability Display

Shows combined probability of having all 4 lock afflictions:

```lua
local lockAffs = {"anorexia", "slickness", "asthma", "paralysis"}
local lockProb = getStateProbabilityV3(lockAffs)

if lockProb >= 0.9 then
    -- Green [LOCK:XX%]
elseif lockProb >= 0.3 then
    -- Yellow [LOCK:XX%]
end
```

## Ignored Afflictions

Some afflictions are hidden from display:

```lua
local ignoreAffs = {curseward = true, blindness = true, deafness = true}
```

## Update Triggering

The display updates on:

1. **State changes** - After any V3 operation (apply, cure, collapse)
2. **Target acquired** - Reset and refresh display
3. **Prompt** - Regular refresh with game prompts

```lua
-- Called after V3 state changes
updateAffDisplayV3()

-- Registered for automatic updates
registerAnonymousEventHandler("targets updated", tarc.write)
```

## V2 Fallback Display

If V3 is disabled, the window falls back to V2 display:

```lua
if affConfigV3 and affConfigV3.enabled then
    -- V3 probability-based display
else
    -- V2 binary display (fallback)
end
```

## Example Displays

### Fresh Target (no afflictions)
```
Target: Aegoth
[V3: 1 branches]
```

### Single Confirmed Affliction
```
Target: Aegoth
PAR
[V3: 1 branches]
```

### Multiple Afflictions with Uncertainty
```
Target: Aegoth
PAR AST:67 CLU:50
[V3: 3 branches]
```

### Near Lock State
```
Target: Aegoth
[LOCK:75%] PAR ANO SLI:75 AST:75
[V3: 2 branches]
```

### Full Lock Confirmed
```
Target: Aegoth
[LOCK:100%] PAR ANO SLI AST
[V3: 1 branches]
```
