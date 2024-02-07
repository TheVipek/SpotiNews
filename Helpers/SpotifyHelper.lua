local json = require("../deps/json");
local http = require("../deps/coro-http");
local sMath = require("./SigmaMath");
local sParser = require("./SigmaParser");
local urlHelper = require("./UrlHelper");
local base64 = require("../deps/base64");
SpotifyHelper = {}

function SpotifyHelper:new(id, secret)
    local obj = {};
    setmetatable(obj, self);
    self.__index = self;
    self.clientSecret = secret;
    self.clientID = id;
    self.tokenEndPoint = "https://accounts.spotify.com/api/token";
    return obj;
end

local function Authorize(endpoint, id, secret)
    local headers = {
        { "Content-Type",  "application/x-www-form-urlencoded" },
        { "Authorization", "Basic " .. base64.encode(id .. ':' .. secret) }
    }

    local body = "grant_type=client_credentials"

    local res, tokenResponse = http.request('POST', endpoint, headers, body)
    if res.code == 200 then
        local tokenData = json.decode(tokenResponse);
        return { code = res.code, value = tokenData.access_token };
    else
        return { code = res.code, value = "" };
    end
end

function SpotifyHelper:GetNewAlbumReleases(days, limit)
    days = sMath.Clamp(days, 0, 30);
    limit = sMath.Clamp(limit, 0, 50);
    local tokenResult = Authorize(self.tokenEndPoint, self.clientID, self.clientSecret);
    if tokenResult.code ~= 200 then
        return nil;
    end
    local token = tokenResult.value;
    local newReleases = {};
    if token ~= nil then
        local url = "https://api.spotify.com/v1/browse/new-releases?limit=" .. limit;
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
    local tokenResult = Authorize(self.tokenEndPoint, self.clientID, self.clientSecret);
    if tokenResult.code ~= 200 then
        return nil;
    end
    local token = tokenResult.value;
    local url = "https://api.spotify.com/v1/artists/" .. artistID;
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
    local tokenResult = Authorize(self.tokenEndPoint, self.clientID, self.clientSecret);
    if tokenResult.code ~= 200 then
        return nil;
    end
    local token = tokenResult.value;
    local url = "https://api.spotify.com/v1/search";
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
    local tokenResult = Authorize(self.tokenEndPoint, self.clientID, self.clientSecret);
    if tokenResult.code ~= 200 then
        return nil;
    end
    local token = tokenResult.value;
    local url = "https://api.spotify.com/v1/artists/" .. artistID .. "/albums";
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
    local tokenResult = Authorize(self.tokenEndPoint, self.clientID, self.clientSecret);
    if tokenResult.code ~= 200 then
        return nil;
    end
    local token = tokenResult.value;
    local url = "https://api.spotify.com/v1/albums/" .. albumID;
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
    local tokenResult = Authorize(self.tokenEndPoint, self.clientID, self.clientSecret);
    if tokenResult.code ~= 200 then
        return nil;
    end
    local token = tokenResult.value;
    local url = "https://api.spotify.com/v1/search";
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
    local tokenResult = Authorize(self.tokenEndPoint, self.clientID, self.clientSecret);
    if tokenResult.code ~= 200 then
        return nil;
    end
    local token = tokenResult.value;
    local url = "https://api.spotify.com/v1/tracks/" .. trackID;
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
end

function SpotifyHelper:GetTrackByName(trackName)
    local tokenResult = Authorize(self.tokenEndPoint, self.clientID, self.clientSecret);
    if tokenResult.code ~= 200 then
        return nil;
    end
    local url = "https://api.spotify.com/v1/search";
    local token = tokenResult.value;
    if token ~= nil then
        local headers = {
            { "Content-Type",  "application/json" },
            { "Authorization", "Bearer " .. token }
        };

        local params = urlHelper:urlEscape("track:" .. trackName);
        url = url .. "?q=" .. params .. "&type=track";
        local res, body = http.request('GET', url, headers);
        if res.code == 200 then
            local data = json.decode(body);
            return data.tracks.items[1] ~= nil and data.tracks.items[1] or nil;
        end
    end

    return nil;
end

return SpotifyHelper;
