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

grunds = {}
grunds.name = minetest.get_current_modname()
grunds.path = minetest.get_modpath(minetest.get_current_modname())

function file_exists(path)
	local f=io.open(path,"r")
	if f~=nil then
		io.close(f)
		return true
	else
		return false
	end
end

-- Load mapgen specific functions and fails if not available
local mg_name = minetest.get_mapgen_setting("mg_name")
do
	mgutil = grunds.path .. "/mgutil/" .. mg_name .. ".lua"
	if not file_exists(mgutil) then
		minetest.log("error", "Mod " .. grunds.name .. " is not avialable on mapgen "..mg_name..".")
		return
	end
	grunds.getLevelAtPoint = dofile(mgutil)
end

-- Big int numbers are truncated by Lua, so adding small int to them results in
-- the same number. Baseseed will be added with local seeds
grunds.baseseed = minetest.get_mapgen_setting("seed") % (2^32)

local p = dofile(grunds.path .. "/profile.lua")
dofile(grunds.path .. "/nodes.lua")
dofile(grunds.path .. "/distribute.lua")
dofile(grunds.path .. "/tree.lua")
dofile(grunds.path .. "/biome.lua")
dofile(grunds.path .. "/mapgen.lua")

local pi, sqrt = math.pi, math.sqrt
local max, random = math.max, math.random

c_air = minetest.get_content_id("air")
c_bark = minetest.get_content_id("grunds:bark")
c_wood_1 = minetest.get_content_id("grunds:tree_1")
c_wood_2 = minetest.get_content_id("grunds:tree_2")
c_leaves = minetest.get_content_id("grunds:leaves")

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


local water_level = tonumber(minetest.get_mapgen_setting("water_level"))

-- Test function
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
			z = math.floor(pos.z),
		}

		center.y = grunds.getLevelAtPoint(center.x, center.z)

		if center.y == nil then
			return false, "Not a suitable position for growing a tree"
		end
		if center.y < water_level then center.y = water_level end

		p.init()
		p.start('total')
		p.start('voxelmanip')
		local minp = { x = center.x - 80, y = center.y - 20, z = center.z - 80 }
		local maxp = { x = center.x + 80, y = center.y + 160, z = center.z + 80 }
		local manip = minetest.get_voxel_manip()
		p.stop('voxelmanip')

		p.start('maketree')
	--	center.y = 50
		local tree = grunds.make_tree(center, treeparam)
		p.stop('maketree')

		local segments = tree.segments
		local tufts = tree.tufts

		print("Segments", #segments)
		print("Tufts", #tufts)

		p.start('rendering')
		grunds.render(segments, tufts, minp, maxp, manip)
		p.stop('rendering')
		p.start('voxelmanip')
		manip:write_to_map()
		p.stop('voxelmanip')
		p.stop('total')
		p.show()

		return true, "Tree grown!"
	end
})
