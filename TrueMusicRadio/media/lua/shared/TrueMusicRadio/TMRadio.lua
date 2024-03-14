if isServer() then 
	return 
end

require "TCMusicDefenitions"
require "TMRSound"

TMRadio = {}

TMRadio.soundCache = {}

TMRadio.cacheSize = 50	-- number of devices to keep in cache

TMRadio.PlaylistTerminalA = {}

TMRadio.PlaylistTerminalB = {}

TMRadio.PlaylistGlobal = {}

TMRadio.Channels = {}

-------------------
-- PLAY NEW SONG --
-------------------

TMRadio.PlaySound = function(number, device)
	if not number or not device then
		return
	end

    	local sound = nil
	local deviceData = device:getDeviceData()
    	local t = TMRadio.getData(deviceData)

    	if t then
        	sound = t.sound
    	else
        	sound = TMRSound:new()
    	end

    	if deviceData:isInventoryDevice() then
        	sound:set3D(false)
        	sound:setVolumeModifier(0.6)
    	elseif deviceData:isIsoDevice() then
        	sound:setPosAtObject(device)
        	sound:setVolumeModifier(0.4)
    	elseif deviceData:isVehicleDevice() then
        	local vehiclePart = deviceData:getParent()
        	if vehiclePart then
            		local vehicle = vehiclePart:getVehicle()
            		if vehicle then
                		sound:setEmitter(vehicle:getEmitter()) -- use car's emitter, car radios don't have one
                		if vehicle == getPlayer():getVehicle() then -- player is in the car
                    			sound:set3D(false)
                    			sound:setVolumeModifier(0.8)
                		elseif not TMRadio.VehicleWindowsIntact(vehicle) then
                    			sound:set3D(true)
                    			sound:setVolumeModifier(0.4)
				else
                    			sound:set3D(true)
                    			sound:setVolumeModifier(0.2)
                		end
            		end
        	end
    	end

    	sound:setVolume(deviceData:getDeviceVolume())

	if isClient() then
		--print("Client: client list")
		if #TMRadioClient.PlaylistTerminalA > 0 then
			--print("Client: getting A from client list")
			TMRadio.PlaylistTerminalA = TMRadioClient.PlaylistTerminalA
		end
		if #TMRadioClient.PlaylistTerminalB > 0 then
			--print("Client: getting B from client list")
			TMRadio.PlaylistTerminalB = TMRadioClient.PlaylistTerminalB
		end
	end

	if #TMRadio.PlaylistTerminalA == 0 then
		--print("Client: A not found in client list, pull from local moddata")
		TMRadio.PlaylistTerminalA = ModData.getOrCreate("TMRadioA")
	end
	if #TMRadio.PlaylistTerminalB == 0 then
		--print("Client: B not found in client list, pull from local moddata")
		TMRadio.PlaylistTerminalB = ModData.getOrCreate("TMRadioB")
	end

	if #TMRadio.PlaylistTerminalA == 0 then
		--print("Client: A not found in moddata, create default list")
		TMRadio.PlaylistTerminalA = TMRadio.CreatePlaylist()
	end
	if #TMRadio.PlaylistTerminalB == 0 then
		--print("Client: B not found in moddata, create default list")
		TMRadio.PlaylistTerminalB = TMRadio.CreatePlaylist()
	end

	if #TMRadio.PlaylistGlobal == 0 then
		--print("Client: No list found, create new global list for default channels")
		TMRadio.PlaylistGlobal = TMRadio.CreatePlaylist()
	end

	local songName = nil


	if deviceData:getChannel() == 94000 then	
    		songName = TMRadio.PlaylistTerminalA[number]
	elseif deviceData:getChannel() == 94200 then
    		songName = TMRadio.PlaylistTerminalB[number]
	elseif deviceData:getChannel() == 94400 or deviceData:getChannel() == 94600 or deviceData:getChannel() == 94800 then
    		songName = TMRadio.PlaylistGlobal[number]
	else
		return
	end

	TMRadio.Channels[deviceData:getChannel()] = number

	if songName == nil then
		print("TMRadio: Error processing requested song")
		return
	else
		print("TMRadio: Playing song[" .. number .. "] " .. songName)
		sound:play(songName)
	end

	local position = TMRadio.whereAreYou(device)

    	t = t or {}
    	t.device = device
    	t.deviceData = deviceData
    	t.channel = deviceData:getChannel()
    	t.sound = sound
	t.muted = false
	t.x = position.x
	t.y = position.y
	t.z = position.z

    	tickCounter2 = 200

	--print("X: " .. t.x .. " Y: " .. t.y .. " Z: " .. t.z)
	--print("Sound Cache Counter before clean: " .. #TMRadio.soundCache)

	if #TMRadio.soundCache > 0 then
		for index,x in ipairs(TMRadio.soundCache) do
			if x.device == device then
				table.remove(TMRadio.soundCache, index)
			end
		end
	end

    	table.insert( TMRadio.soundCache, 1, t )
    	if #TMRadio.soundCache > TMRadio.cacheSize then
        	for i = TMRadio.cacheSize+1, #TMRadio.soundCache do
            		table.remove(TMRadio.soundCache, i)
        	end
    	end

	print("TMRadio: Soundcache counter after new sound: [" .. #TMRadio.soundCache .. "/" .. TMRadio.cacheSize .. "]")

    	return t
end

--------------------------
-- START ON DEVICE TEXT --
--------------------------

function TMRadio.OnDeviceText(guid, interactCodes, x, y, z, line, device)
    	local radio = nil
	local square = getSquare(x, y, z)
    
    	-- Radio Device: Portable/HAM radio or vehicle radio
	if square then
        	for i = 0, square:getObjects():size()-1 do
        		local item = square:getObjects():get(i)

            		-- Portable/HAM radio
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

    	if radio == nil and device == nil then
       		return
    	elseif radio == nil then
		radio = device
	end

	local deviceData = radio:getDeviceData()

	if not deviceData:getIsTurnedOn() then
		return
	end

	local radioX = deviceData:getParent():getX()
	local radioY = deviceData:getParent():getY()
	local radioZ = deviceData:getParent():getZ()
	local radioDist = math.sqrt((getPlayer():getX() - radioX) ^ 2 + (getPlayer():getY() - radioY) ^ 2 + (getPlayer():getZ() - radioZ) ^ 2)

	if radioDist > 75 then
		return
	end

	local radioChannel = radio:getDeviceData():getChannel()

	if not radioChannel then
		return
	end

	if not (radioChannel == 94000 or radioChannel == 94200 or radioChannel == 94400 or radioChannel == 94600 or radioChannel == 94800) then
		return
	end

	for index,t in ipairs(TMRadio.soundCache) do  
		if t.device == radio then
			if TMRadio.isPlaying(t) then
				return
			end
		end
	end

	--print("Activated Radio at x: " .. radioX .. " y: " .. radioY .. " z: " .. radioZ)

	local songNumber = TMRadio.ChooseSong(radioChannel)
	if isClient() and not deviceData:isInventoryDevice() then
		local args = {x = radioX, y = radioY, z = radioZ, channel = radioChannel, number = songNumber}
		sendClientCommand("TMRadio", "Play", args)
	else
		if not TMRadio.Channels[radioChannel] then 
			TMRadio.Channels[radioChannel] = songNumber
			TMRadio.PlaySound(songNumber, radio)
		else
			TMRadio.PlaySound(TMRadio.Channels[radioChannel], radio)
		end
	end
end

Events.OnDeviceText.Add(TMRadio.OnDeviceText)

-----------------------------
-- UPDATE RADIO SOUNDCACHE --
-----------------------------

TMRadio.UpdateSoundCache = function(number, channel)
	if not number or not channel then
		return
	end

	TMRadio.Channels[channel] = number

	if #TMRadio.soundCache < 1 then
		return
	end

	for index,t in ipairs(TMRadio.soundCache) do  
		local deviceData = t.device:getDeviceData()
		if deviceData:getChannel() == channel then
			TMRadio.PlaySound(number, t.device)
			--print(channel .. " " .. number)
		end
	end
end

---------------------------
-- INTERACTION OVERRIDES --
---------------------------

TMRadio.AddOverrides = function()
    	local TMRRadioAction_performToggleOnOff = ISRadioAction.performToggleOnOff
    	function ISRadioAction:performToggleOnOff()
        	TMRRadioAction_performToggleOnOff(self)
        	local t = TMRadio.getData(self.deviceData)
        	if t then
			if t.deviceData:getIsTurnedOn() and t.deviceData:getChannel() == t.channel and (self.deviceData:getChannel() == 94000 or self.deviceData:getChannel() == 94200 or self.deviceData:getChannel() == 94400 or self.deviceData:getChannel() == 94600 or self.deviceData:getChannel() == 94800) then
                		t.muted = false
            		else
                		t.muted = true -- mute sound instead of stopping it, so we can turn it back on
            		end
            		TMRadio.updateVolume(t)
        	elseif self.deviceData:getIsTurnedOn() and (self.deviceData:getChannel() == 94000 or self.deviceData:getChannel() == 94200 or self.deviceData:getChannel() == 94400 or self.deviceData:getChannel() == 94600 or self.deviceData:getChannel() == 94800) then
			local songNumber = TMRadio.ChooseSong(self.deviceData:getChannel())
			if isClient() and not self.deviceData:isInventoryDevice() then
				local position = TMRadio.whereAreYou(self.deviceData:getParent())
				local x = position.x
				local y = position.y
				local z = position.z
				local args = {x = x, y = y, z = z, channel = self.deviceData:getChannel(), number = songNumber}
				sendClientCommand("TMRadio", "Play", args)
			else
				if TMRadio.Channels[self.deviceData:getChannel()] > 0 then
					TMRadio.PlaySound(TMRadio.Channels[self.deviceData:getChannel()], self.deviceData:getParent())
				else
					TMRadio.Channels[self.deviceData:getChannel()] = songNumber
					TMRadio.PlaySound(songNumber, self.deviceData:getParent())
				end
			end
		end
    	end
    
    	local TMRRadioAction_performSetChannel = ISRadioAction.performSetChannel
    	function ISRadioAction:performSetChannel()
		local oldChannel = self.deviceData:getChannel()
		--print("old channel: " .. oldChannel)
		local x = TMRadio.getData(self.deviceData)
		if self.deviceData:getChannel() == 94000 or self.deviceData:getChannel() == 94200 or self.deviceData:getChannel() == 94400 or self.deviceData:getChannel() == 94600 or self.deviceData:getChannel() == 94800 then
			if x then
                		x.muted = true -- mute sound instead of stopping it, so we can turn it back on
            			TMRadio.updateVolume(x)
			end
		end
        	TMRRadioAction_performSetChannel(self)
		local newChannel = self.deviceData:getChannel()
		--print("new channel: " .. newChannel)
		local songNumber = TMRadio.ChooseSong(self.deviceData:getChannel())
        	local t = TMRadio.getData(self.deviceData)
		if not isClient() and not isServer() and oldChannel == newChannel and (self.deviceData:getChannel() == 94000 or self.deviceData:getChannel() == 94200 or self.deviceData:getChannel() == 94400 or self.deviceData:getChannel() == 94600 or self.deviceData:getChannel() == 94800) then
			--print("push to the next song")
			if t then
				TMRadio.UpdateSoundCache(songNumber, self.deviceData:getChannel())
				return
			else
				TMRadio.PlaySound(TMRadio.Channels[self.deviceData:getChannel()], self.deviceData:getParent())
				return
			end
		elseif t then
			if t.deviceData:getIsTurnedOn() and t.deviceData:getChannel() == t.channel and (self.deviceData:getChannel() == 94000 or self.deviceData:getChannel() == 94200 or self.deviceData:getChannel() == 94400 or self.deviceData:getChannel() == 94600 or self.deviceData:getChannel() == 94800) then
                		t.muted = false
			elseif t.deviceData:getIsTurnedOn() and (self.deviceData:getChannel() == 94000 or self.deviceData:getChannel() == 94200 or self.deviceData:getChannel() == 94400 or self.deviceData:getChannel() == 94600 or self.deviceData:getChannel() == 94800) then
                		t.muted = false
				if isClient() and not self.deviceData:isInventoryDevice() then
					local position = TMRadio.whereAreYou(self.deviceData:getParent())
					local x = position.x
					local y = position.y
					local z = position.z
					local args = {x = x, y = y, z = z, channel = self.deviceData:getChannel(), number = songNumber}
					sendClientCommand("TMRadio", "Play", args)
				else
					TMRadio.PlaySound(TMRadio.Channels[self.deviceData:getChannel()], self.deviceData:getParent())
				end
            		else
                		t.muted = true -- mute sound instead of stopping it, so we can turn it back on
 	           	end
            		TMRadio.updateVolume(t)
		elseif self.deviceData:getIsTurnedOn() and (self.deviceData:getChannel() == 94000 or self.deviceData:getChannel() == 94200 or self.deviceData:getChannel() == 94400 or self.deviceData:getChannel() == 94600 or self.deviceData:getChannel() == 94800) then
			if isClient() and not self.deviceData:isInventoryDevice() then
				local position = TMRadio.whereAreYou(self.deviceData:getParent())
				local x = position.x
				local y = position.y
				local z = position.z
				local args = {x = x, y = y, z = z, channel = self.deviceData:getChannel(), number = songNumber}
				sendClientCommand("TMRadio", "Play", args)
			else
				TMRadio.PlaySound(TMRadio.Channels[self.deviceData:getChannel()], self.deviceData:getParent())
			end
		end
    	end
    
    	local TMRRadioAction_performSetVolume = ISRadioAction.performSetVolume
    	function ISRadioAction:performSetVolume()
        	if self:isValidSetVolume() then
            		TMRRadioAction_performSetVolume(self)
            		local t = TMRadio.getData(self.deviceData)
            		if t then
                		TMRadio.updateVolume(t)
           		end
        	end
    	end

    	local TMREnterVehicle_perform = ISEnterVehicle.perform
    	function ISEnterVehicle:perform()
        	TMREnterVehicle_perform(self)
        	local t = TMRadio.getEmitter( self.character:getVehicle():getEmitter() )
        	if t then
            		t.sound:setVolumeModifier(0.8)
            		t.sound:set3D(false)
            		TMRadio.updateVolume(t)
        	end
    	end
    
    	local TMRExitVehicle_perform = ISExitVehicle.perform
    	function ISExitVehicle:perform()
        	local t = TMRadio.getEmitter(self.character:getVehicle():getEmitter())
        	if t then
			t.x = self.character:getVehicle():getX()
			t.y = self.character:getVehicle():getY()
			t.z = self.character:getVehicle():getZ()
			if not TMRadio.VehicleWindowsIntact(self.character:getVehicle()) then
            			t.sound:setVolumeModifier(0.4)
            			t.sound:set3D(true)
            			TMRadio.updateVolume(t)
			else
            			t.sound:setVolumeModifier(0.2)
            			t.sound:set3D(true)
            			TMRadio.updateVolume(t)
			end
        	end
        	TMRExitVehicle_perform(self)
    	end

	local TMRRadioWindow_update = ISRadioWindow.update
	function ISRadioWindow:update()
  		ISCollapsableWindow.update(self)
		local maxDist = 5
    		--if not isClient() and self:getIsVisible() then -- might be an issue
    		if self:getIsVisible() then
        		if self.deviceType and self.device and self.player and self.deviceData then
            			if self.deviceType=="InventoryItem" then
					if self.device:isInPlayerInventory() then
						return
					else
						self:close()
         	           			return
					end
            			elseif self.deviceType == "IsoObject" or self.deviceType == "VehiclePart" then
					if self.device:getSquare() then
						local distanceToRadio = math.sqrt((self.player:getX() - self.device:getX()) ^ 2 + (self.player:getY() - self.device:getY()) ^ 2 + (self.player:getZ() - self.device:getZ()) ^ 2)
        		        		if distanceToRadio > maxDist then
							self:close()
        		            			return
						end
					end
           		     	end
        		end
		end
		TMRRadioWindow_update(self)
	end

	local TMRDropItemAction_perform = ISDropItemAction.perform
	function ISDropItemAction:perform()
		if isClient() then
			if instanceof(self.item, "Radio") then
				local deviceData = self.item:getDeviceData()
				if deviceData then
 		       	   		local t = TMRadio.getData(deviceData)
					local args = {}
            				if t then
                				args = {x = t.x, y = t.y, z = t.z}
						--print("getting position from t: " .. args.x .. " " .. args.y .. " " .. args.z)
					else
						local position = TMRadio.whereAreYou(self.item)
						local x = position.x
						local y = position.y
						local z = position.z
                				args = {x = x, y = y, z = z}
						--print("getting position from where are you: " .. args.x .. " " .. args.y .. " " .. args.z)
					end
					print("TMRadio: Sending stop command to server: " .. args.x .. " " .. args.y .. " " .. args.z)
					if (args.x + args.y + args.z) ~= 0 then
						sendClientCommand("TMRadio", "Stop", args)
					end
				end
			end
		end

		TMRDropItemAction_perform(self)
	end

	local TMRDropWorldItemAction_perform = ISDropWorldItemAction.perform
	function ISDropWorldItemAction:perform()
		if isClient() then
			if instanceof(self.item, "Radio") then
				local deviceData = self.item:getDeviceData()
				if deviceData then
 		       	   		local t = TMRadio.getData(deviceData)
					local args = {}
            				if t then
                				args = {x = t.x, y = t.y, z = t.z}
						--print("getting position from t: " .. args.x .. " " .. args.y .. " " .. args.z)
					else
						local position = TMRadio.whereAreYou(self.item)
						local x = position.x
						local y = position.y
						local z = position.z
                				args = {x = x, y = y, z = z}
						--print("getting position from where are you: " .. args.x .. " " .. args.y .. " " .. args.z)
					end
					print("TMRadio: Sending stop command to server: " .. args.x .. " " .. args.y .. " " .. args.z)
					if (args.x + args.y + args.z) ~= 0 then
						sendClientCommand("TMRadio", "Stop", args)
					end
				end
			end
		end

		TMRDropWorldItemAction_perform(self)
	end

	local TMRInventoryTransferAction_perform = ISInventoryTransferAction.perform
	function ISInventoryTransferAction:perform()
		if isClient() then
			local ignore = false
			if self.srcContainer == self.character:getInventory() and self.destContainer:isInCharacterInventory(self.character) then
				ignore = true
			elseif self.destContainer == self.character:getInventory() and self.srcContainer:isInCharacterInventory(self.character) then
				ignore = true
			elseif self.srcContainer:isInCharacterInventory(self.character) and self.destContainer:isInCharacterInventory(self.character) then
				ignore = true
			end

			if not ignore and instanceof(self.item, "Radio") then
				local deviceData = self.item:getDeviceData()
				if deviceData then
 		       	   		local t = TMRadio.getData(deviceData)
					local args = {}
            				if t then
                				args = {x = t.x, y = t.y, z = t.z}
						--print("getting position from t: " .. args.x .. " " .. args.y .. " " .. args.z)
					else
						local position = TMRadio.whereAreYou(self.item)
						local x = position.x
						local y = position.y
						local z = position.z
                				args = {x = x, y = y, z = z}
						--print("getting position from where are you: " .. args.x .. " " .. args.y .. " " .. args.z)
					end
					print("TMRadio: Sending stop command to server: " .. args.x .. " " .. args.y .. " " .. args.z)
					if (args.x + args.y + args.z) ~= 0 then
						sendClientCommand("TMRadio", "Stop", args)
					end
				end
			end
		end

		TMRInventoryTransferAction_perform(self)
	end

	local TMRGrabItemAction_transferItem = ISGrabItemAction.transferItem
	function ISGrabItemAction:transferItem(item)
		if isClient() then
			if instanceof(item:getItem(), "Radio") then
				local deviceData = item:getItem():getDeviceData()
				if deviceData then
 		       	   		local t = TMRadio.getData(deviceData)
					local args = {}
            				if t then
                				args = {x = t.x, y = t.y, z = t.z}
						--print("getting position from t: " .. args.x .. " " .. args.y .. " " .. args.z)
					else
						local position = TMRadio.whereAreYou(item:getItem())
						local x = position.x
						local y = position.y
						local z = position.z
                				args = {x = x, y = y, z = z}
						--print("getting position from where are you: " .. args.x .. " " .. args.y .. " " .. args.z)
					end
					print("TMRadio: Sending stop command to server: " .. args.x .. " " .. args.y .. " " .. args.z)
					if (args.x + args.y + args.z) ~= 0 then
						sendClientCommand("TMRadio", "Stop", args)
					end
				end
			end
		end

		TMRGrabItemAction_transferItem(self, item)
	end

	local TMRMoveableSpriteProps_pickUpMoveableInternal = ISMoveableSpriteProps.pickUpMoveableInternal
	function ISMoveableSpriteProps:pickUpMoveableInternal(character, square, object, sprInstance, spriteName, createItem, rotating)
		if isClient() then
			if object and instanceof(object, "IsoRadio") then
				local deviceData = object:getDeviceData()
              	    		if deviceData and square then
					local args = {x = square:getX(), y = square:getY(), z = square:getZ()}
					print("TMRadio: Sending stop command to server: " .. args.x .. " " .. args.y .. " " .. args.z)
					if (args.x + args.y + args.z) ~= 0 then
						sendClientCommand("TMRadio", "Stop", args)
					end
				end
                  	end
		end

		return TMRMoveableSpriteProps_pickUpMoveableInternal(self, character, square, object, sprInstance, spriteName, createItem, rotating)
	end
end

Events.OnGameStart.Add(TMRadio.AddOverrides)

-------------------------------------------
-- ADJUST SOUNDS BASED ON DISTANCE/STATE --
-------------------------------------------

local minRange = 5
local maxRange = 50
local p = nil
local X = 0
local Y = 0
local Z = 0
local dropoffRange = 0
local volumeModifier = 0
local distanceToRadio = 0
local finalVolume = 0
local tickCounter1 = 0
local tickCounter2 = 0
local tickCounter3 = 0
local syncPlaylistRequest = true

function TMRadio.adjustSounds()
        p = getPlayer()
        X = p:getX()
        Y = p:getY()
        Z = p:getZ()

    	-- TODO: tickrates depend on framerate. find something time-based instead
    	if tickCounter2 < 1000 then 
        	tickCounter2=tickCounter2+1
    	else
		local TMRRadiosAttractZombies = SandboxVars.TrueMusicRadio.TMRRadiosAttractZombies 
        	--attract zombies
		if TMRRadiosAttractZombies then
	        	for _,t in ipairs(TMRadio.soundCache) do
        	    		if TMRadio.isPlaying(t) and t.device ~= nil and t.device == t.deviceData:getParent() then
                			local range = t.deviceData:getDeviceVolume() * t.sound.volumeModifier*2.5 * maxRange
					if t.deviceData:isVehicleDevice() then
						--print("call zombies to car")
						local vehicle = t.deviceData:getParent():getVehicle()
						if TMRadio.VehicleWindowsIntact(vehicle) then
							addSound(vehicle, t.x, t.y, t.x, range/4, range/2)
						else
							addSound(vehicle, t.x, t.y, t.z, range, range)
						end
					elseif t.deviceData:isInventoryDevice() then
						if t.device:getContainer() then
							if t.device:getContainer():getType() == "none" and t.deviceData:getHeadphoneType() == -1 then
								--print("call zombies to player without headphones")
								addSound(p, t.x, t.y, t.z, range/4, range/2)
							elseif t.device:getContainer():getType() ~= "none" then
								--print("call zombies to container")
								addSound(container, t.x, t.y, t.z, range/4, range/2)
							end
						end
                			elseif t.device:getSquare() then
						--print("call zombies to world radio")
                    				addSound(t.device, t.x, t.y, t.z, range, range)
					end
                		end
            		end
        	end
        	tickCounter2 = 0
    	end
    	if tickCounter1 < 5 then 
		tickCounter1=tickCounter1+1 
		return 
	end
    	tickCounter1 = 0

	if syncPlaylistRequest == true then
		if isClient() then
			TMRadioClient.UpdatePlaylistFromServer()
		else
			TMRadio.Channels = ModData.getOrCreate("TMRadioChannels")
			if TMRadio.Channels[94000] == nil then
				TMRadio.Channels[94000] = TMRadio.ChooseSong(94000)
			end
			if TMRadio.Channels[94200] == nil then
				TMRadio.Channels[94200] = TMRadio.ChooseSong(94200)
			end
			if TMRadio.Channels[94400] == nil then
				TMRadio.Channels[94400] = TMRadio.ChooseSong(94400)
			end
			if TMRadio.Channels[94600] == nil then
				TMRadio.Channels[94600] = TMRadio.ChooseSong(94600)
			end
			if TMRadio.Channels[94800] == nil then
				TMRadio.Channels[94800] = TMRadio.ChooseSong(94800)
			end
			--print("94: " ..  TMRadio.Channels[94000])
			--print("94.2: " ..  TMRadio.Channels[94200])
			--print("94.4: " ..  TMRadio.Channels[94400])
			--print("94.6: " ..  TMRadio.Channels[94600])
			--print("94.8: " ..  TMRadio.Channels[94800])
			ModData.add("TMRadioChannels", TMRadio.Channels)
		end
		syncPlaylistRequest = false
	end

	-- check status of soundcache for emitters leaving the distance check, reversed to pull broken bits out
	for index = #TMRadio.soundCache, 1, -1 do 
		t = TMRadio.soundCache[index]  
		if t.device ~= t.deviceData:getParent() then 
               		t.device = t.deviceData:getParent() 
		end
		local position = TMRadio.whereAreYou(t.device, index)
		if (position.x + position.y + position.z) ~= 0 then
			t.x = position.x
			t.y = position.y
			t.z = position.z
		end
		if t.device == nil then
			t.sound:setVolume(0)
			t.muted = true
    	         	TMRadio.updateVolume(t)
			t.sound:stop()
			table.remove(TMRadio.soundCache, index)
			--print("turned off due to lost device")
		elseif not t.deviceData:isInventoryDevice() and getSquare(t.x, t.y, t.z) == nil then
			t.sound:setVolume(0)
			t.muted = true
    	        	TMRadio.updateVolume(t)
			t.sound:stop()
			table.remove(TMRadio.soundCache, index)
			--print("stopping sound in container due to loss of square")
		elseif not t.deviceData:isInventoryDevice() and not (t.deviceData:isVehicleDevice() and p:getVehicle()) then
			distanceToRadio = math.sqrt((X - t.x) ^ 2 + (Y - t.y) ^ 2 + (Z - t.z) ^ 2)
			if distanceToRadio > 75 then
				t.sound:setVolume(0)
				t.muted = true
    	         		TMRadio.updateVolume(t)
				t.sound:stop()
				table.remove(TMRadio.soundCache, index)
				--print("turned off due to distance: " .. distanceToRadio)
			end
		elseif t.deviceData:isInventoryDevice() then
			if t.device:getContainer() and t.device:getContainer():getType() ~= "none" then
				distanceToRadio = math.sqrt((X - t.x) ^ 2 + (Y - t.y) ^ 2 + (Z - t.z) ^ 2)
				if distanceToRadio > 75 then
					t.sound:setVolume(0)
					t.muted = true
     	        	 		TMRadio.updateVolume(t)
					t.sound:stop()
					table.remove(TMRadio.soundCache, index)
					--print("in container turned off due to distance: " .. distanceToRadio)
				end
			end
		end
	end

    	highestVolume = 0

    	for index,t in ipairs(TMRadio.soundCache) do   
        	-- sync states     
        	if t.sound and t.sound:isPlaying() then
            		if not t.deviceData:getIsTurnedOn() and not t.muted then
                		t.muted = true
				--print("muted by tick, was not turned on")
            		end
			if not t.muted and not (t.deviceData:getChannel() == 94000 or t.deviceData:getChannel() == 94200 or t.deviceData:getChannel() == 94400 or t.deviceData:getChannel() == 94600 or t.deviceData:getChannel() == 94800) then
                		t.muted = true
				--print("muted by tick, was not on valid TMRadio channel")
			end
			if t.device.isInPlayerInventory and t.device:isInPlayerInventory() then
             			t.sound:set3D(false)
               		else
               			t.sound:setPos(t.x, t.y, t.z)
				t.sound:set3D(true)
               		end
                	TMRadio.updateVolume(t)
        	end

        	--adjust volume based on distance
        	if TMRadio.isPlaying(t) or (t.deviceData:getParent() ~= nil and t.deviceData:getIsTurnedOn()) then
    			if not t.muted then
        			t.sound:setVolume(t.deviceData:getDeviceVolume())
            			if t.deviceData:isInventoryDevice() then
                			highestVolume = 1
				elseif t.deviceData:isVehicleDevice() and p:getVehicle() then
        				if t.deviceData:getParent():getVehicle() == p:getVehicle() then
           					highestVolume = 1
					end
				else
                			distanceToRadio = math.sqrt((X - t.x) ^ 2 + (Y - t.y) ^ 2 + (Z - t.z) ^ 2)
                			if distanceToRadio < maxRange then
                    				dropoffRange = (maxRange-minRange)*0.2 + t.deviceData:getDeviceVolume() * t.sound.volumeModifier*2.5 * (maxRange-minRange)*0.8
                    				volumeModifier = (minRange + dropoffRange - distanceToRadio) / dropoffRange
                    				if volumeModifier < 0 then 
							volumeModifier = 0 
						end
 	                   			t.sound:setVolume(t.deviceData:getDeviceVolume() * volumeModifier)
        	            			finalVolume = t.deviceData:getDeviceVolume() * t.sound.volumeModifier * volumeModifier
                	    			if finalVolume > highestVolume then 
							highestVolume = finalVolume 
						end
             		      		end
            			end
			end
			-- check to see if the next song needs to play
			if not TMRadio.isPlaying(t) and tickCounter3 > 25 and (t.deviceData:getChannel() == 94000 or t.deviceData:getChannel() == 94200 or t.deviceData:getChannel() == 94400 or t.deviceData:getChannel() == 94600 or t.deviceData:getChannel() == 94800) then
				tickCounter3 = 0
				print("TMRadio: Song ended play another")
				local songNumber = TMRadio.ChooseSong(t.deviceData:getChannel())
				if isClient() then
					local args = {x = t.x, y = t.y, z = t.z, channel = t.deviceData:getChannel(), number = songNumber}
					sendClientCommand("TMRadio", "PlayNext", args)
				else
					TMRadio.UpdateSoundCache(songNumber, t.deviceData:getChannel())
				end
			elseif not TMRadio.isPlaying(t) and (t.deviceData:getChannel() == 94000 or t.deviceData:getChannel() == 94200 or t.deviceData:getChannel() == 94400 or t.deviceData:getChannel() == 94600 or t.deviceData:getChannel() == 94800) then
				tickCounter3 = tickCounter3 + 1
				--if tickCounter3 > 50 then
				--	print("ticking")
				--end
			end
        	end
    	end

    	--adjust Zomboid music volume
    	local optionsVolume = getCore():getOptionMusicVolume()/10
    	local optionsVolumeModified = optionsVolume - optionsVolume*highestVolume*10
    	if optionsVolumeModified < 0 then 
		optionsVolumeModified = 0 
	end
    	getSoundManager():setMusicVolume(optionsVolumeModified)
end

Events.OnTick.Add(TMRadio.adjustSounds)

TMRadio.OnMainMenuEnter = function()
    	--reset Zomboid music volume again
    	getSoundManager():setMusicVolume( getCore():getOptionMusicVolume()/10 )
end

Events.OnMainMenuEnter.Add( TMRadio.OnMainMenuEnter )

-------------
-- VARIOUS --
-------------

local vehicleWindows = {
    	"Windshield",
    	"WindshieldRear",
    	"WindowFrontLeft", 
    	"WindowFrontRight", 
    	"WindowMiddleLeft", 
    	"WindowMiddleRight", 
    	"WindowRearLeft", 
    	"WindowRearRight"
}

TMRadio.VehicleWindowsIntact = function(vehicle)
    	for k,v in ipairs(vehicleWindows) do
        	local vehiclePart = vehicle:getPartById(v)
        	if vehiclePart and (not vehiclePart:getInventoryItem() or (vehiclePart:getWindow() and vehiclePart:getWindow():isOpen())) then
            		return false
        	end
   	 end

    	return true
end

TMRadio.updateVolume = function(t)
    	if not t.muted then
        	t.sound:setVolume(t.deviceData:getDeviceVolume())
    	else
        	t.sound:setVolume(0)
    	end
end

TMRadio.isPlaying = function(t)
    	if not t.deviceData:getIsTurnedOn() then 
		return false 
	end
    	if t.muted then 
		return false 
	end
    	if t.sound and t.sound:isPlaying() then 
		return true 
	end
    	return false
end

TMRadio.getData = function(deviceData)
    	for _,t in ipairs(TMRadio.soundCache) do
        	if t.deviceData == deviceData then
            		return t
        	end
    	end
end

TMRadio.getEmitter = function(emitter)
    	for _,t in ipairs(TMRadio.soundCache) do
        	if t.sound.emitter == emitter then
            		return t
        	end
    	end
end

TMRadio.whereAreYou = function(device, index)
	local remove = nil
	local x = nil
	local y = nil
	local z = nil
	local deviceData = device.getDeviceData and device:getDeviceData() or nil

	if not device or not deviceData then
		return
	end

	-- if the radio is part of a vehicle
	if deviceData.isVehicleDevice and deviceData:isVehicleDevice() then
		x = deviceData:getParent():getVehicle():getX()
		y = deviceData:getParent():getVehicle():getY()
		z = deviceData:getParent():getVehicle():getZ()
		--print("location from vehicle")
	end

	-- if the radio is in the player inventory which includes primary and secondary hands and in bags
	if not x and device.isInPlayerInventory and device:isInPlayerInventory() then
		x = getPlayer():getX()
		y = getPlayer():getY()
		z = getPlayer():getZ()
		--print("location from player")
	end

	-- if the radio is in a square on on it's own
	if not x and device.getSquare and device:getSquare() then
		x = device:getX()
		y = device:getY()
		z = device:getZ()
		--print("location from self - has square uses direct getx")
	end
	if not x and device.getSquare and device:getSquare() then
		x = device:getSquare():getX()
		y = device:getSquare():getY()
		z = device:getSquare():getZ()
		--print("location from square - has square uses direct getx through square")
	end
	if not x and device.getX and device:getX() then
		x = device:getX()
		y = device:getY()
		z = device:getZ()
		--print("location from self - has no square")
	end

	-- if the radio is in a container like a crate but not a bag on the ground
	if not x and deviceData:isInventoryDevice() then
		if device.getContainer and device:getContainer() and
		   device.getOutermostContainer and device:getOutermostContainer() and
		   device.getOutermostContainer.getParent and device:getOutermostContainer():getParent() and 
		   device.getOutermostContainer.getParent.getX and device:getOutermostContainer():getParent():getX() then
			x = t.device:getOutermostContainer():getParent():getX()
			y = t.device:getOutermostContainer():getParent():getY()
			z = t.device:getOutermostContainer():getParent():getZ()
			--print("location from container")
		end
	end	

	if not x then
		local t = TMRadio.getData(deviceData)
		if t then 
			x = t.x
			y = t.y
			z = t.z
			--print("unable to get a new location, defaulted to last known location")
		else
			x = 0
			y = 0
			z = 0
			--print("unable to get a new location, defaulted zeros")
		end
		--if t and index and device.isSpriteInvisible and device:isSpriteInvisible() then
		--	t.sound:setVolume(0)
		--	t.muted = true
    	        --	TMRadio.updateVolume(t)
		--	t.sound:stop()
		--	table.remove(TMRadio.soundCache, index)	
		--	--print("It's dead, Jim.")
		--end
	end

	--if x and y and z then
	--	print("new location: " .. x .. " " .. y .. " " .. z)
	--end
	return {x = x, y = y, z = z}
end

TMRadio.ChooseSong = function(channel)
	if not channel then
		return
	end
	
	local songNumber = nil

	if channel == 94000 then 
		if isClient() then
			--print("Client choosesong: looking for playlist")
			if #TMRadioClient.PlaylistTerminalA > 0 then
				--print("Client choosesong: pulling A from client playlist")
				TMRadio.PlaylistTerminalA = TMRadioClient.PlaylistTerminalA
			end
		end
		if #TMRadio.PlaylistTerminalA == 0 then
			--print("Client choosesong: looking for playlist A in moddata")
			TMRadio.PlaylistTerminalA = ModData.getOrCreate("TMRadioA")
		end
		if #TMRadio.PlaylistTerminalA == 0 then
			--print("Client choosesong: unable to find playlist A creating new list")
			TMRadio.PlaylistTerminalA = TMRadio.CreatePlaylist()
		end
		songNumber = ZombRand(1, #TMRadio.PlaylistTerminalA)
	elseif channel == 94200 then 
		if isClient() then
			--print("Client choosesong: looking for playlist")
			if #TMRadioClient.PlaylistTerminalB > 0 then
				--print("Client choosesong: pulling B from client playlist")
				TMRadio.PlaylistTerminalB = TMRadioClient.PlaylistTerminalB
			end
		end
		if #TMRadio.PlaylistTerminalB == 0 then
			--print("Client choosesong: looking for playlist B in moddata")
			TMRadio.PlaylistTerminalB = ModData.getOrCreate("TMRadioB")
		end
		if #TMRadio.PlaylistTerminalB == 0 then
			--print("Client choosesong: unable to find playlist A creating new list")
			TMRadio.PlaylistTerminalB = TMRadio.CreatePlaylist()
		end
		songNumber = ZombRand(1, #TMRadio.PlaylistTerminalB)
	elseif channel == 94400 or channel == 94600 or channel == 94800 then
		if #TMRadio.PlaylistGlobal == 0 then
			--print("Client choosesong: unable to find default global playlist creating new default list")
			TMRadio.PlaylistGlobal = TMRadio.CreatePlaylist()
		end
		songNumber = ZombRand(1, #TMRadio.PlaylistGlobal)
	end
	
	return songNumber
end

TMRadio.CreatePlaylist = function()
	local tempGlobalPlaylist = {}

	for k,v in pairs(GlobalMusic) do
    		tempGlobalPlaylist[#tempGlobalPlaylist + 1] = k
	end

	--print("TMRadio: created a new GlobalTrueMusic playlist")
	return tempGlobalPlaylist
end