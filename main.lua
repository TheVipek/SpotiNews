local discordia = require('./deps/discordia')
local client = discordia.Client()
local config = require('./config');
local spotifyHelper = require("./Helpers/SpotifyHelper");

local helper = spotifyHelper:new(config.SPOTIFY_CLIENT_ID, config.SPOTIFY_CLIENT_SECRET);
local MAX_REPLIES = 10;

local function GetCommand(str)
	return string.match(str, "^%S+")
end

---@return table
local function GetArgs(str)
	local args = {}

	for arg in string.gmatch(str, "%S+") do
		args[#args + 1] = arg:gsub("'", "");
	end
	return args
end



local prefix = "!";
local commands = {
	---@param args any need to specify
	[prefix .. "newReleases"] = function(message, args)
		if args[1] == nil or args[1] == 0 then
			message:reply("You didn't specificed days (1-x)")
			return;
		end

		local releases = helper:GetNewAlbumReleases(tonumber(args[1]), MAX_REPLIES)
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
				}
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
	[prefix .. "getArtistDiscography"] = function(message, args)
		if args[1] == nil or args[1] == "" then
			message:reply("Please specify what artist discography you want to get")
		end
		local artist = helper:GetArtistByName(args[1]);
		local getImageUrl = function()
			if artist.images[1] ~= nil then
				return {
					url = artist.images[1].url,
					--height = artist.images[1].images[1].height,
					--width = artist.images[1].images[1].width
					height = 100,
					width = 100
				}
			end
			return {
				url = "",
				height = 0,
				width = 0
			}
		end
		local getReleasedAlbums = function()
			local fields = {};
			local artistAlbums = helper:GetArtistAlbums(artist.id);
			for _, value in ipairs(artistAlbums.items) do
				fields[#fields + 1] = {
					name = "[" .. value.album_type .. "] " .. value.name,
					value = value.release_date,
					inline = false
				}
			end

			return fields;
		end
		getReleasedAlbums();
		local embed = {
			title = "Discography",
			--url = "",
			author =
			{
				name = artist.name,
				url = artist.external_urls.spotify
			},
			image = getImageUrl(),
			fields = getReleasedAlbums(),
			footer = {
				text = "Albums found on Spotify"
			}
		}
		print(message);
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
		local args = GetArgs(message.content:sub(#command + 2));

		commands[command](message, args);
	end
end)


client:run('Bot ' .. config.TOKEN);
