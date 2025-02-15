-- In here i will show you the file-name, line and what to change.

-- file-name : qb-ambulancejob | server.lua
-- line : 345
-- Replace 911e with the one below.
QBCore.Commands.Add('911e', Lang:t('info.ems_report'), {{name = 'message', help = Lang:t('info.message_sent')}}, false, function(source, args)
	local src = source
	local message
	if args[1] then message = table.concat(args, " ") else message = Lang:t('info.civ_call') end
    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
	local Player = QBCore.Functions.GetPlayer(src)
    local players = QBCore.Functions.GetQBPlayers()
    for _, v in pairs(players) do
        if v.PlayerData.job.name == 'ambulance' and v.PlayerData.job.onduty then
            TriggerClientEvent('hospital:client:ambulanceAlert', v.PlayerData.source, coords, message)
        end
    end
	TriggerEvent('qb-log:server:CreateLog', 'ChangeMe', '911e Created', 'yellow', ('**Name:** %s | **License:** ||(%s)||\n **Info:** %s '):format(GetPlayerName(src), Player.PlayerData.license, message))
end)

-- file-name : qb-policejob | server.lua
-- line : 505
-- Replace 911p with the one below.
QBCore.Commands.Add('911p', Lang:t("commands.police_report"), {{name='message', help= Lang:t("commands.message_sent")}}, false, function(source, args)
	local src = source
    local message
	if args[1] then message = table.concat(args, " ") else message = Lang:t("commands.civilian_call") end
    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    local Player = QBCore.Functions.GetPlayer(src)
    local players = QBCore.Functions.GetQBPlayers()
    for _, v in pairs(players) do
        if v and v.PlayerData.job.name == 'police' and v.PlayerData.job.onduty then
            local alertData = {title = Lang:t("commands.emergency_call"), coords = {x = coords.x, y = coords.y, z = coords.z}, description = message}
            TriggerClientEvent("qb-phone:client:addPoliceAlert", v.PlayerData.source, alertData)
            TriggerClientEvent('police:client:policeAlert', v.PlayerData.source, coords, message)
        end
    end
    TriggerEvent('qb-log:server:CreateLog', 'ChangeMe', '911p Created', 'yellow', ('**Name:** %s | **License:** ||(%s)||\n **Info:** %s '):format(GetPlayerName(src), Player.PlayerData.license, message))
end)

-- file-name : qb-banking | server.lua
-- line : 408
-- Replace givecash with the one below.
QBCore.Commands.Add('givecash', Lang:t('command.givecash'), {{name = 'id', help = 'Player ID'}, {name = 'amount', help = 'Amount'}}, true, function(source, args)
    local src = source
	local id = tonumber(args[1])
	local amount = math.ceil(tonumber(args[2]))

	if id and amount then
		local xPlayer = QBCore.Functions.GetPlayer(src)
		local xReciv = QBCore.Functions.GetPlayer(id)

		if xReciv and xPlayer then
			if not xPlayer.PlayerData.metadata["isdead"] then
				local distance = xPlayer.PlayerData.metadata["inlaststand"] and 3.0 or 10.0
				if #(GetEntityCoords(GetPlayerPed(src)) - GetEntityCoords(GetPlayerPed(id))) < distance then
                    if amount > 0 then
                        if xPlayer.Functions.RemoveMoney('cash', amount) then
                            if xReciv.Functions.AddMoney('cash', amount) then
                                TriggerClientEvent('QBCore:Notify', src, Lang:t('success.give_cash',{id = tostring(id), cash = tostring(amount)}), "success")
                                TriggerClientEvent('QBCore:Notify', id, Lang:t('success.received_cash',{id = tostring(src), cash = tostring(amount)}), "success")
                                TriggerClientEvent("payanimation", src)
                                TriggerEvent('qb-log:server:CreateLog', 'ChangeMe', 'Give Cash (Player)', 'white', ('**Sender:** %s | **License:** ||(%s)||\n **Reciever:** %s | **License:** ||(%s)||\n **Info:** Gave ($%s) '):format(GetPlayerName(src), xPlayer.PlayerData.license, GetPlayerName(args[1]), xReciv.PlayerData.license, args[2]))
                            else
                                -- Return player cash
                                xPlayer.Functions.AddMoney('cash', amount)
                                TriggerClientEvent('QBCore:Notify', src, Lang:t('error.not_give'), "error")
                            end
                        else
                            TriggerClientEvent('QBCore:Notify', src, Lang:t('error.not_enough'), "error")
                        end
                    else
                        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.invalid_amount'), "error")
                    end
				else
					TriggerClientEvent('QBCore:Notify', src, Lang:t('error.too_far_away'), "error")
				end
			else
				TriggerClientEvent('QBCore:Notify', src, Lang:t('error.dead'), "error")
			end
		else
			TriggerClientEvent('QBCore:Notify', src, Lang:t('error.wrong_id'), "error")
		end
	else
		TriggerClientEvent('QBCore:Notify', src, Lang:t('error.givecash'), "error")
	end
end)

