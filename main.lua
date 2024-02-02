local discordia = require('./deps/discordia')
local client = discordia.Client()
local config = require('./config');
local spotifyHelper = require("./spotifyHelper");

local helper = spotifyHelper:new(config.SPOTIFY_CLIENT_ID, config.SPOTIFY_CLIENT_SECRET);
local prefix = "!";

local function CreateReleasesNotification(releases)
	local selectedEmbeds = {};
	for i = 1, #releases, 1 do
		local getCreators = function()
			local output = {};
			for j, artist in ipairs(releases[i].artists) do
				output[#output + 1] = artist.name;
			end
			return table.concat(output, ',', 1, #output);
		end

		local creators = getCreators();
		local feats = function()
			local output = {};

			for j, item in ipairs(releases[i].tracks.items) do
				for k, artist in ipairs(item.artists) do
					output[artist] = true;
				end
			end
		end

		selectedEmbeds[#selectedEmbeds + 1] = {
			title = releases[i].name,
			url = releases[i].external_urls.spotify,
			author = {
				name = creators
			},
			fields = {
				{
					name = "Track Count",
					value = releases[i].total_tracks,
					inline = true,
				}
			}
		}
	end
	return selectedEmbeds;
end


client:on("ready", function()
	print('Logged in as ' .. client.user.username)
end)

client:on("messageCreate", function(message)
	if string.sub(message.content, 1, 1) == prefix then
		local command = string.sub(message.content, 2, #message.content);
		if command == 'newReleases' then
			message:reply {
				embeds = CreateReleasesNotification(helper:GetNewAlbumReleases(7, 50))
			}
			-- message:reply {
			-- 	embeds = {
			-- 		{
			-- 			title = "Embed Title",
			-- 			description = "Here is my fancy description!",
			-- 			author = {
			-- 				name = message.author.username,
			-- 				icon_url = message.author.avatarURL
			-- 			},
			-- 			fields = { -- array of fields
			-- 				{
			-- 					name = "Field 1",
			-- 					value = "This is some information",
			-- 					inline = true
			-- 				},
			-- 				{
			-- 					name = "Field 2",
			-- 					value = "This is some more information",
			-- 					inline = false
			-- 				}
			-- 			},
			-- 			footer = {
			-- 				text = "Created with Discordia"
			-- 			},
			-- 			color = 0x000000 -- hex color code
			-- 		},
			-- 		{
			-- 			title = "Embed Title",
			-- 			description = "Here is my fancy description!",
			-- 			author = {
			-- 				name = message.author.username,
			-- 				icon_url = message.author.avatarURL
			-- 			},
			-- 			fields = { -- array of fields
			-- 				{
			-- 					name = "Field 1",
			-- 					value = "This is some information",
			-- 					inline = true
			-- 				},
			-- 				{
			-- 					name = "Field 2",
			-- 					value = "This is some more information",
			-- 					inline = false
			-- 				}
			-- 			},
			-- 			footer = {
			-- 				text = "Created with Discordia"
			-- 			},
			-- 			color = 0x000000 -- hex color code
			-- 		}

			-- 	}
			-- }
		end
	end
end)


client:run('Bot ' .. config.TOKEN);
