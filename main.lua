package.path = ";./lua_modules/share/lua/5.4/?.lua;" .. package.path;
package.cpath = ";./lua_modules/lib/lua/5.4/?.dll;" .. package.cpath;
package.path = ";./deps/?.lua;" .. package.path;
package.cpath = ";./deps/?/init.lua" .. package.cpath;
local discordia = require('discordia')
local client = discordia.Client()
local config = require('config');
local spotifyHelper = require("spotifyHelper");

local helper = spotifyHelper:new(config.SPOTIFY_CLIENT_ID);
client:on("ready", function()
	print('Logged in as '.. client.user.username)
	helper:GetNewAlbumReleases(5,50);
end)

client:on("messageCreate", function(message)
	if message.content == '!ping' then
		message.channel:send('Pong!')
	end
end)

client:run('Bot ' .. config.TOKEN);