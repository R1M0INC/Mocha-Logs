-- In here i will show you the file-name, line and what to change.

----------------
---- SERVER ----
----------------

-- [Un Managed Showroom]

-- file-name : qb-vehicleshop | server.lua
-- line : 140 (may differ mines heavily modified)
-- Replace event-financePayment with the one below.
RegisterNetEvent('qb-vehicleshop:server:financePayment', function(paymentAmount, vehData)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local cash = player.PlayerData.money['cash']
    local bank = player.PlayerData.money['bank']
    local plate = vehData.vehiclePlate
    paymentAmount = tonumber(paymentAmount)
    local minPayment = tonumber(vehData.paymentAmount)
    local timer = (Config.PaymentInterval * 60)
    local newBalance, newPaymentsLeft, newPayment = calculateNewFinance(paymentAmount, vehData)
    if newBalance > 0 then
        if Player and paymentAmount >= minPayment then
            if cash >= paymentAmount then
                Player.Functions.RemoveMoney('cash', paymentAmount)
                MySQL.update('UPDATE player_vehicles SET balance = ?, paymentamount = ?, paymentsleft = ?, financetime = ? WHERE plate = ?', {newBalance, newPayment, newPaymentsLeft, timer, plate})
                TriggerEvent('qb-log:server:CreateLog', 'ChangeMe', 'Dealership (Finance)', 'blue', ('**Customer:** %s | **License:** ||(%s)||\n **New Payment:** ($%s) | Cash\n **Outstanding:** %s\n **Remaining Payments:** %s\n **Vehicle Plate:** %s '):format(GetPlayerName(src), Player.PlayerData.license, paymentAmount, newBalance, newPaymentsLeft, plate))
            elseif bank >= paymentAmount then
                Player.Functions.RemoveMoney('bank', paymentAmount)
                MySQL.update('UPDATE player_vehicles SET balance = ?, paymentamount = ?, paymentsleft = ?, financetime = ? WHERE plate = ?', {newBalance, newPayment, newPaymentsLeft, timer, plate})
                TriggerEvent('qb-log:server:CreateLog', 'ChangeMe', 'Dealership (Finance)', 'blue', ('**Customer:** %s | **License:** ||(%s)||\n **New Payment:** ($%s) | Bank\n **Outstanding:** %s\n **Remaining Payments:** %s\n **Vehicle Plate:** %s '):format(GetPlayerName(src), Player.PlayerData.license, paymentAmount, newBalance, newPaymentsLeft, plate))
            else
                TriggerClientEvent('QBCore:Notify', src, Lang:t('error.notenoughmoney'), 'error')
            end
        else
            TriggerClientEvent('QBCore:Notify', src, Lang:t('error.minimumallowed') .. comma_value(minPayment), 'error')
        end
    else
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.overpaid'), 'error')
    end
end)

-- file-name : qb-vehicleshop | server.lua
-- line : 173 (may differ mines heavily modified)
-- Replace event-financePaymentFull with the one below.
RegisterNetEvent('qb-vehicleshop:server:financePaymentFull', function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local cash = Player.PlayerData.money['cash']
    local bank = Player.PlayerData.money['bank']
    local vehBalance = data.vehBalance
    local vehPlate = data.vehPlate
    if Player and vehBalance ~= 0 then
        if cash >= vehBalance then
            Player.Functions.RemoveMoney('cash', vehBalance)
            MySQL.update('UPDATE player_vehicles SET balance = ?, paymentamount = ?, paymentsleft = ?, financetime = ? WHERE plate = ?', {0, 0, 0, 0, vehPlate})
            TriggerEvent('qb-log:server:CreateLog', 'ChangeMe', 'Dealership (Finance)', 'blue', ('**Customer:** %s | **License:** ||(%s)||\n **Payment:** ($%s) | Cash\n **Vehicle Plate:** %s\n **Remaining Payments:** 0\n **Remaining Balance:** 0 '):format(GetPlayerName(src), Player.PlayerData.license, vehBalance, vehPlate))
        elseif bank >= vehBalance then
            Player.Functions.RemoveMoney('bank', vehBalance)
            MySQL.update('UPDATE player_vehicles SET balance = ?, paymentamount = ?, paymentsleft = ?, financetime = ? WHERE plate = ?', {0, 0, 0, 0, vehPlate})
            TriggerEvent('qb-log:server:CreateLog', 'ChangeMe', 'Dealership (Finance)', 'blue', ('**Customer:** %s | **License:** ||(%s)||\n **Payment:** ($%s) | Bank\n **Vehicle Plate:** %s\n **Remaining Payments:** 0\n **Remaining Balance:** 0 '):format(GetPlayerName(src), Player.PlayerData.license, vehBalance, vehPlate))
        else
            TriggerClientEvent('QBCore:Notify', src, Lang:t('error.notenoughmoney'), 'error')
        end
    else
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.alreadypaid'), 'error')
    end
end)

