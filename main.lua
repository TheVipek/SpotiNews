local discordia = require('./deps/discordia')
local client = discordia.Client()
local config = require('./config');
local spotifyHelper = require("./Helpers/SpotifyHelper");

local helper = spotifyHelper:new(config.SPOTIFY_CLIENT_ID, config.SPOTIFY_CLIENT_SECRET);
local MAX_REPLIES = 10;
---@param str string
---@return table
local function GetArgs(str)
	local args = {};
	for arg in string.gmatch(str, "%S+") do
		args[#args + 1] = arg;
	end
	return args;
end

---@param releases table from SpotifyHelper
---@return table
local function CreateReleasesAsEmbeds(releases)
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
	return selectedEmbeds;
end

local prefix = "!";
local commands = {
	[prefix .. "newReleases"] = function(message, args)
		if args.days == nil or args.days == 0 then
			message:reply("You didn't specificed days (1-x)")
			return;
		end
		local releasesAsEmbeds = CreateReleasesAsEmbeds(helper:GetNewAlbumReleases(args.days, MAX_REPLIES));
		if #releasesAsEmbeds > 0 then
			message:reply {
				embeds = releasesAsEmbeds
			}
		else
			message:reply("Couldn't find any new releases");
		end
	end

}

client:on("ready", function()
	print('Logged in as ' .. client.user.username)
end)

client:on("messageCreate", function(message)
	local args = GetArgs(message.content);
	if commands[args[1]] then
		commands[args[1]](message, { days = tonumber(args[2]) });
	end
end)


client:run('Bot ' .. config.TOKEN);
