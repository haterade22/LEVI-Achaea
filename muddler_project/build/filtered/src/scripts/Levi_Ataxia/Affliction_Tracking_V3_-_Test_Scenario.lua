--[[
    Test script for V3 Branching State Tracker

    This walks through the user's example scenario:
    1. Inflict Asthma/Paralysis
    2. They cure both
    3. Asthma/Paralysis again
    4. They cure Paralysis
    5. Inflict Weariness/Clumsiness
    6. They eat kelp (3 candidates: asthma, weariness, clumsiness)
       → Branches into 33% each for three possibilities
    7. They smoke → collapses to 100% weariness+clumsiness

    Run with: testV3Scenario()
]]--

function testV3Scenario()
    echo("\n")
    echo("=======================================================\n")
    echo("  V3 Branching State Tracker - Test Scenario\n")
    echo("=======================================================\n\n")

    -- Enable V3 and reset
    affConfigV3.enabled = true
    affConfigV3.debugEcho = false  -- Suppress debug messages for cleaner output
    resetStatesV3()

    local function showState(step, description)
        echo("--- Step " .. step .. ": " .. description .. " ---\n")
        echo("Branches: " .. #afflictionStatesV3 .. "\n")
        for i, state in ipairs(afflictionStatesV3) do
            local affs = {}
            for aff in pairs(state.affs) do table.insert(affs, aff) end
            table.sort(affs)
            local affStr = #affs > 0 and table.concat(affs, ", ") or "(empty)"
            echo(string.format("  %d: {%s} @ %.1f%%\n", i, affStr, state.prob * 100))
        end
        echo("\n")
    end

    -- Initial state
    showState(0, "Initial (empty)")

    -- Step 1: Inflict Asthma/Paralysis
    applyAffV3("asthma")
    applyAffV3("paralysis")
    showState(1, "Inflict Asthma + Paralysis")

    -- Step 2: They cure both (separate herb cures)
    -- Kelp cures asthma (only kelp-curable aff)
    onHerbCureV3("kelp")
    echo("  (Target ate kelp)\n")
    showState("2a", "After kelp")

    -- Bloodroot cures paralysis (only bloodroot-curable aff)
    onHerbCureV3("bloodroot")
    echo("  (Target ate bloodroot)\n")
    showState("2b", "After bloodroot - both cured")

    -- Step 3: Asthma/Paralysis again
    applyAffV3("asthma")
    applyAffV3("paralysis")
    showState(3, "Inflict Asthma + Paralysis again")

    -- Step 4: They cure Paralysis
    onHerbCureV3("bloodroot")
    echo("  (Target ate bloodroot)\n")
    showState(4, "After bloodroot - paralysis cured")

    -- Step 5: Inflict Weariness/Clumsiness
    applyAffV3("weariness")
    applyAffV3("clumsiness")
    showState(5, "Inflict Weariness + Clumsiness")

    -- Step 6: They eat kelp (3 candidates)
    echo("  (Target ate kelp - 3 candidates: asthma, weariness, clumsiness)\n")
    onHerbCureV3("kelp")
    showState(6, "After kelp - BRANCHING!")

    -- Show probabilities
    echo("Affliction Probabilities:\n")
    echo(string.format("  asthma:     %.1f%%\n", getAffProbabilityV3("asthma") * 100))
    echo(string.format("  weariness:  %.1f%%\n", getAffProbabilityV3("weariness") * 100))
    echo(string.format("  clumsiness: %.1f%%\n", getAffProbabilityV3("clumsiness") * 100))
    echo("\n")

    -- Step 7: They smoke (proves asthma absent)
    echo("  (Target smoked - proves asthma is ABSENT)\n")
    collapseAffAbsentV3("asthma")
    showState(7, "After smoke - COLLAPSE!")

    -- Final probabilities
    echo("Final Affliction Probabilities:\n")
    echo(string.format("  asthma:     %.1f%%\n", getAffProbabilityV3("asthma") * 100))
    echo(string.format("  weariness:  %.1f%%\n", getAffProbabilityV3("weariness") * 100))
    echo(string.format("  clumsiness: %.1f%%\n", getAffProbabilityV3("clumsiness") * 100))
    echo("\n")

    -- Verify expected result
    local asthmaProb = getAffProbabilityV3("asthma")
    local wearinessProb = getAffProbabilityV3("weariness")
    local clumsinessProb = getAffProbabilityV3("clumsiness")

    echo("=======================================================\n")
    if asthmaProb == 0 and wearinessProb == 1.0 and clumsinessProb == 1.0 then
        cecho("<green>TEST PASSED!</green>\n")
        echo("Asthma = 0%, Weariness = 100%, Clumsiness = 100%\n")
    else
        cecho("<red>TEST FAILED!</red>\n")
        echo("Expected: Asthma=0%, Weariness=100%, Clumsiness=100%\n")
        echo(string.format("Got: Asthma=%.1f%%, Weariness=%.1f%%, Clumsiness=%.1f%%\n",
            asthmaProb * 100, wearinessProb * 100, clumsinessProb * 100))
    end
    echo("=======================================================\n\n")

    -- Re-enable debug echo
    affConfigV3.debugEcho = true
end

-- Quick test of branching/collapsing
function testV3Quick()
    echo("\n=== Quick V3 Test ===\n")

    affConfigV3.enabled = true
    resetStatesV3()

    -- Add 3 kelp-curable affs
    applyAffV3("asthma")
    applyAffV3("clumsiness")
    applyAffV3("weariness")

    echo("After adding asthma, clumsiness, weariness:\n")
    showBranchesV3()

    -- Kelp cure
    onHerbCureV3("kelp")

    echo("\nAfter kelp (should branch to 3 states):\n")
    showBranchesV3()

    -- Smoke
    collapseAffAbsentV3("asthma")

    echo("\nAfter smoke (should collapse to 1 state):\n")
    showBranchesV3()
end
