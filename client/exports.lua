function TrackPhone(phone, time)
	if not phone then return false end
	if not time then time = Config.TrackingMaxTime end
	local hits, coords = lib.callback.await("rb-triangulation:cb:triangulatePlayer", false, phone)

	if hits then
		CancelCurrentTracking()
		CreateTrackingBlip(hits, coords, phone)
		TrackTimer(time)
		return true
	end
end exports("TrackPhone", TrackPhone)

function TrackPhoneContinuously(phone, time, delay)
	if not phone then return false end
	if not time then time = Config.TrackingMaxTime end
	if not delay or (delay < 1) then delay = 1 end
	local hits, coords = lib.callback.await("rb-triangulation:cb:triangulatePlayer", false, phone)

	if hits then
		CancelCurrentTracking()
		TrackTimer(time)
		TrackingDelay(phone, delay)
		return true
	end
end exports("TrackPhoneContinuously", TrackPhoneContinuously)

function CancelTracking()
	CancelCurrentTracking()
end exports("CancelTracking", CancelTracking)

function GetClosestMastToPed()
	local ped = PlayerPedId()
	local pCoords = GetEntityCoords(ped)
	local yDist = 5000
	local closestMast = nil

	for i = 1, #Config.Masts do
		local xDist = #(pCoords-vec3(Config.Masts[i].coords.x, Config.Masts[i].coords.y, Config.Masts[i].coords.z))
		if xDist < yDist then
			yDist = xDist
			closestMast = i
		end
	end

	return closestMast, yDist or false
end exports("GetClosestMastToPed", GetClosestMastToPed)

function GetClosestMastToCoords(coords)
	if not coords then return false end
	local yDist = 5000
	local closestMast = nil

	for i = 1, #Config.Masts do
		local xDist = #(vec3(coords.x, coords.y, coords.z)-vec3(Config.Masts[i].coords.x, Config.Masts[i].coords.y, Config.Masts[i].coords.z))
		if xDist < yDist then
			yDist = xDist
			closestMast = i
		end
	end

	return closestMast, yDist or false
end exports("GetClosestMastToCoords", GetClosestMastToCoords)

function GetPlayersInPlayerMastCoverage()
	local data = lib.callback.await("rb-triangulation:cb:getMastData", false)
	local closestMast, distance = GetClosestMastToPed()
	local mastPos = Config.Masts[closestMast].coords
	local mastCoverage = data[closestMast].coverage
	local playersInRange = lib.callback.await("rb-triangulation:cb:getAllPlayersInCoverage", false, mastPos, mastCoverage)

	return playersInRange or false
end exports("GetPlayersInPlayerMastCoverage", GetPlayersInPlayerMastCoverage)