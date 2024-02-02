SigmaMath = {}

function SigmaMath.Clamp(val, min, max)
    val = val or 0;
    min = min or 0;
    max = max or 0;
    
    if val < min then
        val = min;
    end

    if val > max then
        val = max;
    end

    return val;
end

return SigmaMath;