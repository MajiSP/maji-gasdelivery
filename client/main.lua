local QBCore = exports['qb-core']:GetCoreObject()

local props = {
    'prop_storagetank_02b',
}

local refuelProp = 'prop_oil_wellhead_06'

local coords = vector3(1733.08, -1556.68, 112.66)
local heading = 252.0
local tankerCoords = vector3(1738.34, -1530.89, 112.65)
local refuelheading = 254.5
local cooldown = 0
local blip = nil
local stationsRefueled = 0
local maxStations = 0
local truck = 0
local trailer = 0
local nozzleInHand = false
local Rope1 = nil
local Rope2 = nil
local playerPed = PlayerPedId()
local targetCoord = vector3(1688.59, -1460.29, 111.65)
local distanceThreshold = 15.0
local RefuelingStation = false
local timestried = 0
local StoredTruck = nil
local StoredTrailer = nil
local src = source

local trailerModels = {
    '1956216962',
    '3564062519'
}

local myBoxZone = BoxZone:Create(vector3(1694.6, -1460.75, 112.92), 26.8, 15, {
    heading = 345,
    debugPoly = false
})

--/////////////////////////////////////////////////////////////////////////////////////////////////--

local function LoadAnimDict(dict)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(10) end
end

--/////////////////////////////////////////////////////////////////////////////////////////////////--

local pedModel = Config.PedType
local pedCoords = vector4(1721.87, -1557.67, 111.65, 243.12)

--/////////////////////////////////////////////////////////////////////////////////////////////////--

CreateThread(function()
    while true do
        FreezeEntityPosition(pumpProp, true)
        Wait(0)
    end
end)

CreateThread(function()
    local pedHash = GetHashKey(pedModel)
    RequestModel(pedHash)

    while not HasModelLoaded(pedHash) do
        Wait(0)
    end

    local targetped = CreatePed(4, pedHash, pedCoords.x, pedCoords.y, pedCoords.z, pedCoords.w, false, true)
    SetEntityAsMissionEntity(targetped, true, true)
    SetBlockingOfNonTemporaryEvents(targetped, true)
    SetPedDiesWhenInjured(targetped, false)
    SetPedCanRagdollFromPlayerImpact(targetped, false)
    SetPedCanRagdoll(targetped, false)
    SetPedCanPlayAmbientAnims(targetped, true)
    SetPedCanPlayAmbientBaseAnims(targetped, true)
    SetPedCanPlayGestureAnims(targetped, true)
    SetPedCanPlayVisemeAnims(targetped, false, false)
    SetPedCanPlayInjuredAnims(targetped, false)
    FreezeEntityPosition(targetped, true)
    SetEntityInvincible(targetped, true)

    if Config.UseMenu == true then
        if Config.Menu == 'qb' and Config.Target == 'qb' then
            exports['qb-target']:AddTargetModel({pedHash}, {
                options = {
                    {
                        num = 1,
                        type = "client",
                        event = "md-opentruckermenu",
                        icon = "fas fa-sign-in-alt",
                        label = "Talk To Boss!",
                    },
                  
                },
                distance = 2.0,
            })
        end
    else
        if Config.Target == 'qb' then
            exports['qb-target']:AddTargetModel({pedHash}, {
                options = {
                    {
                        num = 1,
                        type = "server",
                        event = "md-checkCash",
                        icon = "fas fa-sign-in-alt",
                        label = "Rent a Truck and Start Work",
                    },
                    {
                        num = 2,
                        type = "server",
                        event = "md-ownedtruck",
                        icon = "fas fa-sign-in-alt",
                        label = "Start Work With Your Own Truck",
                    },
                    {
                        num = 3,
                        type = "client",
                        event = "GetTruckerPay",
                        icon = "fas fa-money-bill-wave",
                        label = "Get Paycheck",
                    },
                    {
                        num = 4,
                        type = "client",
                        event = "RestartJob",
                        icon = "fas fa-ban",
                        label = "Restart Job",
                    },
                },
                distance = 2.0,
            })
        end
    end
end)


--/////////////////////////////////////////////////////////////////////////////////////////////////--

