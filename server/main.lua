local QBCore = exports['qb-core']:GetCoreObject()
local mastData = Config.Masts

local function TriangulateCoords(coords)
	if not coords then return false end
	local hits = 0

	for i = 1, #mastData do
		local mastCoords = vec3(mastData[i].coords.x, mastData[i].coords.y, mastData[i].coords.z)
		local distance = #(coords-mastCoords)

		if distance < mastData[i].coverage then
			hits += 1
		end
	end

	if hits < 1 then return false end
	return hits, coords
end

local function CreateTimestamp()
	local utcTable = os.date("!*t")
	local unix = os.time(utcTable)
	local hour = utcTable.hour
	local suffix = "AM"

	if hour >= 12 then
		suffix = "PM"
	end
	if hour == 0 then
		hour = 12
	elseif hour > 12 then
		hour = hour - 12
	end

	local monthName = os.date("!%B", unix)
	return string.format("%s %d, %d:%02d %s", monthName, utcTable.day, hour, utcTable.min, suffix)
end

lib.callback.register("rb-triangulation:cb:triangulatePlayer", function(source, phone)
	for _, p in pairs(QBCore.Functions.GetQBPlayers()) do
		if tostring(p.PlayerData.charinfo.phone) == tostring(phone) then
			local item = p.Functions.GetItemByName("phone")

			if item and item.amount and item.amount > 0 then
				local playerId = p.PlayerData.source
				local coords = GetEntityCoords(GetPlayerPed(playerId))
				local trackingHits = TriangulateCoords(coords)
				return trackingHits, coords
			end

			break
		end
	end

	return false
end)

lib.callback.register("rb-triangulation:cb:getAllPlayersInCoverage", function(source, mastPos, mastCoverage)
	local src = source
	local Player = QBCore.Functions.GetPlayer(src)
	if not Player then return end
	local myCid = Player.PlayerData.citizenid
	local otherCids = {}

	for _, p in pairs(QBCore.Functions.GetQBPlayers()) do
		local pS = p.PlayerData.source
		local pC = GetEntityCoords(GetPlayerPed(pS))
		local distance = #(pC-vec3(mastPos.x, mastPos.y, mastPos.z))

		if distance <= mastCoverage then
			otherCids[#otherCids+1] = p.PlayerData.citizenid
		end
	end

	if not otherCids or not next(otherCids) then return false end
	return otherCids
end)

lib.callback.register("rb-triangulation:cb:getMastData", function(source)
	return mastData
end)

RegisterNetEvent("rb-triangulation:server:syncData", function(payload, newLogEntry)
	if newLogEntry then
		payload[newLogEntry.mastId].logs[#payload[newLogEntry.mastId].logs+1] = {
			activity = newLogEntry.activity,
			time = CreateTimestamp()
		}

		payload[newLogEntry.mastId].recovering = {
			state = true,
			expires = os.time() + Config.RecoveryExpiration
		}
	end

	for i = 1, #payload do
		for t = 1, #Config.Coverage do

			-- What do you do when things gets too easy?
			-- Answer: You complicate it.
			if payload[i].health == Config.Coverage[1].health then
				if payload[i].coverage ~= Config.Coverage[1].radius then
					payload[i].coverage = Config.Coverage[1].radius
				end
			end

			if payload[i].coverage == Config.Coverage[t].radius then
				if Config.Coverage[t+1] then
					if payload[i].health <= Config.Coverage[t+1].health then
						payload[i].coverage = Config.Coverage[t+1].radius
					end
				end

				if Config.Coverage[t-1] then
					if payload[i].health >= Config.Coverage[t-1].health then
						payload[i].coverage = Config.Coverage[t-1].radius
					end
				end
			end
		end
	end

	mastData = payload
	TriggerClientEvent("rb-triangulation:client:syncData", -1, mastData)
end)

RegisterNetEvent("rb-triangulation:server:pay", function()
	local src = source
	local Player = QBCore.Functions.GetPlayer(source)
	if not Player then return end

	Player.Functions.AddMoney("bank", Config.Repairing.payPerRepair, "Mast Repair")
end)

CreateThread(function()
	for i = 1, #mastData do
		mastData[i].coverage = Config.Coverage[1].radius
		mastData[i].health = Config.Coverage[1].health
		mastData[i].recovering = {}
		mastData[i].logs = {}
	end
end)

CreateThread(function()
	while true do
		Wait(2000)

		for i = 1, #mastData do
			if next(mastData[i].recovering) and mastData[i].recovering.state then
				if os.time() > mastData[i].recovering.expires then
					mastData[i].recovering.state = false
					TriggerEvent("rb-triangulation:server:syncData", mastData)
				end
			end
		end
	end
end)

CreateThread(function()
	while true do
		Wait(10000)

		local changeOccured = false
		local chance = math.random(1, 100)
		local mast = math.random(1, #mastData)

		if mast and next(mastData[mast]) then
			if mastData[mast].health > Config.Coverage[#Config.Coverage].health then
				if mastData[mast].health > 95 then
					if chance <= 7 then
						changeOccured = true
						mastData[mast].health -= Config.Deterioration
					end

				elseif mastData[mast].health <= 95 and mastData[mast].health > 70 then
					if chance <= 5 then
						changeOccured = true
						mastData[mast].health -= Config.Deterioration
					end

				else
					if chance <= 2 then
						changeOccured = true
						mastData[mast].health -= Config.Deterioration
					end
				end

				if mastData[mast].health < 0 then
					mastData[mast].health = 1
				end
			end

			if changeOccured then
				TriggerEvent("rb-triangulation:server:syncData", mastData)
			end
		end
	end
end)