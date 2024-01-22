local QBCore = exports['qb-core']:GetCoreObject()

RegisterServerEvent('md-checkCash')
AddEventHandler('md-checkCash', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local moneyType = Config.PayType
    local balance = Player.Functions.GetMoney(moneyType)
    if Config.Debug == true then
        print(moneyType)
    end
    if balance >= Config.TruckPrice then
        if moneyType == 'cash' then
            Player.Functions.RemoveMoney(moneyType, Config.TruckPrice, "gas-delivery-truck")
            TriggerClientEvent('spawnTruck', src)
            TriggerClientEvent('TrailerBlip', src)
        else
            Player.Functions.RemoveMoney(moneyType, Config.TruckPrice, "gas-delivery-truck")
            TriggerClientEvent('spawnTruck', src)
            TriggerClientEvent('TrailerBlip', src)
        end
    else
        TriggerClientEvent('NotEnoughTruckMoney', src)
    end
end)
RegisterServerEvent('md-ownedtruck')
AddEventHandler('md-ownedtruck', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local moneyType = Config.PayType
    local balance = Player.Functions.GetMoney(moneyType)
    if Config.Debug == true then
        print(moneyType)
    end
     if balance >= Config.TankPrice then
        if moneyType == 'cash' then
            Player.Functions.RemoveMoney(moneyType, Config.TankPrice, "gas-Tank-truck")
            TriggerClientEvent('spawnTruck2', src)
            TriggerClientEvent('TrailerBlip', src)
        else
            Player.Functions.RemoveMoney(moneyType, Config.TankPrice, "gas-Tank-truck")
            TriggerClientEvent('spawnTruck2', src)
            TriggerClientEvent('TrailerBlip', src)
        end
    else
        TriggerClientEvent('NotEnoughTankMoney', src)
    end 
end)

RegisterServerEvent('md-getpaid')
AddEventHandler('md-getpaid', function(stationsRefueled)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local moneyType = Config.PayType
    local balance = Player.Functions.GetMoney(moneyType)
    Player.Functions.AddMoney(Config.PayType, stationsRefueled * Config.PayPerFueling, "gas-delivery-paycheck")
end)
