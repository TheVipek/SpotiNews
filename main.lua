local discordia = require('./deps/discordia')
local client = discordia.Client()
local config = require('./config');
local spotifyHelper = require("./spotifyHelper");

local helper = spotifyHelper:new(config.SPOTIFY_CLIENT_ID, config.SPOTIFY_CLIENT_SECRET);
client:on("ready", function()
	print('Logged in as ' .. client.user.username)
end)

client:on("messageCreate", function(message)
	if message.content == '!newReleases' then
		local releases = helper:GetNewAlbumReleases(7, 50);
		for i = 1, #releases, 1 do
			message:reply(releases[i].name);
		end
	end
end)

client:run('Bot ' .. config.TOKEN);
