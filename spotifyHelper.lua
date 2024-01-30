local json = require("dkjson");
local http = require("coro-http");
local sMath = require("SigmaMath");

SpotifyHelper = {}

function SpotifyHelper:new(id)
    local obj = {};
    setmetatable(obj, self);
    self.__index = self;
    self.clientID = id;
    return obj;
end

function SpotifyHelper:GetNewAlbumReleases(days, limit)
    print("Lua Version:", _VERSION);
    days = sMath.Clamp(days,0, 30);
    limit = sMath.Clamp(limit,0, 50);
    local url = "https://api.spotify.com/v1/browse/new-releases?limit="..limit;
    local headers = {
        {"Content-Type", "application/json"},
        {"Authorization", "Bearer " .. self.clientID}
    };
    local res, body = http.request('GET', url, headers);

    print(res.code, res.reason);
    print(body);

end


return SpotifyHelper;