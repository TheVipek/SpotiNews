local config = require('../config');
local spotifyHelper = require("../Helpers/SpotifyHelper"):new(config.SPOTIFY_CLIENT_ID, config.SPOTIFY_CLIENT_SECRET);
local chatGPTHelper = require("../Helpers/ChatGPTHelper"):new(config.CHATGPT_APIKEY);
math.randomseed(os.time());

-- Sends a prompt to ChatGPT and returns the answer. Errors if API key setup is incorrect.
local function AskChatGPT(prompt, systemInfo)
    local answer = chatGPTHelper:Ask(prompt, systemInfo);
    if answer.code ~= 200 then
        error("To get ChatGPT Answer please setup correctly APIKEY in config.lua", 2);
    end
    return answer.value;
end

-- Executes a Spotify API request using the specified method and arguments. Errors if credentials are incorrect.
local function SpotifyRequest(obj, method, ...)
    local data = method(obj, ...);
    if data == nil then
        error("To use Spotify API, please setup correctly client id and secret in config.lua", 3);
    end
    return spotifyHelper;
end

local prefix = "!";

-- Defines commands for a Discord bot, mapping each command to its functionality and description.
local commands = {
    [prefix .. "latestReleases"] =
    {
        call = function(message, args)
            if args[1] == nil or args[1] == 0 then
                error("Specify days", 2);
            end
            message:reply("Looking for releases from past " .. args[1] .. " days...");
            local releases = SpotifyRequest(spotifyHelper, spotifyHelper.GetNewAlbumReleases, tonumber(args[1]),
                config.MAX_EMBED_REPLIES);
            local selectedEmbeds = {};
            for i = 1, #releases, 1 do
                local getCreatorsName = function()
                    local output = {};
                    for _, artist in ipairs(releases[i].artists) do
                        output[#output + 1] = artist.name;
                    end
                    return {
                        name = table.concat(output, ',', 1, #output)
                    };
                end
                local getImageUrl = function()
                    if releases[i].images[1] ~= nil then
                        return {
                            url = releases[i].images[1].url,
                            height = releases[i].images[1].height,
                            width = releases[i].images[1].width
                        }
                    end
                    return {
                        url = "",
                        height = 0,
                        width = 0
                    }
                end

                selectedEmbeds[#selectedEmbeds + 1] = {
                    title = releases[i].name,
                    url = releases[i].external_urls.spotify ~= nil and releases[i].external_urls.spotify or "",
                    author = getCreatorsName(),
                    fields = {
                        {
                            name = "Track Count",
                            value = releases[i].total_tracks,
                            inline = true,
                        }
                    },
                    image = getImageUrl(),
                    footer = {
                        text = "Release Date \n" .. releases[i].release_date,
                    },
                    color = math.random(0, 0xFFFFFF),
                }
            end

            if #selectedEmbeds > 0 then
                message:reply {
                    embeds = selectedEmbeds
                }
            else
                message:reply("Couldn't find any new releases");
            end
        end,
        description = "This command lets you get latest releases => _Arg: amount of days_"
    },
    [prefix .. "artistDiscography"] =
    {
        call = function(message, args)
            if args[1] == nil or args[1] == "" then
                error("Specify artist", 2);
            end
            message:reply("Looking for data about " .. '"' .. args[1] .. '"' .. " discography...");
            local desc = AskChatGPT("Give me description for " .. args[1] .. " discography.",
                "You're music veteran. Please format it correctly.Few sentences maximum.");

            local artist = SpotifyRequest(spotifyHelper, spotifyHelper.GetArtistByName, args[1]);
            -- local artist = SpotifyRequest(spotifyHelper:GetArtistByName(args[1]));
            local getReleasedAlbums = function()
                local artistAlbums = spotifyHelper:GetArtistAlbums(artist.id);
                local fields = {};
                for _, value in ipairs(artistAlbums.items) do
                    if value.album_type ~= "single" then
                        fields[#fields + 1] = {
                            name = "**" .. value.release_date .. "**",
                            value = "[" ..
                                value.name ..
                                "](" ..
                                value.external_urls.spotify ..
                                ")" .. "\u{2003}" .. "(" .. "[cover](" .. value.images[1].url .. ")" .. ")"
                        }
                    end

                    --Discord LIMIT
                    if #fields == 25 then
                        break;
                    end
                end
                return fields;
            end
            getReleasedAlbums();
            local embed = {
                description = desc,
                author =
                {
                    name = artist.name,
                    url = artist.external_urls.spotify,
                    icon_url = artist.images[1].url
                },
                fields = getReleasedAlbums(),
                footer = {
                    text = "Albums found on Spotify"
                },
                color = math.random(0, 0xFFFFFF),
            }
            message:reply {
                embed = embed
            }
        end,
        description = "This command lets you get artist discography => _Arg: name of artist_"
    },
    [prefix .. "albumInfo"] =
    {
        call = function(message, args)
            if args[1] == nil or args[1] == "" then
                error("Specify album", 2);
            end
            message:reply("Looking for informations about " .. '"' .. args[1] .. '"' .. " album...");

            local albumByNameData = SpotifyRequest(spotifyHelper, spotifyHelper.GetAlbumByName, args[1]);
            local albumByIdData = SpotifyRequest(spotifyHelper, spotifyHelper.GetAlbum, albumByNameData.id);
            -- local albumByNameData = SpotifyRequest(spotifyHelper:GetAlbumByName(args[1]));
            -- local albumByIdData = SpotifyRequest(spotifyHelper:GetAlbum(albumByNameData.id));
            local desc = AskChatGPT("Give me description for " .. albumByNameData.name,
                "You're music veteran. Please format it correctly.Few sentences maximum.");

            local getAlbumTracklist = function()
                local fields = {};
                for idx, track in ipairs(albumByIdData.tracks.items) do
                    local msToSec = tonumber(track.duration_ms) / 1000;
                    fields[#fields + 1] = {
                        name = idx .. "." .. "**" .. track.name .. "**",
                        value = tostring(math.floor(msToSec / 60) .. ":" .. math.floor(msToSec % 60))
                    }
                    --Discord LIMIT
                    if #fields == 25 then
                        break;
                    end
                end

                return fields;
            end

            local embed = {
                author =
                {
                    name = albumByNameData.name,
                    url = albumByNameData.external_urls.spotify,
                    icon_url = albumByNameData.images[1].url
                },
                description = desc,
                fields = getAlbumTracklist(),
                footer = {
                    text = albumByNameData.release_date .. "\n" .. albumByIdData.label
                },
                color = math.random(0, 0xFFFFFF)
            }
            message:reply {
                embed = embed
            }
        end,
        description = "This command lets you get informations about album => _Arg: name of album_"
    },
    [prefix .. "trackInfo"] =
    {
        call = function(message, args)
            if args[1] == nil or args[1] == "" then
                error("Specify track", 2);
                return;
            end
            message:reply("Looking for informations about " .. '"' .. args[1] .. '"' .. " track...");

            local trackData = SpotifyRequest(spotifyHelper, spotifyHelper.GetTrackByName, args[1]);
            -- local trackData = SpotifyRequest(spotifyHelper:GetTrackByName(args[1]));
            local desc = AskChatGPT(
                "Give me interesting facts about song named " .. trackData.name,
                "You're music veteran. Please format it correctly.Few sentences maximum.");

            local msToSec = tonumber(trackData.duration_ms) / 1000;
            local minutes = math.floor(msToSec / 60);
            local seconds = math.floor(msToSec % 60);
            local formatedSeconds = (seconds < 10) and "0" .. seconds or seconds;
            local getCreatorsName = function()
                local output = {};
                for _, artist in ipairs(trackData.artists) do
                    output[#output + 1] = "[" .. artist.name .. "](" .. artist.external_urls.spotify .. ")";
                end
                return {
                    name = table.concat(output, ',', 1, #output)
                };
            end

            local embed = {
                author =
                {
                    name = trackData.name,
                    url = trackData.external_urls.spotify,
                    icon_url = trackData.album.images[1].url
                },
                description = desc,
                fields = {
                    {
                        name = "Author",
                        value = getCreatorsName().name
                    },
                    {
                        name = "Release Date",
                        value = trackData.album.release_date
                    },
                    {
                        name = "Duration",
                        value = tostring(minutes .. ":" .. formatedSeconds)
                    }
                },
                color = math.random(0, 0xFFFFFF)
            }
            message:reply {
                embed = embed
            }
        end,
        description = "This command lets you get informations about track => _Arg: name of track_"
    },
    [prefix .. "lyrics"] =
    {
        call = function(message, args)
            error("Functionality not implemented.", 2);
            if args[1] == nil or args[1] == "" then
                message:reply("Please specify what track lyrics you want to get")
            end
            -- "You're music evaluator, which gives answer which only contains text about what user asked, without any formalities. Keep it in 3 sentences maximum"
            message:reply("If answer won't be appropriate,please give more information. Thinking...");
            local lyrics = AskChatGPT("Give me lyrics for " .. args[1] .. "",
                "Response only with song lyrics.Please format it correctly");
            local embed = {
                field = {
                    name = "LYRICS for " .. args[1],
                    value = lyrics
                },
                color = math.random(0, 0xFFFFFF)
            }
            message:reply {
                embed = embed
            }
        end,
        description =
        "~~This command lets you get informations about lyrics => Arg: name of track (for better results you can add name of artist)~~ UNAVALIABLE"
    },
    [prefix .. "facts"] =
    {
        call = function(message, args)
            if args[1] == nil or args[1] == "" then
                error("Specify topic", 2);
            end
            message:reply("If answer won't be appropriate,please provide more data.Searching for " .. '"' ..
                args[1] .. '"' .. " facts...");
            local info = AskChatGPT("Give me interestring facts / trivia about" .. args[1],
                "You're music veteran.Please format it correctly.Keep it in few sentences.");
            local embed = {
                author = {
                    name = "Facts about " .. args[1]
                },
                description = info,
                color = math.random(0, 0xFFFFFF)
            }
            message:reply {
                embed = embed
            }
        end,
        description = "This command lets you get music facts and trivia => _Arg: music topic which you want to explore_"
    },
    [prefix .. "genreRecommendations"] =
    {
        call = function(message, args)
            if args[1] == nil or args[1] == "" then
                error("Specify genres", 2);
            end
            message:reply("If answer won't be appropriate,please provide more data.Searching for " .. '"' ..
                args[1] .. '"' .. " recommendations...");
            local info = AskChatGPT(
                "Give me genres i could like.The ones that i enjoy: " ..
                args[1] .. " If you find any, tell me why i could like them",
                "You're music veteran.Please format it correctly.Keep it in 10 sentences maximum.");
            local embed = {
                author = {
                    name = "Genre Recommendations"
                },
                description = info,
                color = math.random(0, 0xFFFFFF)
            }
            message:reply {
                embed = embed
            }
        end,
        description =
        "This command lets you get genre recommendations with quick summary why you might like them => _Arg: genres that you listen to_"
    },
    [prefix .. "musicJoke"] =
    {
        call = function(message, args)
            local response;
            if args[1] == nil or args[1] == "" then
                message:reply("You didn't specified about what you want to hear joke.Looking for random...");
                response = AskChatGPT(
                    "Please tell me music joke",
                    "You're comedian.Please format it correctly.Maximum few sentences.");
            else
                message:reply("If answer won't be appropriate,please provide more data.Searching for joke about " ..
                    '"' ..
                    args[1] .. '"' .. "...");
                response = AskChatGPT(
                    "Please tell me music joke about" .. args[1],
                    "You're comedian and your jokes focus on music industry, surrounding it topics."
                    .. "Please format it correctly.Maximum few sentences.");
            end
            local embed = {
                author = {
                    name = "Music Joke"
                },
                description = response,
                color = math.random(0, 0xFFFFFF)
            }
            message:reply {
                embed = embed
            }
        end,
        description =
        "This command lets you get music joke => _Arg: (*optional) topic about which you want to hear joke_"
    },
    [prefix .. "help"] =
    {
        call = function(message, args)
            message:reply { embed = {
                title = "**COMMANDS**",
                fields = GetCommandsDescription(),
            } };
        end,
        description = "This command lets you display all commands",
    }
}

-- Generates and returns descriptions for all available commands for the help menu.
function GetCommandsDescription()
    local fields = {};
    for k, v in pairs(commands) do
        fields[#fields + 1] = {
            name = "**" .. k .. "**",
            value = v.description
        }
    end
    return fields;
end

return commands;
