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

	-- Start length (value + random) Lenght of the first segment
	start_length = 20,
	start_length_rnd = 5,

	-- Start thickness factor (value + random)
	start_thickness = 2, -- 1 = same as lenght
	start_thickness_rnd = 0.5,

	rotate_each_node_by = pi/2,
	rotate_each_node_by_rnd = pi/10,
	branch_yaw_rnd = pi/10,
	branch_pitch_rnd = pi/10,
	branch_len_rnd = 0.1,
	shares = {
		[1] = { 1, 1 },
		[100] = {1, 1 },
	}, -- TODO : Adapt to starting thickness (could be 0 to 1)
	shares_rnd = 0.2, -- TODO : Should have same effect whatever share numbers
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

local function newTuft(p, r)
	return {
		p = p,
		radius = r,
		r2 = r * r,
		minp = vector.subtract(p, r),
		maxp = vector.add(p, r),
	}
end

local function newSegment(p1, p2, th1, th2)
	if p1.x == p2.x and p1.y == p2.y and p1.z == p2.z then
		return nil
	end
	local s = {
		th = th1,
		thinc = th2 - th1,
		p = table.copy(p1),
		v = vector.subtract(p2, p1),
	}

	-- Square of the vector lenght
	s.d2 = s.v.x * s.v.x + s.v.y * s.v.y + s.v.z * s.v.z
	-- inverse (used in segmentNearestPoint)
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

local function get_shares(thickness)
	local sh1, t1, sh2, t2
	for t, sh in pairs(tree.shares) do
		if t < thickness and (t1 == nil or t1 < t) then
			t1 = t
			sh1 = sh
		end
		if t > thickness and (t2 == nil or t2 > t) then
			t2 = t
			sh2 = sh
		end
	end

	local sh = {}
	local factor
	if not t1 then
		factor = 1
	end
	if not t2 then
		factor = 0
	end
	if t1 and t2 then
		factor = (thickness - t1)/(t2 - t1)
	end

	local num = sh1 and #sh1 or 0
	if sh2 and #sh2 > num then num = #sh2 end
	local sum = 0

	for i = 1, num do
		local n1 = sh1 and sh1[i] or 0
		local n2 = sh2 and sh2[i] or 0
		local s = n1 + (n2 - n1) * factor + tree.shares_rnd * rnd()
		if s > 0 then
			sh[#sh + 1] = s
			sum = sum + s
		end
	end

	-- Normalize
	for i = 1, #sh do
		sh[i] = sh[i] / sum
	end

	return sh
end

local function grund(center)

	p.init()
	p.start('total')
	p.start('voxelmanip')
	local minp = { x = center.x - 50, y = center.y, z = center.z - 50 }
	local maxp = { x = center.x + 50, y = center.y + 100, z = center.z + 50 }
	local manip = minetest.get_voxel_manip()
	local e1, e2 = manip:read_from_map(minp, maxp)
	local area = VoxelArea:new{MinEdge=e1, MaxEdge=e2}
	local data = manip:get_data()
	p.stop('voxelmanip')

	p.start('segments')

	local segments = {}
	local tufts = {}

	-- TODO : add a counter limitation
	local function grow(pos, rotax, dir, thickness)

		-- Branch end
		if thickness < 0.5 then
			tufts[#tufts + 1] = newTuft(vector.add(pos, dir), 8)
			return
		end

		-- Choose divisions
		local shares = get_shares(thickness)

		-- Rotate around branch axe
		local yaw = tree.rotate_each_node_by +
			rnd() * tree.rotate_each_node_by_rnd

		-- Make branches
		local dir1 = vector.normalize(dir)

		for _, share in ipairs(shares) do

			yaw = yaw + 2 * pi / #shares +
				rnd() * tree.branch_yaw_rnd
			local pitch = (1 - share)*(1 - share) * pi * 0.5 +
				rnd() * tree.branch_pitch_rnd
--			local len = (share + 1) * 0.5 +
--				rnd() * tree.branch_len_rnd
			local len = 0.8 + rnd() * tree.branch_len_rnd + 0.1 / thickness

			local newrotax = rotate(dir1, yaw, rotax)
			local newdir = vector.multiply(
				rotate(newrotax, pitch, dir), len)

			local newpos = vector.add(pos, dir)
			local newthickness = thickness * share
			segments[#segments+1] = newSegment(pos, newpos, thickness, newthickness)

			grow(newpos, newrotax, newdir, newthickness)
		end
	end

	-- Start conditions
	-------------------

	-- Random yaw
	local rotax = rotate({ x = 0, y = 1, z = 0}, math.random() * pi * 2, { x = 0, y = 0, z = 1})

	-- Length and thickness
	local lenght = tree.start_length + tree.start_length_rnd * rnd()
	local thickness = lenght*(tree.start_thickness + tree.start_thickness_rnd * rnd())
	print("Start length:", lenght)
	print("Start thickness:", thickness)

	-- Start with some pitch and given lenght
	local dir = rotate(rotax, tree.start_pitch_rnd * rnd(), { x = 0, y = 1, z = 0})
	dir = vector.multiply(dir, tree.start_length + tree.start_length_rnd * rnd())

	-- First (trunk) segment
	local pos = vector.add(center, dir)
	segments[#segments+1] = newSegment(center, pos, thickness * 1.1, thickness)

	grow(pos, rotax, dir, thickness)
	p.stop('segments')

	print("Segments", #segments)
	print("Tufts", #tufts)

	p.start('rendering')

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
								if random() > 0.9 then
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
