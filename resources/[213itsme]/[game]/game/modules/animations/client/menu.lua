local ESX = exports['game']:getSharedObject()

local open = false
local menuemote = RageUI.CreateMenu('Animations', 'Menu Personnel')
local smdance = RageUI.CreateSubMenu(menuemote, 'Animations', 'Dance')
local smobjet = RageUI.CreateSubMenu(menuemote, 'Animations', 'Objet')
local smgeste = RageUI.CreateSubMenu(menuemote, 'Animations', 'Action')
local smautre = RageUI.CreateSubMenu(menuemote, 'Animations', 'Divers')
local smactivite = RageUI.CreateSubMenu(menuemote, 'Animations', 'Activité')
local smpos = RageUI.CreateSubMenu(menuemote, 'Animations', 'Position')
local smsport = RageUI.CreateSubMenu(menuemote, 'Animations', 'Sport')
local smsante = RageUI.CreateSubMenu(menuemote, 'Animations', 'Santé')
local smmarche = RageUI.CreateSubMenu(menuemote, 'Animations', 'Style de marche')
local smshortcut = RageUI.CreateSubMenu(menuemote, 'Animation', 'Actions')

local raccourcis = {
    [1] = nil,
    [2] = nil,
    [3] = nil,
    [4] = nil
}

local selectedShortcutAnim = nil
local previewPed = nil
local previewActive = false
local previewAnimName = nil
local previewBuffer = {}
local categoryFilters = {
    dance = '',
    objet = '',
    geste = '',
    autre = '',
    activite = '',
    pos = '',
    sport = '',
    sante = ''
}

local shortcutAnimationIds = {
    [1] = 0,
    [2] = 0,
    [3] = 0,
    [4] = 0
}

local animationIndexByName = {}
local animationDataByIndex = {}
local shortcutKvpPrefix = 'menuemote_shortcut_'

local function normalizeFilterText(value)
    if not value then
        return ''
    end

    value = tostring(value):lower()
    value = value:gsub('%s+', ' ')
    return value
end

local function animationMatchesFilter(label, animName, filterValue)
    local currentFilter = normalizeFilterText(filterValue)
    if currentFilter == '' then
        return true
    end

    local labelText = normalizeFilterText(label)
    local animText = normalizeFilterText(animName)

    return string.find(labelText, currentFilter, 1, true) ~= nil
        or string.find(animText, currentFilter, 1, true) ~= nil
end

local function openCategoryFilter(categoryKey)
    local input = Game.Input('Montant')
    if input then
        categoryFilters[categoryKey] = tostring(input)
        ESX.ShowNotification(('Filtre appliqué : %s'):format(tostring(input)))
    else
        ESX.ShowNotification('~r~Action annulée.')
    end
end


menuemote.Closed = function()
    open = false
    destroyPreviewPed()
end

local function notify(msg)
    if ESX and ESX.ShowNotification then
        ESX.ShowNotification(msg)
    end
end

local function getShortcutKvpKey(slot)
    return ('%s%s'):format(shortcutKvpPrefix, slot)
end

local function registerAnimationIndex(animTable)
    if not animTable then
        return
    end

    for _, entry in pairs(animTable) do
        if entry and entry.dance and entry.dance ~= '' and not animationIndexByName[entry.dance] then
            local index = #animationDataByIndex + 1
            animationIndexByName[entry.dance] = index
            animationDataByIndex[index] = {
                name = entry.dance,
                label = entry.nom or entry.dance
            }
        end
    end
end

local function getShortcutLabel(slot)
    local animName = raccourcis[slot]
    if not animName or animName == '' then
        return 'Aucun'
    end

    local animId = shortcutAnimationIds[slot]
    local animData = animId and animationDataByIndex[animId] or nil
    return animData and animData.label or animName
end

local function saveShortcut(slot)
    local animId = shortcutAnimationIds[slot] or 0
    SetResourceKvpInt(getShortcutKvpKey(slot), animId)
end

local function loadShortcuts()
    for slot = 1, 4 do
        local animId = GetResourceKvpInt(getShortcutKvpKey(slot))
        if animId and animId > 0 and animationDataByIndex[animId] then
            shortcutAnimationIds[slot] = animId
            raccourcis[slot] = animationDataByIndex[animId].name
        else
            shortcutAnimationIds[slot] = 0
            raccourcis[slot] = nil
        end
    end
end

local function initializeAnimationIndexes()
    animationIndexByName = {}
    animationDataByIndex = {}

    registerAnimationIndex(danceanim)
    registerAnimationIndex(objetanim)
    registerAnimationIndex(gesteanim)
    registerAnimationIndex(autreanim)
    registerAnimationIndex(activiteanim)
    registerAnimationIndex(posanim)
    registerAnimationIndex(sportanim)
    registerAnimationIndex(santeanim)

    loadShortcuts()
end

