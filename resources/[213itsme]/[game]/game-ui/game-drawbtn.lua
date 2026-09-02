GAMEDRAW = {}

local uiIndex = 0
local activeUi = {}

local function FormatKey(key)
    local map = {
        ["ENTER"] = "↵",
        ["RETURN"] = "↵",
        ["BACKSPACE"] = "⌫",
        ["TAB"] = "⇥",
        ["SPACE"] = "␣",
        ["SHIFT"] = "⇧",
        ["CTRL"] = "Ctrl",
        ["ALT"] = "Alt",
        ["ESC"] = "⎋",
        ["ESCAPE"] = "⎋",
        ["LEFT"] = "←",
        ["RIGHT"] = "→",
        ["UP"] = "↑",
        ["DOWN"] = "↓"
    }

    return map[string.upper(key)] or key
end

local function ExtractKey(text)
    local key = ""
    local cleanText = text or ""

    local match = cleanText:match("~(.-)~")
    if match then
        key = FormatKey(match)
        cleanText = cleanText:gsub("~.-~", "")
    end

    cleanText = cleanText:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
    return cleanText, key
end

function GAMEDRAW:SetUI(state, text, id)
    if state then
        if not id then
            uiIndex = uiIndex + 1
            id = uiIndex
        end

        local cleanText, key = ExtractKey(text or "")

        activeUi[id] = true

        SendNUIMessage({
            action = "add",
            id = id,
            text = cleanText,
            key = key
        })

        return id
    else
        if id then
            activeUi[id] = nil
            SendNUIMessage({
                action = "remove",
                id = id
            })
        else
            activeUi = {}
            SendNUIMessage({
                action = "clear"
            })
        end
    end
end

function SetUI(state, text, id)
    return GAMEDRAW:SetUI(state, text, id)
end

function HideUI(id)
    return GAMEDRAW:SetUI(false, nil, id)
end

function ClearUI()
    return GAMEDRAW:SetUI(false)
end

exports("SetUI", function(state, text, id)
    return GAMEDRAW:SetUI(state, text, id)
end)

exports("HideUI", function(id)
    return GAMEDRAW:SetUI(false, nil, id)
end)

exports("ClearUI", function()
    return GAMEDRAW:SetUI(false)
end)