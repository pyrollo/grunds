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

minetest.register_chatcommand("find_biome", {
	params = "<name>",
	description = "Find biome area",
	privs = { privs = server },
	func = function(name, param)
		local function testbiome(id, x, y, z)
			local biome = minetest.get_biome_data({ x = x, y = y, z = z })
			if biome.biome == id then
				return ("Biome %s found at (%d, %d, %d)"):format(
					minetest.get_biome_name(id), x, y, z)
			end
		end

		local player = minetest.get_player_by_name(name)
		if not player then
			return false, "Player not found"
		end

		local bname = param
		local bid = minetest.get_biome_id(bname)

		if not bid then
			return false, ("Unknown biome \"%s\""):format(bname)
		end

		-- Random version
		for i = 1, 1000 do
			result = testbiome(bid,
				math.random(-20000, 20000),
				math.random(0, 50),
				math.random(-20000, 20000))
			if result then return true, result end
		end
		return false, "Not lucky"

--[[ Nearest version
		local pos = player:get_pos()
		local x = math.floor(pos.x)
		local z = math.floor(pos.z)

		local biome = minetest.get_biome_data(pos)
		if biome.biome == bid then
			return true, ("You are already in a \"%s\" biome."):format(bname)
		end
		minetest.chat_send_player(name, ("Biome %s id=%s"):format(bname, bid))

		local step = 32
		local maxradius = 200
		local y = 10
		local result
		for radius = 1, maxradius do
			for xx = -radius, radius do
				result = testbiome(bid, x + xx * step, y, z - radius * step)
				if result then return true, result end
				result = testbiome(bid, x + xx * step, y, z + radius * step)
				if result then return true, result end
			end
			for zz = -radius+1, radius-1 do
				result = testbiome(bid, x - radius * step, y, z + zz * step)
				if result then return true, result end
				result = testbiome(bid, x + radius * step, y, z + zz * step)
				if result then return true, result end
			end
		end
		return true, ("Biome %s not found in a %d x %d area."):format(
			bname, maxradius*step, maxradius*step)
 ]]
	end,
})
