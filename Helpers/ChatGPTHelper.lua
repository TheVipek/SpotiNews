local ChatGPTHelper = {}

local json = require("../lua_modules/share/lua/5.4/dkjson");
local http = require("../deps/coro-http");


function ChatGPTHelper:new(ApiKey)
    local obj = {};
    setmetatable(obj, self);
    self.__index = self;
    self.ApiKey = ApiKey;
    self.endpoint = "https://api.openai.com/v1/chat/completions";
    return obj;
end

function ChatGPTHelper:Ask(prompt, systemInfo)
    local data = {
        model = "gpt-3.5-turbo-0125",
        messages = { -- Using 'messages' as per chat API format
            {
                role = "system",
                content = systemInfo
            },
            {
                role = "user",
                content = prompt
            }
        }
    }
    local headers = {
        { "Content-Type",  "application/json" },
        { "Authorization", "Bearer " .. self.ApiKey }
    };
    local res, body = http.request("POST", self.endpoint, headers, json.encode(data));
    if res.code == 200 then
        return json.decode(body).choices[1].message.content;
    end
end

return ChatGPTHelper;