-- file-name : qb-vehicleshop | server.lua
-- line : 198 (may differ mines heavily modified)
-- Replace event-buyShowroomVehicle with the one below.
RegisterNetEvent('qb-vehicleshop:server:buyShowroomVehicle', function(vehicle)
    local src = source
    vehicle = vehicle.buyVehicle
    local Player = QBCore.Functions.GetPlayer(src)
    local cid = Player.PlayerData.citizenid
    local cash = Player.PlayerData.money['cash']
    local bank = Player.PlayerData.money['bank']
    local vehiclePrice = QBCore.Shared.Vehicles[vehicle]['price']
    local plate = GeneratePlate()
    if cash > tonumber(vehiclePrice) then
        MySQL.insert('INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, garage, state) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {
            Player.PlayerData.license,
            cid,
            vehicle,
            GetHashKey(vehicle),
            '{}',
            plate,
            'pillboxgarage',
            0
        })
        TriggerClientEvent('QBCore:Notify', src, Lang:t('success.purchased'), 'success')
        TriggerClientEvent('qb-vehicleshop:client:buyShowroomVehicle', src, vehicle, plate)
        Player.Functions.RemoveMoney('cash', vehiclePrice, 'vehicle-bought-in-showroom')
        TriggerEvent('qb-log:server:CreateLog', 'ChangeMe', 'Dealership (Purchase)', 'blue', ('**Customer:** %s | **License:** ||(%s)||\n **Price:** ($%s) | Bank\n **Vehicle:** %s | **Vehicle Plate:** %s '):format(GetPlayerName(src), Player.PlayerData.license, vehiclePrice, vehicle, plate))
    elseif bank > tonumber(vehiclePrice) then
        MySQL.insert('INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, garage, state) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {
            Player.PlayerData.license,
            cid,
            vehicle,
            GetHashKey(vehicle),
            '{}',
            plate,
            'pillboxgarage',
            0
        })
        TriggerClientEvent('QBCore:Notify', src, Lang:t('success.purchased'), 'success')
        TriggerClientEvent('qb-vehicleshop:client:buyShowroomVehicle', src, vehicle, plate)
        Player.Functions.RemoveMoney('bank', vehiclePrice, 'vehicle-bought-in-showroom')
        TriggerEvent('qb-log:server:CreateLog', 'ChangeMe', 'Dealership (Purchase)', 'blue', ('**Customer:** %s | **License:** ||(%s)||\n **Price:** ($%s) | Cash\n **Vehicle:** %s | **Vehicle Plate:** %s '):format(GetPlayerName(src), Player.PlayerData.license, vehiclePrice, vehicle, plate))
    else
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.notenoughmoney'), 'error')
    end
end)

