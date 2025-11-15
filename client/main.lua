local QBCore = exports['qb-core']:GetCoreObject()
local mastData, objects, blips, pBlips, trackingBlips = {}, {}, {}, {}, {}
local currentlyTrackingPlayer = false
local isPlayingAnimation = false

local function ScrambleTriangulationCoords(coords, radius)
	local a = math.random() * 2.0 * math.pi
	local d = radius * (math.random() ^ 2.0)
	return vec3(coords.x + math.cos(a)*d, coords.y + math.sin(a)*d, coords.z)
end

function CreateTrackingBlip(hits, coords, phone)
	if hits > #Config.Tracking then
		hits = #Config.Tracking
	end

	local radius = Config.Tracking[hits]
	local scrambledCoords = ScrambleTriangulationCoords(coords, radius)

	-- Radius Blip
	local blip = AddBlipForRadius(
		scrambledCoords.x,
		scrambledCoords.y,
		scrambledCoords.z,
		radius
	)
	SetBlipSprite(blip, 9)
	SetBlipColour(blip, 1)
	SetBlipAlpha(blip, 150)
	trackingBlips[#trackingBlips+1] = blip

	-- Center Blip
	local blip = AddBlipForCoord(
		scrambledCoords.x,
		scrambledCoords.y,
		scrambledCoords.z
	)
	SetBlipSprite(blip, 484)
	SetBlipColour(blip, 1)
	SetBlipScale(blip, 1.0)
	SetBlipDisplay(blip, 4)
	SetBlipAsShortRange(blip, false)
	SetBlipHighDetail(blip, true)
	BeginTextCommandSetBlipName("STRING")
	AddTextComponentString("Tracking Phone #: ["..phone.."]")
	EndTextCommandSetBlipName(blip)
	trackingBlips[#trackingBlips+1] = blip
end

local function RemoveTrackingBlip()
	for _, v in pairs(trackingBlips) do
		if DoesBlipExist(v) then
			RemoveBlip(v)
		end
	end
end

function TrackTimer(time)
	CreateThread(function()
		currentlyTrackingPlayer = true
		local timer = time or Config.TrackingMaxTime

		while timer > 0 and currentlyTrackingPlayer do
			Wait(1000)
			timer -= 1
		end

		currentlyTrackingPlayer = false
		RemoveTrackingBlip()
	end)
end

function TrackingDelay(phone, delay)
	CreateThread(function()
		while phone and currentlyTrackingPlayer do
			local hits, coords = lib.callback.await("rb-triangulation:cb:triangulatePlayer", false, phone)

			if hits then
				RemoveTrackingBlip()
				CreateTrackingBlip(hits, coords, phone)
			end

			Wait(delay*1000)
		end

		RemoveTrackingBlip()
	end)
end

function CancelCurrentTracking()
	if currentlyTrackingPlayer then
		currentlyTrackingPlayer = false
	end
end

local function CreateObjectNoNetwork(obj, coords)
	if not obj or not coords then return false end

	lib.requestModel(obj)

	local newObj = CreateObject(joaat(obj), coords.x, coords.y, coords.z-1, false, true, false)
	SetEntityHeading(newObj, coords.w)
	FreezeEntityPosition(newObj, true)

	return newObj
end

local function DisableKeys()
	DisableControlAction(0, 30, true)
	DisableControlAction(0, 31, true)
	DisableControlAction(0, 21, true)
	DisableControlAction(0, 22, true)
	DisableControlAction(0, 24, true)
	DisableControlAction(0, 25, true)
	DisableControlAction(0, 140, true)
	DisableControlAction(0, 141, true)
	DisableControlAction(0, 142, true)
	DisableControlAction(0, 143, true)
	DisableControlAction(0, 263, true)
	DisableControlAction(0, 264, true)
	DisableControlAction(0, 45, true)
end

local function PlayAnimation(dict, anim)
	if not dict or not anim then return end
	local ped = PlayerPedId()

	lib.requestAnimDict(dict)
	TaskPlayAnim(ped, dict, anim, 8.0, -8.0, -1, 49, 0.0, false, false, false)
	isPlayingAnimation = true

	CreateThread(function()
		while isPlayingAnimation do
			Wait(0)
			DisableKeys()
		end
	end)
end

local function StopAnimation()
	local ped = PlayerPedId()

	isPlayingAnimation = false
	ClearPedTasks(ped)
end

local function RadiusToKey(radius)
	for key, data in pairs(Config.Coverage) do
		if data.radius == radius then
			return key
		end
	end

	return nil
end

local function CreateBlipsForMasts()
	if Config.Debug or Config.Blips then
		if blips and next(blips) then
			for _, v in pairs(blips) do
				if DoesBlipExist(v) then
					RemoveBlip(v)
				end
			end
		end

		if pBlips and next(pBlips) then
			for _, v in pairs(pBlips) do
				if DoesBlipExist(v) then
					RemoveBlip(v)
				end
			end
		end

		for i = 1, #mastData do
			local mast = mastData[i]

			if Config.Debug then
				local blip = AddBlipForRadius(mast.coords.x, mast.coords.y, mast.coords.z, mast.coverage)
				SetBlipSprite(blip, 9)
				SetBlipColour(blip, color)
				SetBlipAlpha(blip, 150)
				blips[#blips+1] = blip
			end

			if Config.Blips then
				local k = RadiusToKey(mast.coverage)
				local disp = AddBlipForCoord(mast.coords.x, mast.coords.y, mast.coords.z)
				SetBlipSprite(disp, 767)
				SetBlipColour(disp, Config.Coverage[k].blipColor)
				SetBlipScale(disp, 0.7)
				SetBlipHighDetail(disp, true)
				SetBlipAsShortRange(disp, true)
				BeginTextCommandSetBlipName("STRING")
				AddTextComponentString("Mast")
				EndTextCommandSetBlipName(disp)
				pBlips[#pBlips+1] = disp
			end
		end
	end
end

RegisterNetEvent("rb-triangulation:client:syncData", function(payload)
	mastData = payload
	CreateBlipsForMasts()
end)

RegisterNetEvent("rb-triangulation:client:repair", function(payload)
	local mastId = GetClosestMastToCoords(payload.coords)
	local mast = mastData[mastId]

	if mast.health < Config.Coverage[1].health then
		PlayAnimation(Config.Repairing.dict, Config.Repairing.anim)
		local success = Minigame("Repairing mast")
		StopAnimation()

		mastData[mastId].health += Config.Repairing.mastHealthAddition

		if mast.health > Config.Coverage[1].health then
			mast.health = Config.Coverage[1].health
		end

		local newLogEntry = {mastId = mastId, activity = "🟢 Repaired"}
		TriggerServerEvent("rb-triangulation:server:syncData", mastData, newLogEntry)
		TriggerServerEvent("rb-triangulation:server:pay")
		Notify("Repair successful", 3000, "success")
	else
		Notify("No reparation needed", 3000, "inform")
	end
end)

RegisterNetEvent("rb-triangulation:client:hack", function(payload)
	local mastId = GetClosestMastToCoords(payload.coords)
	local mast = mastData[mastId]
	local newHealth = nil

	if mast.health > Config.Coverage[#Config.Coverage].health then
		if Config.PoliceAlert then
			PoliceAlert(payload.coords)
		end

		PlayAnimation(Config.Hacking.dict, Config.Hacking.anim)
		local success = Minigame("Compromising mast")
		StopAnimation()

		if success then
			newHealth = (mast.health-Config.Hacking.mastHealthReduction)

			if mast.health < 1 then
				newHealth = 1
			end

			mastData[mastId].health = newHealth
			local newLogEntry = {mastId = mastId, activity = "🟣 Hacked"}
			TriggerServerEvent("rb-triangulation:server:syncData", mastData, newLogEntry)

			local input = lib.inputDialog("System", {
				{type = "input", label = "Enter Phone number", icon = "hashtag", required = true},
			})

			if input and input[1] then
				if TrackPhone(input[1]) then
					Notify("Tracking Phone", 3000, "success")
				else
					Notify("Phone could not be tracked", 3000, "error")
				end
			end
		end
	else
		Notify("Too damaged", 3000, "inform")
	end
end)

RegisterNetEvent("rb-triangulation:client:status", function(payload)
	local mastId = GetClosestMastToCoords(payload.coords)
	local mast = mastData[mastId]
	local color = "blue"
	local logs = ""

	if next(mast.logs) then
		for _, v in pairs(mast.logs) do
			logs = logs .. (v.activity or "Unknown") .. " — " .. (v.time or "") ..  " UTC\n"
		end
	else
		logs = "N/A"
	end

	if mast.recovering.state then
		color = "orange"
	end

	lib.registerContext({
		id = "mast_options",
		title = "Mast ["..mastId.."]",
		options = {
			{
				readOnly = true,
				title = "Status",
				progress = mast.health,
				colorScheme = color
			},

			{
				readOnly = true,
				title = "Logs",
				description = logs
			},
		}
	})

	lib.showContext("mast_options")
end)

CreateThread(function()
	for i = 1, #Config.Masts do
		local mast = Config.Masts[i]

		local offsetBox = Config.Offsets.box
		local offsetLight = Config.Offsets.light
		local boxWithOffset = vec4(GetObjectOffsetFromCoords(mast.coords, offsetBox), mast.coords.w)
		local lightWithOffset = vec4(GetObjectOffsetFromCoords(mast.coords, offsetLight), mast.coords.w)

		local objMast = CreateObjectNoNetwork(Config.Props.mast, vec4(mast.coords.x, mast.coords.y, mast.coords.z-0.25, mast.coords.w-180))
		local objBox = CreateObjectNoNetwork(Config.Props.box, boxWithOffset)
		local objLight = CreateObjectNoNetwork(Config.Props.light, lightWithOffset)

		local rot = GetEntityRotation(objMast)
		SetEntityRotation(objLight, rot.x+40, rot.y, rot.z+280, 2, false)
		SetEntityHeading(objBox, mast.coords.w-180)

		objects[#objects+1] = objMast
		objects[#objects+1] = objBox
		objects[#objects+1] = objLight

		if Config.Debug then
			local blip = AddBlipForRadius(mast.coords.x, mast.coords.y, mast.coords.z, Config.Coverage[1].radius)
			SetBlipSprite(blip, 9)
			SetBlipColour(blip, 0)
			SetBlipAlpha(blip, 150)
			blips[#blips+1] = blip
		end

		if Config.Blips then
			local disp = AddBlipForCoord(mast.coords.x, mast.coords.y, mast.coords.z)
			SetBlipSprite(disp, 767)
			SetBlipColour(disp, Config.Coverage[1].blipColor)
			SetBlipScale(disp, 0.7)
			SetBlipHighDetail(disp, true)
			SetBlipAsShortRange(disp, true)
			BeginTextCommandSetBlipName("STRING")
			AddTextComponentString("Mast")
			EndTextCommandSetBlipName(disp)
			pBlips[#pBlips+1] = disp
		end
	end

	exports.ox_target:addModel(Config.Props.box, {
		{
			label = "Status",
			distance = 1.0,
			icon = "fas fa-signal",
			event = "rb-triangulation:client:status",
			canInteract = function()
				local _, distance = GetClosestMastToPed()
				if distance < 3.0 then return true end
			end
		},

		{
			label = "Repair",
			distance = 1.0,
			icon = "fas fa-wrench",
			event = "rb-triangulation:client:repair",
			canInteract = function()
				local id, distance = GetClosestMastToPed()
				if distance < 3.0 and not mastData[id].recovering.state then return true end
			end

		},

		{
			label = "Hack",
			distance = 1.0,
			icon = "fas fa-user-secret",
			event = "rb-triangulation:client:hack",
			canInteract = function()
				local id, distance = GetClosestMastToPed()
				if distance < 3.0 and not mastData[id].recovering.state then return true end
			end
		},
	})

	Wait(500)
	mastData = lib.callback.await("rb-triangulation:cb:getMastData", false)
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName == GetCurrentResourceName() then
		for _, v in pairs(objects) do
			if DoesEntityExist(v) then
				DeleteObject(v)
			end
		end
    end
end)