Citizen.CreateThread(function()
    for _, info in pairs(Config.Blip) do
        local startblip = AddBlipForCoord(info.x, info.y, info.z)
        SetBlipSprite(startblip, info.id)
        SetBlipDisplay(startblip, 4)
        SetBlipScale(startblip, 0.5)
        SetBlipColour(startblip, info.color)
        SetBlipAsShortRange(startblip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(info.title)
        EndTextCommandSetBlipName(startblip)
    end
end)

--/////////////////////////////////////////////////////////////////////////////////////////////////--

RegisterNetEvent("md-opentruckermenu")
AddEventHandler("md-opentruckermenu", function()
    exports['qb-menu']:openMenu({
        {
            header = "Gas Delivery Job",
            txt = "",
            isMenuHeader = true
        },
        {
            header = "Rent a Truck and Start Work",
            txt = "Rent a Truck and Start Work. Additional Rental fees will be taken from you.",
            icon = "fas fa-sign-in-alt",
            params = {
                event = "md-checkCash",
            }
        },
        {
            header = "Start Work With Your Own Truck",
            txt = "Start Work With Your Own Truck. only the Trailer Fees will be taken from you",
            icon = "fas fa-sign-in-alt",
            params = {
                event = "md-ownedtruck",
            }
        },
        {
            header = "Get Paycheck",
            txt = "Get Your Paycheck",
            icon = "fas fa-money-bill-wave",
            params = {
                event = "GetTruckerPay",
            }
        },
        {
            header = "Restart Job",
            txt = "Restart The Job",
            icon = "fas fa-ban",
            params = {
                event = "RestartJob",
            }
        },
        
    })
   
end)

RegisterNetEvent("spawnTruck")
AddEventHandler("spawnTruck", function()
    QBCore.Functions.SpawnVehicle(Config.TruckToSpawn, function(veh)
        RemoveBlip(blip)
        DeleteVehicle(StoredTruck)
        TruckNetID = NetworkGetNetworkIdFromEntity(veh)
        if Config.Debug == true then
            print("truck ID: "..TruckNetID)
        end
        SetVehicleNumberPlateText(veh, 'TRUCK' .. tostring(math.random(1000, 9999)))
        SetEntityHeading(veh, heading)

        exports[Config.FuelScript]:SetFuel(veh, 100.0)

        TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
        if Config.VehicleKeys == 'qb-vehiclekeys' then
            TriggerEvent("vehiclekeys:client:SetOwner", QBCore.Functions.GetPlate(veh))
            SetVehicleEngineOn(veh, true, true, false)
        else
            if Config.VehicleKeys == 'mk_vehiclekeys' then
                exports["mk_vehiclekeys"]:AddKey(veh)
            end
        end
        truck = 1
        StoredTruck = NetworkGetEntityFromNetworkId(TruckNetID)
    end, coords, heading, true, true)

    QBCore.Functions.SpawnVehicle(Config.TrailerToSpawn, function(veh1)
        DeleteVehicle(StoredTrailer)
        TrailerNetID = NetworkGetNetworkIdFromEntity(veh1)
        if Config.Debug == true then
            print("trailer ID: "..TrailerNetID)
        end
        SetVehicleNumberPlateText(veh1, 'TRUCKER')
        SetEntityHeading(veh1, heading)

        StoredTrailer = NetworkGetEntityFromNetworkId(TrailerNetID)
    end, tankerCoords, heading, true, true)
   
end)

RegisterNetEvent("spawnTruck2")
AddEventHandler("spawnTruck2", function()

    QBCore.Functions.SpawnVehicle(Config.TrailerToSpawn, function(veh2)
        DeleteVehicle(StoredTrailer)
        TrailerNetID = NetworkGetNetworkIdFromEntity(veh2)
        if Config.Debug == true then
            print("trailer ID: "..TrailerNetID)
        end
        SetVehicleNumberPlateText(veh2, 'TRUCKER')
        SetEntityHeading(veh2, heading)

        truck = 1
        StoredTrailer = NetworkGetEntityFromNetworkId(TrailerNetID)
    end, tankerCoords, heading, true, true)
end)

--/////////////////////////////////////////////////////////////////////////////////////////////////--

RegisterNetEvent('TrailerBlip', function()
    blip = AddBlipForCoord(1736.51, -1530.79, 112.66)
    SetBlipSprite(blip, 1)
    SetBlipColour(blip, 5)
    SetBlipScale(blip, 1.0)
    SetBlipRoute(blip, true)
    SetBlipFlashes(blip, true)
    QBCore.Functions.Notify('Go get your tanker!', 'success', 5000)

    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(0)
            local playerPed = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(playerPed, false)

            if vehicle ~= 0 then
                local trailer = GetVehicleTrailerVehicle(vehicle)


                if trailer == 1 then
                    RemoveBlip(blip)
                    TriggerEvent('spawnFlashingBlip')
                    if Config.Debug == true then
                        print("trailer connected")
                    end
                    break
                end
            end
        end
    end)
end)

