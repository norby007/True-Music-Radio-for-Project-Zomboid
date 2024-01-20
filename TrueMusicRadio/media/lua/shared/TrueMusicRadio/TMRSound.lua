if isServer() then
	return
end

TMRSound = {
    	emitter = nil,
    	id = nil,
    	x = 0,
    	y = 0,
    	z = 0,
    	volume = 1,
    	volumeModifier = 1,
    	sound3D = false,
}

function TMRSound:new()
    	local o = {}
	setmetatable(o, self)
    	self.__index = self
	return o
end

function TMRSound:setEmitter(emitter)
    	self.emitter = emitter
end

function TMRSound:play(sound)
    	local hasEmitter = self.emitter
    	local hadId = self.id

    	if hasEmitter then
        	self:stop()
    	else
        	self.emitter = IsoWorld.instance:getFreeEmitter()
        	self.emitter:setPos(self.x, self.y, self.z)
    	end
    	local gameSound = GameSounds.getSound(sound)
    	local gameSoundClip = gameSound:getRandomClip()
    	self.id = self.emitter:playClip(gameSoundClip, nil)
    	self.emitter:setVolume(self.id, self.volume * self.volumeModifier)
    	self.emitter:set3D(self.id, self.sound3D)
    	self.emitter:tick()
end

function TMRSound:stop()
    	if self.emitter and self.id then
        	self.emitter:stopSound(self.id)
    	end
    	self.id = nil
end

function TMRSound:isPlaying()
    	if not self.id then 
		return false 
	end
    	return self.emitter and self.emitter:isPlaying(self.id)
end

function TMRSound:setVolume(value)
    	self.volume = value
    	if self.id then
        	self.emitter:setVolume(self.id, self.volume * self.volumeModifier)
        	self.emitter:tick()
    	end
end
function TMRSound:setVolumeModifier(value)
    	self.volumeModifier = value
    	if self.id then
        	self:setVolume(self.volume)
    	end
end

function TMRSound:setPos(x,y,z)
    	self.x = x+0.5
    	self.y = y+0.5
    	self.z = z or 0
    	self:set3D(true)
    
    	if self.emitter then
        	self.emitter:setPos(x, y, z)
        	self.emitter:tick()
    	end
end

function TMRSound:setPosAtObject(obj)
    	if not obj then 
		return 
	end
    	self:setPos(obj:getX(), obj:getY(), obj:getZ())
end

function TMRSound:set3D(bool)
    	if bool == nil then 
		bool = true 
	end
    	self.sound3D = bool
    	if self.id then
        	self.emitter:set3D(self.id, self.sound3D)
        	self.emitter:tick()
    	end
end