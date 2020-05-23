--[[
	Mgutils - Some helper function related to core mapgens
	(c) Pierre-Yves Rollo

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU Lesser General Public License as published
	by the Free Software Foundation, either version 2.1 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <http://www.gnu.org/licenses/>.
--]]

--------------------------------------------------------------------------------
-- Mapgen V7
--------------------------------------------------------------------------------

mgutils.has_biomes = true

-- Imitation of mapgen_v7.cpp
-----------------------------

local function rangelim(v, min, max)
	if v < min then return min end
	if v > max then return max end
	return v
end

-- Hardcoded default values from mapgen_v7.cpp
-- These value are needed when minetest.get_mapgen_setting_noiseparams
-- returns nil (unfortunately happends when map_meta have not been saved yet)
mgutils.defaults = {
	mgv7_spflags            = "mountains, ridges, caverns",
	mgv7_mount_zero_level   = 0,
	mgv7_np_terrain_base    = {offset=4,    scale=70,  spread={x=600,  y=600,  z=600 }, seed=82341, octaves=5, persist=0.6,  lacunarity=2 },
	mgv7_np_terrain_alt     = {offset=4,    scale=25,  spread={x=600,  y=600,  z=600 }, seed=5934,  octaves=5, persist=0.6,  lacunarity=2 },
	mgv7_np_terrain_persist = {offset=0.6,  scale=0.1, spread={x=2000, y=2000, z=2000}, seed=539,   octaves=3, persist=0.6,  lacunarity=2 },
	mgv7_np_height_select   = {offset=-8,   scale=16,  spread={x=500,  y=500,  z=500 }, seed=4213,  octaves=6, persist=0.7,  lacunarity=2 },
	mgv7_np_mount_height    = {offset=256,  scale=112, spread={x=1000, y=1000, z=1000}, seed=72449, octaves=3, persist=0.6,  lacunarity=2 },
	mgv7_np_ridge_uwater    = {offset=0,    scale=1,   spread={x=1000, y=1000, z=1000}, seed=85039, octaves=5, persist=0.6,  lacunarity=2 },
	mgv7_np_mountain        = {offset=-0.6, scale=1,   spread={x=250,  y=350,  z=250 }, seed=5333,  octaves=5, persist=0.63, lacunarity=2 },
}

-- Mapgen parameters
local mount_zero_level = mgutils.get_setting("mgv7_mount_zero_level")
local water_level      = mgutils.get_setting("water_level")
local flags            = mgutils.get_flags("mgv7_spflags")

-- Noise params
local np_terrain_alt     = mgutils.get_noiseparams("mgv7_np_terrain_alt")
local np_terrain_base    = mgutils.get_noiseparams("mgv7_np_terrain_base")

-- Noises
local n_height_select
local n_terrain_persist
local n_mountain
local n_mount_height
local n_ridge_uwater

local intialized = false

local function init_noises()
	if intialized then return end
	intialized = true

	n_height_select   = mgutils.get_noise("mgv7_np_height_select")
	n_terrain_persist = mgutils.get_noise("mgv7_np_terrain_persist")
	n_mountain        = mgutils.get_noise("mgv7_np_mountain")
	n_mount_height    = mgutils.get_noise("mgv7_np_mount_height")
	n_ridge_uwater    = mgutils.get_noise("mgv7_np_ridge_uwater")
end

local function v7_baseTerrainLevelAtPoint(x, y)
	local pos2d = { x = x, y = y }
	local hselect = n_height_select:get_2d(pos2d)
	hselect = rangelim(hselect, 0, 1)
	local persist = n_terrain_persist:get_2d(pos2d)

	np_terrain_base.persistence = persist;
	local height_base = minetest.get_perlin(np_terrain_base):get_2d(pos2d)

	np_terrain_alt.persistence = persist;
	local height_alt = minetest.get_perlin(np_terrain_alt):get_2d(pos2d)

	if (height_alt > height_base) then
		return math.floor(height_alt)
	end

	return math.floor((height_base * hselect) +
			(height_alt * (1 - hselect)))
end

local function v7_mountainTerrainAtPoint(x, y, z)
	local mnt_h_n = n_mount_height:get2d({ x = x, y = z })
	if mnt_h_n < 1 then mnt_h_n = 1 end

	local density_gradient = - (y - mount_zero_level) / mnt_h_n
	local mnt_n = n_mountain:get3d({ x = x, y = y, z = z })

	return mnt_n + density_gradient >= 0;
end

function mgutils.get_level_at_point(x, z)
	init_noises()

	if flags.ridges then
		local uwatern = n_ridge_uwater:get2d({ x = x, y = z }) * 2
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
