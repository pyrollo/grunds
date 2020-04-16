--[[
	Mgutils - Some helper function related to core mapgens
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

local enable_test_mg = false -- Set to true only mgutils integration tests. NOT FOR PRODUCTION SERVERS

local mg = {
	name = minetest.get_mapgen_setting("mg_name"),
	defaults = {},
	water_level = tonumber(minetest.get_mapgen_setting("water_level")),

	-- getLevelAtPoint - Retrieves y level at x, z if possible or nil
	--                   Redefined in mapgen specific scripts
	get_level_at_point = function(x, z) return nil end,
}

function mg.get_setting(name)
	return minetest.get_mapgen_setting(""..name) or
		mg.defaults[name]
end

function mg.get_flags(name)
	local flags = {}
	for flag in string.gmatch(mg.get_setting(name), "[^ ,]+") do
		flags[flag] = true
	end
	return flags
end

function mg.get_noiseparams(name)
	return minetest.get_mapgen_setting_noiseparams(""..name) or
		mg.defaults[name]
end

function mg.get_noise(name)
	local n = minetest.get_perlin(mg.get_noiseparams(name))
	return n
end

-- Load mapgen specific functions and fails if not available
local modname = minetest.get_current_modname()
local mgscript = minetest.get_modpath(modname) .. "/mgutils/mg_" .. mg.name .. ".lua"

local mgcode, error = loadfile(mgscript)
if not mgcode then
	minetest.log("error", error)
	minetest.log("error", "Mod " .. modname .. " is not avialable on mapgen "..mg.name.." (mgutils wont work).")
	return
end

mgcode(mg)

if enable_test_mg then
	-- This will create a mese block each 16 nodes, at the altitude given by mgutil
	-- No block added if altitude not found.
	-- Mese blocks should be exactly on the top of the map generated terain

	local c_mese = minetest.get_content_id("default:mese")

	minetest.register_on_generated(function (minp, maxp, blockseed)
		-- Now rendering
		local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
		local data = vm:get_data()
		local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}

		for x = math.ceil(minp.x/16)*16, maxp.x, 16 do
			for z = math.ceil(minp.z/16)*16, maxp.z, 16 do
				local y = mg.get_level_at_point(x, z)
				if y then
					data[area:index(x, y, z)] = c_mese
				end
			end
		end
		vm:set_data(data)
		vm:write_to_map()
	end)
end

return mg
