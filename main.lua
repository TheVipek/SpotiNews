local client = require('./deps/discordia').Client();
local config = require('./config');
local commands = require('./libs/commands');
local commandsUtils = require('./libs/commandsUtils');

client:on("messageCreate", function(message)
	local command = commandsUtils.GetCommand(message.content);
	if commands[command] then
		local args = commandsUtils.GetArgs(message.content:sub(#command + 1));
		local status, error = pcall(commands[command].call, message, args);
		if not status then
			message:reply(error .. " (Remember that when you specify arguments you need to use '' ex. 'Music')")
		end
	end
end)


client:run('Bot ' .. config.DISCORD_TOKEN);