-- file-name : qb-phone | server,lua
-- line : 1036
-- Replace bill with the one below.
QBCore.Commands.Add('bill', 'Bill A Player', {{name = 'id', help = 'Player ID'}, {name = 'amount', help = 'Fine Amount'}}, false, function(source, args)
    local src = source
    local biller = QBCore.Functions.GetPlayer(source)
    local billed = QBCore.Functions.GetPlayer(tonumber(args[1]))
    local amount = tonumber(args[2])
    if biller.PlayerData.job.name == "leo" or biller.PlayerData.job.name == 'ambulance' or biller.PlayerData.job.name == 'mechanic' then
        if billed ~= nil then
            if biller.PlayerData.citizenid ~= billed.PlayerData.citizenid then
                if amount and amount > 0 then
                    MySQL.insert(
                        'INSERT INTO phone_invoices (citizenid, amount, society, sender, sendercitizenid) VALUES (?, ?, ?, ?, ?)',
                        {billed.PlayerData.citizenid, amount, biller.PlayerData.job.name,
                         biller.PlayerData.charinfo.firstname, biller.PlayerData.citizenid})
                    TriggerClientEvent('qb-phone:RefreshPhone', billed.PlayerData.source)
                    TriggerClientEvent('QBCore:Notify', source, 'Invoice Successfully Sent', 'success')
                    TriggerClientEvent('QBCore:Notify', billed.PlayerData.source, 'New Invoice Received')
                    TriggerEvent('qb-log:server:CreateLog', 'ChangeMe', 'Bill (Player)', 'white', ('**Sender:** %s | **License:** ||(%s)||\n **Reciever:** %s | **License:** ||(%s)||\n **Info:** Billed For ($%s) '):format(GetPlayerName(src), biller.PlayerData.license, GetPlayerName(args[1]), billed.PlayerData.license, args[2]))
                else
                    TriggerClientEvent('QBCore:Notify', source, 'Must Be A Valid Amount Above 0', 'error')
                end
            else
                TriggerClientEvent('QBCore:Notify', source, 'You Cannot Bill Yourself', 'error')
            end
        else
            TriggerClientEvent('QBCore:Notify', source, 'Player Not Online', 'error')
        end
    else
        TriggerClientEvent('QBCore:Notify', source, 'No Access', 'error')
    end
end)

