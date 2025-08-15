local isInDuel = false
local duelArena = nil
local targetPlayer = nil

RegisterNetEvent("president_1v1:openArenaMenu", function(targetId, arenas)
    targetPlayer = targetId
    local options = {}

    for i, arena in ipairs(arenas) do
        if not arena.occupied then
            table.insert(options, {
                title = "Aréna " .. i,
                description = "Volná",
                onSelect = function()
                    TriggerServerEvent("president_1v1:sendInvite", targetPlayer, i)
                end
            })
        else
            table.insert(options, {
                title = "Aréna " .. i,
                description = "❌ Obsazeno",
                disabled = true
            })
        end
    end

    lib.registerContext({
        id = '1v1_arena_select',
        title = 'Výběr arény',
        options = options
    })
    lib.showContext('1v1_arena_select')
end)

RegisterNetEvent("president_1v1:receiveInvite", function(opponentId, arenaIndex)
    lib.registerContext({
        id = '1v1_invite_menu',
        title = 'Výzva na 1v1',
        options = {
            {
                title = '✅ Přijmout',
                icon = 'check',
                onSelect = function()
                    TriggerServerEvent("president_1v1:acceptInvite", opponentId, arenaIndex)
                end
            },
            {
                title = '❌ Odmítnout',
                icon = 'xmark',
                onSelect = function()
                    TriggerServerEvent("president_1v1:declineInvite", opponentId)
                end
            }
        }
    })
    lib.showContext('1v1_invite_menu')
end)

RegisterNetEvent("president_1v1:teleportArena", function(coords)
    local ped = PlayerPedId()
    SetEntityCoords(ped, coords.x, coords.y, coords.z)
    SetEntityHeading(ped, 0.0)
    SetEntityHealth(ped, 200)
    SetPedArmour(ped, 100)
    isInDuel = false
    duelArena = coords
end)

RegisterNetEvent("president_1v1:teleportLobby", function(coords)
    local ped = PlayerPedId()
    SetEntityCoords(ped, coords.x, coords.y, coords.z)
    SetEntityHeading(ped, coords.w or 0.0)
    SetEntityHealth(ped, 200)
    SetPedArmour(ped, 100)
    isInDuel = false
    duelArena = nil
end)

RegisterNetEvent("president_1v1:startCountdown", function()
    local countdown = 5
    local ped = PlayerPedId()

    FreezeEntityPosition(ped, true)
    SetPlayerInvincible(PlayerId(), true)

    TriggerEvent('okokNotify:Alert', "1v1", "Souboj začne za "..countdown.." sekund!", 5000, "info")

    CreateThread(function()
        while countdown > 0 do
            TriggerEvent('okokNotify:Alert', "1v1", "Začíná za "..countdown.."...", 1000, "info")
            countdown = countdown - 1
            Wait(1000)
        end

        isInDuel = true
        FreezeEntityPosition(ped, false)
        SetPlayerInvincible(PlayerId(), false)
        TriggerEvent('okokNotify:Alert', "1v1", "Souboj začíná!", 3000, "success")
    end)
end)

CreateThread(function()
    while true do
        Wait(500)
        if isInDuel and IsEntityDead(PlayerPedId()) then
            TriggerServerEvent("president_1v1:endDuel")
            Wait(3000)
        end
    end
end)

CreateThread(function()
    while true do
        Wait(500)
        if isInDuel and duelArena then
            local ped = PlayerPedId()
            local pos = GetEntityCoords(ped)
            local dist = #(pos - vector3(duelArena.x, duelArena.y, duelArena.z))
            if dist > 50.0 then
                SetEntityCoords(ped, duelArena.x, duelArena.y, duelArena.z)
                TriggerEvent('okokNotify:Alert', "1v1", "Nemůžeš opustit arénu!", 2000, "error")
            end
        end
    end
end)