local function loadAnimDict(dict)
    if not dict or dict == '' then
        return false
    end

    RequestAnimDict(dict)
    local timeout = GetGameTimer() + 5000

    while not HasAnimDictLoaded(dict) do
        Wait(10)
        RequestAnimDict(dict)
        if GetGameTimer() > timeout then
            return false
        end
    end

    return true
end

local function loadModel(model)
    local modelHash = model
    if type(modelHash) == 'string' then
        modelHash = GetHashKey(modelHash)
    end

    if not IsModelInCdimage(modelHash) then
        return false
    end

    RequestModel(modelHash)
    local timeout = GetGameTimer() + 5000

    while not HasModelLoaded(modelHash) do
        Wait(10)
        RequestModel(modelHash)
        if GetGameTimer() > timeout then
            return false
        end
    end

    return modelHash
end

function destroyPreviewPed()
    previewActive = false

    if previewPed and DoesEntityExist(previewPed) then
        ClearPedTasksImmediately(previewPed)
        SetEntityAsMissionEntity(previewPed, true, true)
        DeleteEntity(previewPed)
    end

    previewPed = nil
    previewAnimName = nil
    previewBuffer = {}
end

local function getEmoteData(animName)
    if not animName or animName == '' or not GAMEANIM then
        return nil
    end

    local pools = {
        GAMEANIMEmotes,
        GAMEANIMDances,
        GAMEANIMPropEmotes,
        GAMEANIMGestes,
        GAMEANIMAutres,
        GAMEANIMActivites,
        GAMEANIMPositions,
        GAMEANIMSports,
        GAMEANIMSantes,
        GAMEANIMShared,
    }

    for _, pool in ipairs(pools) do
        if pool and pool[animName] then
            return pool[animName]
        end
    end

    return nil
end

local function playPreviewAnimation(animName)
    if not previewPed or not DoesEntityExist(previewPed) then
        return
    end

    local emoteData = getEmoteData(animName)
    if not emoteData then
        return
    end

    local dict, anim = table.unpack(emoteData)
    if not dict or not anim or dict == '' or anim == '' then
        return
    end

    ClearPedTasksImmediately(previewPed)

    if dict == 'Scenario' or dict == 'MaleScenario' then
        TaskStartScenarioInPlace(previewPed, anim, 0, true)
        return
    end

    if loadAnimDict(dict) then
        TaskPlayAnim(previewPed, dict, anim, 8.0, -8.0, -1, 1, 0.0, false, false, false)
    end
end

local function ensurePreviewPed()
    local playerPed = PlayerPedId()

    if previewPed and DoesEntityExist(previewPed) then
        ClonePedToTarget(playerPed, previewPed)
        return true
    end

    local modelHash = loadModel(GetEntityModel(playerPed))
    if not modelHash then
        return false
    end

    previewPed = CreatePed(26, modelHash, 0.0, 0.0, 0.0, 0.0, false, false)
    SetModelAsNoLongerNeeded(modelHash)

    if not previewPed or not DoesEntityExist(previewPed) then
        previewPed = nil
        return false
    end

    ClonePedToTarget(playerPed, previewPed)
    SetEntityCollision(previewPed, false, false)
    SetEntityInvincible(previewPed, true)
    SetEntityLocallyVisible(previewPed)
    NetworkSetEntityInvisibleToNetwork(previewPed, true)
    SetEntityCanBeDamaged(previewPed, false)
    SetBlockingOfNonTemporaryEvents(previewPed, true)
    SetEntityAlpha(previewPed, 255)
    FreezeEntityPosition(previewPed, true)

    return true
end

