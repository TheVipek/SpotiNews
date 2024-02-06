local json = require("../lua_modules/share/lua/5.4/dkjson");
local http = require("../deps/coro-http");
local sMath = require("./SigmaMath");
local sParser = require("./SigmaParser");
local urlHelper = require("./UrlHelper");
local tokenHelper = require("./AccessTokenHelper");
GeniusHelper = {}

function GeniusHelper:new(apikey)
    local obj = {};
    setmetatable(obj, self);
    self.__index = self;
    self.APIKey = apikey;
    return obj;
end

function GeniusHelper:GetSong(songName)
    local url = "https://api.genius.com/search";
    local headers = {
        { "Content-Type",  "application/json" },
        { "Authorization", "Bearer " .. self.APIKey }
    };

    local params = urlHelper:urlEscape(songName);
    url = url .. "?q=" .. params;
    local res, body = http.request('GET', url, headers);
    if res.code == 200 then
        local data = json.decode(body);
        return data.artists.items[1] ~= nil and data.artists.items[1] or nil;
    end

    return nil;
end