-- file-name : qb-vehicleshop | server.lua
-- line : 448
-- Replace transfervehicle with the one below.
QBCore.Commands.Add('transfervehicle', Lang:t('general.command_transfervehicle'), {{name = 'ID', help = Lang:t('general.command_transfervehicle_help')}, {name = 'amount', help = Lang:t('general.command_transfervehicle_amount')}}, false, function(source, args)
    local src = source
    local buyerId = tonumber(args[1])
    local sellAmount = tonumber(args[2])
    if buyerId == 0 then return TriggerClientEvent('QBCore:Notify', src, Lang:t('error.Invalid_ID'), 'error') end
    local ped = GetPlayerPed(src)
    local targetPed = GetPlayerPed(buyerId)
    if targetPed == 0 then return TriggerClientEvent('QBCore:Notify', src, Lang:t('error.buyerinfo'), 'error') end
    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle == 0 then return TriggerClientEvent('QBCore:Notify', src, Lang:t('error.notinveh'), 'error') end
    local plate = QBCore.Shared.Trim(GetVehicleNumberPlateText(vehicle))
    if not plate then return TriggerClientEvent('QBCore:Notify', src, Lang:t('error.vehinfo'), 'error') end
    local player = QBCore.Functions.GetPlayer(src)
    local target = QBCore.Functions.GetPlayer(buyerId)
    local row = MySQL.single.await('SELECT * FROM player_vehicles WHERE plate = ?', {plate})
    if Config.PreventFinanceSelling then
        if row.balance > 0 then return TriggerClientEvent('QBCore:Notify', src, Lang:t('error.financed'), 'error') end
    end
    if row.citizenid ~= player.PlayerData.citizenid then return TriggerClientEvent('QBCore:Notify', src, Lang:t('error.notown'), 'error') end
    if #(GetEntityCoords(ped) - GetEntityCoords(targetPed)) > 5.0 then return TriggerClientEvent('QBCore:Notify', src, Lang:t('error.playertoofar'), 'error') end
    local targetcid = target.PlayerData.citizenid
    local targetlicense = QBCore.Functions.GetIdentifier(target.PlayerData.source, 'license')
    if not target then return TriggerClientEvent('QBCore:Notify', src, Lang:t('error.buyerinfo'), 'error') end
    if not sellAmount then
        MySQL.update('UPDATE player_vehicles SET citizenid = ?, license = ? WHERE plate = ?', {targetcid, targetlicense, plate})
        TriggerClientEvent('QBCore:Notify', src, Lang:t('success.gifted'), 'success')
        TriggerClientEvent('vehiclekeys:client:SetOwner', buyerId, plate)
        TriggerClientEvent('QBCore:Notify', buyerId, Lang:t('success.received_gift'), 'success')
        TriggerEvent('qb-log:server:CreateLog', 'ChangeMe', 'Transfer Vehicle (Player)', 'white', ('**Seller:** %s | **License:** ||(%s)||\n **Buyer:** %s | **License:** ||(%s)||\n **Info:** Seller gifted their vehicle for free '):format(GetPlayerName(src), player.PlayerData.license, GetPlayerName(buyerId), target.PlayerData.license))
        return
    end
    if target.Functions.GetMoney('cash') > sellAmount then
        MySQL.update('UPDATE player_vehicles SET citizenid = ?, license = ? WHERE plate = ?', {targetcid, targetlicense, plate})
        player.Functions.AddMoney('cash', sellAmount)
        target.Functions.RemoveMoney('cash', sellAmount)
        TriggerClientEvent('QBCore:Notify', src, Lang:t('success.soldfor') .. comma_value(sellAmount), 'success')
        TriggerClientEvent('vehiclekeys:client:SetOwner', buyerId, plate)
        TriggerClientEvent('QBCore:Notify', buyerId, Lang:t('success.boughtfor') .. comma_value(sellAmount), 'success')
        TriggerEvent('qb-log:server:CreateLog', 'ChangeMe', 'Transfer Vehicle (Player)', 'white', ('**Seller:** %s | **License:** ||(%s)||\n **Buyer:** %s | **License:** ||(%s)||\n **Info:** Sold vehicle for ($%s) using (cash) '):format(GetPlayerName(src), player.PlayerData.license, GetPlayerName(buyerId), target.PlayerData.license, sellAmount))
    elseif target.Functions.GetMoney('bank') > sellAmount then
        MySQL.update('UPDATE player_vehicles SET citizenid = ?, license = ? WHERE plate = ?', {targetcid, targetlicense, plate})
        player.Functions.AddMoney('bank', sellAmount)
        target.Functions.RemoveMoney('bank', sellAmount)
        TriggerClientEvent('QBCore:Notify', src, Lang:t('success.soldfor') .. comma_value(sellAmount), 'success')
        TriggerClientEvent('vehiclekeys:client:SetOwner', buyerId, plate)
        TriggerClientEvent('QBCore:Notify', buyerId, Lang:t('success.boughtfor') .. comma_value(sellAmount), 'success')
        TriggerEvent('qb-log:server:CreateLog', 'ChangeMe', 'Transfer Vehicle (Player)', 'white', ('**Seller:** %s | **License:** ||(%s)||\n **Buyer:** %s | **License:** ||(%s)||\n **Info:** Sold vehicle for ($%s) using (bank) '):format(GetPlayerName(src), player.PlayerData.license, GetPlayerName(buyerId), target.PlayerData.license, sellAmount))
    else
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.buyertoopoor'), 'error')
    end
end)

