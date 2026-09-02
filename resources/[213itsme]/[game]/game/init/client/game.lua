Game = {}

function Game.Logs(msg)
    print(("[^2GAMES^7] %s"):format(msg))
end

function Game.Input(title)
    local input = lib.inputDialog(
        title,
        {
            { type = "input", label = title }
        },
        { allowCancel = true }
    )

    if input == nil or input[1] == nil or #input[1] == 0 or input[1] == "" then
        return nil
    end

    return input[1]
end

exports('input', Game.Input)