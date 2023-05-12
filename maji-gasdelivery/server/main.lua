local QBCore = exports['qb-core']:GetCoreObject()

RegisterServerEvent('md-checkCash')
AddEventHandler('md-checkCash', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local moneyType = Config.PayType
    local balance = Player.Functions.GetMoney(moneyType)
    print(moneyType)
    if balance >= Config.TruckPrice then
        if moneyType == 'cash' then
            Player.Functions.RemoveMoney(moneyType, Config.TruckPrice)
            TriggerClientEvent('spawnTruck', src)
            TriggerClientEvent('TrailerBlip', src)
        else
            Player.Functions.RemoveMoney(moneyType, Config.TruckPrice)
            TriggerClientEvent('spawnTruck', src)
            TriggerClientEvent('TrailerBlip', src)
        end
    else
        TriggerClientEvent('NotEnoughTruckMoney', src)
    end
end)

RegisterServerEvent('md-getpaid')
AddEventHandler('md-getpaid', function(stationsRefueled)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local moneyType = Config.PayType
    local balance = Player.Functions.GetMoney(moneyType)
    Player.Functions.AddMoney(Config.PayType, stationsRefueled * Config.PayPerFueling)
end)
