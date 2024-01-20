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
		if #TMRadioClient.PlaylistTerminalA > 0 then
			TMRadio.PlaylistTerminalA = TMRadioClient.PlaylistTerminalA
		end
		if #TMRadioClient.PlaylistTerminalB > 0 then
			TMRadio.PlaylistTerminalB = TMRadioClient.PlaylistTerminalB
		end
	end

	if #TMRadio.PlaylistTerminalA == 0 then
		TMRadio.PlaylistTerminalA = ModData.getOrCreate("TMRadioA")
	end
	if #TMRadio.PlaylistTerminalB == 0 then
		TMRadio.PlaylistTerminalB = ModData.getOrCreate("TMRadioB")
	end

	if #TMRadio.PlaylistTerminalA == 0 then
		TMRadio.PlaylistTerminalA = TMRadio.CreatePlaylist()
	end
	if #TMRadio.PlaylistTerminalB == 0 then
		TMRadio.PlaylistTerminalB = TMRadio.CreatePlaylist()
	end

	if #TMRadio.PlaylistGlobal == 0 then
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

	if songName == nil then
		print("TMRadio: Error processing requested song")
		return
	else
		print("TMRadio: Playing song[" .. number .. "] " .. songName)
		sound:play(songName)
	end

    	t = t or {}
	t.x = device:getX()
	t.y = device:getY()
	t.z = device:getZ()
    	t.device = device
    	t.deviceData = deviceData
    	t.channel = deviceData:getChannel()
    	t.sound = sound
	t.muted = false
    	tickCounter2 = 200

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

	for index,t in ipairs(TMRadio.soundCache) do
		if t.device ~= nil then
			t.x = t.device:getX()
			t.y = t.device:getY()
			t.z = t.device:getZ()
		end
		local square = getSquare(t.x, t.y, t.z)
		if square == nil then 
			t.sound:setVolume(0)
			t.muted = true
                	TMRadio.updateVolume(t)
			t.sound:stop()
			table.remove(TMRadio.soundCache, index)
			--print("TMRadio: Soundcache counter after removing sound: [" .. #TMRadio.soundCache .. "/" .. TMRadio.cacheSize .. "]")
		else
			local deviceData = t.device:getDeviceData()
			if deviceData:getChannel() == channel then
				TMRadio.PlaySound(number, t.device)
			end
		end
	end
end

---------------------------
-- INTERACTION OVERRIDES --
---------------------------

TMRadio.AddOverrides = function()
    	local ISRadioAction_performToggleOnOff = ISRadioAction.performToggleOnOff
    	function ISRadioAction:performToggleOnOff()
        	ISRadioAction_performToggleOnOff(self)
        	local t = TMRadio.getData(self.deviceData)
        	if t then
            		if t.deviceData:getIsTurnedOn() and t.deviceData:getChannel() == t.channel then
                		t.muted = false
            		else
                		t.muted = true -- mute sound instead of stopping it, so we can turn it back on
            		end
            		TMRadio.updateVolume(t)
        	elseif self.deviceData:getIsTurnedOn() and (self.deviceData:getChannel() == 94000 or self.deviceData:getChannel() == 94200 or self.deviceData:getChannel() == 94400 or self.deviceData:getChannel() == 94600 or self.deviceData:getChannel() == 94800) then
			local songNumber = TMRadio.ChooseSong(self.deviceData:getChannel())
			if isClient() and not self.deviceData:isInventoryDevice() then
				local args = {x = self.deviceData:getParent():getX(), y = self.deviceData:getParent():getY(), z = self.deviceData:getParent():getZ(), channel = self.deviceData:getChannel(), number = songNumber}
				sendClientCommand("TMRadio", "Play", args)
			else
				if not TMRadio.Channels[self.deviceData:getChannel()] then 
					TMRadio.Channels[self.deviceData:getChannel()] = songNumber
					TMRadio.PlaySound(songNumber, self.deviceData:getParent())
				else
					TMRadio.PlaySound(TMRadio.Channels[self.deviceData:getChannel()], self.deviceData:getParent())
				end
			end
		end
    	end
    
    	local ISRadioAction_performSetChannel = ISRadioAction.performSetChannel
    	function ISRadioAction:performSetChannel()
		local channelBefore = nil
        	local t = TMRadio.getData(self.deviceData)
        	if t then
			if TMRadio.isPlaying(t) then
				channelBefore = t.channel
			end
        	end
        	ISRadioAction_performSetChannel(self)
		if t and channelBefore ~= nil then
			if self.deviceData:getChannel() == channelBefore then
				return
            		elseif self.deviceData:getChannel() == 94000 or self.deviceData:getChannel() == 94200 or self.deviceData:getChannel() == 94400 or self.deviceData:getChannel() == 94600 or self.deviceData:getChannel() == 94800 then
                		t.muted = false
            		else
                		t.muted = true -- mute sound instead of stopping it, so we can switch back to the channel
            		end
            		TMRadio.updateVolume(t)
		end
        	if self.deviceData:getIsTurnedOn() and (self.deviceData:getChannel() == 94000 or self.deviceData:getChannel() == 94200 or self.deviceData:getChannel() == 94400 or self.deviceData:getChannel() == 94600 or self.deviceData:getChannel() == 94800) then
			local songNumber = TMRadio.ChooseSong(self.deviceData:getChannel())
			if isClient() and not self.deviceData:isInventoryDevice() then
				local args = {x = self.deviceData:getParent():getX(), y = self.deviceData:getParent():getY(), z = self.deviceData:getParent():getZ(), channel = self.deviceData:getChannel(), number = songNumber}
				sendClientCommand("TMRadio", "Play", args)
			else
				if not TMRadio.Channels[self.deviceData:getChannel()] then 
					TMRadio.Channels[self.deviceData:getChannel()] = songNumber
					TMRadio.PlaySound(songNumber, self.deviceData:getParent())
				else
					TMRadio.PlaySound(TMRadio.Channels[self.deviceData:getChannel()], self.deviceData:getParent())
				end
			end
		end
    	end
    
    	local ISRadioAction_performSetVolume = ISRadioAction.performSetVolume
    	function ISRadioAction:performSetVolume()
        	if self:isValidSetVolume() then
            		ISRadioAction_performSetVolume(self)
            		local t = TMRadio.getData(self.deviceData)
            		if t then
                		TMRadio.updateVolume(t)
           		end
        	end
    	end

    	local ISEnterVehicle_perform = ISEnterVehicle.perform
    	function ISEnterVehicle:perform()
        	ISEnterVehicle_perform(self)
        	local t = TMRadio.getEmitter( self.character:getVehicle():getEmitter() )
        	if t then
            		t.sound:setVolumeModifier(0.8)
            		t.sound:set3D(false) -- no 3d sound while in car, it sounds glitchy
            		TMRadio.updateVolume(t)
        	end
    	end
    
    	local ISExitVehicle_perform = ISExitVehicle.perform
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
        	ISExitVehicle_perform(self)
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
local vehicleEmitter = nil
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
        	--attract zombies
        	for _,t in ipairs(TMRadio.soundCache) do
            		if TMRadio.isPlaying(t) and t.deviceData:getHeadphoneType() == -1 and t.device == t.deviceData:getParent() then
                		local range = t.deviceData:getDeviceVolume() * t.sound.volumeModifier*2.5 * maxRange
                		if t.deviceData:isInventoryDevice() or t.deviceData:isVehicleDevice() then
                    			addSound(p, X, Y, Z, range/4, range/2)
                		else
                    			addSound(t.device, t.device:getX(), t.device:getY(), t.device:getZ(), maxRange, maxRange) 
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

	if isClient() and syncPlaylistRequest == true then
		TMRadioClient.UpdatePlaylistFromServer()
		syncPlaylistRequest = false
	end

	for index,t in ipairs(TMRadio.soundCache) do  
		if not t.deviceData:isInventoryDevice() and not (t.deviceData:isVehicleDevice() and p:getVehicle()) then
			distanceToRadio = math.sqrt((X - t.x) ^ 2 + (Y - t.y) ^ 2 + (Z - t.z) ^ 2)
			if distanceToRadio > 75 then
				t.sound:setVolume(0)
				t.muted = true
     	         		TMRadio.updateVolume(t)
				t.sound:stop()
				table.remove(TMRadio.soundCache, index)
				--print("TMRadio: Tick after removing sound due to distance: " .. distanceToRadio .. " [" .. #TMRadio.soundCache .. "/" .. TMRadio.cacheSize .. "]")
			end
		end
	end

    	highestVolume = 0

    	for index,t in ipairs(TMRadio.soundCache) do        
        	-- sync states
        	if t.sound and t.sound:isPlaying() then
            		if not t.deviceData:isVehicleDevice() and t.device ~= t.deviceData:getParent() then 
                		-- device object changed, this happens when the player picks up or places objects. no idea what's up with car radios
                		t.device = t.deviceData:getParent() -- update our device reference
                		if t.deviceData:isInventoryDevice() then
                    			t.sound:set3D(false)
                		else
                    			t.sound:setPosAtObject(t.device)
                		end
            		end
            		if t.deviceData:isInventoryDevice() and t.deviceData:getIsTurnedOn() and t.device:getType() ~= "CDplayer" then -- make an exception for CDplayer
                		if t.device ~= p:getPrimaryHandItem() and t.device ~= p:getSecondaryHandItem() then -- devices only work if equipped & should be switched off otherwise
                    			t.deviceData:setIsTurnedOn(false) -- turn device off in case zomboid didn't do so
                		end
            		end
            		if not t.deviceData:getIsTurnedOn() and not t.muted then -- device was switched off without player action
                		t.muted = true -- sync sound accordingly
                		TMRadio.updateVolume(t)
            		end
        	end
        	--adjust volume based on distance
        	if TMRadio.isPlaying(t) then
    			if not t.muted then
        			t.sound:setVolume(t.deviceData:getDeviceVolume())
    			end
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
		elseif t.deviceData:getParent() ~= nil and t.deviceData:getIsTurnedOn() then 
    			if not t.muted then
        			t.sound:setVolume(t.deviceData:getDeviceVolume())
    			end
            		if t.deviceData:isInventoryDevice() then
                		highestVolume = 1
			end
			if t.deviceData:isVehicleDevice() and p:getVehicle() then
        			if t.deviceData:getParent():getVehicle() == p:getVehicle() then
           				highestVolume = 1
				end
			end
			if highestVolume == 0 then
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
			if tickCounter3 > 25 and (t.deviceData:getChannel() == 94000 or t.deviceData:getChannel() == 94200 or t.deviceData:getChannel() == 94400 or t.deviceData:getChannel() == 94600 or t.deviceData:getChannel() == 94800) then
				tickCounter3 = 0
				--print("TMRadio: Song ended play another")
				local songNumber = TMRadio.ChooseSong(t.deviceData:getChannel())
				if isClient() then
					local args = {x = t.x, y = t.y, z = t.z, channel = t.deviceData:getChannel(), number = songNumber}
					sendClientCommand("TMRadio", "PlayNext", args)
				else
					TMRadio.UpdateSoundCache(songNumber, t.deviceData:getChannel())
				end
			else
				tickCounter3 = tickCounter3 + 1
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

TMRadio.ChooseSong = function(channel)
	if not channel then
		return
	end
	
	local songNumber = nil

	if channel == 94000 then 
		if isClient() then
			if #TMRadioClient.PlaylistTerminalA > 0 then
				TMRadio.PlaylistTerminalA = TMRadioClient.PlaylistTerminalA
			end
		end
		if #TMRadio.PlaylistTerminalA == 0 then
			TMRadio.PlaylistTerminalA = ModData.getOrCreate("TMRadioA")
		end
		if #TMRadio.PlaylistTerminalA == 0 then
			TMRadio.PlaylistTerminalA = TMRadio.CreatePlaylist()
		end
		songNumber = ZombRand(1, #TMRadio.PlaylistTerminalA+1)
	elseif channel == 94200 then 
		if isClient() then
			if #TMRadioClient.PlaylistTerminalB > 0 then
				TMRadio.PlaylistTerminalB = TMRadioClient.PlaylistTerminalB
			end
		end
		if #TMRadio.PlaylistTerminalB == 0 then
			TMRadio.PlaylistTerminalB = ModData.getOrCreate("TMRadioB")
		end
		if #TMRadio.PlaylistTerminalB == 0 then
			TMRadio.PlaylistTerminalB = TMRadio.CreatePlaylist()
		end
		songNumber = ZombRand(1, #TMRadio.PlaylistTerminalB+1)
	elseif channel == 94400 or channel == 94600 or channel == 94800 then
		if #TMRadio.PlaylistGlobal == 0 then
			TMRadio.PlaylistGlobal = TMRadio.CreatePlaylist()
		end
		songNumber = ZombRand(1, #TMRadio.PlaylistGlobal+1)
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