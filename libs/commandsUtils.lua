return
{
    GetCommand = function(str)
        return string.match(str, "^%S+")
    end,
    GetArgs = function(str)
        local args = {}

        for arg in string.gmatch(str, "'([^']+)") do
            args[#args + 1] = arg:gsub("'", "");
        end
        return args
    end
}
