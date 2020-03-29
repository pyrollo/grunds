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

local pi, cos, sin = math.pi, math.cos, math.sin
local abs, max, random = math.abs, math.max, math.random

dofile(grunds.path..'/mapgen.lua')

c_tree = minetest.get_content_id("default:tree")
c_leaves = minetest.get_content_id("default:leaves")


-- Add two random numbers, make it a bit gaussian
local function rnd()
	return random() + random() - 1
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

local tree = {
	rotate_each_node_by = pi/2,
	rotate_each_node_by_rnd = pi/10,
	branch_yaw_rnd = pi/10,
	branch_pitch_rnd = pi/10,
	branch_len_rnd = 0.1,
	shares = {
		[1] = { 1, 1, 1, 1, 1 },
		[6] = { 5, 5, 1 },
		[8] = { 2, 7, 1 },
		[10] = { 1 },
	},
	shares_rnd = 2,
}

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

	local minp = { x = center.x - 50, y = center.y, z = center.z - 50 }
	local maxp = { x = center.x + 50, y = center.y + 100, z = center.z + 50 }
	local manip = minetest.get_voxel_manip()
	local e1, e2 = manip:read_from_map(minp, maxp)
	local area = VoxelArea:new{MinEdge=e1, MaxEdge=e2}
	local data = manip:get_data()

	local function plot(p, cid)
		local i = area:indexp({
			x = math.floor(p.x + 0.5),
			y = math.floor(p.y + 0.5),
			z = math.floor(p.z + 0.5),
		})
		if area:containsi(i) then
			data[i] = cid
		end
	end

	local function line(p1, p2)
		local p = table.copy(p1)
		local v = vector.subtract(p2, p1)
		local f = math.ceil(math.max(math.abs(v.x), math.abs(v.y), math.abs(v.z)))
		v = vector.divide(v, f)
		for _ = 1,f do
			plot(p, c_tree)
			p = vector.add(p, v)
		end
		plot(p1, c_leaves)
		plot(p2, c_leaves)
	end

	local function grow(pos, rotax, dir, length, thickness)
		length = length + vector.length(dir)

		-- Draw branch
		local newpos = vector.add(pos, dir)
		line (pos, newpos)

		-- Branch end
		if thickness < 1 then
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
			local len = (share + 1) * 0.5 +
				rnd() * tree.branch_len_rnd

			local newrotax = rotate(dir1, yaw, rotax)
			local newdir = vector.multiply(
				rotate(newrotax, pitch, dir), len)

			grow(newpos, newrotax, newdir, length, thickness * share)
		end
	end

	grow(center, { x = 0, y = 0, z = 1}, { x = 0, y = 20, z = 0}, 0, 10)

	manip:set_data(data)
	manip:write_to_map()
end

minetest.register_chatcommand("g", {
	params = "",
	description = "Grund !",
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		if not player then
			return false, "Player not found"
		end
		local center = player:get_pos()
		center.y = 0
		grund(center)
	end
})
