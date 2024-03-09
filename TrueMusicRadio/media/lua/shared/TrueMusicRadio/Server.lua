if isClient() then 
	return 
end

TMRadioServer = {}

TMRadioServer.PlaylistTerminalA = {}

TMRadioServer.PlaylistTerminalB = {}

TMRadioServer.PlaylistGlobal = {}

TMRadioServer.Channels = {}

TMRadioServer.CreatePlaylist = function()
	local tempGlobalPlaylist = {}

	for k,v in pairs(GlobalMusic) do
    		tempGlobalPlaylist[#tempGlobalPlaylist + 1] = k
	end

	--print("TMRadio: Created a new GlobalTrueMusic playlist")
	return tempGlobalPlaylist
end

TMRadioServer.SendServerCommandToClients = function(command, args)
	if not isClient() and not isServer() then
		triggerEvent("OnServerCommand", "TMRadio", command, args) -- Singleplayer
	else
		sendServerCommand("TMRadio", command, args) -- Multiplayer
	end
end

TMRadioServer.Play = function(player, args)
	if #TMRadioServer.PlaylistTerminalA == 0 then
		TMRadioServer.PlaylistTerminalA = ModData.getOrCreate("TMRadioA")
	end
	if #TMRadioServer.PlaylistTerminalB == 0 then
		TMRadioServer.PlaylistTerminalB = ModData.getOrCreate("TMRadioB")
	end
	if #TMRadioServer.PlaylistTerminalA == 0 then
		TMRadioServer.PlaylistTerminalA = TMRadioServer.CreatePlaylist()
		ModData.add("TMRadioA", TMRadioServer.PlaylistTerminalA)
	end
	if #TMRadioServer.PlaylistTerminalB == 0 then
		TMRadioServer.PlaylistTerminalB = TMRadioServer.CreatePlaylist()
		ModData.add("TMRadioB", TMRadioServer.PlaylistTerminalB)
	end
	if #TMRadioServer.PlaylistGlobal == 0 then
		TMRadioServer.PlaylistGlobal = TMRadioServer.CreatePlaylist()
	end
	if not TMRadioServer.Channels[args.channel] then
		--print("TMRadio: adding channel to channel list")
		TMRadioServer.Channels[args.channel] = args.number
	else
		--print("TMRadio: song already attached to current channel list, send it to the client")
		args.number = TMRadioServer.Channels[args.channel]
	end
	ModData.add("TMRadioChannels", TMRadioServer.Channels)
	--print("TMRadio: Server needs to send play to clients")
	TMRadioServer.SendServerCommandToClients("Play", args)
end

TMRadioServer.Stop = function(player, args)
	--print("TMRadio: Server needs to send stop to clients")
	TMRadioServer.SendServerCommandToClients("Stop", args)
end

TMRadioServer.PlayNext = function(player, args)
	if #TMRadioServer.PlaylistTerminalA == 0 then
		TMRadioServer.PlaylistTerminalA = ModData.getOrCreate("TMRadioA")
	end
	if #TMRadioServer.PlaylistTerminalB == 0 then
		TMRadioServer.PlaylistTerminalB = ModData.getOrCreate("TMRadioB")
	end
	if #TMRadioServer.PlaylistTerminalA == 0 then
		TMRadioServer.PlaylistTerminalA = TMRadioServer.CreatePlaylist()
		ModData.add("TMRadioA", TMRadioServer.PlaylistTerminalA)
	end
	if #TMRadioServer.PlaylistTerminalB == 0 then
		TMRadioServer.PlaylistTerminalB = TMRadioServer.CreatePlaylist()
		ModData.add("TMRadioB", TMRadioServer.PlaylistTerminalB)
	end
	if #TMRadioServer.PlaylistGlobal == 0 then
		TMRadioServer.PlaylistGlobal = TMRadioServer.CreatePlaylist()
	end
	TMRadioServer.Channels[args.channel] = args.number
	ModData.add("TMRadioChannels", TMRadioServer.Channels)
	--print("TMRadio: Server needs to send playnext to clients")
	TMRadioServer.SendServerCommandToClients("PlayNext", args)
end

TMRadioServer.UpdatePlaylistTerminalA = function(player, args)
	if args.request == true then
		--print("Server: Client requesting A")
		if #TMRadioServer.PlaylistTerminalA == 0 then
			--print("Server: A not found, pull from moddata")
			TMRadioServer.PlaylistTerminalA = ModData.getOrCreate("TMRadioA")
		end
		if #TMRadioServer.PlaylistTerminalA == 0 then
			--print("Server: A still not found, create default list")
			TMRadioServer.PlaylistTerminalA = TMRadioServer.CreatePlaylist()
		end
	else
		--print("Server: Updating A from client")
		TMRadioServer.PlaylistTerminalA = args
	end
	ModData.add("TMRadioA", TMRadioServer.PlaylistTerminalA)
	ModData.transmit("TMRadioA", TMRadioServer.PlaylistTerminalA)	
	--print("Server: updated A send to clients")
	TMRadioServer.SendServerCommandToClients("UpdatePlaylistTerminalA", TMRadioServer.PlaylistTerminalA)
end

TMRadioServer.UpdatePlaylistTerminalB = function(player, args) 
	if args.request == true then
		--print("Server: Client requesting B")
		if #TMRadioServer.PlaylistTerminalB == 0 then
			--print("Server: B not found, pull from moddata")
			TMRadioServer.PlaylistTerminalB = ModData.getOrCreate("TMRadioB")
		end
		if #TMRadioServer.PlaylistTerminalB == 0 then
			--print("Server: B still not found, create default list")
			TMRadioServer.PlaylistTerminalB = TMRadioServer.CreatePlaylist()
		end
	else
		--print("Server: Updating B from client")
		TMRadioServer.PlaylistTerminalB = args
	end
	ModData.add("TMRadioB", TMRadioServer.PlaylistTerminalB)
	ModData.transmit("TMRadioB", TMRadioServer.PlaylistTerminalB)
	--print("Server: updated B send to clients")
	TMRadioServer.SendServerCommandToClients("UpdatePlaylistTerminalB", TMRadioServer.PlaylistTerminalB)
end

TMRadioServer.UpdateChannels = function(player, args) 
	if args.request == true then
		--print("Server: Client requesting channels")
		if #TMRadioServer.PlaylistGlobal == 0 then
			TMRadioServer.PlaylistGlobal = TMRadioServer.CreatePlaylist()
		end
		TMRadioServer.Channels = ModData.getOrCreate("TMRadioChannels")
		if TMRadioServer.Channels[94000] == nil or TMRadioServer.Channels[94000] > #TMRadioServer.PlaylistTerminalA then
			TMRadioServer.Channels[94000] = ZombRand(1, #TMRadioServer.PlaylistTerminalA)
		end
		if TMRadioServer.Channels[94200] == nil or TMRadioServer.Channels[94200] > #TMRadioServer.PlaylistTerminalB then
			TMRadioServer.Channels[94200] = ZombRand(1, #TMRadioServer.PlaylistTerminalB)
		end
		if TMRadioServer.Channels[94400] == nil or TMRadioServer.Channels[94400] > #TMRadioServer.PlaylistGlobal then
			TMRadioServer.Channels[94400] = ZombRand(1, #TMRadioServer.PlaylistGlobal)
		end
		if TMRadioServer.Channels[94600] == nil or TMRadioServer.Channels[94600] > #TMRadioServer.PlaylistGlobal then
			TMRadioServer.Channels[94600] = ZombRand(1, #TMRadioServer.PlaylistGlobal)
		end
		if TMRadioServer.Channels[94800] == nil or TMRadioServer.Channels[94800] > #TMRadioServer.PlaylistGlobal then
			TMRadioServer.Channels[94800] = ZombRand(1, #TMRadioServer.PlaylistGlobal)
		end
		--print("Server: Updated channels send to clients")
		--print("94: " ..  TMRadioServer.Channels[94000])
		--print("94.2: " ..  TMRadioServer.Channels[94200])
		--print("94.4: " ..  TMRadioServer.Channels[94400])
		--print("94.6: " ..  TMRadioServer.Channels[94600])
		--print("94.8: " ..  TMRadioServer.Channels[94800])
		ModData.add("TMRadioChannels", TMRadioServer.Channels)
		TMRadioServer.SendServerCommandToClients("UpdateChannels", TMRadioServer.Channels)
	end
end

TMRadioServer.OnClientCommand = function(module, command, player, args)
    	if not (module == "TMRadio" and TMRadioServer[command]) then
		return
	end
	print("TMRadio: Server getting a " .. command .. " from a client.")
	TMRadioServer[command](player, args)
end

Events.OnClientCommand.Add(TMRadioServer.OnClientCommand)

TMRadioServer.OnReceiveGlobalModData = function(module, args)
	if not args then
		return
	end
	
    	if module == "TMRadioA" then
		TMRadioServer.PlaylistTerminalA = args
		ModData.add("TMRadioA", TMRadioServer.PlaylistTerminalA)
		ModData.transmit("TMRadioA", TMRadioServer.PlaylistTerminalA)	
	elseif module == "TMRadioB" then
		TMRadioServer.PlaylistTerminalB = args
		ModData.add("TMRadioB", TMRadioServer.PlaylistTerminalB)
		ModData.transmit("TMRadioB", TMRadioServer.PlaylistTerminalB)		
	end
end

Events.OnReceiveGlobalModData.Add(TMRadioServer.OnReceiveGlobalModData)

return TMRadioServer