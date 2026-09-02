local function billPlayerByIdentifier(targetIdentifier, senderIdentifier, sharedAccountName, label, amount, reason)
	local xTarget = ESX.GetPlayerFromIdentifier(targetIdentifier)
	amount = ESX.Math.Round(amount)
	reason = reason or 'Pas de raison spécifiée'

	if amount <= 0 then return end

	if string.match(sharedAccountName, "society_") then
		MySQL.insert.await(
			'INSERT INTO billing (identifier, sender, target_type, target, label, amount, reason) VALUES (?, ?, ?, ?, ?, ?, ?)',
			{ targetIdentifier, senderIdentifier, 'society', sharedAccountName, label, amount, reason }
		)

		if xTarget then
			xTarget.showNotification(TranslateCap('received_invoice'))
		end
		return
	end

	MySQL.insert.await(
		'INSERT INTO billing (identifier, sender, target_type, target, label, amount, reason) VALUES (?, ?, ?, ?, ?, ?, ?)',
		{ targetIdentifier, senderIdentifier, 'player', senderIdentifier, label, amount, reason }
	)

	if xTarget then
		xTarget.showNotification(TranslateCap('received_invoice'))
	end
end

local function billPlayer(targetId, senderIdentifier, sharedAccountName, label, amount, reason)
	local xTarget = ESX.GetPlayerFromId(targetId)
	if not xTarget then return end

	billPlayerByIdentifier(xTarget.identifier, senderIdentifier, sharedAccountName, label, amount, reason)
end

RegisterNetEvent('gamemode:billing:sendBill', function(targetId, sharedAccountName, label, amount, reason)
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)
	if not xPlayer then return end

	local jobName = string.gsub(sharedAccountName, 'society_', '')

	if xPlayer.job.name ~= jobName then
		return print(("[^2ERROR^7] Player ^5%s^7 Attempted to Send bill from a society (^5%s^7), but does not have the correct Job - Possibly Cheats")
			:format(_source, sharedAccountName))
	end

	billPlayer(targetId, xPlayer.identifier, sharedAccountName, label, amount, reason)
end)

exports("BillPlayer", billPlayer)

RegisterNetEvent('gamemode:billing:sendBillToIdentifier', function(targetIdentifier, sharedAccountName, label, amount, reason)
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)
	if not xPlayer then return end

	local jobName = string.gsub(sharedAccountName, 'society_', '')

	if xPlayer.job.name ~= jobName then
		return print(("[^2ERROR^7] Player ^5%s^7 Attempted to Send bill from a society (^5%s^7), but does not have the correct Job - Possibly Cheats")
			:format(_source, sharedAccountName))
	end

	billPlayerByIdentifier(targetIdentifier, xPlayer.identifier, sharedAccountName, label, amount, reason)
end)

exports("BillPlayerByIdentifier", billPlayerByIdentifier)

ESX.RegisterServerCallback('gamemode:billing:getBills', function(source, cb)
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)
	if not xPlayer then return cb({}) end

	local result = MySQL.query.await(
		'SELECT amount, id, label, reason FROM billing WHERE identifier = ?',
		{ xPlayer.identifier }
	)

	cb(result)
end)

ESX.RegisterServerCallback('gamemode:billing:getTargetBills', function(source, cb, target)
	local xPlayer = ESX.GetPlayerFromId(target)
	if not xPlayer then return cb({}) end

	local result = MySQL.query.await(
		'SELECT amount, id, label, reason FROM billing WHERE identifier = ?',
		{ xPlayer.identifier }
	)

	cb(result)
end)

ESX.RegisterServerCallback('gamemode:billing:payBill', function(source, cb, billId)
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)
	if not xPlayer then return cb() end

	local result = MySQL.single.await(
		'SELECT sender, target_type, target, amount FROM billing WHERE id = ?',
		{ billId }
	)
	if not result then return cb() end

	local amount = result.amount
	local xTarget = ESX.GetPlayerFromIdentifier(result.sender)

	if result.target_type == 'player' then
		if not xTarget then
			xPlayer.showNotification(TranslateCap('player_not_online'))
			return cb()
		end

		local paymentAccount = 'money'
		if xPlayer.getMoney() < amount then
			paymentAccount = 'bank'
			if xPlayer.getAccount('bank').money < amount then
				xTarget.showNotification(TranslateCap('target_no_money'))
				xPlayer.showNotification(TranslateCap('no_money'))
				return cb()
			end
		end

		local rowsChanged = MySQL.update.await(
			'DELETE FROM billing WHERE id = ?',
			{ billId }
		)
		if rowsChanged ~= 1 then return cb() end

		xPlayer.removeAccountMoney(paymentAccount, amount, "Bill Paid")
		xTarget.addAccountMoney(paymentAccount, amount, "Paid bill")

		local groupedDigits = ESX.Math.GroupDigits(amount)
		xPlayer.showNotification(TranslateCap('paid_invoice', groupedDigits))
		xTarget.showNotification(TranslateCap('received_payment', groupedDigits))

		return cb(true)
	end

	TriggerEvent('esx_addonaccount:getSharedAccount', result.target, function(account)
		local paymentAccount = 'money'
		if xPlayer.getMoney() < amount then
			paymentAccount = 'bank'
			if xPlayer.getAccount('bank').money < amount then
				if xTarget then
					xTarget.showNotification(TranslateCap('target_no_money'))
				end
				xPlayer.showNotification(TranslateCap('no_money'))
				return cb()
			end
		end

		local rowsChanged = MySQL.update.await(
			'DELETE FROM billing WHERE id = ?',
			{ billId }
		)
		if rowsChanged ~= 1 then return cb() end

		xPlayer.removeAccountMoney(paymentAccount, amount, "Bill Paid")
		account.addMoney(amount)

		TriggerEvent("gamemode:billing:paidBill", _source, billId)

		local groupedDigits = ESX.Math.GroupDigits(amount)
		xPlayer.showNotification(TranslateCap('paid_invoice', groupedDigits))

		if xTarget then
			xTarget.showNotification(TranslateCap('received_payment', groupedDigits))
		end

		cb(true)
	end)
end)
