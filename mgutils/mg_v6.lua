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
-- Mapgen V6
--------------------------------------------------------------------------------

mgutils.has_biomes = false

-- Imitation of mapgen_v6.cpp
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
	mgv6_spflags           = "jungles, trees, biomeblend, mudflow",
	mgv6_np_terrain_base   = {offset=-4,   scale=20,  spread={x=250, y=250, z=250}, seed=82341, octaves=5, persist=0.6,  lacunarity=2 },
	mgv6_np_terrain_higher = {offset=20,   scale=16,  spread={x=500, y=500, z=500}, seed=85039, octaves=5, persist=0.6,  lacunarity=2 },
	mgv6_np_steepness      = {offset=0.85, scale=0.5, spread={x=125, y=125, z=125}, seed=-932,  octaves=5, persist=0.7,  lacunarity=2 },
	mgv6_np_height_select  = {offset=0,    scale=1,   spread={x=250, y=250, z=250}, seed=4213,  octaves=5, persist=0.69, lacunarity=2 },
}

-- Mapgen parameters
local flags            = mgutils.get_flags("mgv7_spflags")

-- Noises parameters
local np_terrain_base   = mgutils.get_noiseparams("mgv6_np_terrain_base")
local np_terrain_higher = mgutils.get_noiseparams("mgv6_np_terrain_higher")
local np_steepness      = mgutils.get_noiseparams("mgv6_np_steepness")
local np_height_select  = mgutils.get_noiseparams("mgv6_np_height_select")

-- Noises
local n_terrain_base
local n_terrain_higher
local n_steepness
local n_height_select

--local intialized = false

local function init_noises()
	init_noises = function() end -- Run only once
--	if intialized then return end
--	intialized = false

	n_terrain_base   = minetest.get_perlin(np_terrain_base)
	n_terrain_higher = minetest.get_perlin(np_terrain_higher)
	n_steepness      = minetest.get_perlin(np_steepness)
	n_height_select  = minetest.get_perlin(np_height_select)
end

local function baseTerrainLevel(terrain_base, terrain_higher,
	steepness, height_select)

	local base   = 1 + terrain_base
	local higher = 1 + terrain_higher

	-- Limit higher ground level to at least base
	if higher < base then
		higher = base
	end

	-- Steepness factor of cliffs
	local b = steepness
	b = rangelim(b, 0.0, 1000.0)
	b = 5 * b * b * b * b * b * b * b
	b = rangelim(b, 0.5, 1000.0)

	-- Values 1.5...100 give quite horrible looking slopes
	if b > 1.5 and b < 100.0 then
		if b < 10 then
			b = 1.5
		else
			b = 100
		end
	end

	local a_off = -0.20 -- Offset to more low
	local a = 0.5 + b * (a_off + height_select);
	a = rangelim(a, 0.0, 1.0) -- Limit

	return math.floor(base * (1.0 - a) + higher * a)
end

function mgutils.get_level_at_point(x, z)
	init_noises()

	if flags.flat then return mgutils.water_level end

	local terrain_base = n_terrain_base:get_2d({
			x = x + 0.5 * np_terrain_base.spread.x,
			y = z + 0.5 * np_terrain_base.spread.y})

	local terrain_higher = n_terrain_higher:get_2d({
			x = x + 0.5 * np_terrain_higher.spread.x,
			y = z + 0.5 * np_terrain_higher.spread.y})

	local steepness = n_steepness:get_2d({
			x = x + 0.5 * np_steepness.spread.x,
			y = z + 0.5 * np_steepness.spread.y})

	local height_select = n_height_select:get_2d({
			x = x + 0.5 * np_height_select.spread.x,
			y = z + 0.5 * np_height_select.spread.y})

	return baseTerrainLevel(terrain_base, terrain_higher, steepness,
			height_select) + 2 -- (Dust)
end
