if isServer() then 
	return 
end

require "TMRadio"

UseTerminalMenu = {}
UseTerminalMenu.doBuildMenu = function(player, context, worldobjects)

	local Terminal = nil
	local X = nil
	local Y = nil
	local Z = nil

	for _,object in ipairs(worldobjects) do
		local square = object:getSquare()

		if not square then
			return
		end

		X = square:getX()
		Y = square:getY()
		Z = square:getZ()

		if (X ~= 4833 or Y ~= 6277 or Z ~= 0) and (X ~= 4834 or Y ~= 6277 or Z ~= 0) and (X ~= 4832 or Y ~= 6279 or Z ~= 0) then
			return
		end
	
		for i=1,square:getObjects():size() do
			local thisObject = square:getObjects():get(i-1)
			
			if thisObject:getSprite() then
				local properties = thisObject:getSprite():getProperties()
				local spr = thisObject:getSprite():getName()  

				if properties == nil then
					return
				end

				local customName = nil
				local groupName = nil

				if properties:Is("CustomName") then
					customName = properties:Val("CustomName")
				end


				if properties:Is("GroupName") then
					groupName = properties:Val("GroupName")
				end
			
				if customName == "Terminal" and groupName == "Security" then				
					Terminal = thisObject
					Terminal:getModData()
					if not Terminal:getContainer() then
						local index = Terminal:getObjectIndex()
               					sledgeDestroy(Terminal)
						Terminal:getSquare():transmitRemoveItemFromSquareOnServer(Terminal)
						Terminal:getSquare():transmitRemoveItemFromSquare(Terminal)            

                				Terminal = IsoThumpable.new(getCell(), square, spr, false, ISWoodenContainer:new(spr, nil))  
                				Terminal:setIsContainer(true)
                				Terminal:getContainer():setType("securityterminal")
                				Terminal:getContainer():setCapacity(110)

                				square:AddTileObject(Terminal, index)
						square:transmitAddObjectToSquare(Terminal, Terminal:getObjectIndex())
						square:transmitModdata()
              					Terminal:transmitCompleteItemToServer()
                				Terminal:transmitUpdatedSpriteToServer()

						local tempGlobalPlaylist = {}
						for k,v in pairs(GlobalMusic) do
    							tempGlobalPlaylist[#tempGlobalPlaylist + 1] = k
						end

						local maxMusic = SandboxVars.TrueMusicRadio.TMRMusicTerminalFilledAmount

						if maxMusic == 6 then
							maxMusic = 0
							Terminal:getModData()['LoadedCapacity'] = 0
						elseif maxMusic == 5 then
							maxMusic = ZombRand(1,111)
							Terminal:getModData()['LoadedCapacity'] = ZombRand(1,111)
						elseif maxMusic == 4 then
							maxMusic = ZombRand(75,111)
							Terminal:getModData()['LoadedCapacity'] = ZombRand(75,111)
						elseif maxMusic == 3 then
							maxMusic = ZombRand(25,75)
							Terminal:getModData()['LoadedCapacity'] = ZombRand(25,75)
						elseif maxMusic == 2 then
							maxMusic = ZombRand(10,25)
							Terminal:getModData()['LoadedCapacity'] = ZombRand(10,25)
						elseif maxMusic == 1 then
							maxMusic = ZombRand(1,10)
							Terminal:getModData()['LoadedCapacity'] = ZombRand(1,10)
						end
				
						local canEject = SandboxVars.TrueMusicRadio.TMRTerminalEjectsMusic
						if not canEject then
							Terminal:getModData()['LoadedCapacity'] = 0
						end
						Terminal:transmitModData()

						local musicItems = 0
						while musicItems < maxMusic do
							local musicItem = "Tsarcraft." .. tempGlobalPlaylist[ZombRand(1, #tempGlobalPlaylist+1)]
							local addItem = Terminal:getItemContainer():AddItem(musicItem)
							if isClient() then
								Terminal:getItemContainer():addItemOnServer(addItem)
							end
							musicItems = musicItems + 1
						end
					end
					break
				end
			end 
		end 
	end

	if not Terminal then 
		return 
	end

	if not Terminal:getModData()['LoadedCapacity'] then
		Terminal:getModData()['LoadedCapacity'] = 0
	end

	if X == 4833 and Y == 6277 and Z == 0 then
		context:addOption(TMRadio.translation.update94,
				  worldobjects,
				  UseTerminalMenu.onUseTerminal,
				  getSpecificPlayer(player),
				  Terminal,
				  "Update")

		context:addOption(TMRadio.translation.revert94,
				  worldobjects,
				  UseTerminalMenu.onUseTerminal,
				  getSpecificPlayer(player),
				  Terminal,
				  "RevertA")
	elseif X == 4834 and Y == 6277 and Z == 0 then
		context:addOption(TMRadio.translation.update942,
				  worldobjects,
				  UseTerminalMenu.onUseTerminal,
				  getSpecificPlayer(player),
				  Terminal,
				  "Update")

		context:addOption(TMRadio.translation.revert942,
				  worldobjects,
				  UseTerminalMenu.onUseTerminal,
				  getSpecificPlayer(player),
				  Terminal,
				  "RevertB")
	elseif X == 4832 and Y == 6279 and Z == 0 and Terminal:getModData()['LoadedCapacity'] > 0 then
		context:addOption(TMRadio.translation.ejectmedia,
				  worldobjects,
				  UseTerminalMenu.onUseTerminal,
				  getSpecificPlayer(player),
				  Terminal,
				  "Eject Music")
	end
end

UseTerminalMenu.getFrontSquare = function(square, facing)
	local value = nil
	
	if facing == "S" then
		value = square:getS()
	elseif facing == "E" then
		value = square:getE()
	elseif facing == "W" then
		value = square:getW()
	elseif facing == "N" then
		value = square:getN()
	end
	
	return value
end

UseTerminalMenu.getFacing = function(properties, square)

	local facing = nil

	if properties:Is("Facing") then
		facing = properties:Val("Facing")
	end

	if square:getE() and facing == "E" then
		facing = "E"
	elseif square:getS() and facing == "S" then
		facing = "S" 
	elseif square:getW() and facing == "W" then
		facing = "W"
	elseif square:getN() and facing == "N" then
		facing = "N"
	else 
		facing = nil
	end

	return facing
end

UseTerminalMenu.walkToFront = function(thisPlayer, Terminal)
	local spriteName = Terminal:getSprite():getName()
	if not spriteName then
		return false
	end

	local properties = Terminal:getSprite():getProperties()
	local facing = UseTerminalMenu.getFacing(properties, Terminal:getSquare())
	if facing == nil then
		thisPlayer:Say(TMRadio.translation.sayaccessblocked)
		return false
	end
	
	local frontSquare = UseTerminalMenu.getFrontSquare(Terminal:getSquare(), facing)
	local turn = UseTerminalMenu.getFrontSquare(frontSquare, facing)
	
	if not frontSquare then
		return false
	end

	local terminalSquare = Terminal:getSquare()

	if AdjacentFreeTileFinder.privTrySquare(terminalSquare, frontSquare) then
		ISTimedActionQueue.add(ISWalkToTimedAction:new(thisPlayer, frontSquare))
		if turn then
			thisPlayer:faceLocation(terminalSquare:getX(), terminalSquare:getY())
		end
		return true
	end

	return false
end

UseTerminalMenu.onUseTerminal = function(worldobjects, player, terminal, MyChoice)
	if (not UseTerminalMenu.walkToFront(player, terminal) and terminal:getContainer()) then 
		return 
	end

	local square = terminal:getSquare()

	if not ((SandboxVars.AllowExteriorGenerator and square:haveElectricity()) or (SandboxVars.ElecShutModifier > -1 and GameTime:getInstance():getNightsSurvived() < SandboxVars.ElecShutModifier and square:isOutside() == false)) then
		player:Say(TMRadio.translation.sayneedsgenerator)
		return
	end

	if MyChoice == "Eject Music" then
		local tempGlobalPlaylist = {}
		for k,v in pairs(GlobalMusic) do
			tempGlobalPlaylist[#tempGlobalPlaylist + 1] = k
		end
		local musicItem = "Tsarcraft." .. tempGlobalPlaylist[ZombRand(1, #tempGlobalPlaylist+1)]
		square:playSound("TCBoombox_stop")
		player:getInventory():AddItem(musicItem)
		terminal:getModData()['LoadedCapacity'] = terminal:getModData()['LoadedCapacity'] - 1
		terminal:transmitModData()
		--print("Terminal capacity: " .. terminal:getModData()['LoadedCapacity'])
		return
	elseif MyChoice == "RevertA" then
		square:playSound("LightSwitch")
		TMRadio.PlaylistTerminalA = TMRadio.CreatePlaylist()
		if isClient() then
			sendClientCommand("TMRadio", "UpdatePlaylistTerminalA", TMRadio.PlaylistTerminalA)
		end
		ModData.add("TMRadioA", TMRadio.PlaylistTerminalA)
		ModData.transmit("TMRadioA", TMRadio.PlaylistTerminalA)
		local songNumber = ZombRand(1, #TMRadio.PlaylistTerminalA+1)
		if isClient() then
			local args = {x = terminal:getX(), y = terminal:getY(), z = terminal:getZ(), channel = 94000, number = songNumber}	
			sendClientCommand("TMRadio", "PlayNext", args)
		else
			TMRadio.UpdateSoundCache(songNumber, 94000)
		end
	elseif MyChoice == "RevertB" then
		square:playSound("LightSwitch")
		TMRadio.PlaylistTerminalB = TMRadio.CreatePlaylist()
		if isClient() then
			sendClientCommand("TMRadio", "UpdatePlaylistTerminalB", TMRadio.PlaylistTerminalB)
		end
		ModData.add("TMRadioB", TMRadio.PlaylistTerminalB)
		ModData.transmit("TMRadioB", TMRadio.PlaylistTerminalB)	
		local songNumber = ZombRand(1, #TMRadio.PlaylistTerminalB+1)
		if isClient() then
			local args = {x = terminal:getX(), y = terminal:getY(), z = terminal:getZ(), channel = 94200, number = songNumber}	
			sendClientCommand("TMRadio", "PlayNext", args)
		else
			TMRadio.UpdateSoundCache(songNumber, 94200)
		end
	elseif MyChoice == "Update" then
		square:playSound("LightSwitch")
		local terminalItems = nil

		if terminal:getContainer() then
			terminalItems = terminal:getItemContainer():getItems()
		end

		if terminalItems:size() == 0 then
			player:Say("There are no items in this terminal.")
			return
		end

		if terminal:getX() == 4833 and terminal:getY() == 6277 and terminal:getZ() == 0 then
			TMRadio.PlaylistTerminalA = {}
			for i=0, terminalItems:size()-1 do
				local item = terminalItems:get(i)
				TMRadio.PlaylistTerminalA[#TMRadio.PlaylistTerminalA + 1] = item:getType()
			end
			local songNumber = ZombRand(1, #TMRadio.PlaylistTerminalA+1)
			ModData.add("TMRadioA", TMRadio.PlaylistTerminalA)
			if isClient() then
				ModData.transmit("TMRadioA", TMRadio.PlaylistTerminalA)
				sendClientCommand("TMRadio", "UpdatePlaylistTerminalA", TMRadio.PlaylistTerminalA)
				local args = {x = terminal:getX(), y = terminal:getY(), z = terminal:getZ(), channel = 94000, number = songNumber}	
				sendClientCommand("TMRadio", "PlayNext", args)
				--print("Client: Transmitting A to server")
			else
				TMRadio.UpdateSoundCache(songNumber, 94000)
			end
		elseif terminal:getX() == 4834 and terminal:getY() == 6277 and terminal:getZ() == 0 then
			TMRadio.PlaylistTerminalB = {}
			for i=0, terminalItems:size()-1 do
				local item = terminalItems:get(i)
				TMRadio.PlaylistTerminalB[#TMRadio.PlaylistTerminalB + 1] = item:getType()
			end
			local songNumber = ZombRand(1, #TMRadio.PlaylistTerminalB+1)
			ModData.add("TMRadioB", TMRadio.PlaylistTerminalB)
			if isClient() then
				ModData.transmit("TMRadioB", TMRadio.PlaylistTerminalB)	
				sendClientCommand("TMRadio", "UpdatePlaylistTerminalB", TMRadio.PlaylistTerminalB)
				local args = {x = terminal:getX(), y = terminal:getY(), z = terminal:getZ(), channel = 94200, number = songNumber}	
				sendClientCommand("TMRadio", "PlayNext", args)
				--print("Client: Transmitting B to server")
			else
				TMRadio.UpdateSoundCache(songNumber, 94200)
			end
		end
	end
end

Events.OnPreFillWorldObjectContextMenu.Add(UseTerminalMenu.doBuildMenu)