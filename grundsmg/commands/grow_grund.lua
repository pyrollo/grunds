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
local max, random = math.max, math.random

-- Test function
minetest.register_chatcommand("grow_grund", {
	params = "",
	description = "Grow a giant grund at your position",
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		if not player then
			return false, "Player not found"
		end
		local pos = player:get_pos()
		local pos = {
			x = math.floor(pos.x),
			z = math.floor(pos.z),
		}

		pos.y = mgutils.get_level_at_point(pos.x, pos.z)

		if pos.y == nil then
			return false, "Not a suitable position for growing a tree"
		end

		if pos.y < mgutils.water_level then pos.y = mgutils.water_level end

		local tree = btlib.build_tree(pos, grunds.trees.grund)
		local minp, maxp = btlib.get_minmaxp(tree)
		local manip = minetest.get_voxel_manip()
		manip:read_from_map(minp, maxp)
		btlib.render(tree.segments, tree.tufts, minp, maxp, manip)
		manip:write_to_map()

		return true, "Tree grown!"
	end
})
