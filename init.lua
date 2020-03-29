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

local pi, cos, sin = math.pi, math.cos, math.sin
local abs, max, random = math.abs, math.max, math.random

local pi2 = pi / 2

grunds.name = minetest.get_current_modname()
grunds.path = minetest.get_modpath(minetest.get_current_modname())

dofile(grunds.path..'/mapgen.lua')

c_tree = minetest.get_content_id("default:tree")
c_leaves = minetest.get_content_id("default:leaves")

-- Axis a vector with len 1 around which pos will be rotated by angle
local function rotate(axis, angle, origin, pos)
	local c, s, c1 = cos(angle), sin(angle), 1 - cos(angle)
	local ax, ay, az = axis.x, axis.y, axis.z
	local px, py, pz = pos.x - origin.x, pos.y - origin.y, pos.z - origin.z
	return {
		x =
			px * (c1 * ax * ax + c) +
			py * (c1 * ax * ay - s * az) +
			pz * (c1 * ax * az + s * ay) +
			origin.x,
		y =
			px * (c1 * ay * ax + s * az) +
			py * (c1 * ay * ay + c) +
			pz * (c1 * ay * az - s * ax) +
			origin.y,
		z =
			px * (c1 * az * ax - s * ay) +
			py * (c1 * az * ay + s * ax) +
			pz * (c1 * az * az + c) +
			origin.z,
	}
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

	local o0 = { x = 0, y = 0, z = 0 }

	local function grow(pos, rotax, dir)
		local dir1 = vector.normalize(dir)

		n = 1
		while (n < 5 and random() > 0.3) do
			n = n + 1
		end

		local yaw = 2 * pi * random()

		for i = 1, n do
			yaw = yaw + 2 * pi / n + (random() - 0.5) * 0.1
 			local pitch = (n - 1) * pi / 8 + (random() - 0.5) * 0.03
			local len = 0.6 + (random() - 0.5) * 0.1

			local newrotax = rotate(dir1, yaw, o0, rotax)
			local newdir = vector.multiply(
				rotate(newrotax, pitch, o0, dir), len)
			local newpos = vector.add(pos, newdir)
			line (pos, newpos)
			if vector.length(newdir) > 5 then
				grow(newpos, newrotax, newdir)
			end
		end
	end

	grow(center, { x = 0, y = 0, z = 1}, { x = 0, y = 30, z = 0})

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
