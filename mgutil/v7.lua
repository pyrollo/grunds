-- Imitation of mapgen_v7.cpp

local function rangelim(v, min, max)
	if v < min then return min end
	if v > max then return max end
	return v
end

local function int(x)
	return math.floor(x)
end

-- Hardcoded default values from mapgen_v7.cpp
-- These value are needed when minetest.get_mapgen_setting_noiseparams
-- returns nil (unfortunately happends when map_meta have not been saved yet)
local mg_defaults = {
	mgv7_spflags            = "mountains, ridges, caverns",
	mgv7_mount_zero_level   = 0,
	mgv7_np_terrain_base    = {offset=4,    scale=70,  spread={x=600,  y=600,  z=600 }, seed=82341, octaves=5, persist=0.6,  lacunarity=2.0},
	mgv7_np_terrain_alt     = {offset=4,    scale=25,  spread={x=600,  y=600,  z=600 }, seed=5934,  octaves=5, persist=0.6,  lacunarity=2.0},
	mgv7_np_terrain_persist = {offset=0.6,  scale=0.1, spread={x=2000, y=2000, z=2000}, seed=539,   octaves=3, persist=0.6,  lacunarity=2.0},
	mgv7_np_height_select   = {offset=-8,   scale=16,  spread={x=500,  y=500,  z=500 }, seed=4213,  octaves=6, persist=0.7,  lacunarity=2.0},
	mgv7_np_mount_height    = {offset=256,  scale=112, spread={x=1000, y=1000, z=1000}, seed=72449, octaves=3, persist=0.6,  lacunarity=2.0},
	mgv7_np_ridge_uwater    = {offset=0,    scale=1,   spread={x=1000, y=1000, z=1000}, seed=85039, octaves=5, persist=0.6,  lacunarity=2.0},
	mgv7_np_mountain        = {offset=-0.6, scale=1,   spread={x=250,  y=350,  z=250 }, seed=5333,  octaves=5, persist=0.63, lacunarity=2.0},
}

local seed = minetest.get_mapgen_setting("seed")

local function get_mg_setting(name)
	return minetest.get_mapgen_setting(""..name) or
		mg_defaults[name]
end

local function get_mg_noiseparams(name)
	local np = minetest.get_mapgen_setting_noiseparams(""..name) or
		mg_defaults[name]
	np.seed = np.seed + seed
	return np
end

local function get_mg_flags(name)
	local flags = {}
	for flag in string.gmatch(get_mg_setting(name), "[^ ,]+") do
		flags[flag] = true
	end
	return flags
end

-- Mapgen parameters
local mount_zero_level = get_mg_setting("mgv7_mount_zero_level")
local water_level      = get_mg_setting("water_level")
local flags            = get_mg_flags("mgv7_spflags")

-- Noises
local np_ridge_uwater    = get_mg_noiseparams("mgv7_np_ridge_uwater")
local np_height_select   = get_mg_noiseparams("mgv7_np_height_select")
local np_terrain_persist = get_mg_noiseparams("mgv7_np_terrain_persist")
local np_terrain_base    = get_mg_noiseparams("mgv7_np_terrain_base")
local np_terrain_alt     = get_mg_noiseparams("mgv7_np_terrain_alt")
local np_mount_height    = get_mg_noiseparams("mgv7_np_mount_height")
local np_mountain        = get_mg_noiseparams("mgv7_np_mountain")

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

	np_terrain_base.persistence = persist;
	local height_base = get2dNoise(np_terrain_base, pos2d)

	np_terrain_alt.persistence = persist;
	local height_alt = get2dNoise(np_terrain_alt, pos2d)

	if (height_alt > height_base) then
		return int(height_alt)
	end

	return int((height_base * hselect) +
			(height_alt * (1 - hselect)))
end

local function v7_mountainTerrainAtPoint(x, y, z)
	local mnt_h_n = get2dNoise(np_mount_height, { x = x, y = z })
	if mnt_h_n < 1 then mnt_h_n = 1 end

	local density_gradient = - (y - mount_zero_level) / mnt_h_n
	local mnt_n = get3dNoise(np_mountain, { x = x, y = y, z = z })

	return mnt_n + density_gradient >= 0;
end

-- getLevelAtPoint(x, z)
return function(x, z)
	if  flags.ridges then
		local uwatern = get2dNoise(np_ridge_uwater, { x = x, y = z }) * 2
		if math.abs(uwatern) <= 0.2 then
			-- To be accurate on ridges we'll have to manage them
			-- as mountains and get only the upper level.
			-- This involves do query another 3D noise.
			-- For now, keep it simple : no spawn in ridges
			return nil
		end
	end

	local y = v7_baseTerrainLevelAtPoint(x, z);

	if not flags.mountains then
		return y + 2;
	end

	for i = 1, 256 do
		if not v7_mountainTerrainAtPoint(x, y + 1, z) then
			return y + 1
		end
		y = y + 1
	end

	return nil
end
