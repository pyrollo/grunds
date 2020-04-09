local pi, sqrt = math.pi, math.sqrt
local max, random = math.max, math.random

local res = minetest.register_biome({
	name = "grunds",
	node_top = "default:dirt_with_rainforest_litter",
	depth_top = 1,
	node_filler = "default:dirt",
	depth_filler = 5,
	node_riverbed = "default:sand",
	depth_riverbed = 2,
	node_dungeon = "default:desert_stone_block",
	node_dungeon_alt = "default:desert_stone_brick",
	node_dungeon_stair = "stairs:stair_desert_stone_block",
	y_max = 31000,
	y_min = 1,
	heat_point = 55,
	humidity_point = 70,
})

minetest.register_decoration({
	name = "grunds:papyrus2",
	biomes = {"grunds"},
	deco_type = "simple",
	place_on = {"default:dirt_with_rainforest_litter"},
	height_max = 6,
	fill_ratio = 0.5,
	decoration = "default:papyrus",
	height_max = 4,
})

local treeradius = 150 -- Have to look around if any far tree has branches in this chunk

local treeparam = {

	trunk = {
		-- Trunk pitch random. If 0, trunk will start perfectly vertical
		pitch_rnd = pi/15,

		-- Trunk thickness (value + random) this will give thickness for
		-- branches and roots
		thickness = 150,
		thickness_rnd = 40,
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
			radius = 9,
			density = 0.1,
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

		gravity_effect = 0.6,

		splits = {
			{ thickness = 10, random = 5 },
			{ thickness = 10, random = 5 },
			{ thickness = 10, random = 5 },
		},
	},

}

c_air = minetest.get_content_id("air")
c_bark = minetest.get_content_id("grunds:bark")
c_wood_1 = minetest.get_content_id("grunds:tree_1")
c_wood_2 = minetest.get_content_id("grunds:tree_2")
c_leaves = minetest.get_content_id("grunds:leaves")

local water_level = tonumber(minetest.get_mapgen_setting("water_level"))

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

function grunds.render(segments, tufts, minp, maxp, data, area)
	local maxdiff, t, th, vx, vy, vz, d, dif, s, vmi
	local sv, sp, svx, svy, svz, spx, spy, spz
	local segmentsz, segmentszy, tuftsz, tuftszy

	for i = 1, #segments do
		s = segments[i]
		s.root = s.type == "root" or s.type == "trunk"
	end

	for z = minp.z, maxp.z do -- 80 times loop
		-- Limit to items which intesects z
		segmentsz = inter_coord(segments, "z", z)
		tuftsz = inter_coord(tufts, "z", z)

		for y = minp.y, maxp.y do -- 640 times loop
			-- Limit to items which intesects y
			segmentszy = inter_coord(segmentsz, "y", y)
			tuftszy = inter_coord(tuftsz, "y", y)
			vmi = area:index(minp.x, y, z)

			for x = minp.x, maxp.x do -- 5120 times loop

				maxdiff = nil

				local cid = data[vmi]
				local def = minetest.registered_nodes[
					minetest.get_name_from_content_id(cid)]

				local branchok =
					cid == c_air or not def or
					not def.is_ground_content

				for index = 1, #segmentszy do -- 5120 * #segments times loop

					-- In this loop every thing has to be as optimized
					-- as possible. This uses less function calls and
					-- table lookups as possible.

					s = segmentszy[index]

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
				end

				-- Maxdiff is the maximum distance from outside
				if maxdiff then
					if maxdiff < 1.1 then
						data[vmi] = c_bark
					else
						if (maxdiff % 2 > 1) then
							data[vmi] = c_wood_1
						else
							data[vmi] = c_wood_2
						end
					end
				else
					-- Place leaves only in air
					if data[vmi] == c_air then
						for _, t in ipairs(tuftszy) do
							if t.minp.x <= x and t.maxp.x >= x then
								-- Vector between tuft center and current pos
								vx = x - t.center.x
								vy = y - t.center.y
								vz = z - t.center.z

								-- Square length of this vector ([#4])
								d = vx*vx + vy*vy + vz*vz

								-- Now do the test
								if d < t.radius2 then
									if random() < t.density then
										data[vmi] = c_leaves
										break
									end
								end
							end
						end
					end
				end

				vmi = vmi + 1
			end
		end
	end
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
		{x = maxp.x + treeradius, y = maxp.z + treeradius}, 100, 1, 20)

	for i = 1, #points do
		local p = points[i]
		local x, z = p.x, p.y

		local tree = treebuffer[x.." "..z]

		-- Make tree if it is not already buffered
		if tree == nil then
			local seed = grunds.baseseed + x + z * 65498
			local y = grunds.getLevelAtPoint(x, z)

			if y and y > water_level then
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
	local data = vm:get_data()
	local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}
	grunds.render(segments, tufts, minp, maxp, data, area)
	vm:set_data(data)
	vm:set_lighting( {day=0, night=0})
	vm:calc_lighting()
	vm:write_to_map()
end)