--/////////////////////////////////////////////////////////////////////////////////////////////////--

RegisterNetEvent('spawnFlashingBlip', function()
    blip = AddBlipForCoord(1686.17, -1457.77, 112.39)
    SetBlipSprite(blip, 1)
    SetBlipColour(blip, 5)
    SetBlipScale(blip, 1.0)
    SetBlipRoute(blip, true)
    SetBlipFlashes(blip, true)
    QBCore.Functions.Notify('Go fuel up your tanker!', 'success', 5000)
    local pumpProp = CreateObject('prop_storagetank_02b', 1688.59, -1460.29, 111.65, true, false, false)
    SetEntityHeading(pumpProp, refuelheading)
    FreezeEntityPosition(pumpProp, true)
end)

--/////////////////////////////////////////////////////////////////////////////////////////////////--

function GetPump(coordss)
	local prop = nil
	local propCoords
	for i = 1, #props, 1 do
		local currentPumpModel = props[i]
		prop = GetClosestObjectOfType(coordss.x, coordss.y, coordss.z, 3.0, currentPumpModel, true, true, true)
		propCoords = GetEntityCoords(prop)
        if Config.Debug == true then
		    print("Gas Pump: ".. prop,  "Pump Coords: "..propCoords)
        end
		if prop ~= 0 then break end
	end
	return propCoords, prop
end

--/////////////////////////////////////////////////////////////////////////////////////////////////--

RegisterNetEvent('refuelTanker', function()
    if Config.Debug == true then
        print("blip: ", blip)
    end

    local vehicle = GetLastDrivenVehicle()
    local trailer = 0
    local hasTrailer, trailerHandle = GetVehicleTrailerVehicle(vehicle, trailer)
    if truck == 1 then
        if not hasTrailer then
            QBCore.Functions.Notify('You need to get your tanker!', 'error', 5000)
        else
            if cooldown == 0 then
                local playerPed = PlayerPedId()
                LoadAnimDict("anim@am_hold_up@male")
                TaskPlayAnim(playerPed, "anim@am_hold_up@male", "shoplift_high", 2.0, 8.0, -1, 50, 0, 0, 0, 0)
                TriggerServerEvent("InteractSound_SV:PlayOnSource", "pickupnozzle", 0.4)
                Wait(300)
                StopAnimTask(playerPed, "anim@am_hold_up@male", "shoplift_high", 1.0)
                fuelnozzle1 = CreateObject('prop_cs_fuel_nozle', 1.0, 1.0, 1.0, true, true, false)
                local lefthand = GetPedBoneIndex(playerPed, 18905)
                AttachEntityToEntity(fuelnozzle1, playerPed, lefthand, 0.13, 0.04, 0.01, -42.0, -115.0, -63.42, 0, 1, 0, 1, 0, 1)
                local grabbednozzlecoords = GetEntityCoords(playerPed)
                local propCoords, prop = GetPump(grabbednozzlecoords)
                RopeLoadTextures()
                while not RopeAreTexturesLoaded() do
                    Wait(0)
                    RopeLoadTextures()
                end
                while not prop do
                    Wait(0)
                end
                Rope1 = AddRope(propCoords.x, propCoords.y, propCoords.z, 0.0, 0.0, 0.0, 3.0, 3, 10.0, 0.0, 1.0, false, false, false, 1.0, true)
                while not Rope1 do
                    Wait(0)
                end
                ActivatePhysics(Rope1)
                Wait(100)
                local nozzlePos1 = GetEntityCoords(fuelnozzle1)
                nozzlePos1 = GetOffsetFromEntityInWorldCoords(fuelnozzle1, 0.0, -0.033, -0.195)
                AttachEntitiesToRope(Rope1, prop, fuelnozzle1, propCoords.x, propCoords.y, propCoords.z + 2.1, nozzlePos1.x, nozzlePos1.y, nozzlePos1.z, length, false, false, nil, nil)
                nozzleInHand = true
                BringToTruck()
                Citizen.CreateThread(function()
                    while nozzleInHand do
                        local currentcoords = GetEntityCoords(playerPed)
                        local dist = #(grabbednozzlecoords - currentcoords)
                        if dist > 10.0 then
                            QBCore.Functions.Notify('Your fuel line has broken!', 'error', 5000)
                            nozzleInHand = false
                            FreezeEntityPosition(trailerId, false)
                            DeleteObject(fuelnozzle1)
                            RopeUnloadTextures()
                            DeleteRope(Rope1)
                        end
                        Wait(2500)
                    end
                end)
            else
                QBCore.Functions.Notify('You have already fueled your truck!', 'error', 5000)
            end
        end
    else
        QBCore.Functions.Notify('You do not have a truck!', 'error', 5000)
    end
end)

