local json = require("./lua_modules/share/lua/5.4/dkjson");
local http = require("./deps/coro-http");
local sMath = require("./Helpers/SigmaMath");
local sParser = require("./Helpers/SigmaParser");
local base64 = require("./deps/base64");
SpotifyHelper = {}

function SpotifyHelper:new(id, secret)
    local obj = {};
    setmetatable(obj, self);
    self.__index = self;
    self.clientSecret = secret;
    self.clientID = id;
    return obj;
end

--ADD MECHANIC FOR CHECKING IF TOKEN EXPIRED, TO REDUCE AMOUNT OF REQUESTS

local function GetAccessToken(id, secret)
    local tokenUrl = "https://accounts.spotify.com/api/token"

    local headers = {
        { "Content-Type",  "application/x-www-form-urlencoded" },
        { "Authorization", "Basic " .. base64.encode(id .. ':' .. secret) }
    }

    local body = "grant_type=client_credentials"

    -- Make the POST request to get the token
    local res, tokenResponse = http.request('POST', tokenUrl, headers, body)

    if res.code == 200 then
        -- Assuming the response is JSON with an access_token field
        local tokenData = json.decode(tokenResponse)
        return tokenData.access_token
    else
        -- Handle error: invalid response, no token, etc.
        print("Error obtaining access token:", res.reason)
        return nil
    end
end


function SpotifyHelper:GetNewAlbumReleases(days, limit)
    days = sMath.Clamp(days, 0, 30);
    limit = sMath.Clamp(limit, 0, 50);
    local url = "https://api.spotify.com/v1/browse/new-releases?limit=" .. limit;
    local token = GetAccessToken(self.clientID, self.clientSecret);
    local newReleases = {};
    if token ~= nil then
        local headers = {
            { "Content-Type",  "application/json" },
            { "Authorization", "Bearer " .. token }
        };
        local res, body = http.request('GET', url, headers);

        if res.code == 200 then
            local minDate = os.time() - (days * 24 * 60 * 60) -- days * hours * minutes * seconds
            local albumDate;
            local data = json.decode(body);

            if data ~= nil then
                for _, val in ipairs(data.albums.items) do
                    albumDate = sParser.StrToDate(val.release_date, "(%d+)-(%d+)-(%d+)");
                    if albumDate > minDate then
                        newReleases[#newReleases + 1] = val;
                    end
                end
            end
        end
    end

    return newReleases;
end

return SpotifyHelper;