local function startPreviewLoop()
    if previewActive then
        return
    end

    previewActive = true
    previewBuffer = {}

    CreateThread(function()
        while previewActive and open do
            if previewPed and DoesEntityExist(previewPed) then
                local world, normal = GetWorldCoordFromScreenCoord(0.405, 0.235)
                local depth = 5.8
                local target = world + normal * depth
                local camRot = GetGameplayCamRot(2)

                previewBuffer[#previewBuffer + 1] = target
                if #previewBuffer > 6 then
                    table.remove(previewBuffer, 1)
                end

                local avg = vector3(0.0, 0.0, 0.0)
                for i = 1, #previewBuffer do
                    avg = avg + previewBuffer[i]
                end

                avg = avg / #previewBuffer

                SetEntityCoords(previewPed, avg.x, avg.y, avg.z - 0.92, false, false, false, true)
                SetEntityHeading(previewPed, camRot.z + 180.0)
                SetEntityRotation(previewPed, 0.0, 0.0, camRot.z + 180.0, 2, true)

                if previewAnimName then
                    local emoteData = getEmoteData(previewAnimName)
                    if emoteData then
                        local dict, anim = table.unpack(emoteData)

                        if dict == 'Scenario' or dict == 'MaleScenario' then
                            if not IsPedUsingAnyScenario(previewPed) then
                                TaskStartScenarioInPlace(previewPed, anim, 0, true)
                            end
                        elseif dict and anim and dict ~= '' and anim ~= '' then
                            if not IsEntityPlayingAnim(previewPed, dict, anim, 3) then
                                playPreviewAnimation(previewAnimName)
                            end
                        end
                    end
                end
            end

            Wait(4)
        end

        destroyPreviewPed()
    end)
end

local function handlePreviewForAnim(animName)
    if not animName or animName == '' then
        return
    end

    if not ensurePreviewPed() then
        return
    end

    if previewAnimName ~= animName then
        previewAnimName = animName
        playPreviewAnimation(animName)
    end

    startPreviewLoop()
end

local function playEmoteCommand(animName)
    if not animName or animName == '' then
        notify('Animation invalide')
        return
    end

    ExecuteCommand('e ' .. animName)
end

local function setSelectedAnimation(animName, animLabel)
    if not animName or animName == '' then
        selectedShortcutAnim = nil
        notify('Cette animation ne peut pas être assignée')
        return
    end

    selectedShortcutAnim = {
        name = animName,
        label = animLabel or animName
    }
end

local function assignShortcut(slot)
    if not selectedShortcutAnim or not selectedShortcutAnim.name then
        notify('Aucune animation sélectionnée')
        return
    end

    if raccourcis[slot] then
        notify(('Le raccourci %s a déjà une animation'):format(slot))
        return
    end

    local animId = animationIndexByName[selectedShortcutAnim.name]
    if not animId then
        notify('Impossible de sauvegarder cette animation')
        return
    end

    for existingSlot = 1, 4 do
        if raccourcis[existingSlot] == selectedShortcutAnim.name then
            notify(('Cette animation est déjà attribuée au raccourci %s'):format(existingSlot))
            return
        end
    end

    raccourcis[slot] = selectedShortcutAnim.name
    shortcutAnimationIds[slot] = animId
    saveShortcut(slot)
    notify(('Raccourci %s défini sur : %s'):format(slot, selectedShortcutAnim.label))
end

local function clearAllShortcuts()
    for i = 1, 4 do
        raccourcis[i] = nil
        shortcutAnimationIds[i] = 0
        saveShortcut(i)
    end

    notify('Tous les raccourcis ont été supprimés')
end

local function playShortcut(slot)
    local animName = raccourcis[slot]
    if animName then
        playEmoteCommand(animName)
    end
end

local function startdemarche(lib, anim)
    ESX.Streaming.RequestAnimSet(lib, function()
        SetPedMovementClipset(PlayerPedId(), anim, true)
    end)
end

local function stopCurrentAnimation()
    local playerPed = PlayerPedId()
    ClearPedTasks(playerPed)
    DestroyAllProps(playerPed)
end

yamsstopanim = stopCurrentAnimation

local function drawCategoryMenu(categoryKey, animTable)
    local currentFilter = categoryFilters[categoryKey] or ''

    RageUI.Button('Filtrer', nil, { RightLabel = currentFilter ~= '' and currentFilter or 'Aucun' }, true, {
        onSelected = function()
            openCategoryFilter(categoryKey)
        end
    })

    if currentFilter ~= '' then
        RageUI.Button('~r~Retirer le filtre~s~', nil, {}, true, {
            onSelected = function()
                categoryFilters[categoryKey] = ''
                notify('Filtre retiré')
            end
        })
    end

    for _, v in pairs(animTable) do
        if animationMatchesFilter(v.nom, v.dance, currentFilter) then
            RageUI.Button(v.nom, nil, { RightLabel = '>>>' }, true, {
                onActive = function()
                    setSelectedAnimation(v.dance, v.nom)
                    handlePreviewForAnim(v.dance)
                end,
                onSelected = function()
                    setSelectedAnimation(v.dance, v.nom)
                end
            }, smshortcut)
        end
    end
end

function menuemoteyams()
    if open then
        open = false
        RageUI.Visible(menuemote, false)
        destroyPreviewPed()
        return
    end

    open = true
    RageUI.Visible(menuemote, true)

    CreateThread(function()
        while open do
            RageUI.IsVisible(menuemote, function()
                RageUI.Button("Arrêter l'animation en cours", nil, {}, true, {
                    onSelected = function()
                        ExecuteCommand('e c')
                    end
                })

                RageUI.Button('Dance', nil, { RightLabel = '>>>' }, true, {}, smdance)
                RageUI.Button('Objets', nil, { RightLabel = '>>>' }, true, {}, smobjet)
                RageUI.Button('Actions', nil, { RightLabel = '>>>' }, true, {}, smgeste)
                RageUI.Button('Divers', nil, { RightLabel = '>>>' }, true, {}, smautre)
                RageUI.Button('Activité', nil, { RightLabel = '>>>' }, true, {}, smactivite)
                RageUI.Button('Positions', nil, { RightLabel = '>>>' }, true, {}, smpos)
                RageUI.Button('Sport', nil, { RightLabel = '>>>' }, true, {}, smsport)
                RageUI.Button('Santé', nil, { RightLabel = '>>>' }, true, {}, smsante)
                RageUI.Button('Styles de marche', nil, { RightLabel = '>>>' }, true, {}, smmarche)
                RageUI.Button('~r~Supprimer tous mes raccourcis~s~', nil, {}, true, {
                    onSelected = function()
                        clearAllShortcuts()
                    end
                })
            end)

            RageUI.IsVisible(smdance, function()
                drawCategoryMenu('dance', danceanim)
            end)

            RageUI.IsVisible(smobjet, function()
                drawCategoryMenu('objet', objetanim)
            end)

            RageUI.IsVisible(smgeste, function()
                drawCategoryMenu('geste', gesteanim)
            end)

            RageUI.IsVisible(smautre, function()
                drawCategoryMenu('autre', autreanim)
            end)

            RageUI.IsVisible(smactivite, function()
                drawCategoryMenu('activite', activiteanim)
            end)

            RageUI.IsVisible(smpos, function()
                drawCategoryMenu('pos', posanim)
            end)

            RageUI.IsVisible(smsport, function()
                drawCategoryMenu('sport', sportanim)
            end)

            RageUI.IsVisible(smsante, function()
                drawCategoryMenu('sante', santeanim)
            end)

            RageUI.IsVisible(smmarche, function()
                destroyPreviewPed()

                RageUI.Button('Retirer le style de marche', nil, { RightLabel = '>>>' }, true, {
                    onSelected = function()
                        ResetPedMovementClipset(PlayerPedId())
                    end
                })

                for _, v in pairs(marcheeanim) do
                    RageUI.Button(v.nom, nil, { RightLabel = '>>>' }, true, {
                        onSelected = function()
                            startdemarche(v.lamarche1, v.lamarche2)
                        end
                    })
                end
            end)

            RageUI.IsVisible(smshortcut, function()
                if selectedShortcutAnim then
                    handlePreviewForAnim(selectedShortcutAnim.name)
                else
                    destroyPreviewPed()
                end

                RageUI.Separator('Animation : ' .. (selectedShortcutAnim and selectedShortcutAnim.label or 'Aucune'))

                RageUI.Button('Jouer maintenant', nil, {}, selectedShortcutAnim ~= nil, {
                    onSelected = function()
                        playEmoteCommand(selectedShortcutAnim.name)
                    end
                })

                RageUI.Button('Attribuer au raccourci 1', nil, { RightLabel = getShortcutLabel(1) }, selectedShortcutAnim ~= nil, {
                    onSelected = function()
                        assignShortcut(1)
                    end
                })

                RageUI.Button('Attribuer au raccourci 2', nil, { RightLabel = getShortcutLabel(2) }, selectedShortcutAnim ~= nil, {
                    onSelected = function()
                        assignShortcut(2)
                    end
                })

                RageUI.Button('Attribuer au raccourci 3', nil, { RightLabel = getShortcutLabel(3) }, selectedShortcutAnim ~= nil, {
                    onSelected = function()
                        assignShortcut(3)
                    end
                })

                RageUI.Button('Attribuer au raccourci 4', nil, { RightLabel = getShortcutLabel(4) }, selectedShortcutAnim ~= nil, {
                    onSelected = function()
                        assignShortcut(4)
                    end
                })
            end)

            Wait(0)
        end

        destroyPreviewPed()
    end)
end

RegisterCommand(_GAMEMODE.Bind["Emotes"].command, function()
    menuemoteyams()
end, false)

RegisterKeyMapping(_GAMEMODE.Bind["Emotes"].command,_GAMEMODE.Bind["Emotes"].description,'keyboard',_GAMEMODE.Bind["Emotes"].key)

RegisterCommand(_GAMEMODE.Bind["CancelEmotes"].command, function()
    yamsstopanim()
end, false)

RegisterKeyMapping(_GAMEMODE.Bind["CancelEmotes"].command,_GAMEMODE.Bind["CancelEmotes"].description,'keyboard',_GAMEMODE.Bind["CancelEmotes"].key)

RegisterCommand('emoteraccourci1', function()
    playShortcut(1)
end, false)

RegisterCommand('emoteraccourci2', function()
    playShortcut(2)
end, false)

RegisterCommand('emoteraccourci3', function()
    playShortcut(3)
end, false)

RegisterCommand('emoteraccourci4', function()
    playShortcut(4)
end, false)

RegisterKeyMapping('emoteraccourci1', 'Raccourci animation 1', 'keyboard', '1')
RegisterKeyMapping('emoteraccourci2', 'Raccourci animation 2', 'keyboard', '2')
RegisterKeyMapping('emoteraccourci3', 'Raccourci animation 3', 'keyboard', '3')
RegisterKeyMapping('emoteraccourci4', 'Raccourci animation 4', 'keyboard', '4')
danceanim = {
  {nom = "Dance", dance = "dance"},
  {nom = "Dance 2", dance = "dance2"},
  {nom = "Dance 3", dance = "dance3"},
  {nom = "Dance 4", dance = "dance4"},
  {nom = "Dance 5", dance = "dance5"},
  {nom = "Dance 6", dance = "dance6"},
  {nom = "Dance 7", dance = "dance7"},
  {nom = "Dance 8", dance = "dance8"},
  {nom = "Dance 9", dance = "dance9"},
  {nom = "Dance Femme", dance = "dancef"},
  {nom = "Dance Femme 2", dance = "dancef2"},
  {nom = "Dance Femme 3", dance = "dancef3"},
  {nom = "Dance Femme 4", dance = "dancef4"},
  {nom = "Dance Femme 5", dance = "dancef5"},
  {nom = "Dance Femme 6", dance = "dancef6"},
  {nom = "Dance bâtons lumineux", dance = "danceglowstick"},
  {nom = "Dance bâtons lumineux 2", dance = "danceglowstick2"},
  {nom = "Dance bâtons lumineux 3", dance = "danceglowstick3"},
  {nom = "Dance de Cheval", dance = "dancehorse"},
  {nom = "Dance de Cheval 2", dance = "dancehorse2"},
  {nom = "Dance de Cheval 3", dance = "dancehorse3"},
  {nom = "Dance Timide", dance = "danceshy"},
  {nom = "Dance Timide 2", dance = "danceshy2"},
  {nom = "Dance Idiote", dance = "dancesilly"},
  {nom = "Dance Idiote 2", dance = "dancesilly2"},
  {nom = "Dance Idiote 3", dance = "dancesilly3"},
  {nom = "Dance Idiote 4", dance = "dancesilly4"},
  {nom = "Dance Idiote 5", dance = "dancesilly5"},
  {nom = "Dance Lente", dance = "danceslow"},
  {nom = "Dance Lente 2", dance = "danceslow2"},
  {nom = "Dance Lente 3", dance = "danceslow3"},
}

objetanim = {
  {nom = "Avoir un Sac à dos", dance = "backpack"},
  {nom = "Boir de la Bière", dance = "beer"},
  {nom = "Pancarte SDF", dance = "beg"},
  {nom = "Fumer une Chicha", dance = "bong"},
  {nom = "Lire un Livre", dance = "book"},
  {nom = "Tenir un Bouquet de fleur", dance = "bouquet"},
  {nom = "Tenir une Boite", dance = "box"},
  {nom = "Tenir une Mallette", dance = "brief3"},
  {nom = "Tenir un Burger", dance = "buger"},
  {nom = "Prendre un Appareil Photo", dance = "camera"},
  {nom = "Tenir un Verre de Champagne", dance = "champagne"},
  {nom = "Arroser du Champagne", dance = "champagnespray"},
  {nom = "Fumer une Cigarette", dance = "cig"},
  {nom = "Fumer un Cigar", dance = "cigar"},
  {nom = "Nettoyer une Table", dance = "clean"},
  {nom = "Nettoyer une Vitre", dance = "clean2"},
  {nom = "Consulter un Bloc Notes", dance = "clipboard"},
  {nom = "Tenir un Café", dance = "coffee"},
  {nom = "Tenir une Tasse", dance = "cup"},
  {nom = "Manger un Donut", dance = "donut"},
  {nom = "Manger une Barre de Chocolat", dance = "egobar"},
  {nom = "Tenir un Verre de Champagne Vide", dance = "flute"},
  {nom = "Jouer une Guitare", dance = "guitar"},
  {nom = "Jouer de la Guitare en mouvement", dance = "guitar2"},  
  {nom = "Jouer de la Guitare éléctrique", dance = "guitarelectric"},
  {nom = "Jouer de la Guitare éléctrique 2", dance = "guitarelectric2"},
  {nom = "Fumer un Joint", dance = "joint"},
  {nom = "Faire une Pluie de Billet", dance = "makeitrain"},
  {nom = "Consulter une Carte GPS", dance = "map"},
  {nom = "Plaque de Photo d'Identité", dance = "mugshot"},
  {nom = "Ecrire sur un Bloc Note", dance = "notepad"},
  {nom = "Regarder son Téléphone", dance = "phone"},
  {nom = "Appeler Quelqu'un", dance = "phonecall"},
  {nom = "Tenir une Rose", dance = "rose"},
  {nom = "Manger un Sandwich", dance = "sandwich"},
  {nom = "Tenir une Canette de Soda", dance = "soda"},
  {nom = "Tenir une Valise", dance = "suitcase"},
  {nom = "Tenir une Mallette", dance = "suitcase2"},
  {nom = "Consulter une Tablette", dance = "tablet"},
  {nom = "Consulter une Tablette 2", dance = "tablet2"},
  {nom = "Tenir une Peluche", dance = "teddy"},
  {nom = "Tenir un Parapluie", dance = "umbrella"},
  
}

gesteanim = {
  {nom = "Ajustez sa Chemise", dance = "adjust"},
  {nom = "Se Disputer", dance = "argue"},
  {nom = "Faire des Geste de la Main", dance = "boi"},
  {nom = "Applaudir Joyeusement", dance = "clap"},
  {nom = "Applaudir comme un Débile", dance = "clapangry"},
  {nom = "C'est mon Frère saaaa", dance = "comeatmebro"},
  {nom = "Tousser", dance = "cough"},
  {nom = "Toi la ! t'es un Homme Mort", dance = "cutthroat"},
  {nom = "Je vais te trancher la Gorge", dance = "cutthroat2"},
  {nom = "Ah Merde...", dance = "damn"},
  {nom = "Manger", dance = "eat"},
  {nom = "Oh lala ...", dance = "facepalm"},
  {nom = "Hein ? Pas possible ...", dance = "facepalm2"},
  {nom = "Quelle Malheur", dance = "facepalm3"},
  {nom = "Quel Idiot ...", dance = "facepalm4"},
  {nom = "Fuck", dance = "finger"},
  {nom = "Double Fuck", dance = "finger2"},
  {nom = "Montrer ses Muscles", dance = "flex"},
  {nom = "Signe Gang de Marabunta", dance = "gangsign"},
  {nom = "Signe de Gang", dance = "gangsign2"},
  {nom = "Tcheck", dance = "handshake"},
  {nom = "Tcheck 2", dance = "handshake2"},
  {nom = "Lever les Mains en l'Air", dance = "handsup"},
  {nom = "Coup de Tete", dance = "headbutt"},
  {nom = "Calin", dance = "hug"},
  {nom = "Calin 2", dance = "hug2"},
  {nom = "Clown", dance = "jazzhands"},
  {nom = "Utiliser une Clée", dance = "keyfob"},
  {nom = "Toquer à une Porte", dance = "knock"},
  {nom = "Toquer Fort à une Porte", dance = "knock2"},
  {nom = "Se craquer les Doigts", dance = "knucklecrunch"},
  {nom = "S'aggripper à quelqu'un", dance = "leanside5"},
  {nom = "Faire du Stop", dance = "lift"},
  {nom = "Non pas du Tout !", dance = "no"},
  {nom = "Non de la tete", dance = "no2 "},
  {nom = "Absolument pas", dance = "noway"},
  {nom = "Okk", dance = "ok"},
  {nom = "Peace and Love", dance = "peace"},
  {nom = "Ramasser Quelque chose", dance = "pickup"},
  {nom = "Main sur me Holster", dance = "reaching"},
  {nom = "Salut de l'Armée", dance = "salute"},
  {nom = "Salut de l'Armée 2", dance = "salute2"},
  {nom = "Enelever la Poussière au sol", dance = "shakeoff"},
  {nom = "Hein ?", dance = "shrug"},
  {nom = "Giffler Quelqu'un", dance = "slap"},
  {nom = "Applaudir Doucement", dance = "slowclap"},
  {nom = "Sa Pue ...", dance = "stink"},
  {nom = "Penser Profonde", dance = "think2"},
  {nom = "Double Pouce en l'Air", dance = "thumbsup"},
  {nom = "Coucouu !", dance = "wave"},
  {nom = "Salut de Reine", dance = "wave2"},
  {nom = "Sifflé", dance = "whistle"},
  {nom = "Sifflé 2", dance = "whistle2"},
  {nom = "Yeahh", dance = "yeah"},
}




autreanim = {
  {nom = "Se Ré-habillez Correment", dance = "adjusttie"},
  {nom = "Faire l'avion", dance = "airplane"},
  {nom = "Faire le Chien", dance = "bark"},
  {nom = "Faire l'Oiseau", dance = "bird"},
  {nom = "Plein de Bisous", dance = "blowkiss"},
  {nom = "Célébration", dance = "celebrate"},
  {nom = "Faire la Poule", dance = "chiken"},
  {nom = "Faire le Clown", dance = "clown"},
  {nom = "Faire le DJ", dance = "dj"},
  {nom = "Faire un Tweerk", dance = "twerk"},
  {nom = "Faire un Tweerk 2", dance = "lapdance2"},
  {nom = "Faire un Tweerk 3", dance = "lapdance3"},
  {nom = "Faire le Superman", dance = "ledge"},
  {nom = "Pousser sur le Coté", dance = "peek"},
  {nom = "Pousser", dance = "push"},
  {nom = "Pousser 2", dance = "push2"},
  {nom = "Radio", dance = "radio"},
  {nom = "S'asseoir", dance = "sit"},
  {nom = "S'asseoir 2", dance = "sit2"},
  {nom = "S'asseoir 3", dance = "sit3"},
  {nom = "S'asseoir 4", dance = "sit4"},
  {nom = "S'asseoir 5", dance = "sit5"},
  {nom = "S'asseoir 6", dance = "sit6"},
  {nom = "S'asseoir 7", dance = "sit7"},
  {nom = "S'asseoir 8", dance = "sit8"},
  {nom = "S'asseoir 9", dance = "sit9"},
  {nom = "S'asseoir sur une Chaise", dance = "sitchair"},
  {nom = "S'asseoir sur une Chaise 2", dance = "sitchair2"},
  {nom = "S'asseoir sur une Chaise 3", dance = "sitchair3"},
  {nom = "S'asseoir sur une Chaise 4", dance = "sitchair4"},
  {nom = "S'asseoir sur une Chaise 5", dance = "sitchair5"},
  {nom = "S'asseoir sur une Chaise 6", dance = "sitchair6"},
  {nom = "S'asseoir Tristement", dance = "sitsad"},
  {nom = "S'asseoir Effrayer", dance = "sitscared"},
  {nom = "Pointer avec son arme", dance = "stickup"},
  {nom = "Faire le Super-Héro", dance = "superhero"},
  {nom = "Faire le Super-Héro 2", dance = "superhero2"},
  {nom = "Pointer avec son arme 2", dance = "threaten"},
}


activiteanim = {
  {nom = "Faire de la Guitare dans le Vent", dance = "airguitar"},
  {nom = "Faire du Piano dans le Vent", dance = ""},
  {nom = "ATM", dance = "atm"},
  {nom = "BBQ", dance = "bbq"},
  {nom = "Fin de Spectale", dance = "bow"},
  {nom = "Félécitation", dance = "cheer"},
  {nom = "Boire", dance = "drink"},
  {nom = "Ivre à en Tomber", dance = "fallover"},
  {nom = "Se Prendre une Balle dans la Tete", dance = "fallover4"},
  {nom = "Se Prendre une Droite", dance = "fallover5"},
  {nom = "Taper au Marteau", dance = "hammer"},
  {nom = "Tenir son Sac", dance = "hiking"},
  {nom = "Tenir un Balai", dance = "janitor"},
  {nom = "Souffler les Feuilles", dance = "leafblower"},
  {nom = "Essuyer une vitre", dance = "maid"},
  {nom = "Réparer un moteur", dance = "mechanic"},
  {nom = "Réparer l'Avant d'un Véhicule", dance = "mechanic3"},
  {nom = "Sortir son Notepad", dance = "notepad2"},
  {nom = "Boire une Bière en dansant", dance = "party"},
  {nom = "Fumer une Cigarette", dance = "smoke"},
  {nom = "Fumer de la Weed", dance = "smokeweed"},
  {nom = "Envoyer un Message", dance = "texting"},
  {nom = "Taper sur un Clavier", dance = "type"},
  {nom = "Crocheter une Porte", dance = "weld"},
}



posanim = {
  {nom = "Grosse Sieste", dance = "bumsleep"},
  {nom = "Allongé Relax", dance = "chill"},
  {nom = "Allongé Dos au Sol", dance = "cloudgaze"},
  {nom = "Allongé Dos au Sol 2", dance = "cloudgaze"},
  {nom = "Les Mains sur la Ceinture", dance = "cop"},
  {nom = "LSPD Bras Croisé", dance = "cop2"},
  {nom = "LSPD Appel Radio", dance = "cop3"},
  {nom = "Croiser les Bras", dance = "crossarms"},
  {nom = "Croiser les Bras 2", dance = "crossarms2"},
  {nom = "Croiser les Bras 3", dance = "crossarms3"},
  {nom = "Croiser les Bras 4", dance = "crossarms4"},
  {nom = "Croiser les Bras 5", dance = "crossarms5"},
  {nom = "Croiser les Bras 6", dance = "crossarms6"},
  {nom = "Dormir Debout", dance = "fallassleep"},
  {nom = "Pose de Videur", dance = "guard"},
  {nom = "Attendre un Client", dance = "hangout"},
  {nom = "Tcheck Gang", dance = "hug3"},
  {nom = "Attendre Poser contre un Mur", dance = "lean"},
  {nom = "Poser contre un Mur à Fumer", dance = "lean2"},
  {nom = "Poser contre un Mur Détendu", dance = "lean3"},
  {nom = "Poser contre un Mur les Mains Croisés", dance = ""},
  {nom = "S'allonger à Plat Ventre", dance = "prone"},
  {nom = "Dormir", dance = "sleep"},
  {nom = "Faire la Statue", dance = "statue"},
  {nom = "Faire la Statue 2", dance = "statue2"},
  {nom = "Faire la Statue 3", dance = "statue3"},
  {nom = "Se Rendre", dance = "surrender"},
  {nom = "Faire le T", dance = "t"},
  {nom = "Faire le T 2", dance = "t2"},
  {nom = "Attendre", dance = "wait"},
  {nom = "Attendre 2", dance = "wait2"},
  {nom = "Attendre 3", dance = "wait3"},
  {nom = "Attendre 4", dance = "wait4"},
  {nom = "Attendre 5", dance = "wait5"},
  {nom = "Attendre 6", dance = "wait6"},
  {nom = "Attendre 7", dance = "wait7"},
  {nom = "Attendre 8", dance = "wait8"},
  {nom = "Attendre 9", dance = "wait9"},
  {nom = "Attendre 10", dance = "wait10"},
  {nom = "Attendre 11", dance = "wait11"},
  {nom = "Attendre 12", dance = "wait12"},
  {nom = "Attendre 13", dance = "wait13"},
}


sportanim = {
  {nom = "Entrainement de Boxe", dance = "boxing"},
  {nom = "Entrainement de Boxe 2", dance = "boxing2"},
  {nom = "Faire des Tractions", dance = "chinup"},
  {nom = "Faire un Salto", dance = "flip"},
  {nom = "Faire un Salto 2", dance = "flip2"},
  {nom = "S'échauffer pour un Jogging", dance = "jog"},
  {nom = "Faire son Jogging", dance = "jog2"},
  {nom = "Faire son Jogging 2", dance = "jog3"},
  {nom = "Faire son Jogging 3", dance = "jog4"},
  {nom = "Faire son Jogging 4", dance = "jog5"},
  {nom = "Faire des JumpingJacks", dance = "jumpingjacks"},
  {nom = "Faire du Karate", dance = "karate"},
  {nom = "Faire du Karate 2", dance = "karate2"},
  {nom = "Faire des Pompe", dance = "pushup"},
  {nom = "Faire des Abdos", dance = "situp"},
  {nom = "Célébration sur les Genoux", dance = "slide"},
  {nom = "Célébration sur les Genoux 2", dance = "slide2"},
  {nom = "Célébration sur les Genoux 3", dance = "slide3"},
  {nom = "Tir à la Bate", dance = "slugger"},
  {nom = "Faire du Yoga", dance = "yoga"},
}



santeanim = {
  {nom = "Massage Cardique au Sol", dance = "cpr"},
  {nom = "Massage Cardique sur une Table", dance = "cpr2"},
  {nom = "Ramper au Sol Blessé", dance = "crawl"},
  {nom = "Medecin Inspectant une Personne", dance = "medic"},
  {nom = "Perde Connaisance", dance = "passout"},
  {nom = "Perde Connaisance 2", dance = "passout2"},
  {nom = "Perde Connaisance 3", dance = "passout3"},
  {nom = "Perde Connaisance 4", dance = "passout4"},
  {nom = "Perde Connaisance 5", dance = "passout5"},
  {nom = "Blesser par Balle au Sol", dance = "shot"},
}

-- Liste des Styles de Marhes

marcheeanim = {
	{nom = "Depressif homme", lamarche1 = "move_m@depressed@a", lamarche2 ="move_m@depressed@a"},
	{nom = "Depressif femme", lamarche1 = "move_f@depressed@a", lamarche2 ="move_f@depressed@a"},
	{nom = "Business", lamarche1 = "move_m@business@a", lamarche2 ="move_m@business@a"},
	{nom = "Determiné", lamarche1 = "move_m@brave@a", lamarche2 ="move_m@brave@a"},
	{nom = "Casual", lamarche1 = "move_m@casual@a", lamarche2 ="move_m@casual@a"},
	{nom = "Trop mangé", lamarche1 = "move_m@fat@a", lamarche2 ="move_m@fat@a"},
	{nom = "Hipster", lamarche1 = "move_m@hipster@a", lamarche2 ="move_m@hipster@a"},
	{nom = "Blessé", lamarche1 = "move_m@injured", lamarche2 ="move_m@injured"},
	{nom = "Intimidé", lamarche1 = "move_m@hurry@a", lamarche2 ="move_m@hurry@a"},
	{nom = "Hobo", lamarche1 = "move_m@hobo@a", lamarche2 ="move_m@hobo@a"},
	{nom = "Malheureux", lamarche1 = "move_m@sad@a", lamarche2 ="move_m@sad@a"},
	{nom = "Muscle", lamarche1 = "move_m@muscle@a", lamarche2 ="move_m@muscle@a"},
	{nom = "Choc", lamarche1 = "move_m@shocked@a", lamarche2 ="move_m@shocked@a"},
	{nom = "Sombre", lamarche1 = "move_m@shadyped@a", lamarche2 ="move_m@shadyped@a"},
	{nom = "Fatigue", lamarche1 = "move_m@buzzed", lamarche2 ="move_m@buzzed"},
	{nom = "Fier", lamarche1 = "move_m@money", lamarche2 ="move_m@money"},
	{nom = "Petite course", lamarche1 = "move_m@quick", lamarche2 ="move_m@quick"},
	{nom = "Mangeuse d'homme", lamarche1 = "move_f@maneater", lamarche2 ="move_f@maneater"},
}

initializeAnimationIndexes()