-- file-name : qb-vehicleshop | server.lua
-- line : 243 (may differ mines heavily modified)
-- Replace event-financeVehicle with the one below.
RegisterNetEvent('qb-vehicleshop:server:financeVehicle', function(downPayment, paymentAmount, vehicle)
    local src = source
    downPayment = tonumber(downPayment)
    paymentAmount = tonumber(paymentAmount)
    local Player = QBCore.Functions.GetPlayer(src)
    local cid = Player.PlayerData.citizenid
    local cash = Player.PlayerData.money['cash']
    local bank = Player.PlayerData.money['bank']
    local vehiclePrice = QBCore.Shared.Vehicles[vehicle]['price']
    local timer = (Config.PaymentInterval * 60)
    local minDown = tonumber(round((Config.MinimumDown / 100) * vehiclePrice))
    if downPayment > vehiclePrice then return TriggerClientEvent('QBCore:Notify', src, Lang:t('error.notworth'), 'error') end
    if downPayment < minDown then return TriggerClientEvent('QBCore:Notify', src, Lang:t('error.downtoosmall'), 'error') end
    if paymentAmount > Config.MaximumPayments then return TriggerClientEvent('QBCore:Notify', src, Lang:t('error.exceededmax'), 'error') end
    local plate = GeneratePlate()
    local balance, vehPaymentAmount = calculateFinance(vehiclePrice, downPayment, paymentAmount)
    if cash >= downPayment then
        MySQL.insert('INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, garage, state, balance, paymentamount, paymentsleft, financetime) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
            Player.PlayerData.license,
            cid,
            vehicle,
            GetHashKey(vehicle),
            '{}',
            plate,
            'pillboxgarage',
            0,
            balance,
            vehPaymentAmount,
            paymentAmount,
            timer
        })
        TriggerClientEvent('QBCore:Notify', src, Lang:t('success.purchased'), 'success')
        TriggerClientEvent('qb-vehicleshop:client:buyShowroomVehicle', src, vehicle, plate)
        Player.Functions.RemoveMoney('cash', downPayment, 'vehicle-bought-in-showroom')
        TriggerEvent('qb-log:server:CreateLog', 'ChangeMe', 'Dealership (Finance)', 'blue', ('**Customer:** %s | **License:** ||(%s)||\n **Down Payment:** ($%s) | Cash\n **Vehicle Price:** ($%s)\n **Remaining Payments:** %s\n **Vehicle:** %s | **Vehicle Plate:** %s '):format(GetPlayerName(src), Player.PlayerData.license, downPayment, vehiclePrice, paymentAmount, vehicle, plate))
    elseif bank >= downPayment then
        MySQL.insert('INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, garage, state, balance, paymentamount, paymentsleft, financetime) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
            Player.PlayerData.license,
            cid,
            vehicle,
            GetHashKey(vehicle),
            '{}',
            plate,
            'pillboxgarage',
            0,
            balance,
            vehPaymentAmount,
            paymentAmount,
            timer
        })
        TriggerClientEvent('QBCore:Notify', src, Lang:t('success.purchased'), 'success')
        TriggerClientEvent('qb-vehicleshop:client:buyShowroomVehicle', src, vehicle, plate)
        Player.Functions.RemoveMoney('bank', downPayment, 'vehicle-bought-in-showroom')
        TriggerEvent('qb-log:server:CreateLog', 'ChangeMe', 'Dealership (Finance)', 'blue', ('**Customer:** %s | **License:** ||(%s)||\n **Down Payment:** ($%s) | Bank\n **Vehicle Price:** ($%s)\n **Remaining Payments:** %s\n **Vehicle:** %s | **Vehicle Plate:** %s '):format(GetPlayerName(src), Player.PlayerData.license, downPayment, vehiclePrice, paymentAmount, vehicle, plate))
    else
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.notenoughmoney'), 'error')
    end
end)

