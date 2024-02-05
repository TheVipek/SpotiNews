local ChatGPTHelper = {}

local json = require("../lua_modules/share/lua/5.4/dkjson");
local http = require("../deps/coro-http");


function ChatGPTHelper:new(ApiKey)
    local obj = {};
    setmetatable(obj, self);
    self.__index = self;
    self.ApiKey = ApiKey;
    self.endpoint = "https://api.openai.com/v1/engines/gpt-3.5-turbo-0613/completions";
    return obj;
end

function ChatGPTHelper:Ask(prompt, maxTokens, systemInfo)
    local data = {
        prompt = prompt,
        max_tokens = maxTokens,
        system = systemInfo
    }
    local headers = {
        { "Content-Type",  "application/json" },
        { "Authorization", "Bearer " .. self.ApiKey }
    };
    local res, body = http.request("POST", self.endpoint, headers, json.encode(data));
    print(body);
    if res.code == 200 then
        return json.decode(body).choices[1].text;
    end
end

return ChatGPTHelper;
