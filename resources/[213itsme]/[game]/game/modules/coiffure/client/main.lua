function Game.Marker(type, pos, color)
    DrawMarker(type, pos.x, pos.y, pos.z - 0.98, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, color[1], color[2], color[3], color[4] or 200, false, false, 2, false, nil, nil, false)
end

Citizen.CreateThread(function()
    for i, pos in ipairs(_COIFFURE.Positions) do
        local blip = AddBlipForCoord(pos.x, pos.y, pos.z)
        SetBlipSprite(blip, 71)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 0.8)
        SetBlipColour(blip, 1)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(_COIFFURE.BLIPSNAME)
        EndTextCommandSetBlipName(blip)
    end
end)

Citizen.CreateThread(function()
    while true do
        local wait = 1000
        local ped = PlayerPedId()
        local playerCoords = GetEntityCoords(ped)

        for i, pos in ipairs(_COIFFURE.Positions) do
            local distance = #(playerCoords - pos)

            if distance < 20.0 then
                wait = 0
                DrawMarker(25,pos.x, pos.y, pos.z - 0.98,0.0, 0.0, 0.0,0.0, 0.0, 0.0,1.0, 1.0, 1.0,51, 181, 229, 200,false, false, 2, false, nil, nil, false)
                if distance < 2.0 then
                    if IsControlJustPressed(0, 38) then
                        TriggerEvent("game-hair:toogleUI")
                    end
                end
            end
        end

        Citizen.Wait(wait)
    end
end)