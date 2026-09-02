local uiOpen = false
local GAME_CHARACTER = {}
GAME_CHARACTER.Cam = nil

function CreateCreatorCam()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    GAME_CHARACTER.Cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)

    local offset = GetOffsetFromEntityInWorldCoords(ped, 0.0, 2.2, 0.7)
    SetCamCoord(GAME_CHARACTER.Cam, offset.x, offset.y, offset.z)

    PointCamAtEntity(GAME_CHARACTER.Cam, ped, 0.0, 0.0, 0.65, true)

    SetCamActive(GAME_CHARACTER.Cam, true)
    RenderScriptCams(true, false, 0, true, true)
end

function ChangeCreatorCam(mode)
    if not GAME_CHARACTER.Cam then return end

    local ped = PlayerPedId()

    if mode == "face" then
        local offset = GetOffsetFromEntityInWorldCoords(ped, 0.0, 0.8, 0.7)
        SetCamCoord(GAME_CHARACTER.Cam, offset.x, offset.y, offset.z)
        PointCamAtEntity(GAME_CHARACTER.Cam, ped, 0.0, 0.0, 0.65, true)
    else
        local offset = GetOffsetFromEntityInWorldCoords(ped, 0.0, 2.2, 0.7)
        SetCamCoord(GAME_CHARACTER.Cam, offset.x, offset.y, offset.z)
        PointCamAtEntity(GAME_CHARACTER.Cam, ped, 0.0, 0.0, 0.5, true)
    end
end

function DeleteCreatorCam()
    if GAME_CHARACTER.Cam then
        RenderScriptCams(false, true, 300, true, true)
        DestroyCam(GAME_CHARACTER.Cam, false)
        GAME_CHARACTER.Cam = nil
    end
end

local function setNui(state)
    uiOpen = state
    SetNuiFocus(state, state)

    if state then
        CreateCreatorCam()
        ChangeCreatorCam("body")
    else
        DeleteCreatorCam()
    end

    SendNUIMessage({
        action = 'setVisible',
        visible = state
    })
end

local function openClotg()
    TriggerEvent('skinchanger:getSkin', function(skin)
        TriggerEvent('skinchanger:getData', function(_, maxVals)
            setNui(true)

            SendNUIMessage({
                action = 'hydrate',
                skin = skin or {},
                maxVals = maxVals or {}
            })
        end)
    end)
end

RegisterCommand("test", function()
    openClotg()
end)

RegisterNetEvent("game-hair:toogleUI")
AddEventHandler("game-hair:toogleUI", function()
    if uiOpen then
        setNui(false)
    else
        openClotg()
    end
end)

RegisterNUICallback('close', function(_, cb)
    setNui(false)
    cb('ok')
end)

RegisterNUICallback('uiReady', function(_, cb)
    TriggerEvent('skinchanger:getSkin', function(skin)
        TriggerEvent('skinchanger:getData', function(_, maxVals)
            cb({
                ok = true,
                skin = skin or {},
                maxVals = maxVals or {}
            })
        end)
    end)
end)

RegisterNUICallback('applySkin', function(data, cb)
    if data and data.skin then
        TriggerEvent('skinchanger:loadSkin', data.skin)
    end
    cb('ok')
end)

RegisterNUICallback('saveSkin', function(data, cb)
    if data and data.skin then
        TriggerEvent('skinchanger:loadSkin', data.skin)
        TriggerServerEvent('esx_skin:save', data.skin)
    end

    setNui(false)
    cb('ok')
end)

RegisterNUICallback('changeCamera', function(data, cb)
    if data and data.mode then
        if data.mode == 'face' then
            ChangeCreatorCam('face')
        else
            ChangeCreatorCam('body')
        end
    end

    cb('ok')
end)