--/////////////////////////////////////////////////////////////////////////////////////////////////--

RegisterNetEvent('ReturnNozzle', function()
	nozzleInHand = false
	TriggerServerEvent("InteractSound_SV:PlayOnSource", "putbacknozzle", 0.4)
	Wait(250)
	DeleteObject(fuelnozzle1)
    DeleteObject(fuelnozzle2)
	RopeUnloadTextures()
	DeleteRope(Rope1)
    DeleteRope(Rope2)
end)

--/////////////////////////////////////////////////////////////////////////////////////////////////--

function BringToTruck()
    if Config.Debug == true then
        print("cooldown: "..cooldown)
    end
    CreateThread(function()
        local insideZone = false
        while true do
            Wait(500)
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)

            if myBoxZone:isPointInside(playerCoords) then
                if not insideZone then
                    insideZone = true
                    if truck == 1 and cooldown == 0 then
                        QBCore.Functions.Notify('Go fuel up the tanker!', 'success', 5000)
                        if Config.Target == 'qb' then
                            for _, model in ipairs(trailerModels) do
                                local modelHash = tonumber(model)
                                exports['qb-target']:AddTargetModel({modelHash}, {
                                options = {
                                {
                                    type = "client",
                                    event = "FuelTruck",
                                    icon = "fas fa-gas-pump",
                                    label = "Fuel Truck",
                                    canInteract = function()
                                        if nozzleInHand and cooldown == 0 then
                                            return true
                                        else
                                            return false
                                        end
                                    end
                                },
                            },
                            distance = 5.0,
                            })
                            end
			            end
                    end
                    if Config.Debug == true then
                        print("Player has entered the box zone")
                    end
                end
            else
                if insideZone then
                    insideZone = false
                    if Config.Debug == true then
                        print("Player has left the box zone")
                    end
                end
            end
        end
    end)
end

--/////////////////////////////////////////////////////////////////////////////////////////////////--

RegisterNetEvent('FuelTruck', function()
local playerPed = PlayerPedId()
LoadAnimDict("timetable@gardener@filling_can")
TaskPlayAnim(playerPed, "timetable@gardener@filling_can", "gar_ig_5_filling_can", 8.0, 1.0, -1, 1, 0, 0, 0, 0)
TriggerServerEvent("InteractSound_SV:PlayOnSource", "refuel", 0.3)
QBCore.Functions.Progressbar('Refueling', 'Refueling Tanker...', 15000, false, true, {
    disableMovement = true,
    disableCarMovement = true,
    disableMouse = false,
    disableCombat = true
    }, {}, {}, {}, function()
        cooldown = cooldown + 1
        maxStations = 0
        StopAnimTask(playerPed, "timetable@gardener@filling_can", "gar_ig_5_filling_can", 3.0, 3.0, -1, 2, 0, 0, 0, 0)
        TriggerServerEvent("InteractSound_SV:PlayOnSource", "fuelstop", 0.4)
        QBCore.Functions.Notify('You have finished refueling. You will be receiving an email with the location soon!', 'success', 5000)
        RemoveBlip(blip)
        Wait(10000)
        GetNextLocation()
    end, function()
        StopAnimTask(playerPed, "timetable@gardener@filling_can", "gar_ig_5_filling_can", 3.0, 3.0, -1, 2, 0, 0, 0, 0)
        TriggerServerEvent("InteractSound_SV:PlayOnSource", "fuelstop", 0.4)
        QBCore.Functions.Notify('Stopped Refueling...', 'error', 5000)
    end)
end)

--/////////////////////////////////////////////////////////////////////////////////////////////////--

