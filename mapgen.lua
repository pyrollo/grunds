
c_mese = minetest.get_content_id("default:mese")
local mapdata = {}

minetest.register_on_generated(function (minp, maxp, blockseed)
	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	local data = vm:get_data()
	local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}

	-- Voxel manip indexes
	local vmix, vmiy, vmiz
	vmiz = area:index(minp.x, minp.y, minp.z)

	local n = 16
	local nx = math.ceil((maxp.x - minp.x)/16)
	local nz = math.ceil((maxp.z - minp.z)/16)

	for zz = 1, nz do
		for xx = 1, nx do
			local x = minp.x + xx*16
			local z = minp.z + zz*16
			local y = grunds.getLevelAtPoint(x, z)
			if y and y >= minp.y and y <= maxp.y then
				data[area:index(x, y, z)] = c_mese
			end
		end
	end

	vm:set_data(data)
	vm:set_lighting( {day=0, night=0})
	vm:calc_lighting()
	vm:write_to_map()
end)
