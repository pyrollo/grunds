--[[
	Grunds - Giant trees biome for Minetest
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

-- =============================================================================
--
-- MAPGEN INTEGRATION
--
-- Creates a biome with one model of giant trees
--
-- =============================================================================

-- Big int numbers are truncated by Lua, so adding small int to them results in
-- the same number. Baseseed will be added with local seeds
grunds.baseseed = minetest.get_mapgen_setting("seed") % (2^32)

if mgutils.has_biomes then
	local soil_node = "default:dirt_with_grass"
	local res = minetest.register_biome({
		name = "grunds",
	--	node_top = "default:dirt_with_rainforest_litter",
		node_top = soil_node,
		depth_top = 1,
		node_filler = "default:dirt",
		depth_filler = 5,
		node_riverbed = "default:sand",
		depth_riverbed = 2,
		y_max = 50,
		y_min = 1,
		vertical_blend = 8,
		heat_point = 55,
		humidity_point = 70,
	})

	minetest.register_decoration({
		name = "grunds:apple_tree",
		deco_type = "schematic",
		place_on = {soil_node},
		sidelen = 16,
		noise_params = {
			offset = 0.026,
			scale = 0.015,
			spread = {x = 250, y = 250, z = 250},
			seed = 2,
			octaves = 3,
			persist = 0.66
		},
		biomes = {"grunds"},
		y_max = 31000,
		y_min = 1,
		schematic = minetest.get_modpath("default") .. "/schematics/apple_tree.mts",
		flags = "place_center_x, place_center_z",
		rotation = "random",
	})

	minetest.register_decoration({
		name = "grunds:apple_log",
		deco_type = "schematic",
		place_on = {soil_node},
		place_offset_y = 1,
		sidelen = 16,
		noise_params = {
			offset = 0.0012,
			scale = 0.0007,
			spread = {x = 250, y = 250, z = 250},
			seed = 2,
			octaves = 3,
			persist = 0.66
		},
		biomes = {"grunds"},
		y_max = 31000,
		y_min = 1,
		schematic = minetest.get_modpath("default") .. "/schematics/apple_log.mts",
		flags = "place_center_x",
		rotation = "random",
	})

	for i = 1,5 do
		minetest.register_decoration({
			name = "grunds:grass_"..i,
			biomes = {"grunds"},
			deco_type = "simple",
			place_on = {soil_node},
			fill_ratio = 0.2,
			decoration = "default:grass_"..i,
		})
	end
end

local treeradius = 150 -- Have to look around if any far tree has branches in this chunk
local treedistance = 80 -- Minimum tree distance
local treebuffer = grunds.new_buffer(50)

local biome_names = { "grunds" }
local biomes = {}
for _, name in pairs(biome_names) do
	local id = minetest.get_biome_id(name)
	if id then
		biomes[id] = name
	end
end

if mgutils.has_biomes then
	minetest.register_on_generated(function (minp, maxp, blockseed)
		local segments = {}
		local tufts = {}

		-- Choose random candidate positions evenly distributed for trees
		local points = grunds.distribute({x = minp.x - treeradius, y = minp.z - treeradius},
			{x = maxp.x + treeradius, y = maxp.z + treeradius}, treedistance, 1, 40)

		for i = 1, #points do
			local p = points[i]
			local x, z = p.x, p.y

			local tree = treebuffer[x.." "..z]

			-- Make tree if it is not already buffered
			if tree == nil then
				local seed = grunds.baseseed + x + z * 65498
				local y = mgutils.get_level_at_point(x, z)

				if y and y > mgutils.water_level then
					local biome = minetest.get_biome_data({x=x, y=y, z=z})
					if biomes[biome.biome] then
						tree = btlib.build_tree({x=x, y=y, z=z}, grunds.trees.grund, seed)
					end
				end

				-- Bufferize
				if tree then
					treebuffer[x.." "..z] = tree
				else
					treebuffer[x.." "..z] = false
				end
			end

			-- If tree, see what's to be rendered
			if tree then
				-- Add intersecting segments to those to be rendered
				for _, segment in ipairs(tree.segments) do
					if btlib.intersects(segment, minp, maxp) then
						segments[#segments + 1] = segment
					end
				end
				-- Add intersecting tufts to those to be rendered
				for _, tuft in ipairs(tree.tufts) do
					if btlib.intersects(tuft, minp, maxp) then
						tufts[#tufts + 1] = tuft
					end
				end
			end
		end

		-- Now rendering
		local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
		btlib.render(segments, tufts, minp, maxp, vm)
		vm:set_lighting( {day=0, night=0})
		vm:calc_lighting()
		vm:write_to_map()
	end)
end
