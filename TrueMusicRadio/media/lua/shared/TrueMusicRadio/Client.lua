if isServer() then 
	return 
end

TMRadioClient = {}

TMRadioClient.PlaylistTerminalA = {}

TMRadioClient.PlaylistTerminalB = {}

TMRadioClient.Channels = {}

TMRadioClient.FindRadio = function(args)
	if not args then
		return
	end

    	local radio = nil
	local square = getSquare(args.x, args.y, args.z)
    
    	-- Radio Device: Portable/HAM radio or vehicle radio
	if square then
        	for i = 0, square:getObjects():size()-1 do
        		local item = square:getObjects():get(i)

            		-- Portable/HAM radio or television
            		if instanceof(item, "IsoRadio") and item:getDeviceData() ~= nil then
                		radio = item
                		break
            		end

            		-- Vehicle radio
            		if instanceof(item, "IsoObject") then
               			local vehicle = square:getVehicleContainer()
                		if vehicle then
                    			local part = vehicle:getPartById("Radio");
                    			if part and part:getDeviceData() then
                      				radio = part
                      				break
                    			end
                		end
			end
            	end
        end

	return radio
end

TMRadioClient.Stop = function(args)
	if not args then
		return
	end

	print("TMRadio: Client received stop command at " .. args.x .. " " .. args.y .. " " .. args.z)

	if #TMRadio.soundCache > 0 then
		for index = #TMRadio.soundCache, 1, -1 do 
			t = TMRadio.soundCache[index]  
			if t.x == args.x and t.y == args.y and t.z == args.z then
				t.sound:setVolume(0)
				t.muted = true
                		TMRadio.updateVolume(t)
				t.sound:stop()
				table.remove(TMRadio.soundCache, index)
			end
		end
	end
end

TMRadioClient.Play = function(args)
	if not args then
		return
	end

	TMRadio.Channels[args.channel] = args.number

	--print("TMRadio: Client received play command")

	local radio = nil

	if #TMRadio.soundCache > 0 then
		for _,t in ipairs(TMRadio.soundCache) do
			if t.x == args.x and t.y == args.y and t.z == args.z then
				radio = t.device
			end
		end	
	end	

	if radio == nil then
		radio = TMRadioClient.FindRadio(args)
	end

	if radio == nil then
		return
	end

	print("TMRadio: client play: " .. args.number)
	TMRadio.PlaySound(args.number, radio)
end

TMRadioClient.PlayNext = function(args)
	if not args then
		return
	end

	TMRadio.Channels[args.channel] = args.number

	--print("TMRadio: Client received playnext command")

	if #TMRadio.soundCache > 0 then
		print("TMRadio: Soundcache updating channel: " .. args.channel)
		TMRadio.UpdateSoundCache(args.number, args.channel)
	end

	local radio = nil

	if #TMRadio.soundCache > 0 then
		for _,t in ipairs(TMRadio.soundCache) do
			if t.x == args.x and t.y == args.y and t.z == args.z then
				radio = t.device
			end
		end	
	end	

	if radio == nil then
		radio = TMRadioClient.FindRadio(args)
	end

	if radio == nil then
		return
	end

	print("TMRadio: client playnext on new radio: " .. args.number)
	TMRadio.PlaySound(args.number, radio)
end

TMRadioClient.UpdatePlaylistTerminalA = function(args)
	--print("Client: getting update for A")
	TMRadioClient.PlaylistTerminalA = args
	ModData.add("TMRadioA", TMRadioClient.PlaylistTerminalA)
end

TMRadioClient.UpdatePlaylistTerminalB = function(args)
	--print("Client: getting update for B")
	TMRadioClient.PlaylistTerminalB = args
	ModData.add("TMRadioB", TMRadioClient.PlaylistTerminalB)
end

TMRadioClient.UpdateChannels = function(args)
	print("Client: getting update for channels")
	TMRadioClient.Channels = args
	TMRadio.Channels = args
	ModData.add("TMRadioChannels", TMRadioClient.Channels)
	--print("94: " ..  TMRadio.Channels[94000])
	--print("94.2: " ..  TMRadio.Channels[94200])
	--print("94.4: " ..  TMRadio.Channels[94400])
	--print("94.6: " ..  TMRadio.Channels[94600])
	--print("94.8: " ..  TMRadio.Channels[94800])
end

TMRadioClient.OnServerCommand = function(module, command, args)
    	if not (module == "TMRadio" and TMRadioClient[command]) then
		return
	end
	print("TMRadio: Client getting a " .. command .. " from the server")
        TMRadioClient[command](args)
end

Events.OnServerCommand.Add(TMRadioClient.OnServerCommand)

TMRadioClient.OnReceiveGlobalModDataClient = function(module, args)
	if not args then
		return
	end
	
    	if module == "TMRadioA" then
		TMRadioClient.PlaylistTerminalA = args
		TMRadio.PlaylistTerminalA = args
		ModData.add("TMRadioA", TMRadioClient.PlaylistTerminalA)
	elseif module == "TMRadioB" then
		TMRadioClient.PlaylistTerminalB = args
		TMRadio.PlaylistTerminalB = args
		ModData.add("TMRadioB", TMRadioClient.PlaylistTerminalB)
	end
end

Events.OnReceiveGlobalModData.Add(TMRadioClient.OnReceiveGlobalModDataClient)

TMRadioClient.UpdatePlaylistFromServer = function()
	print("TMRadio: Client sending request for terminal playlist from the server")
	sendClientCommand("TMRadio", "UpdatePlaylistTerminalA", {request = true})
	sendClientCommand("TMRadio", "UpdatePlaylistTerminalB", {request = true})
	sendClientCommand("TMRadio", "UpdateChannels", {request = true})
end

return TMRadioClient