ESX = exports["es_extended"]:getSharedObject()

local lobbyCoords = vector4(2132.7991, 2379.6013, 101.7589, 355.7060) -- kam to oba portne po ukonceni / where do both of them go after finishing
local activeDuels = {}
local cooldowns = {}
local COOLDOWN_TIME = 3 * 60 * 1000 -- 3 minuty / 3 minutes

local arenas = {
    {player1 = vector3(1456.3, 1178.8, 114.2), player2 = vector3(1456.4, 1126.3, 114.3), occupied = false}, -- můžete upravit souřadnice / you can edit coords
    {player1 = vector3(1460.0, 1178.0, 114.2), player2 = vector3(1460.5, 1126.0, 114.3), occupied = false}, -- můžete upravit souřadnice / you can edit coords
    {player1 = vector3(1465.0, 1175.0, 114.2), player2 = vector3(1465.5, 1123.0, 114.3), occupied = false}, -- můžete upravit souřadnice / you can edit coords
}

RegisterCommand("1v1", function(source, args)
    local now = os.time()*1000

    if cooldowns[source] and now - cooldowns[source] < COOLDOWN_TIME then
        local remaining = math.ceil((COOLDOWN_TIME - (now - cooldowns[source])) / 1000)
        TriggerClientEvent('okokNotify:Alert', source, "1v1", "Musíš počkat "..remaining.." sekund před další výzvou.", 5000, "error")
        return
    end

    local targetId = tonumber(args[1])
    if not targetId then
        TriggerClientEvent('okokNotify:Alert', source, "1v1", "Použití: /1v1 [ID hráče]", 5000, "error")
        return
    end

    if targetId == source then
        TriggerClientEvent('okokNotify:Alert', source, "1v1", "Nemůžeš vyzvat sám sebe!", 5000, "error")
        return
    end

    local xTarget = ESX.GetPlayerFromId(targetId)
    if not xTarget then
        TriggerClientEvent('okokNotify:Alert', source, "1v1", "Hráč není online!", 5000, "error")
        return
    end

    if cooldowns[targetId] and now - cooldowns[targetId] < COOLDOWN_TIME then
        local remaining = math.ceil((COOLDOWN_TIME - (now - cooldowns[targetId])) / 1000)
        TriggerClientEvent('okokNotify:Alert', source, "1v1", "Hráč musí počkat "..remaining.." sekund před další výzvou.", 5000, "error")
        return
    end

    if activeDuels[source] or activeDuels[targetId] then
        TriggerClientEvent('okokNotify:Alert', source, "1v1", "Ty nebo vybraný hráč už jste v souboji!", 5000, "error")
        return
    end

    TriggerClientEvent("president_1v1:openArenaMenu", source, targetId, arenas)
end)

RegisterNetEvent("president_1v1:sendInvite", function(targetId, arenaIndex)
    local src = source
    TriggerClientEvent("president_1v1:receiveInvite", targetId, src, arenaIndex)
    TriggerClientEvent('okokNotify:Alert', src, "1v1", "Výzva odeslána hráči "..targetId, 5000, "success")
end)

RegisterNetEvent("president_1v1:acceptInvite", function(opponentId, arenaIndex)
    local src = source
    local now = os.time()*1000
    local arena = arenas[arenaIndex]

    if not arena or arena.occupied then
        TriggerClientEvent('okokNotify:Alert', src, "1v1", "Tato aréna už je obsazená!", 5000, "error")
        return
    end

    arena.occupied = true

    activeDuels[src] = {opponent = opponentId, arena = arena, inDuel = true}
    activeDuels[opponentId] = {opponent = src, arena = arena, inDuel = true}

    TriggerClientEvent("president_1v1:teleportArena", src, arena.player1)
    TriggerClientEvent("president_1v1:teleportArena", opponentId, arena.player2)

    TriggerClientEvent("president_1v1:startCountdown", src)
    TriggerClientEvent("president_1v1:startCountdown", opponentId)
end)

RegisterNetEvent("president_1v1:declineInvite", function(opponentId)
    if ESX.GetPlayerFromId(opponentId) then
        TriggerClientEvent('okokNotify:Alert', opponentId, "1v1", "Soupeř odmítl výzvu.", 5000, "error")
    end
end)

RegisterNetEvent("president_1v1:endDuel", function()
    local src = source
    local duelData = activeDuels[src]
    if duelData and duelData.inDuel then
        local opponentId = duelData.opponent
        local xWinner = ESX.GetPlayerFromId(opponentId)
        local xLoser = ESX.GetPlayerFromId(src)
        local now = os.time()*1000

        if xWinner then
            TriggerClientEvent("president_1v1:teleportLobby", opponentId, lobbyCoords)
            TriggerClientEvent('okokNotify:Alert', opponentId, "1v1", "Vyhrál jsi 1v1!", 5000, "success")
            local reward = math.random(1, 3) -- nahodne rozmezi kolik toho dostane vitez / random number how much the winner gets
            xWinner.addInventoryItem('burger', reward) --- 'burger' - item ktery dostane vitez /  --- 'burger' - an item that winner will receive as a reward
            TriggerClientEvent('okokNotify:Alert', opponentId, "1v1", "Obdržel jsi "..reward.."x Burger za výhru!", 5000, "success")
            cooldowns[opponentId] = now
        end

        if xLoser then
            TriggerClientEvent("president_1v1:teleportLobby", src, lobbyCoords)
            TriggerClientEvent('okokNotify:Alert', src, "1v1", "Prohrál jsi 1v1!", 5000, "error")
            cooldowns[src] = now
        end

        if duelData.arena then
            duelData.arena.occupied = false
        end

        activeDuels[src] = nil
        activeDuels[opponentId] = nil
    end
end)
