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

local pi, sqrt = math.pi, math.sqrt
local min, max, random, floor, abs = math.min, math.max, math.random, math.floor, math.abs

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

local treeradius = 150 -- Have to look around if any far tree has branches in this chunk
local treedistance = 80 -- Minimum tree distance

local treeparam = {

	trunk = {
		-- Trunk pitch random. If 0, trunk will start perfectly vertical
		pitch_rnd = pi/15,

		-- Trunk thickness (value + random) this will give thickness for
		-- branches and roots
		thickness = 120,
		thickness_rnd = 100,
		thickness_factor = 0.8, -- Factor between base and top thickness
		thickness_factor_rnd = 0.1,

		altitude = 10,
		altitude_rnd = 10,

		length_min = 5,
		length_factor = 4,
		length_factor_rnd = 1,
	},

	branches = {
		rotate_each_node_by = pi/2,
		rotate_each_node_by_rnd = pi/10,

		yaw_rnd = pi/10,

		pitch = pi,
		pitch_rnd = pi/10,

		lenght_min = 5,
		lenght_factor = 2,
		lenght_factor_rnd = 1,

		thinckess_min = 0.8,

		splits = {
			{ thickness = 10, random = 2 },
			{ thickness = 10, random = 10 },
	--		{ thickness = 0, random = 1},
		},

		gravity_effect = -0.2,
		tuft = {
			radius = 8,
			density = 0.05,
		}
	},

	roots = {
		rotate_each_node_by = pi/2,
		rotate_each_node_by_rnd = pi/10,

		yaw_rnd = pi/10,

		pitch = 3*pi/4,
		pitch_rnd = pi/10,

		lenght_min = 5,
		lenght_factor = 3,
		lenght_factor_rnd = 0.5,

		thinckess_min = 2,

		gravity_effect = 0.8,

		splits = {
			{ thickness = 10, random = 5 },
			{ thickness = 10, random = 5 },
			{ thickness = 10, random = 5 },
		},
	},

}

local np_decoration = {
	scale = 1,
	spread = {x = 16, y = 16, z = 16},
	seed = 57347,
	octaves = 2,
	persist = 0.5,
}

c_air = minetest.get_content_id("air")
c_bark = minetest.get_content_id("grunds:bark")
c_wood_1 = minetest.get_content_id("grunds:tree_1")
c_wood_2 = minetest.get_content_id("grunds:tree_2")
c_leaves = minetest.get_content_id("grunds:leaves")
c_twigs = minetest.get_content_id("grunds:twigs")
c_moisty = {
	minetest.get_content_id("grunds:bark_moisty_1"),
	minetest.get_content_id("grunds:bark_moisty_2"),
	minetest.get_content_id("grunds:bark_moisty_3"),
}

local treebuffer = {}
local treebuffersize = 50 -- Keep 50 trees in buffer, avoids many computations
-- TODO: Impement buffering emptying

