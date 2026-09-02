_GAMEBILLINGESX = {
    isDead = false,
    bills = {}
}


function _GAMEBILLINGESX:CallbackToGiveBilling(cb)
    ESX.TriggerServerCallback('gamemode:billing:getBills', function(result)
        _GAMEBILLINGESX.bills = result or {}
        if cb then cb() end
    end)
end

function _GAMEBILLINGESX:OpenMenu()
    local main = RageUI.CreateMenu('Menu Personnel', 'INTERACTIONS (FACTURES)')
    RageUI.Visible(main, true)
    _GAMEBILLINGESX:CallbackToGiveBilling()
    while main do
        Citizen.Wait(0)
        RageUI.IsVisible(main, function()
            if #_GAMEBILLINGESX.bills <= 0 then
                RageUI.Separator('~r~Aucune facture')
            else
                for _, v in ipairs(_GAMEBILLINGESX.bills) do
                    RageUI.Button(v.label,('Montant : ~r~%s$ | Raison : ~b~%s'):format(ESX.Math.GroupDigits(v.amount), v.reason or 'N/A'),{},true,{
                        onSelected = function()
                            ESX.TriggerServerCallback('gamemode:billing:payBill', function(paid)
                                if paid then
                                    TriggerEvent('gamemode:billing:paidBill', v.id)
                                    ESX.ShowNotification('Facture payée')
                                else
                                    ESX.ShowNotification('~r~Paiement refusé')
                                end
                                _GAMEBILLINGESX:CallbackToGiveBilling()
                            end, v.id)
                        end
                    })
                end
            end
        end)
    end
end

RegisterCommand(_GAMEMODE.Bind["MenuFacture"].command, function()
    if _GAMEBILLINGESX.isDead then
        ESX.ShowNotification('Vous ne pouvez pas ouvrir le menu en étant mort')
        return
    end
    _GAMEBILLINGESX:OpenMenu()
end, false)

RegisterKeyMapping(_GAMEMODE.Bind["MenuFacture"].command,_GAMEMODE.Bind["MenuFacture"].description,'keyboard',_GAMEMODE.Bind["MenuFacture"].key)

AddEventHandler('esx:onPlayerDeath', function() _GAMEBILLINGESX.isDead = true end)
AddEventHandler('esx:onPlayerSpawn', function() _GAMEBILLINGESX.isDead = false end)