-- file-name : qb-vehicleshop | server.lua
-- line : 303 (may differ mines heavily modified)
-- Replace event-sellShowroomVehicle with the one below.
RegisterNetEvent('qb-vehicleshop:server:sellShowroomVehicle', function(data, playerid)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local Customer = QBCore.Functions.GetPlayer(tonumber(playerid))

    if not Customer then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.Invalid_ID'), 'error')
        return
    end

    if #(GetEntityCoords(GetPlayerPed(src)) - GetEntityCoords(GetPlayerPed(playerid))) < 3 then
        local cid = Customer.PlayerData.citizenid
        local cash = Customer.PlayerData.money['cash']
        local bank = Customer.PlayerData.money['bank']
        local vehicle = data
        local vehiclePrice = QBCore.Shared.Vehicles[vehicle]['price']
        local commission = round(vehiclePrice * Config.Commission)
        local plate = GeneratePlate()
        if cash >= tonumber(vehiclePrice) then
            MySQL.insert('INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, garage, state) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {
                Customer.PlayerData.license,
                cid,
                vehicle,
                GetHashKey(vehicle),
                '{}',
                plate,
                'pillboxgarage',
                0
            })
            TriggerClientEvent('qb-vehicleshop:client:buyShowroomVehicle', Customer.PlayerData.source, vehicle, plate)
            Customer.Functions.RemoveMoney('cash', vehiclePrice, 'vehicle-bought-in-showroom')
            Player.Functions.AddMoney('bank', commission)
            TriggerClientEvent('QBCore:Notify', src, Lang:t('success.earned_commission', {amount = comma_value(commission)}), 'success')
            exports['qb-management']:AddMoney(Player.PlayerData.job.name, vehiclePrice)
            TriggerClientEvent('QBCore:Notify', Customer.PlayerData.source, Lang:t('success.purchased'), 'success')
            TriggerEvent('qb-log:server:CreateLog', 'ChangeMe', 'Dealership (Sale)', 'blue', ('**Salesman:** %s | **License:** ||(%s)||\n **Customer:** %s | **License:** ||(%s)||\n **Vehicle Price:** ($%s) Cash | **Commission** %s\n **Vehicle:** %s | **Vehicle Plate:** %s '):format(GetPlayerName(src), Player.PlayerData.license, GetPlayerName(src), Customer.PlayerData.license, vehiclePrice, commission, vehicle, plate))
        elseif bank >= tonumber(vehiclePrice) then
            MySQL.insert('INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, garage, state) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {
                Customer.PlayerData.license,
                cid,
                vehicle,
                GetHashKey(vehicle),
                '{}',
                plate,
                'pillboxgarage',
                0
            })
            TriggerClientEvent('qb-vehicleshop:client:buyShowroomVehicle', Customer.PlayerData.source, vehicle, plate)
            Customer.Functions.RemoveMoney('bank', vehiclePrice, 'vehicle-bought-in-showroom')
            Player.Functions.AddMoney('bank', commission)
            exports['qb-management']:AddMoney(Player.PlayerData.job.name, vehiclePrice)
            TriggerClientEvent('QBCore:Notify', src, Lang:t('success.earned_commission', {amount = comma_value(commission)}), 'success')
            TriggerClientEvent('QBCore:Notify', Customer.PlayerData.source, Lang:t('success.purchased'), 'success')
            TriggerEvent('qb-log:server:CreateLog', 'ChangeMe', 'Dealership (Sale)', 'blue', ('**Salesman:** %s | **License:** ||(%s)||\n **Customer:** %s | **License:** ||(%s)||\n **Vehicle Price:** ($%s) Bank | **Commission** %s\n **Vehicle:** %s | **Vehicle Plate:** %s '):format(GetPlayerName(src), Player.PlayerData.license, GetPlayerName(src), Customer.PlayerData.license, vehiclePrice, commission, vehicle, plate))
        else
            TriggerClientEvent('QBCore:Notify', src, Lang:t('error.notenoughmoney'), 'error')
        end
    else
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.playertoofar'), 'error')
    end
end)