local function inter_coord(objects, coord, value)
	local result = {}
	for i = 1, #objects do
		if objects[i].minp[coord] <= value and
				objects[i].maxp[coord] >= value then
			result[#result + 1] = objects[i]
		end
	end
	return result
end

local decorations = {
	[c_bark] = {
		{
			density = 0.3,
			noise_point = 1,
			noise_radius = 1,
--			length_noise_factor = 5,
			length_min = 2,
			length_random = 5,
			cid = minetest.get_content_id("grunds:vine_middle"),
			cid_end = minetest.get_content_id("grunds:vine_end"),
		}, {
			density = 0.2,
			noise_point = -1,
			noise_radius = 0.2,
			cid = minetest.get_content_id("grunds:red_fruit"),
		}, {
			density = 0.3,
			noise_point = -1,
			noise_radius = 0.2,
			cid = minetest.get_content_id("grunds:blue_fruit"),
		}
	}
}

function grunds.render(segments, tufts, minp, maxp, voxelmanip)
	local maxdiff, t, th, vx, vy, vz, d, dif, s, vmi
	local sv, sp, svx, svy, svz, spx, spy, spz
	local segmentsx, segmentsxz, tuftsx, tuftsxz
	local last_cid, cid, old_cid, ndef, branchok, dryrun
	local hanging_len = 0
	local hanging_cid, hanging_end_cid, decoration

	-- Preparation
	local node = voxelmanip:get_data()
	local emin, emax =voxelmanip:get_emerged_area()
	local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}

	local decoration_map = minetest.get_perlin_map(np_decoration, {
			x = maxp.x - minp.x + 1,
			y = maxp.y - minp.y + 1,
			z = maxp.z - minp.z + 1
		}):get_3d_map({x = minp.x, y = minp.y, z = minp.z})

	for i = 1, #segments do
		s = segments[i]
		s.root = s.type == "root" or s.type == "trunk"
	end

	-- Lets go now
	for x = minp.x, maxp.x do -- 80 times loop
		-- Limit to items which intesects z
		segmentsx = inter_coord(segments, "x", x)
		tuftsx = inter_coord(tufts, "x", x)

		for z = minp.z, maxp.z do -- 640 times loop
			-- Limit to items which intesects y
			segmentsxz = inter_coord(segmentsx, "z", z)
			tuftsxz = inter_coord(tuftsx, "z", z)
			vmi = area:index(x, maxp.y + 1, z)

			last_cid = node[vmi + area.ystride]
			hanging_len = 0
			dryrun = true

			for y = maxp.y + 1, minp.y, -1 do -- 5120 times loop
				maxdiff = nil
				cid = node[vmi]
				old_cid = cid
				ndef = minetest.registered_nodes[
					minetest.get_name_from_content_id(cid)]

				branchok =
					cid == c_air or not ndef or
					not ndef.is_ground_content

				for index = 1, #segmentsxz do -- 5120 * #segments times loop

					-- In this loop every thing has to be as optimized
					-- as possible. This uses less function calls and
					-- table lookups as possible.

					s = segmentsxz[index]

					if (branchok or s.root)
							and s.minp.x <= x
							and s.maxp.x >= x then
						sv, sp = s.v, s.p
						svx, svy, svz = sv.x, sv.y, sv.z
						spx, spy, spz = sp.x, sp.y, sp.z

						-- Get nearest segment param ([#2])
						t = s.invd2 * (
							svx * (x - spx) +
							svy * (y - spy) +
							svz * (z - spz))

						-- Limited to segment itself
						if t < 0 then t = 0 end
						if t > 1 then t = 1 end

						-- Vector between current pos
						-- and nearest segment point ([#1] + subtract)
						vx = x - svx * t - spx
						vy = y - svy * t - spy
						vz = z - svz * t - spz

						-- Square length of this vector ([#4])
						d = vx * vx + vy * vy + vz * vz

						-- Thickness for the given t ([#3])
						th = s.th + s.thinc * t

						-- Now do the test
						if d < th then
							-- Get more precise for inside trunc stuff
							dif = sqrt(th) - sqrt(d)
							if not maxdiff or (dif > maxdiff) then
								maxdiff = dif
							end
						end
					end
				end -- Segments loop

				-- Maxdiff is the maximum distance from outside
				if maxdiff then
					if maxdiff < 1.1 then
						cid = c_bark
					else
						if (maxdiff % 2 > 1) then
							cid = c_wood_1
						else
							cid = c_wood_2
						end
					end
				end

				-- Tufts
				if cid == c_air then
					for _, t in ipairs(tuftsxz) do -- 5120 * #segments times loop

						if t.minp.x <= x and t.maxp.x >= x then
							-- Vector between tuft center and current pos
							vx = x - t.center.x
							vy = y - t.center.y
							vz = z - t.center.z

							-- Square length of this vector ([#4])
							d = vx*vx + vy*vy + vz*vz

							-- Now do the test
							if d < t.radius2 and random() < t.density then
								dif = t.radius - sqrt(d)
								if random() * dif < 2 then
									cid = c_leaves
								else
									cid = c_twigs
								end
								break -- No need to check further
							end
						end
					end
				end

				-- Hanging decorations

				-- Terminate last vine if encounter a node
				if hanging_cid and last_cid == hanging_cid and cid ~= c_air then
					node[vmi + area.ystride] = hanging_end_cid
					hanging_len = 0
					hanging_cid = nil
				end

				-- Continue ongoing decoration
				if hanging_len > 0 and cid == c_air then
					hanging_len = hanging_len - 1
					if hanging_len == 0 then
						cid = hanging_end_cid
						hanging_cid = nil
					else
						cid = hanging_cid
					end
				end

				if not dryrun then

					-- Start new decoration
					if hanging_len == 0 and cid == c_air and decorations[last_cid] then
						for ix = 1, #decorations[last_cid] do
							decoration = decorations[last_cid][ix]

							noise_result = max(0, decoration.noise_radius -
								abs(decoration_map[z-minp.z+1][y-minp.y+1][x-minp.x+1] - decoration.noise_point))

							if noise_result > 0 and random() < decoration.density then

								hanging_len = decoration.length_min or 1

								if decoration.length_noise_factor then
									hanging_len = floor( decoration.length_noise_factor * noise_result)
								end

								if decoration.length_random then
									hanging_len = hanging_len + random(1, decoration.length_random)
								end

								if hanging_len >= (decoration.length_min or hanging_len) then
									hanging_cid = decoration.cid
									hanging_end_cid = decoration.cid_end or hanging_cid
									cid = decoration.cid_start or hanging_cid
									hanging_len = hanging_len - 1
									break
								else
									hanging_len = 0
								end
							end
						end
					end

					-- Top node change
					if cid == c_bark and
							(last_cid == c_air or last_cid == c_leaves)
					then
						local moisty = floor(decoration_map[z-minp.z+1][y-minp.y+1][x-minp.x+1]*3 + 1)
						if moisty > 0 then
							cid = c_moisty[min(moisty, 3)]
						end
					end

					if cid ~= old_cid and y <= maxp.y then
						node[vmi] = cid
					end
				end

				dryrun = false
				last_cid = cid
				vmi = vmi - area.ystride
			end

			-- Hanging decorations continuation
			if hanging_len > 0 then
				for _ = 1, hanging_len - 1 do
					if node[vmi] == c_air then
						node[vmi] = hanging_cid
					else
						break
					end
					vmi = vmi - area.ystride
				end
				if node[vmi] == c_air then
					node[vmi] = hanging_end_cid
				end
			end
		end
	end
	voxelmanip:set_data(node)
end

local biome_names = { "grunds" }
local biomes = {}
for _, name in pairs(biome_names) do
	local id = minetest.get_biome_id(name)
	if id then
		biomes[id] = name
	end
end

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
			local y = grunds.mg.get_level_at_point(x, z)

			if y and y > grunds.mg.water_level then
				local biome = minetest.get_biome_data({x=x, y=y, z=z})
				if biomes[biome.biome] then
					tree = grunds.make_tree({x=x, y=y, z=z}, treeparam, seed)
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
				if grunds.intersects(segment, minp, maxp) then
					segments[#segments + 1] = segment
				end
			end
			-- Add intersecting tufts to those to be rendered
			for _, tuft in ipairs(tree.tufts) do
				if grunds.intersects(tuft, minp, maxp) then
					tufts[#tufts + 1] = tuft
				end
			end
		end
	end

	-- Now rendering
	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	grunds.render(segments, tufts, minp, maxp, vm)
	vm:set_lighting( {day=0, night=0})
	vm:calc_lighting()
	vm:write_to_map()
end)
