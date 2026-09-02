_GAMEMODE = {}
_GAMEMODE.DEV = true
_GAMEMODE.SERVERNAME = "GameRP"
_GAMEMODE.VERSION = "1.0.0"
_GAMEMODE.GTACOLOR = "~b~"
_GAMEMODE.HEXCOLOR = "#018be7"

 
_GAMEMODE.Bind = {
    ["MenuFacture"] = {
        command = "+facture",
        description = "Menu Facture",
        key = "F4",
    },
    ["Emotes"] = {
        command = "+emotes",
        description = "Ouvrir le menu animations",
        key = "K",
    },
    ["CancelEmotes"] = {
        command = "+cancelemotes",
        description = "Annuler une emote",
        key = "X",
    },
}

exports('GetBind', function(name)
    return _GAMEMODE.Bind[name]
end)