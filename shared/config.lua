Config = {}

-- Show mast-coverage on the map.
Config.Debug = false


-- Show blips for each mast.
Config.Blips = true


-- The props we use for the masts.
Config.Props = {
	mast = "prop_mobile_mast_1",
	box = "prop_elecbox_14",
	light = "prop_wall_light_02a",
}

-- Offsets for the props.
Config.Offsets = {
	box = vec3(2.2, -0.49, 0.0),
	light = vec3(0.45, 0.0, 5.0),
}


-- Config for the hacking-part.
Config.Hacking = {
	dict = "mini@repair", anim = "fixing_a_ped",
	mastHealthReduction = 20 -- 0-100.
}


-- Config for the repairing-part.
Config.Repairing = {
	dict = "mini@repair", anim = "fixing_a_ped",
	mastHealthAddition = 100, -- 0-100.
	payPerRepair = 250 -- How much money do a player recieve after a repair?
}


Config.PoliceAlert = false
function PoliceAlert(coords)
	-- Put your alert here if Config.PoliceAlert = true.
	-- Triggers on Hack.
end


function Minigame(label)
	-- Replace this with your own minigame.
	-- Make sure you have "return true" at the end on success, if success.

	if lib.progressBar({
		duration = 1000,
		label = label,
		canCancel = false,
	})
	then
		return true -- Tell the script that we succeeded.
	end
end


function Notify(msg, duration, alert)
	-- Replace this with your own notification.

	lib.notify({
		description = msg,
		type = alert,
		duration = duration,
		position = "bottom",
		showDuration = true
	})
end


-- How long should the mast recover after a hack or repair?
Config.RecoveryExpiration = 120 -- Seconds.


-- How much should a mast deteriorate if chance is not on its side?
Config.Deterioration = 10


-- How long do we track the player for? This is a default value.
Config.TrackingMaxTime = 30 -- Seconds.


-- How wide is the coverage/radius of a mast, depending on its health?
-- Add however many you'd like.
-- Maximum 100 health. Minimum 1 health.
-- Blip-color if Config.Blips is enabled. This changes color based on health.
Config.Coverage = {
	[1] = {radius = 1000.0, health = 100, blipColor = 18},
	[2] = {radius = 700.0, health = 60, blipColor = 17},
	[3] = {radius = 400.0, health = 30, blipColor = 6} -- The last one == cannot hack. Too broken.
}


-- How wide should the blip-radius be when tracking a player?
-- The smaller the radius, the more precise the location.
-- Add however many you'd like.
Config.Tracking = {
	[1] = 300.0, 	-- Within the radius of 1 mast.
	[2] = 150.0, 	-- Within the radius of 2 masts.
	[3] = 75.0		-- ...and so on.
}


-- Where would you like to put the masts?
-- Add however many you'd like.
-- Visualize your placements by setting "Config.Debug = true".
Config.Masts = {
	[1] = {coords = vec4(703.0571, -399.7086, 41.27916, 68.0)},					-- City
	[2] = {coords = vec4(-1353.207031, 118.531357, 56.238705, 4.825311)},		-- City
	[3] = {coords = vec4(-57.780033, 886.749695, 235.924744, 115.936539)},		-- City
	[4] = {coords = vec4(-525.328064, -642.370972, 33.233963, 179.757843)},		-- City
	[5] = {coords = vec4(-1181.742065, -1131.782715, 5.700800, 20.054012)},		-- City
	[6] = {coords = vec4(-828.494873, -2959.597412, 13.968473, 59.662022)},		-- City
	[7] = {coords = vec4(139.069016, -1495.356934, 29.141638, 320.796356)},		-- City
	[8] = {coords = vec4(997.148865, -2548.128418, 28.468321, 85.024879)},		-- City
	[9] = {coords = vec4(1302.620605, 1211.025757, 107.671844, 92.759148)}, 	-- Senora Road: That one Mafia house, idk
	[10] = {coords = vec4(1825.177002, 2525.044434, 45.672020, 90.690491)}, 	-- Sandy Shores: Prison
	[11] = {coords = vec4(1967.834961, 3778.687744, 32.178455, 120.638252)}, 	-- Sandy Shores: City
	[12] = {coords = vec4(630.589172, 2807.299316, 41.992287, 2.696568)}, 		-- Harmony
	[13] = {coords = vec4(1726.964233, 4775.266602, 41.913891, 268.277954)}, 	-- Grapeseed
	[14] = {coords = vec4(2799.417236, 1473.446167, 24.550653, 345.492889)}, 	-- Power Station
	[15] = {coords = vec4(-199.475586, 6241.725098, 31.495506, 313.457458)}, 	-- Paleto
	[16] = {coords = vec4(-2082.206299, 3213.139160, 32.810333, 240.722900)}, 	-- Zancudo
	[17] = {coords = vec4(-3193.533936, 1062.786255, 20.851561, 65.950165)}, 	-- Chumash
	[18] = {coords = vec4(3605.907715, 3657.691895, 42.606930, 80.137512)}, 	-- Humane Labs
	[19] = {coords = vec4(2437.787598, -355.506378, 93.090874, 231.850098)}, 	-- NOOSE
}