local function GetRandomLocation()
    if cooldown == 1 then
        local station = {}
        if (station ~= nil) then
            for k, _ in pairs(Config.PumpLocations) do
                station[#station + 1] = k
            end

            local randomStation = station[math.random(#station)]
            local randomStationCoords = Config.PumpLocations[randomStation].coords
            return randomStationCoords
        end
    end
end

if Config.Debug == true then
    print(GetRandomLocation())
end

--/////////////////////////////////////////////////////////////////////////////////////////////////--

function GetNextLocation()
local randomLocation = GetRandomLocation()
cache_location = randomLocation
    TriggerServerEvent('qb-phone:server:sendNewMail', {
        sender = "The Boss",
        subject = "New Fuel Delivery",
        message = "I am sending the location to your GPS in your truck. Please deliver the fuel to the customer in time!"
    })
    SendBlipToNewLocation(randomLocation)
    RefuelStation(randomLocation)
    FreezeEntityPosition(pumpProp, true)
end

--/////////////////////////////////////////////////////////////////////////////////////////////////--

function SendBlipToNewLocation(location)
    blip = AddBlipForCoord(location.x, location.y, location.z-1)
    SetBlipSprite(blip, 1)
    SetBlipColour(blip, 5)
    SetBlipScale(blip, 1.0)
    SetBlipRoute(blip, true)
end

--/////////////////////////////////////////////////////////////////////////////////////////////////--

function RefuelStation(location)
    refuelProp1 = CreateObject(refuelProp, location.x, location.y, location.z-1, true, false, false)
    FreezeEntityPosition(refuelProp1, true)
    SetEntityAsMissionEntity(refuelProp1, true, true)
    if cooldown == 1 then
        if Config.Target == 'qb' then
            for _, model in ipairs(trailerModels) do
                local modelHash = tonumber(model)
                exports['qb-target']:AddTargetModel({modelHash}, {
                    options = {
                    {
                        num = 1,
                        event = "pumpRefuel",
                        icon = "fas fa-gas-pump",
                        label = "Grab Fuel Line",
                        action = function()
                            FreezeEntityPosition(trailerId, true)
                            nozzleInHand = true
                            TriggerEvent('pumpRefuel')
                        end,
                        canInteract = function()
                            if not nozzleInHand then
                                return true
                            else
                                return false
                            end
                        end
                    },
                    {
                        num = 2,
                        type = "client",
                        event = "ReturnNozzle",
                        icon = "fas fa-hand",
                        label = "Return Nozzle",
                        action = function()
                            nozzleInHand = false
                            FreezeEntityPosition(trailerId, false)
                            TriggerEvent('ReturnNozzle')
                        end,
                        canInteract = function()
                            if nozzleInHand and RefuelingStation == false then
                                return true
                            else
                                return false
                            end
                        end,
                    },
                },
                distance = 5.0
            })
            end
        end
    end
end

--/////////////////////////////////////////////////////////////////////////////////////////////////--

RegisterNetEvent('pumpRefuel', function()
    local vehicle = GetLastDrivenVehicle()
    local trailer = 0
    local hasTrailer, trailerHandle = GetVehicleTrailerVehicle(vehicle, trailer)
    local lastVehicle = GetPlayersLastVehicle(playerPed)

    if lastVehicle ~= 0 then
        local success, attachedTrailer = GetVehicleTrailerVehicle(lastVehicle, trailer)

        if success then
            trailerId = attachedTrailer

            if trailerId ~= 0 then
                if Config.Debug == true then
                    print("The last trailer attached to the vehicle the player was in has ID: " .. attachedTrailer)
                end
                local trailerCoords = GetEntityCoords(trailerId)
                if Config.Debug == true then
                    print("The trailer with ID " .. trailerId .. " has coordinates: " .. tostring(trailerCoords))
                end

                if not hasTrailer then
                    QBCore.Functions.Notify('You need to get your tanker!', 'error', 5000)
                elseif maxStations == Config.MaxFuelDeliveries then
                    QBCore.Functions.Notify('You need to go back and refuel your truck!', 'success', 5000)
                    RemoveBlip(blip)
                    Wait(1000)
                    TriggerEvent('spawnFlashingBlip')
                else
                    local playerPed = PlayerPedId()
                    LoadAnimDict("anim@am_hold_up@male")
                    TaskPlayAnim(playerPed, "anim@am_hold_up@male", "shoplift_high", 2.0, 8.0, -1, 50, 0, 0, 0, 0)
                    TriggerServerEvent("InteractSound_SV:PlayOnSource", "pickupnozzle", 0.4)
                    Wait(300)
                    StopAnimTask(playerPed, "anim@am_hold_up@male", "shoplift_high", 1.0)
                    fuelnozzle2 = CreateObject('prop_cs_fuel_nozle', 1.0, 1.0, 1.0, true, true, false)
                    local lefthand = GetPedBoneIndex(playerPed, 18905)
                    AttachEntityToEntity(fuelnozzle2, playerPed, lefthand, 0.13, 0.04, 0.01, -42.0, -115.0, -63.42, 0, 1, 0, 1, 0, 1)
                    local grabbednozzlecoords = GetEntityCoords(playerPed)
                    local playerCoords = GetEntityCoords(playerPed)
                    local refuelProps = cache_location
                    RopeLoadTextures()
                    while not RopeAreTexturesLoaded() do
                        Wait(0)
                        RopeLoadTextures()
                    end
                    while not refuelProps do
                        Wait(0)
                    end
                    Rope2 = AddRope(trailerCoords.x, trailerCoords.y, trailerCoords.z, 0.0, 0.0, 0.0, 3.0, 3, 10.0, 0.0, 1.0, false, false, false, 1.0, true)
                    while not Rope2 do
                        Wait(0)
                    end
                    ActivatePhysics(Rope2)
                    Wait(100)
                    local nozzlePos2 = GetEntityCoords(fuelnozzle2)
                    nozzlePos2 = GetOffsetFromEntityInWorldCoords(fuelnozzle2, 0.0, -0.033, -0.195)
                    AttachEntitiesToRope(Rope2, attachedTrailer, fuelnozzle2, trailerCoords.x, trailerCoords.y + 0.185, trailerCoords.z - 1.354, nozzlePos2.x, nozzlePos2.y, nozzlePos2.z, length, false, false, nil, nil)
                    nozzleInHand = true
                    BringToStation()
                    Citizen.CreateThread(function()
                        while nozzleInHand do
                            FreezeEntityPosition(trailerId, true)
                            local currentcoords = GetEntityCoords(playerPed)
                            local dist = #(grabbednozzlecoords - currentcoords)
                            if dist > 10.0 then
                                QBCore.Functions.Notify('Your fuel line has broken!', 'error', 5000)
                                nozzleInHand = false
                                FreezeEntityPosition(trailerId, false)
                                DeleteObject(fuelnozzle2)
                                RopeUnloadTextures()
                                DeleteRope(Rope2)
                            end
                            Wait(2500)
                        end
                    end)
                end
            end
        end
    end
end)

--/////////////////////////////////////////////////////////////////////////////////////////////////--

function BringToStation()
    QBCore.Functions.Notify('Go fuel up the station!', 'success', 5000)
    if Config.Debug == true then
        print("cooldown: "..cooldown)
    end
    if Config.Target == 'qb' then
        exports['qb-target']:AddTargetModel(refuelProp, {
            options = {
            {
                event = "refuelStation1",
                icon = "fas fa-gas-pump",
                label = "Fuel Station",
                canInteract = function()
                    if nozzleInHand and cooldown == 1 then
                        return true
                    else
                        return false
                    end
                end
            },
        },
        distance = 5.0,
    })
     end
end

--/////////////////////////////////////////////////////////////////////////////////////////////////--
RegisterNetEvent('GetTruckerPay', function()
    local truckEntity = NetworkGetEntityFromNetworkId(TruckNetID)
    local trailerEntity = NetworkGetEntityFromNetworkId(TrailerNetID)

    if stationsRefueled > 0 then
        TriggerServerEvent('md-getpaid', stationsRefueled)
        stationsRefueled = 0
        RemoveBlip(blip)
        DeleteVehicle(truckEntity)
        DeleteVehicle(trailerEntity)
        truck = 0
        trailer = 0
        cooldown = 0
        maxStations = 0
    else
        QBCore.Functions.Notify('You havent done any work!', 'error', 5000)
    end
end)

RegisterNetEvent('md-checkCash', function()
    TriggerServerEvent('md-checkCash')
end)

RegisterNetEvent('md-ownedtruck', function()
    TriggerServerEvent('md-ownedtruck')
end)

RegisterNetEvent('RestartJob', function()
    local truckEntity = NetworkGetEntityFromNetworkId(TruckNetID)
    local trailerEntity = NetworkGetEntityFromNetworkId(TrailerNetID)

    if stationsRefueled > 0 and timestried == 0 then
        QBCore.Functions.Notify('You have done work! Do you not want to be paid?', 'error', 5000)
        Wait(1000)
        QBCore.Functions.Notify('Ask me to end your job again to end it...', 'success', 5000)

        timestried = timestried + 1
    else
        stationsRefueled = 0
        RemoveBlip(blip)
        DeleteVehicle(truckEntity)
        DeleteVehicle(trailerEntity)
        truck = 0
        trailer = 0
        cooldown = 0
        maxStations = 0
        timestried = 0
    end
end)

--/////////////////////////////////////////////////////////////////////////////////////////////////--

RegisterNetEvent('NotEnoughTruckMoney', function()
    QBCore.Functions.Notify('You need $'..Config.TruckPrice..'!', 'error', 5000)
end)

RegisterNetEvent('NotEnoughTankMoney', function()
    QBCore.Functions.Notify('You need $'..Config.TankPrice..'!', 'error', 5000)
end)

--/////////////////////////////////////////////////////////////////////////////////////////////////--

CreateThread(function()
    if Config.Target == 'qb' then
        exports['qb-target']:AddTargetModel(props, {
            options = {
                {
                    num = 1,
                    type = "client",
                    event = "refuelTanker",
                    icon = "fas fa-gas-pump",
                    label = "grab nozzle",
                    canInteract = function()
                        if not IsPedInAnyVehicle(PlayerPedId()) and not nozzleInHand and cooldown == 0 then
                            return true
                        end
                    end,
                },
                {
                    num = 2,
                    type = "client",
                    event = "ReturnNozzle",
                    icon = "fas fa-hand",
                    label = "return nozzle",
                    canInteract = function()
                        if nozzleInHand then
                            return true
                        end
                    end,
                },
            },
            distance = 2.0
        })
    end
end)

--/////////////////////////////////////////////////////////////////////////////////////////////////--

RegisterNetEvent('refuelStation1', function()
    local GasBlip3 = blip
    local playerPed = PlayerPedId()
    LoadAnimDict("timetable@gardener@filling_can")
    TaskPlayAnim(playerPed, "timetable@gardener@filling_can", "gar_ig_5_filling_can", 8.0, 1.0, -1, 1, 0, 0, 0, 0)
    TriggerServerEvent("InteractSound_SV:PlayOnSource", "refuel", 0.3)
    RefuelingStation = true
    QBCore.Functions.Progressbar('Refueling', 'Refueling Station...', 30000, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true
        }, {}, {}, {}, function()
            RefuelingStation = false
            stationsRefueled = stationsRefueled + 1
            maxStations = maxStations + 1
            if maxStations == Config.MaxFuelDeliveries then
                StopAnimTask(playerPed, "timetable@gardener@filling_can", "gar_ig_5_filling_can", 3.0, 3.0, -1, 2, 0, 0, 0, 0)
                TriggerServerEvent("InteractSound_SV:PlayOnSource", "fuelstop", 0.4)
                QBCore.Functions.Notify('Your tank is empty! Return to refuel, or get paid!', 'success', 5000)
                RemoveBlip(GasBlip3)
                FreezeEntityPosition(trailerId, false)
                TriggerEvent('spawnFlashingBlip')
                Wait(30000)
                cooldown = cooldown - 1
            else
                QBCore.Functions.Notify('You have finished refueling. You will be receiving an email with the next location soon!', 'success', 5000)
                StopAnimTask(playerPed, "timetable@gardener@filling_can", "gar_ig_5_filling_can", 3.0, 3.0, -1, 2, 0, 0, 0, 0)
                TriggerServerEvent("InteractSound_SV:PlayOnSource", "fuelstop", 0.4)
                RemoveBlip(GasBlip3)
                Wait(10000)
                GetNextLocation()
            end
        end, function()
        StopAnimTask(playerPed, "timetable@gardener@filling_can", "gar_ig_5_filling_can", 3.0, 3.0, -1, 2, 0, 0, 0, 0)
        TriggerServerEvent("InteractSound_SV:PlayOnSource", "fuelstop", 0.4)
        QBCore.Functions.Notify('Stopped Refueling...', 'error', 5000)
        RefuelingStation = false
    end)
end)
