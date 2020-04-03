--[[
	Crater MG - Crater Map Generator for Minetest
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

c_air    = minetest.get_content_id("air")
c_grass  = minetest.get_content_id("default:dirt_with_grass")
c_dirt   = minetest.get_content_id("default:dirt")

minetest.register_on_mapgen_init(function(mapgen_params)
		-- Note on map seed: Lua does not seem to be able to correctly handle 64
		-- bits integer so the 3 last digits are rounded. Same if we add small
		-- numbers to the 64bits key, rounded result will not include small
		-- number adition. So key is restricted to (inaccurate) 32 lower bits
		grunds.mapseed = mapgen_params.seed % (2^32)
	end
)

local mapdata = {}

-- Map generation
minetest.register_on_generated(function (minp, maxp, blockseed)
	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	vm:get_data(mapdata)
	local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}

	-- Voxel manip indexes
	local vmix, vmiy, vmiz
	vmiz = area:index(minp.x, minp.y, minp.z)

	-- Increments of voxel manip index
	local xinc = area:index(minp.x + 1, minp.y, minp.z) - vmiz
	local yinc = area:index(minp.x, minp.y + 1, minp.z) - vmiz
	local zinc = area:index(minp.x, minp.y, minp.z + 1) - vmiz

	for z = minp.z, maxp.z do
		vmix = vmiz
		for x = minp.x, maxp.x do
			vmiy = vmix
			for y = minp.y, maxp.y do
				if mapdata[vmiy] == c_air then
					if y == 0 then
						mapdata[vmiy] = c_grass
					end
					if y < 0 then
						mapdata[vmiy] = c_dirt
					end
				end
				vmiy = vmiy + yinc
			end
			vmix = vmix + xinc
		end -- Z loop
		vmiz = vmiz  + zinc
	end -- X loop

	vm:set_data(mapdata)
	vm:set_lighting( {day=0, night=0})
	vm:calc_lighting()
	vm:write_to_map()
end)
