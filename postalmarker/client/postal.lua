local postals = {}
local pBlip = nil

-- Configuration
Config = {
    Command = 'postal',
    BlipSprite = 8,
    BlipColor = 3,
    DeleteDistance = 100.0,
}

-- Load postal data
Citizen.CreateThread(function()
    local data = LoadResourceFile(GetCurrentResourceName(), 'data/postals.json')
    if data then
        postals = json.decode(data)
        for i, postal in ipairs(postals) do
            postals[i] = {
                vec(postal.x, postal.y),
                code = postal.code
            }
        end
    else
        print('^1[ERROR]^7 Could not load postal data')
    end
end)

-- Check if player arrived at destination
Citizen.CreateThread(function()
    while true do
        Wait(1000)
        if pBlip then
            local playerCoords = GetEntityCoords(PlayerPedId())
            local blipCoords = GetBlipCoords(pBlip)
            local distance = #(playerCoords - blipCoords)

            if distance < Config.DeleteDistance then
                RemoveBlip(pBlip)
                pBlip = nil
            end
        end
    end
end)

-- Register command with suggestion
TriggerEvent('chat:addSuggestion', '/' .. Config.Command, 'Set GPS to a postal code or clear route', {
    { name = 'Postal Code', help = 'The postal code to navigate to (leave empty to clear)' }
})

-- Postal command
RegisterCommand(Config.Command, function(_, args)
    -- No args = clear route
    if #args < 1 then
        if pBlip then
            RemoveBlip(pBlip)
            pBlip = nil
        end
        return
    end

    local userPostal = string.upper(args[1])
    local foundPostal = nil

    -- Find postal
    for _, p in ipairs(postals) do
        if string.upper(p.code) == userPostal then
            foundPostal = p
            break
        end
    end

    if foundPostal then
        -- Clear existing blip
        if pBlip then
            RemoveBlip(pBlip)
        end

        -- Create new blip with route
        pBlip = AddBlipForCoord(foundPostal[1][1], foundPostal[1][2], 0.0)
        SetBlipRoute(pBlip, true)
        SetBlipSprite(pBlip, Config.BlipSprite)
        SetBlipColour(pBlip, Config.BlipColor)
        SetBlipRouteColour(pBlip, Config.BlipColor)

        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName('Postal: ' .. foundPostal.code)
        EndTextCommandSetBlipName(pBlip)
    end
end, false)
