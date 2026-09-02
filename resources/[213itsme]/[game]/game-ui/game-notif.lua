GAMENOTIF = {}

function GAMENOTIF:Send(data)
  SendNUIMessage({
    action = "notify",
    text = data.text or "",
    icon = data.icon or "./img/ems.png",
    duration = data.duration or 3500,
    color = data.color or "#2b87ff"
  })
end

RegisterNetEvent("game:notif:basic", function(data)
  if type(data) ~= "table" then return end
  GAMENOTIF:Send(data)
end)

RegisterNetEvent("game:notif:advanced", function(data)
  if type(data) ~= "table" then return end
  GAMENOTIF:Send(data)
end)

RegisterCommand("testnotif", function()
  TriggerEvent("game:notif:advanced", {text = "Created by 213itsme for Template ~b~Digital Dev~s~", duration = 4000, icon = "./img/msg.png"})
end)