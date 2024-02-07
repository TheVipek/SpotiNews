local ChatGPTHelper = {}

local json = require("../deps/json");
local http = require("../deps/coro-http");


function ChatGPTHelper:new(ApiKey)
    local obj = {};
    setmetatable(obj, self);
    self.__index = self;
    self.ApiKey = ApiKey;
    self.endpoint = "https://api.openai.com/v1/chat/completions";
    return obj;
end

---@param prompt string prompt string The user's input prompt to send to ChatGPT.
---@param systemInfo string systemInfo System-level information or context to provide to ChatGPT.
---@return table A table containing the response code and the ChatGPT-generated message.
function ChatGPTHelper:Ask(prompt, systemInfo)
    local data = {
        model = "gpt-4-0125-preview",
        messages = {
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
        return { code = res.code, value = json.decode(body).choices[1].message.content }
    end
    return { code = res.code, value = "" };
end

return ChatGPTHelper;
