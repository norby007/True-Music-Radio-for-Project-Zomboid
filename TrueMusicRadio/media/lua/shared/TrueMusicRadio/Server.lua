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

TMRadioServer.Play = function(args)
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
	--print("TMRadio: Server needs to send play to clients")
	TMRadioServer.SendServerCommandToClients("Play", args)
end

TMRadioServer.PlayNext = function(args)
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
	--print("TMRadio: Server needs to send playnext to clients")
	TMRadioServer.SendServerCommandToClients("PlayNext", args)
end

TMRadioServer.UpdatePlaylistTerminalA = function(args)
	if args.request == true then
		if #TMRadioServer.PlaylistTerminalA == 0 then
			TMRadioServer.PlaylistTerminalA = ModData.getOrCreate("TMRadioA")
		end
		if #TMRadioServer.PlaylistTerminalA == 0 then
			TMRadioServer.PlaylistTerminalA = TMRadioServer.CreatePlaylist()
		end
	else
		TMRadioServer.PlaylistTerminalA = args
	end
	ModData.add("TMRadioA", TMRadioServer.PlaylistTerminalA)
	ModData.transmit("TMRadioA", TMRadioServer.PlaylistTerminalA)	
	TMRadioServer.SendServerCommandToClients("UpdatePlaylistTerminalA", TMRadioServer.PlaylistTerminalA)
end

TMRadioServer.UpdatePlaylistTerminalB = function(args) 
	if args.request == true then
		if #TMRadioServer.PlaylistTerminalB == 0 then
			TMRadioServer.PlaylistTerminalB = ModData.getOrCreate("TMRadioB")
		end
		if #TMRadioServer.PlaylistTerminalB == 0 then
			TMRadioServer.PlaylistTerminalB = TMRadioServer.CreatePlaylist()
		end
	else
		TMRadioServer.PlaylistTerminalB = args
	end
	ModData.add("TMRadioB", TMRadioServer.PlaylistTerminalB)
	ModData.transmit("TMRadioB", TMRadioServer.PlaylistTerminalB)
	TMRadioServer.SendServerCommandToClients("UpdatePlaylistTerminalB", TMRadioServer.PlaylistTerminalB)
end

TMRadioServer.OnClientCommand = function(module, command, player, args)
    	if not (module == "TMRadio" and TMRadioServer[command]) then
		return
	end
	print("TMRadio: Server getting a " .. command .. " from a client.")
	TMRadioServer[command](args)
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