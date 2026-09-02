local GAME_CHARACTER = {}
local uiOpen = false

local creatorSkin = {
    sex = 0,
    dad = 0,
    mom = 0,
    face_md_weight = 50,
    skin_md_weight = 50,
    hair_1 = 0,
    hair_2 = 0,
    hair_color_1 = 0,
    hair_color_2 = 0,
    tshirt_1 = 15,
    tshirt_2 = 0,
    torso_1 = 15,
    torso_2 = 0,
    decals_1 = 0,
    decals_2 = 0,
    arms = 15,
    pants_1 = 61,
    pants_2 = 0,
    shoes_1 = 34,
    shoes_2 = 0,
    mask_1 = 0,
    mask_2 = 0,
    bproof_1 = 0,
    bproof_2 = 0,
    chain_1 = 0,
    chain_2 = 0,
    helmet_1 = -1,
    helmet_2 = 0,
    glasses_1 = 0,
    glasses_2 = 0,
    watches_1 = -1,
    watches_2 = 0,
    bracelets_1 = -1,
    bracelets_2 = 0,
    bags_1 = 0,
    bags_2 = 0,
    eye_color = 0,
    eyebrows_1 = 0,
    eyebrows_2 = 100,
    eyebrows_3 = 0,
    eyebrows_4 = 0,
    eyebrows_5 = 0,
    eyebrows_6 = 0,
    beard_1 = 0,
    beard_2 = 100,
    beard_3 = 0,
    beard_4 = 0,
    chest_1 = 0,
    chest_2 = 100,
    chest_3 = 0,
    chest_4 = 0,
    makeup_1 = 0,
    makeup_2 = 100,
    makeup_3 = 0,
    makeup_4 = 0,
    lipstick_1 = 0,
    lipstick_2 = 100,
    lipstick_3 = 0,
    lipstick_4 = 0,
    blush_1 = 0,
    blush_2 = 100,
    blush_3 = 0,
    blemishes_1 = 0,
    blemishes_2 = 100,
    age_1 = 0,
    age_2 = 100,
    complexion_1 = 0,
    complexion_2 = 100,
    sun_1 = 0,
    sun_2 = 100,
    moles_1 = 0,
    moles_2 = 100,
    bodyb_1 = 0,
    bodyb_2 = 100,
    bodyb_3 = 0,
    bodyb_4 = 100,
    nose_1 = 0,
    nose_2 = 0,
    nose_3 = 0,
    nose_4 = 0,
    nose_5 = 0,
    nose_6 = 0,
    cheeks_1 = 0,
    cheeks_2 = 0,
    cheeks_3 = 0,
    lip_thickness = 0,
    jaw_1 = 0,
    jaw_2 = 0,
    chin_1 = 0,
    chin_2 = 0,
    chin_3 = 0,
    chin_4 = 0,
    neck_thickness = 0
}


function SetSex(sex)
    creatorSkin.sex = sex
    TriggerEvent('skinchanger:loadDefaultModel', sex == 0, function()
        Wait(150)
        TriggerEvent('skinchanger:loadSkin', creatorSkin)
    end)
end

function SetSkinValue(key, value)
    creatorSkin[key] = value
    TriggerEvent('skinchanger:change', key, value)
end

function CreateCreatorCam()
    GAME_CHARACTER.Cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(GAME_CHARACTER.Cam, -1380.20, -469.60, 72.71)
    SetCamRot(GAME_CHARACTER.Cam, -18.17, 0.0, -173.05)
    SetCamActive(GAME_CHARACTER.Cam, true)
    RenderScriptCams(true, false, 0, true, true)
end

function ChangeCreatorCam(mode)
    if not GAME_CHARACTER.Cam then
        return
    end

    if mode == "face" then
        SetCamCoord(GAME_CHARACTER.Cam, -1379.9219970703, -470.79162597656, 72.722442626953)
        SetCamRot(GAME_CHARACTER.Cam, -8.0461902618408, 0.0, -173.14645385742)
    else
        SetCamCoord(GAME_CHARACTER.Cam, -1380.20, -469.60, 72.71)
        SetCamRot(GAME_CHARACTER.Cam, -18.17, 0.0, -173.05)
    end
end

function DeleteCreatorCam()
    if GAME_CHARACTER.Cam then
        RenderScriptCams(false, true, 300, true, true)
        DestroyCam(GAME_CHARACTER.Cam, false)
        GAME_CHARACTER.Cam = nil
    end
end

function SetCharacterUi(state)
    uiOpen = state
    SetNuiFocus(state, state)

    if state then
        DoScreenFadeOut(800)
        while not IsScreenFadedOut() do
            Wait(0)
        end

        SetEntityCoords(PlayerPedId(), -1379.873, -471.1302, 71.04224)
        SetEntityHeading(PlayerPedId(), 12.83)
        FreezeEntityPosition(PlayerPedId(), true)

        CreateCreatorCam()
        ChangeCreatorCam("body")

        TriggerEvent('skinchanger:getSkin', function(skin)
            if skin then
                for k, v in pairs(skin) do
                    creatorSkin[k] = v
                end
            end

            SendNUIMessage({
                action = "toggle",
                show = true,
                skin = creatorSkin
            })
        end)

        Wait(500)
        DoScreenFadeIn(800)
    else
        FreezeEntityPosition(PlayerPedId(), false)
        DeleteCreatorCam()

        SendNUIMessage({
            action = "toggle",
            show = false
        })
    end
