local json = require("../deps/json");
local http = require("../deps/coro-http");
local sMath = require("./SigmaMath");
local sParser = require("./SigmaParser");
local urlHelper = require("./UrlHelper");
local tokenHelper = require("./AccessTokenHelper");
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

function SpotifyHelper:GetNewAlbumReleases(days, limit)
    days = sMath.Clamp(days, 0, 30);
    limit = sMath.Clamp(limit, 0, 50);
    local url = "https://api.spotify.com/v1/browse/new-releases?limit=" .. limit;
    local token = tokenHelper:GetBasicAuthorization(self.tokenEndPoint, self.clientID, self.clientSecret);
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
    local token = tokenHelper:GetBasicAuthorization(self.tokenEndPoint, self.clientID, self.clientSecret);
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
    local token = tokenHelper:GetBasicAuthorization(self.tokenEndPoint, self.clientID, self.clientSecret);
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
    local token = tokenHelper:GetBasicAuthorization(self.tokenEndPoint, self.clientID, self.clientSecret);
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
    local token = tokenHelper:GetBasicAuthorization(self.tokenEndPoint, self.clientID, self.clientSecret);
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
    local token = tokenHelper:GetBasicAuthorization(self.tokenEndPoint, self.clientID, self.clientSecret);
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
    local url = "https://api.spotify.com/v1/tracks/" .. trackID;
    local token = tokenHelper:GetBasicAuthorization(self.tokenEndPoint, self.clientID, self.clientSecret);
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
    local url = "https://api.spotify.com/v1/search";
    local token = tokenHelper:GetBasicAuthorization(self.tokenEndPoint, self.clientID, self.clientSecret);
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
