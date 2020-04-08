
c_mese = minetest.get_content_id("default:mese")
local mapdata = {}

minetest.register_on_generated(function (minp, maxp, blockseed)
	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	local data = vm:get_data()
	local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}

	-- Voxel manip indexes
	local vmix, vmiy, vmiz
	points = grunds.distribute({x = minp.x, y = minp.z}, {x = maxp.x, y = maxp.z}, 100, 1, 20)

	for i = 1, #points do
		local p = points[i]
		local x, z = p.x, p.y
		local y = grunds.getLevelAtPoint(x, z)
		if y and y >= minp.y and y <= maxp.y and z >= minp.z
			and z <= maxp.z and x >= minp.x and x <= maxp.x then
			data[area:index(x, y, z)] = c_mese
		end
	end

	vm:set_data(data)
	vm:set_lighting( {day=0, night=0})
	vm:calc_lighting()
	vm:write_to_map()
end)
