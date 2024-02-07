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

-- Authorizes with Spotify API using client credentials to obtain an access token.
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

-- Fetches new album releases within a specified timeframe and limit.
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

-- Retrieves details for a specific artist by their Spotify ID.
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

-- Searches for an artist by name and returns their details.
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

-- Fetches albums for a given artist by their Spotify ID.
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

-- Retrieves details of a specific album by its Spotify ID.
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

-- Searches for an album by name and returns its details.
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

-- Retrieves details of a specific track by its Spotify ID.
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

-- Searches for a track by name and returns its details.
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
