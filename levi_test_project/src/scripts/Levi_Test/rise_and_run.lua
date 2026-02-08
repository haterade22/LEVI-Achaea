local function gcd(a, b)
    repeat
        if a == 0 or b == 0 then return 0 end
        a, b = b, a % b
    until b == 0
    return a
end

function riserun(numerator, denominator)
    local conumerator = 1
    local codenominator = 1

    if numerator < 0 then
        conumerator = -1
        numerator = -numerator
    end

    if denominator< 0 then
        codenominator = -1
        denominator= -denominator
    end
    local n = gcd(numerator, denominator)
    -- don't do div/0 math
    if numerator ~= 0 then numerator = numerator/n end
    if denominator ~= 0 then denominator = denominator/n end
    -- if 1 is 0 then the rise or run of the other is 1
    if (numerator == 0 or denominator == 0) and not (numerator == 0 and denominator == 0) then
      if numerator == 0 then denominator = 1 end
      if denominator == 0 then numerator = 1 end
      
    end

    return conumerator * numerator, codenominator * denominator
end
