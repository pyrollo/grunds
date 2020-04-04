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

local pi, cos, sin = math.pi, math.cos, math.sin
local abs, max, random = math.abs, math.max, math.random

c_air = minetest.get_content_id("air")
c_bark = minetest.get_content_id("grunds:bark")
c_wood = minetest.get_content_id("grunds:tree")
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

-- Check if a position is in a bounding box (works for segments and tufts)
local function inBox(b, p)
	return
		p.x > b.minp.x and p.x < b.maxp.x and
		p.y > b.minp.y and p.y < b.maxp.y and
		p.z > b.minp.z and p.z < b.maxp.z
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

local function segmentPoint(s, t)
	return {
		x = s.v.x * t + s.p.x,
		y = s.v.y * t + s.p.y,
		z = s.v.z * t + s.p.z
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

local function segmentNearestParam(s, p)
	-- Determine parameter t corresponding to nearest point
	local t = s.invd2 * (
			s.v.x * (p.x - s.p.x) +
			s.v.y * (p.y - s.p.y) +
			s.v.z * (p.z - s.p.z)
		)
	-- Limited to segment itself
	if t < 0 then t = 0 end
	if t > 1 then t = 1 end

	return t
end

local function segmentThickness(s, t)
	return s.th + s.thinc * t
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
	local function grow(pos, rotax, dir, oldthinkness, thickness)

		-- Add branch
		local newpos = vector.add(pos, dir)
		segments[#segments+1] = newSegment(pos, newpos, oldthinkness, thickness)

		-- Branch end
		if thickness < 0.5 then
			tufts[#tufts + 1] = newTuft(vector.add(pos, dir), 10)
			return
		end

		-- Choose divisions
		local shares = get_shares(thickness)

		-- Make branches
		local yaw = tree.rotate_each_node_by +
			rnd() * tree.rotate_each_node_by_rnd

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

			grow(newpos, newrotax, newdir, thickness, thickness * share)
		end
	end

	-- Start conditions

	-- Random orientation
	local rotax = rotate({ x = 0, y = 1, z = 0}, math.random() * pi * 2, { x = 0, y = 0, z = 1})


	-- Length and thickness
	local lenght = tree.start_length + tree.start_length_rnd * rnd()
	local thickness = lenght*(tree.start_thickness + tree.start_thickness_rnd * rnd())
	print("Start length:", lenght)
	print("Start thickness:", thickness)
	-- Start with some pitch and given lenght
	local dir = rotate(rotax, tree.start_pitch_rnd * rnd(), { x = 0, y = 1, z = 0})
	dir = vector.multiply(dir, tree.start_length + tree.start_length_rnd * rnd())

	grow(center, rotax, dir, thickness * 1.1, thickness)
	p.stop('segments')

	print("Segments", #segments)
	print("Tufts", #tufts)

	p.start('rendering')

	for z = minp.z, maxp.z do
		for y = minp.y, maxp.y do
			local i = area:index(minp.x, y, z)
			for x = minp.x, maxp.x do
				local p = {x=x, y=y, z=z}
				local diff
				for _, s in ipairs(segments) do
					if (inBox(s, p)) then
						local t = segmentNearestParam(s, p)
						local np = segmentPoint(s, t)
						local th = segmentThickness(s, t)
						local v = vector.subtract(p, np)
						local d = v.x*v.x + v.y*v.y + v.z*v.z
						if d < th then
							local dif = math.sqrt(th) - math.sqrt(d)
							if not diff or (dif > diff) then
								diff = dif
							end
						end
					end
				end
				if diff then
					if diff < 1 then
						data[i] = c_bark
					else
						data[i] = c_wood
					end
				else
					for _, t in ipairs(tufts) do
						if (inBox(t, p)) then
							local v = vector.subtract(p, t.p)
							local d = v.x*v.x + v.y*v.y + v.z*v.z
							if d < t.r2 and math.random() > 0.9 then
								data[i] = c_leaves
							end
						end
					end
				end

				i = i + 1
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




local function test(center)

	local minp = { x = center.x - 50, y = center.y, z = center.z - 50 }
	local maxp = { x = center.x + 50, y = center.y + 100, z = center.z + 50 }
	local manip = minetest.get_voxel_manip()
	local e1, e2 = manip:read_from_map(minp, maxp)
	local area = VoxelArea:new{MinEdge=e1, MaxEdge=e2}
	local data = manip:get_data()


	local segment = newSegment(
		{ x = center.x,  y = center.y + 10, z = center.z },
		{ x = center.x + 5,  y = center.y + 40, z = center.z +3 })

	for z = minp.z, maxp.z do
		for y = minp.y, maxp.y do
			local i = area:index(minp.x, y, z)
			for x = minp.x, maxp.x do
				local p = {x=x, y=y, z=z}
				local pp = segmentNearestPoint(segment, p)
				if vector.distance(p, pp) < 5 then
					data[i] = c_tree
				end
				i = i + 1
			end
		end
	end

	manip:set_data(data)
	manip:write_to_map(true)
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
