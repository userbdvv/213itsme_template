---@param src number
---@param xPlayer table
AddEventHandler('esx:playerLoaded', function(src, xPlayer)
	local identifier = xPlayer.getIdentifier()

	local status = MySQL.scalar.await(
		'SELECT `status` FROM `users` WHERE `identifier` = ? LIMIT 1',
		{ identifier }
	)

	status = status and json.decode(status) or {}
	xPlayer.set('status', status)

	TriggerClientEvent('esx_status:load', src, status)
end)

---@param src number
---@param reason string
AddEventHandler('esx:playerDropped', function(src, reason)
	local source = src
	local xPlayer = ESX.GetPlayerFromId(source)
	if not xPlayer then return end

	local status = xPlayer.get('status') or {}
	MySQL.update(
		'UPDATE users SET status = ? WHERE identifier = ?',
		{ json.encode(status), xPlayer.getIdentifier() }
	)
end)

---@param src number
---@param statusName string
---@param cb function|table
AddEventHandler('esx_status:getStatus', function(src, statusName, cb)
	local source = src
	local xPlayer = ESX.GetPlayerFromId(source)
	if not xPlayer then return end

	local status = xPlayer.get('status') or {}
	for i = 1, #status do
		if status[i].name == statusName then
			cb(status[i])
			return
		end
	end
end)

---@param status table
RegisterNetEvent('esx_status:update', function(status)
	local source = source
	local xPlayer = ESX.GetPlayerFromId(source)
	if not xPlayer then return end

	xPlayer.set('status', status)
end)