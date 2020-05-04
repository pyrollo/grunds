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
minetest.register_chatcommand("grow", {
	params = "<tree>",
	description = "Grow a giant tree at your position. Type /grow help to display available trees.",
	privs = { privs = server },
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		if not player then
			return false, "Player not found"
		end

		if param == "" then
			return false, "Missing <tree> parameter"
		end

		if param == "help" then
			local msg = "No available trees"
			if #grunds.trees then
				msg = "Available trees:"
				for name, _ in pairs(grunds.trees) do
					msg = msg .. "\n  " .. name
				end
			end
			return true, msg
		end

		if not grunds.trees[param] then
			return false, ("Unknown tree \"%s\". Type /grow help to display available trees."):format(param)
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

		minetest.chat_send_player(name, ("Growing a %s..."):format(param))

		if pos.y < mgutils.water_level then pos.y = mgutils.water_level end

		local tree = btlib.build_tree(pos, grunds.trees[param])
		local minp, maxp = btlib.get_minmaxp(tree)
		local manip = minetest.get_voxel_manip()
		manip:read_from_map(minp, maxp)
		btlib.render(tree.segments, tree.tufts, minp, maxp, manip)
		manip:write_to_map()

		return true, "Tree grown!"
	end
})
