local discordia = require('./deps/discordia')
local client = discordia.Client()
local config = require('./config');
local spotifyHelper = require("./Helpers/SpotifyHelper"):new(config.SPOTIFY_CLIENT_ID, config.SPOTIFY_CLIENT_SECRET);
-- local chatGPTHelper = require("./Helpers/ChatGPTHelper"):new(config.CHATGPT_APIKEY);

local MAX_REPLIES = 10;
math.randomseed(os.time());

local function GetCommand(str)
	return string.match(str, "^%S+")
end
---@return table
local function GetArgs(str)
	local args = {}

	for arg in string.gmatch(str, "'([^']+)") do
		args[#args + 1] = arg:gsub("'", "");
	end
	return args
end



local prefix = "!";
local commands = {
	---@param args any need to specify
	[prefix .. "latestReleases"] = function(message, args)
		if args[1] == nil or args[1] == 0 then
			message:reply("You didn't specificed days (1-x)")
			return;
		end

		local releases = spotifyHelper:GetNewAlbumReleases(tonumber(args[1]), MAX_REPLIES)
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

			-- 1. Author -> Authors Name
			-- 2. Fields -> Tracks Count
			-- 3. Image -> Album Cover
			-- 4. Footer -> Release Date
			-- TODO: Find most dominant color in image and set it as color of embed
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
	[prefix .. "artistDiscography"] = function(message, args)
		if args[1] == nil or args[1] == "" then
			message:reply("Please specify what artist discography you want to get")
		end
		local artist = spotifyHelper:GetArtistByName(args[1]);
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
			title = "Discography",
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
	[prefix .. "albumInfo"] = function(message, args)
		if args[1] == nil or args[1] == "" then
			message:reply("Please specify what artist album you want to get")
		end
		-- print(chatGPTHelper:Ask("Give me fun fact about Kids See Ghosts", 5,
		-- 	"You're music evaluator, which gives answer which only contains text about what user asked, without any formalities"))
		local albumByNameData = spotifyHelper:GetAlbumByName(args[1]);
		local albumByIdData = spotifyHelper:GetAlbum(albumByNameData.id);

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
	[prefix .. "trackInformation"] = function(message, args)
		if args[1] == nil or args[1] == "" then
			message:reply("Please specify what track information you want to get")
		end
		local trackData = spotifyHelper:GetTrackByName(args[1]);
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
	end


}

client:on("ready", function()
	print('Logged in as ' .. client.user.username)
end)

client:on("messageCreate", function(message)
	local command = GetCommand(message.content);
	if commands[command] then
		local args = GetArgs(message.content:sub(#command + 1));
		commands[command](message, args);
	end
end)


client:run('Bot ' .. config.TOKEN);
