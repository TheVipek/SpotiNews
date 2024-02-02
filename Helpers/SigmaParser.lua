SigmaParser = {}

function SigmaParser.StrToDate(date, pattern)
    local year, month, day = string.match(date, pattern);
    return os.time({ year = year, month = month, day = day });
end

return SigmaParser;
