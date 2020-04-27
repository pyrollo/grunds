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
-- Mapgen Valleys
--------------------------------------------------------------------------------

mgutils.has_biomes = true

-- Imitation of mapgen_valleys.cpp
----------------------------------

-- Hardcoded default values from mapgen_valleys.cpp
-- These value are needed when minetest.get_mapgen_setting_noiseparams
-- returns nil (unfortunately happends when map_meta have not been saved yet)
mgutils.defaults = {
	mgvalleys_river_size            = 5,
	mgvalleys_np_rivers             = { offset=0,   scale=1.2, spread={x=256,  y=256,  z=256 }, seed=1605,  octaves=3, persist=0.5, lacunarity=2 },
	mgvalleys_np_inter_valley_slope = { offset=0,   scale=1,   spread={x=256,  y=512,  z=256 }, seed=1993,  octaves=6, persist=0.8, lacunarity=2 },
	mgvalleys_np_terrain_height     = { offset=0.5, scale=0.5, spread={x=128,  y=128,  z=128 }, seed=746,   octaves=1, persist=1,   lacunarity=2 },
	mgvalleys_np_valley_depth       = { offset=0,   scale=1,   spread={x=256,  y=256,  z=256 }, seed=-6050, octaves=5, persist=0.6, lacunarity=2 },
	mgvalleys_np_valley_profile     = { offset=-10, scale=50,  spread={x=1024, y=1024, z=1024}, seed=5202,  octaves=6, persist=0.4, lacunarity=2 },
	mgvalleys_np_inter_valley_fill  = { offset=5,   scale=4,   spread={x=512,  y=512,  z=512 }, seed=-1914, octaves=1, persist=1,   lacunarity=2 },
}

-- Mapgen parameters
local river_size_factor = mgutils.get_setting("mgvalleys_river_size") / 100
local water_level       = mgutils.get_setting("water_level")

-- Noises
local n_rivers
local n_inter_valley_slope
local n_terrain_height
local n_valley_depth
local n_valley_profile
local n_inter_valley_fill

local intialized = false

local function init_noises()
	if intialized then return end
	intialized = false

	n_rivers             = mgutils.get_noise("mgvalleys_np_rivers")
	n_inter_valley_slope = mgutils.get_noise("mgvalleys_np_inter_valley_slope")
	n_terrain_height     = mgutils.get_noise("mgvalleys_np_terrain_height")
	n_valley_depth       = mgutils.get_noise("mgvalleys_np_valley_depth")
	n_valley_profile     = mgutils.get_noise("mgvalleys_np_valley_profile")
	n_inter_valley_fill  = mgutils.get_noise("mgvalleys_np_inter_valley_fill")
end

function mgutils.get_level_at_point(x, z)
	init_noises()

	-- Check if in a river channel
	local v_rivers = n_rivers:get2d({ x = x, y = z })
	if math.abs(v_rivers) <= river_size_factor then
		-- TODO: Add riverbed calculation
		return nil
	end

	local valley    = n_valley_depth:get2d({ x = x, y = z })
	local valley_d  = valley * valley
	local base      = valley_d + n_terrain_height:get2d({ x = x, y = z })
	local river     = math.abs(v_rivers) - river_size_factor
	local tv        = math.max(river / n_valley_profile:get2d({ x = x, y = z }), 0)
	local valley_h  = valley_d * (1 - math.exp(-tv * tv))
	local surface_y = base + valley_h
	local slope     = valley_h * n_inter_valley_slope:get2d({ x = x, y = z })

	-- TODO: Find proper limits for this check
	for y = 128, - 128, -1 do
		-- TODO: May be better if this 3D noise map is fetched for the hole Y column at once
		local surface_delta = y - surface_y;
		local density = slope * n_inter_valley_fill:get3d({x=x, y=y, z=z}) - surface_delta;

		if density > 0 then -- If solid
			return y + 1;
		end
	end
	return nil;
end
