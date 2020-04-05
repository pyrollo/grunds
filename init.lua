--[[
	Grunds MG - Grunds Map Generator for Minetest
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

grunds = {}
grunds.name = minetest.get_current_modname()
grunds.path = minetest.get_modpath(minetest.get_current_modname())

local p = dofile(grunds.path .. "/profile.lua")
dofile(grunds.path .. "/nodes.lua")
dofile(grunds.path .. "/mapgen.lua")

local pi, cos, sin, sqrt = math.pi, math.cos, math.sin, math.sqrt
local abs, max, random = math.abs, math.max, math.random
local vsubtract = vector.subtract

c_air = minetest.get_content_id("air")
c_bark = minetest.get_content_id("grunds:bark")
c_wood_1 = minetest.get_content_id("grunds:tree_1")
c_wood_2 = minetest.get_content_id("grunds:tree_2")
c_leaves = minetest.get_content_id("grunds:leaves")

local tree = {
	-- Start pitch random. If 0, tree will start perfectly vertical
	start_pitch_rnd = pi/20,

	-- Start thickness of first (trunk) segment (value + random)
	start_thickness = 100,
	start_thickness_rnd = 20,

	rotate_each_node_by = pi/2,
	rotate_each_node_by_rnd = pi/10,
	branch_yaw_rnd = pi/10,

	branch_pitch = 5*pi/8, -- pi/2,
	branch_pitch_rnd = pi/10,

	branch_len_min = 5,
	branch_len_factor = 2,
	branch_len_factor_rnd = 1,
	branches = {
		{ thickness = 10, random = 2 },
		{ thickness = 10, random = 10},
--		{ thickness = 0, random = 1},
	},

	-- Radius of each tuft
	tuft_radius = 9,

	-- Density (0.0 = no leaves, 1.0 = all leaves)
	tuft_density = 0.1,
}


-- Add two random numbers, make it a bit gaussian
local function rnd()
	return random() + random() - 1
end

--[[
Geometric formulas
==================

-- LINES --

Spatial representation of a straight line [#1]:
{
	x = vx * t + px
	y = vy * t + py
	z = vz * t + pz
}

t is the "parameter". (x, y, z) is on line if a t exists.
(vx, vy, vz) is a vector along the line direction.
(px, py, pz) is one of the line point.

This gives coordinates of point from parameter.

-- SEGMENTS --

Our segments are quite simple if we take starting point as (px, py, pz) and
segment vector (from start to end) as (vx, vy, vz).

The segment is constitued of every point for t from 0.0 to 1.0.

-- NEAREST POINT --

To determine the parameter of nearest point of line to position (x0, y0, z0) is
given by :
	t = (vx, vy, vz) * ((x0, y0, z0) - (px, py, pz)) / len((vx, vy, vz))

	t = (vx * (x0 - px) + vy * (y0 - py) + vz * (z0 + pz)) / (vx² + vy² +vz²)

	Quotient is not depending on (x0, y0, z0) so it can be computed once
	when creating segment. Final formula is [#2] :

	t = (vx * (x0 - px) + vy * (y0 - py) + vz * (z0 + pz)) * k

	with k = 1 / (vx² + vy² +vz²)

-- THICKNESS --

Thickness is a simple linear variation from one end of the segment to the other.
Formula has this form [#3]:

	thickness = thickness1 * t + (thickness2 - thickness1)

Thickness is something like a surface. It is compared to square distances.

-- DISTANCE --

Distance between (x1, y1, z1) and (x2, y2, z2) is given by :
	d = squareroot( (x2-x1)² + (y2-y1)² + (z2-z1)² )

To avoid useless calculation, square distance is used as much as possible. For
example, comparing two distances is the same as comparing their squares.

]]

local function interCoord(objects, coord, value)
	local result = {}
	for i = 1, #objects do
		if objects[i].minp[coord] <= value and
				objects[i].maxp[coord] >= value then
			result[#result + 1] = objects[i]
		end
	end
	return result
end

local function intersects(b, minp, maxp)
	return
		b.minp.x <= maxp.x and b.maxp.x >= minp.y and
		b.minp.y <= maxp.y and b.maxp.y >= minp.y and
		b.minp.z <= maxp.z and b.maxp.z >= minp.z
end

-- Create a new tuft and pre-compute as much as possible
local function newTuft(center, radius)
	return {
		-- Bounding box
		minp = vector.subtract(center, radius),
		maxp = vector.add(center, radius),

		-- Center point
		p = center,

		-- Radius and square radius
		radius = radius,
		r2 = radius * radius,
	}
end

-- Create a new segment and pre-compute as much as possible
local function newSegment(p1, p2, th1, th2)
	if p1.x == p2.x and p1.y == p2.y and p1.z == p2.z then
		return nil -- Not a segment
	end
	local s = {
		-- Bounding box
		--minp = See below
		--maxp = See below

		-- Starting thickness and thickness increment
		th = th1,
		thinc = th2 - th1,

		-- Starting point
		p = table.copy(p1),
		-- Vector to ending point
		v = vector.subtract(p2, p1),
	}

	-- Square of the vector lenght
	s.d2 = s.v.x * s.v.x + s.v.y * s.v.y + s.v.z * s.v.z

	-- Its inverse (used in segmentNearestPoint)
	s.invd2 = 1 / s.d2

	-- Bounding box including thickness
	s.minp, s.maxp = vector.sort(p1, p2)
	local d = math.sqrt(math.max(th1, th2))
	s.minp = vector.add(s.minp, -d)
	s.maxp = vector.add(s.maxp, d)

	return s
end

-- Axis a vector with len 1 around which pos will be rotated by angle
local function rotate(axis, angle, vect)
	local c, s, c1 = cos(angle), sin(angle), 1 - cos(angle)
	local ax, ay, az = axis.x, axis.y, axis.z
	return {
		x =
			vect.x * (c1 * ax * ax + c) +
			vect.y * (c1 * ax * ay - s * az) +
			vect.z * (c1 * ax * az + s * ay),
		y =
			vect.x * (c1 * ay * ax + s * az) +
			vect.y * (c1 * ay * ay + c) +
			vect.z * (c1 * ay * az - s * ax),
		z =
			vect.x * (c1 * az * ax - s * ay) +
			vect.y * (c1 * az * ay + s * ax) +
			vect.z * (c1 * az * az + c),
	}
end

local function grund(center)

	-- TODO: use math.randomseed(pos)

	p.init()
	p.start('total')
	p.start('voxelmanip')
	local minp = { x = center.x - 80, y = center.y, z = center.z - 80 }
	local maxp = { x = center.x + 80, y = center.y + 160, z = center.z + 80 }
	local manip = minetest.get_voxel_manip()
	local e1, e2 = manip:read_from_map(minp, maxp)
	local area = VoxelArea:new{MinEdge=e1, MaxEdge=e2}
	local data = manip:get_data()
	p.stop('voxelmanip')

	p.start('segments')

	local segments = {}
	local tufts = {}

	-- TODO : add a counter limitation
	-- rotax and dir MUST be normalized
	local function grow(pos, rotax, dir, length, thickness)

		local sum = 0
		local branches = {}
		-- Choose divisions
		-- Randomize
		for _, branch in ipairs(tree.branches) do
			local thickness = branch.thickness +
				branch.random * rnd()
			if thickness > 0 then
				branches[#branches + 1] = thickness
				sum = sum + thickness
			end
		end

		-- Normalize
		for i = 1, #branches do
			branches[i] = branches[i] / sum
		end

		-- Rotate around branch axe
		local yaw = tree.rotate_each_node_by +
			rnd() * tree.rotate_each_node_by_rnd

		-- Make branches
		for _, part in ipairs(branches) do

			-- Next len and thickness
			local newthickness = part * thickness
			local newlength = math.log(newthickness + 1)
				* (tree.branch_len_factor  +
					rnd() * tree.branch_len_factor_rnd)
				+ tree.branch_len_min

			-- Put branches evenly around 360°
			yaw = yaw + 2 * pi / #branches +
					rnd() * tree.branch_yaw_rnd

			local pitch = (1 - part) * (1 - part)
					* (tree.branch_pitch +
					rnd() * tree.branch_pitch_rnd)

			local newrotax = rotate(dir, yaw, rotax)
			local newdir = rotate(newrotax, pitch, dir)

			local newpos = vector.add(pos,
					vector.multiply(newdir, newlength))

			segments[ #segments + 1 ] =
					newSegment(pos, newpos, thickness, newthickness)

			if newthickness < 0.5 or newlength < tree.branch_len_min then
				-- Branch ends
				tufts[ #tufts + 1 ] = newTuft(newpos, tree.tuft_radius)
			else
				-- Branch continues
				grow(newpos, newrotax, newdir, newlength, newthickness)
			end

		end
	end

	-- Start conditions
	-------------------

	-- Random yaw
	local rotax = rotate({ x = 0, y = 1, z = 0}, math.random() * pi * 2, { x = 0, y = 0, z = 1})

	-- Start with some pitch and given lenght
	local dir = rotate(rotax, tree.start_pitch_rnd * rnd(), { x = 0, y = 1, z = 0})

	-- Length and thickness
	local thickness = tree.start_thickness + tree.start_thickness_rnd * rnd()
	local length = math.log(thickness)
		* tree.branch_len_factor + tree.branch_len_min

	print("Start length:", length)
	print("Start thickness:", thickness)

	-- First (trunk) segment
	local pos = vector.add(center, vector.multiply(dir, length))
	segments[1] = newSegment(center, pos, thickness, thickness)

	grow(pos, rotax, dir, length, thickness)
	p.stop('segments')

	print("Segments", #segments)
	print("Tufts", #tufts)

	p.start('rendering')

	local tuft_density = tree.tuft_density
	local maxdiff, t, np, th, vx, vy, vz ,d, dif, s, vmi
	local sv, sp, svx, svy, svz, spx, spy, spz
	local segmentsz, segmentszy, tuftsz, tuftszy
	for z = minp.z, maxp.z do
		-- Limit to items which intesects z
		segmentsz = interCoord(segments, "z", z)
		tuftsz = interCoord(tufts, "z", z)

		for y = minp.y, maxp.y do
			-- Limit to items which intesects y
			segmentszy = interCoord(segmentsz, "y", y)
			tuftszy = interCoord(tuftsz, "y", y)
			vmi = area:index(minp.x, y, z)
			for x = minp.x, maxp.x do
				-- In this loop every thing has to be as optimized
				-- as possible. This uses less function calls and
				-- table lookups as possible.
				maxdiff = nil
				for index = 1, #segmentszy do
					s = segmentszy[index]
					if s.minp.x <= x and s.maxp.x >= x then
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
					if maxdiff < 1 then
						data[vmi] = c_bark
					else
						if (maxdiff % 2 > 1) then
							data[vmi] = c_wood_1
						else
							data[vmi] = c_wood_2
						end
					end
				else
					for _, t in ipairs(tuftszy) do
						if t.minp.x <= x and t.maxp.x >= x then
							-- Vector between tuft center and current pos
							vx = x - t.p.x
							vy = y - t.p.y
							vz = z - t.p.z

							-- Square length of this vector ([#4])
							d = vx*vx + vy*vy + vz*vz

							-- Now do the test
							if d < t.r2 then
								if random() < tuft_density then
									data[vmi] = c_leaves
								end
							end
						end
					end
				end

				vmi = vmi + 1
			end
		end
	end
	p.stop('rendering')
	p.start('voxelmanip')
	manip:set_data(data)
	manip:write_to_map()
	p.stop('voxelmanip')
	p.stop('total')
	p.show()
end

minetest.register_chatcommand("g", {
	params = "",
	description = "Grund !",
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		if not player then
			return false, "Player not found"
		end
		local pos = player:get_pos()
		local center = {
			x = math.floor(pos.x),
			y = 0,
			z = math.floor(pos.z),
		}

--		grund(center)
		grund(center)
	end
})