end

RegisterNUICallback("close", function(_, cb)
    SetCharacterUi(false)
    cb("ok")
end)

RegisterNUICallback("switchCamera", function(data, cb)
    if data and data.mode then
        ChangeCreatorCam(data.mode)
    end
    cb("ok")
end)

RegisterNUICallback("creator:update", function(data, cb)
    if not data or not data.key then
        cb("ok")
        return
    end

    local key = data.key
    local value = tonumber(data.value) or 0

    if key == "sex" then
        SetSex(value)
        cb("ok")
        return
    end

    if key == "dad" or key == "mom" then
        SetSkinValue(key, value)
        cb("ok")
        return
    end

    if key == "face_md_weight" or key == "skin_md_weight" then
        SetSkinValue(key, value)
        cb("ok")
        return
    end

    if key == "eye_color"
    or key == "hair_1" or key == "hair_2" or key == "hair_color_1" or key == "hair_color_2"
    or key == "eyebrows_1" or key == "eyebrows_2" or key == "eyebrows_3" or key == "eyebrows_4" or key == "eyebrows_5" or key == "eyebrows_6"
    or key == "beard_1" or key == "beard_2" or key == "beard_3" or key == "beard_4"
    or key == "chest_1" or key == "chest_2" or key == "chest_3" or key == "chest_4"
    or key == "blemishes_1" or key == "blemishes_2"
    or key == "age_1" or key == "age_2"
    or key == "complexion_1" or key == "complexion_2"
    or key == "sun_1" or key == "sun_2"
    or key == "moles_1" or key == "moles_2"
    or key == "bodyb_1" or key == "bodyb_2" or key == "bodyb_3" or key == "bodyb_4"
    or key == "makeup_1" or key == "makeup_2" or key == "makeup_3" or key == "makeup_4"
    or key == "lipstick_1" or key == "lipstick_2" or key == "lipstick_3" or key == "lipstick_4"
    or key == "blush_1" or key == "blush_2" or key == "blush_3"
    or key == "nose_1" or key == "nose_2" or key == "nose_3" or key == "nose_4" or key == "nose_5" or key == "nose_6"
    or key == "cheeks_1" or key == "cheeks_2" or key == "cheeks_3"
    or key == "lip_thickness"
    or key == "jaw_1" or key == "jaw_2"
    or key == "chin_1" or key == "chin_2" or key == "chin_3" or key == "chin_4"
    or key == "neck_thickness"
    or key == "tshirt_1" or key == "tshirt_2"
    or key == "torso_1" or key == "torso_2"
    or key == "decals_1" or key == "decals_2"
    or key == "arms"
    or key == "pants_1" or key == "pants_2"
    or key == "shoes_1" or key == "shoes_2"
    or key == "mask_1" or key == "mask_2"
    or key == "bproof_1" or key == "bproof_2"
    or key == "chain_1" or key == "chain_2"
    or key == "helmet_1" or key == "helmet_2"
    or key == "glasses_1" or key == "glasses_2"
    or key == "watches_1" or key == "watches_2"
    or key == "bracelets_1" or key == "bracelets_2"
    or key == "bags_1" or key == "bags_2" then
        SetSkinValue(key, value)
        cb("ok")
        return
    end

    cb("ok")
end)

RegisterNUICallback("creator:submit", function(data, cb)
    if not data then
        cb({ ok = false, message = "invalid_data" })
        return
    end

    local firstname = tostring(data.firstname or "")
    local lastname = tostring(data.lastname or "")
    local dateofbirth = tostring(data.dateofbirth or "")
    local height = tonumber(data.height) or 180

    TriggerEvent('skinchanger:getSkin', function(skin)
        if skin then
            creatorSkin = skin
        end

        TriggerServerEvent('creator:saveCharacter', {
            firstname = firstname,
            lastname = lastname,
            dateofbirth = dateofbirth,
            height = height,
            sex = creatorSkin.sex,
            skin = creatorSkin
        })

        cb({ ok = true })

        DoScreenFadeOut(800)
        while not IsScreenFadedOut() do
            Wait(0)
        end

        GAME_CHARACTER:Spawn()

        Wait(500)
        DoScreenFadeIn(800)
    end)
end)

function GAME_CHARACTER:Spawn()
    local ped = PlayerPedId()

    SetEntityCoords(ped, -1310.3289794922, -449.43832397461, 34.780517578125, false, false, false, true)
    SetEntityHeading(ped, 125.83535766602)
end

RegisterNetEvent('game-creator:open')
AddEventHandler('game-creator:open', function()
    SetCharacterUi(true)
end)

RegisterNetEvent('creator:saved', function()
    SetCharacterUi(false)
end)