-- file-name : qb-vehicleshop | server.lua
-- line : 366 (may differ mines heavily modified)
-- Replace event-sellfinanceVehicle with the one below.
RegisterNetEvent('qb-vehicleshop:server:sellfinanceVehicle', function(downPayment, paymentAmount, vehicle, playerid)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local Customer = QBCore.Functions.GetPlayer(tonumber(playerid))

    if not Customer then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.Invalid_ID'), 'error')
        return
    end

    if #(GetEntityCoords(GetPlayerPed(src)) - GetEntityCoords(GetPlayerPed(playerid))) < 3 then
        downPayment = tonumber(downPayment)
        paymentAmount = tonumber(paymentAmount)
        local cid = Customer.PlayerData.citizenid
        local cash = Customer.PlayerData.money['cash']
        local bank = Customer.PlayerData.money['bank']
        local vehiclePrice = QBCore.Shared.Vehicles[vehicle]['price']
        local timer = (Config.PaymentInterval * 60)
        local minDown = tonumber(round((Config.MinimumDown / 100) * vehiclePrice))
        if downPayment > vehiclePrice then return TriggerClientEvent('QBCore:Notify', src, Lang:t('error.notworth'), 'error') end
        if downPayment < minDown then return TriggerClientEvent('QBCore:Notify', src, Lang:t('error.downtoosmall'), 'error') end
        if paymentAmount > Config.MaximumPayments then return TriggerClientEvent('QBCore:Notify', src, Lang:t('error.exceededmax'), 'error') end
        local commission = round(vehiclePrice * Config.Commission)
        local plate = GeneratePlate()
        local balance, vehPaymentAmount = calculateFinance(vehiclePrice, downPayment, paymentAmount)
        if cash >= downPayment then
            MySQL.insert('INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, garage, state, balance, paymentamount, paymentsleft, financetime) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
                Customer.PlayerData.license,
                cid,
                vehicle,
                GetHashKey(vehicle),
                '{}',
                plate,
                'pillboxgarage',
                0,
                balance,
                vehPaymentAmount,
                paymentAmount,
                timer
            })
            TriggerClientEvent('qb-vehicleshop:client:buyShowroomVehicle', Customer.PlayerData.source, vehicle, plate)
            Customer.Functions.RemoveMoney('cash', downPayment, 'vehicle-bought-in-showroom')
            Player.Functions.AddMoney('bank', commission)
            TriggerClientEvent('QBCore:Notify', src, Lang:t('success.earned_commission', {amount = comma_value(commission)}), 'success')
            exports['qb-management']:AddMoney(Player.PlayerData.job.name, vehiclePrice)
            TriggerClientEvent('QBCore:Notify', Customer.PlayerData.source, Lang:t('success.purchased'), 'success')
            TriggerEvent('qb-log:server:CreateLog', 'ChangeMe', 'Dealership (Finance)', 'blue', ('**Salesman:** %s | **License:** ||(%s)||\n **Customer:** %s | **License:** ||(%s)||\n **Vehicle Price:** ($%s) Cash | **Commission** %s\n **Down Payment:** %s | **Remaining Payments:** %s\n **Vehicle:** %s | **Vehicle Plate:** %s '):format(GetPlayerName(src), Player.PlayerData.license, GetPlayerName(src), Customer.PlayerData.license, vehiclePrice, commission, downPayment, paymentAmount, vehicle, plate))
        elseif bank >= downPayment then
            MySQL.insert('INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, garage, state, balance, paymentamount, paymentsleft, financetime) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
                Customer.PlayerData.license,
                cid,
                vehicle,
                GetHashKey(vehicle),
                '{}',
                plate,
                'pillboxgarage',
                0,
                balance,
                vehPaymentAmount,
                paymentAmount,
                timer
            })
            TriggerClientEvent('qb-vehicleshop:client:buyShowroomVehicle', Customer.PlayerData.source, vehicle, plate)
            Customer.Functions.RemoveMoney('bank', downPayment, 'vehicle-bought-in-showroom')
            Player.Functions.AddMoney('bank', commission)
            TriggerClientEvent('QBCore:Notify', src, Lang:t('success.earned_commission', {amount = comma_value(commission)}), 'success')
            exports['qb-management']:AddMoney(Player.PlayerData.job.name, vehiclePrice)
            TriggerClientEvent('QBCore:Notify', Customer.PlayerData.source, Lang:t('success.purchased'), 'success')
            TriggerEvent('qb-log:server:CreateLog', 'ChangeMe', 'Dealership (Finance)', 'blue', ('**Salesman:** %s | **License:** ||(%s)||\n **Customer:** %s | **License:** ||(%s)||\n **Vehicle Price:** ($%s) Bank | **Commission** %s\n **Down Payment:** %s | **Remaining Payments:** %s\n **Vehicle:** %s | **Vehicle Plate:** %s '):format(GetPlayerName(src), Player.PlayerData.license, GetPlayerName(src), Customer.PlayerData.license, vehiclePrice, commission, downPayment, paymentAmount, vehicle, plate))
        else
            TriggerClientEvent('QBCore:Notify', src, Lang:t('error.notenoughmoney'), 'error')
        end
    else
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.playertoofar'), 'error')
    end
end)
