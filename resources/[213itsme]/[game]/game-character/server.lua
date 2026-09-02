ESX = exports['game']:getSharedObject()

local function trim(value)
    return (value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

RegisterNetEvent('creator:saveCharacter', function(data)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then
        return
    end

    local firstname = trim(tostring(data.firstname or ""))
    local lastname = trim(tostring(data.lastname or ""))
    local dateofbirth = trim(tostring(data.dateofbirth or ""))
    local height = tonumber(data.height) or 180
    local sexValue = tonumber(data.sex) or 0
    local dbSex = sexValue == 1 and 'f' or 'm'
    local skin = data.skin or {}

    if firstname == "" or lastname == "" or dateofbirth == "" then
        TriggerClientEvent('esx:showNotification', src, 'Informations invalides')
        return
    end

    if #firstname > 16 then firstname = firstname:sub(1, 16) end
    if #lastname > 16 then lastname = lastname:sub(1, 16) end
    if #dateofbirth > 10 then dateofbirth = dateofbirth:sub(1, 10) end

    if height < 120 then height = 120 end
    if height > 220 then height = 220 end

    local identifier = xPlayer.identifier
    local skinJson = json.encode(skin)

    local updated = MySQL.update.await([[
        UPDATE users
        SET firstname = ?, lastname = ?, dateofbirth = ?, sex = ?, height = ?, skin = ?
        WHERE identifier = ?
    ]], {
        firstname,
        lastname,
        dateofbirth,
        dbSex,
        height,
        skinJson,
        identifier
    })

    if updated and updated > 0 then
        TriggerClientEvent('esx:showNotification', src, 'Personnage créé')
        TriggerClientEvent('creator:saved', src)
    else
        TriggerClientEvent('esx:showNotification', src, 'Erreur sauvegarde')
    end
end)

AddEventHandler('esx:playerLoaded', function(playerId, xPlayer)
    Citizen.Wait(1000)
    local identifier = xPlayer.identifier

    MySQL.Async.fetchAll('SELECT firstname, lastname FROM users WHERE identifier = @identifier', {
        ['@identifier'] = identifier
    }, function(result)
        if not result[1] or not result[1].firstname or result[1].firstname == '' then
            Wait(1000)
            TriggerClientEvent('game-creator:open', playerId)
        end
    end)
end)