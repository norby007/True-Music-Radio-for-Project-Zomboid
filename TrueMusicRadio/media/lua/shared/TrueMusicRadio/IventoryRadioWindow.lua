if isServer() then
	return 
end

TMRadio = TMRadio or {}

TMRadio.radioWindowFromInventory = function(playerIndex, menu, stack)
    	local item = nil
    	local items = nil
    	if stack and stack[1] and stack[1].items then
        	items = stack[1].items
        	item = items[1]
    	elseif stack and stack[1] then
        	item = stack[1]
    	end

    	if not item then 
		return 
	end

	if not item:isInPlayerInventory() then
		return
	end

	if not instanceof(item, "Radio") then
		return
	end

	local player = getSpecificPlayer(playerIndex)

	menu:addOptionOnTop(getText("IGUI_DeviceOptions"), player, function() ISRadioWindow.activate(player, item) end)
end

Events.OnFillInventoryObjectContextMenu.Add(TMRadio.radioWindowFromInventory)