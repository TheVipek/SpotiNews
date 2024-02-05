local json = require("../lua_modules/share/lua/5.4/dkjson");
local http = require("../deps/coro-http");
local sMath = require("./SigmaMath");
local sParser = require("./SigmaParser");
local base64 = require("../deps/base64");
local urlHelper = require("./UrlHelper");
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

    local res, tokenResponse = http.request('POST', tokenUrl, headers, body)

    if res.code == 200 then
        local tokenData = json.decode(tokenResponse)
        return tokenData.access_token
    else
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

function SpotifyHelper:GetArtist(artistID)
    local url = "https://api.spotify.com/v1/artists/" .. artistID;
    local token = GetAccessToken(self.clientID, self.clientSecret);
    if token ~= nil then
        local headers = {
            { "Content-Type",  "application/json" },
            { "Authorization", "Bearer " .. token }
        };
        local res, body = http.request('GET', url, headers);

        if res.code == 200 then
            return json.decode(body);
        end
    end

    return nil;
end

function SpotifyHelper:GetArtistByName(artistName)
    local url = "https://api.spotify.com/v1/search";
    local token = GetAccessToken(self.clientID, self.clientSecret);
    if token ~= nil then
        local headers = {
            { "Content-Type",  "application/json" },
            { "Authorization", "Bearer " .. token }
        };

        local params = urlHelper:urlEscape("artist:" .. artistName);
        url = url .. "?q=" .. params .. "&type=artist";
        local res, body = http.request('GET', url, headers);
        if res.code == 200 then
            local data = json.decode(body);
            return data.artists.items[1] ~= nil and data.artists.items[1] or nil;
        end
    end

    return nil;
end

function SpotifyHelper:GetArtistAlbums(artistID)
    local url = "https://api.spotify.com/v1/artists/" .. artistID .. "/albums";
    local token = GetAccessToken(self.clientID, self.clientSecret);
    if token ~= nil then
        local headers = {
            { "Content-Type",  "application/json" },
            { "Authorization", "Bearer " .. token }
        };
        local res, body = http.request('GET', url, headers);
        if res.code == 200 then
            return json.decode(body);
        end
    end

    return nil;
end

function SpotifyHelper:GetAlbum(albumID)
    local url = "https://api.spotify.com/v1/albums/" .. albumID;
    local token = GetAccessToken(self.clientID, self.clientSecret);
    if token ~= nil then
        local headers = {
            { "Content-Type",  "application/json" },
            { "Authorization", "Bearer " .. token }
        };
        local res, body = http.request('GET', url, headers);
        if res.code == 200 then
            return json.decode(body);
        end
    end

    return nil;
end

function SpotifyHelper:GetAlbumByName(albumName)
    local url = "https://api.spotify.com/v1/search";
    local token = GetAccessToken(self.clientID, self.clientSecret);
    if token ~= nil then
        local headers = {
            { "Content-Type",  "application/json" },
            { "Authorization", "Bearer " .. token }
        };

        local params = urlHelper:urlEscape("album:" .. albumName);
        url = url .. "?q=" .. params .. "&type=album";
        local res, body = http.request('GET', url, headers);
        if res.code == 200 then
            local data = json.decode(body);
            return data.albums.items[1] ~= nil and data.albums.items[1] or nil;
        end
    end

    return nil;
end

function SpotifyHelper:GetTrack(trackID)

end

function SpotifyHelper:GetTrackByName(trackName)

end

return SpotifyHelper;
