-- Try to imitate mapgen_v7.cpp
-- Works well except for mountains
-- Could be improved to return level also underwater

local function rangelim(v, min, max)
	if v < min then return min end
	if v > max then return max end
	return v
end

local np_height_select   = minetest.get_mapgen_setting_noiseparams("mgv7_np_height_select")
local np_terrain_persist = minetest.get_mapgen_setting_noiseparams("mgv7_np_terrain_persist")
local np_terrain_base    = minetest.get_mapgen_setting_noiseparams("mgv7_np_terrain_base")
local np_terrain_alt     = minetest.get_mapgen_setting_noiseparams("mgv7_np_terrain_alt")
local np_mount_height    = minetest.get_mapgen_setting_noiseparams("mgv7_np_mount_height")
local np_mountain        = minetest.get_mapgen_setting_noiseparams("mgv7_np_mountain")
local np_ridge_uwater    = minetest.get_mapgen_setting_noiseparams("mgv7_np_ridge_uwater")
local mount_zero_level   = minetest.get_mapgen_setting("mgv7_mount_zero_level")
local spflags            = minetest.get_mapgen_setting("mgv7_spflags")
local water_level = 0

-- May have to set 0 during mapgen
local seed = minetest.get_mapgen_setting("seed")
np_height_select.seed   = np_height_select.seed + seed
np_terrain_persist.seed = np_terrain_persist.seed + seed
np_terrain_base.seed    = np_terrain_base.seed + seed
np_terrain_alt.seed     = np_terrain_alt.seed + seed
np_mount_height.seed    = np_mount_height.seed + seed
np_mountain.seed        = np_mountain.seed + seed
np_ridge_uwater.seed    = np_ridge_uwater.seed + seed

local function get3dNoise(params, pos3d)
	-- "The `z` component ... must be must be larger than 1 for 3D noise"
	local size3d = { x = 1, y = 1, z = 2 }
	return PerlinNoiseMap(params, size3d):get_3d_map_flat(pos3d)[1]
end

local function get2dNoise(params, pos2d)
	local size2d = { x = 1, y = 1 }
	return PerlinNoiseMap(params, size2d):get_2d_map_flat(pos2d)[1]
end

local function v7_baseTerrainLevelAtPoint(x, y)
	local pos2d = { x = x, y = y }

	local hselect = get2dNoise(np_height_select, pos2d)
	hselect = rangelim(hselect, 0, 1);

	local persist = get2dNoise(np_terrain_persist, pos2d)

	np_terrain_base.persist = persist;
	local height_base = get2dNoise(np_terrain_base, pos2d)

	np_terrain_alt.persist = persist;
	local height_alt = get2dNoise(np_terrain_alt, pos2d)

	if (height_alt > height_base) then
		return height_alt
	end

	return (height_base * hselect) + (height_alt * (1 - hselect));
end

local function v7_mountainTerrainAtPoint(x, y, z)
	local mnt_h_n = get2dNoise(np_mount_height, { x = x, y = z })
	if mnt_h_n > 1 then mnt_h_n = 1 end

	local density_gradient = - (y - mount_zero_level) / mnt_h_n
	local mnt_n = get3dNoise(np_mountain, { x = x, y = y, z = z })

	return mnt_n + density_gradient >= 0;
end

local function getLevelAtPoint(x, z)
	-- if (spflags & MGV7_RIDGES)
	local uwatern = get2dNoise(np_ridge_uwater, { x = x, y = z })
print(dump(np_ridge_uwater))
	if math.abs(uwatern) <= 0.2 then
		print("IN RIVER")
		return nil
	end
	-- end

	local y = v7_baseTerrainLevelAtPoint(x, z);

	--if (!(spflags & MGV7_MOUNTAINS)) {
	--[[
		if (y <= water_level)
			return nil

		return y + 2;
	]]
	-- end
	print("Base:", y)

	for i = 1, 256 do
		if not v7_mountainTerrainAtPoint(x, y + 1, z) then
			if (y <= water_level) then
				print("IN WATER")
				return nil
			else
				return y + 1
			end
		end
		y = y + 1
	end
	print("IN MOUNTAIN")

	return nil
end

minetest.register_chatcommand("b", {
	params = "x z",
	description = "Biome test",
	func = function(name, param)
		local x, z = string.match(param, "^([%d.-]+)[, ] *([%d.-]+)$")
		if x and z then
			x = tonumber(x)
			z = tonumber(z)
			local y = getLevelAtPoint(x, z)
			if y then
				minetest.chat_send_player(name, "Level: " .. y)
			else
				minetest.chat_send_player(name, "No level found")
				y = 0
			end
			local biome = minetest.get_biome_data({x = x, y = y, z = z})
			local bname = minetest.get_biome_name(biome.biome)
			minetest.chat_send_player(name, "Biome: " .. biome.biome.." - ".. bname)
		end
	end
})
