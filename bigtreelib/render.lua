--[[
	Big tree lib - Giant trees library for Minetest
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

-- =============================================================================
--
-- VOXEL RENDERING
--
-- =============================================================================

local min, max, random, floor, abs = math.min, math.max, math.random, math.floor
local sqrt, abs = math.sqrt, math.abs

-->> TODO: All this should be managed by registration
local np_decoration = {
	scale = 1,
	spread = {x = 16, y = 16, z = 16},
	seed = 57347,
	octaves = 2,
	persist = 0.5,
}
--<< END TODO:

local c_air = minetest.get_content_id("air")

local decorations = btlib.registered_decorations

local function inter_coord(objects, coord, value)
	local result = {}
	for i = 1, #objects do
		if objects[i].minp[coord] <= value and
				objects[i].maxp[coord] >= value then
			result[#result + 1] = objects[i]
		end
	end
	return result
end

-- Renders segments and tufts from trees between minp and maxp, in voxelmanip
-- Can be used with mapgen and standard voxel manips.
function btlib.render(segments, tufts, minp, maxp, voxelmanip)
	local segment, maxdiff, t, th, vx, vy, vz, d, dif, s, vmi
	local sv, sp, svx, svy, svz, spx, spy, spz
	local segmentsx, segmentsxz, tuftsx, tuftsxz
	local last_cid, cid, old_cid, ndef, branchok, dryrun
	local hanging_len = 0
	local hanging_cid, hanging_end_cid, decoration

	-- Preparation
	local node = voxelmanip:get_data()
	local emin, emax = voxelmanip:get_emerged_area()
	local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}

	local decoration_map = minetest.get_perlin_map(np_decoration, {
			x = maxp.x - minp.x + 1,
			y = maxp.y - minp.y + 1,
			z = maxp.z - minp.z + 1
		}):get_3d_map({x = minp.x, y = minp.y, z = minp.z})

	for i = 1, #segments do
		s = segments[i]
		s.root = s.type == "root" or s.type == "trunk"
	end

	-- Lets go now
	for x = minp.x, maxp.x do -- 80 times loop
		-- Limit to items which intesects z
		segmentsx = inter_coord(segments, "x", x)
		tuftsx = inter_coord(tufts, "x", x)

		for z = minp.z, maxp.z do -- 640 times loop
			-- Limit to items which intesects y
			segmentsxz = inter_coord(segmentsx, "z", z)
			tuftsxz = inter_coord(tuftsx, "z", z)
			vmi = area:index(x, maxp.y + 1, z)

			last_cid = node[vmi + area.ystride]
			hanging_len = 0
			dryrun = true

			for y = maxp.y + 1, minp.y, -1 do -- 5120 times loop
				maxdiff = nil
				cid = node[vmi]
				old_cid = cid
				ndef = minetest.registered_nodes[
					minetest.get_name_from_content_id(cid)]

				branchok =
					cid == c_air or not ndef or
					not ndef.is_ground_content

				for index = 1, #segmentsxz do -- 5120 * #segments times loop

					-- In this loop every thing has to be as optimized
					-- as possible. This uses less function calls and
					-- table lookups as possible.

					s = segmentsxz[index]

					if (branchok or s.root)
							and s.minp.x <= x
							and s.maxp.x >= x then
						sv, sp = s.v, s.p
						svx, svy, svz = sv.x, sv.y, sv.z
						spx, spy, spz = sp.x, sp.y, sp.z

						-- Get nearest segment param ([#2])
						t = s.invd2 * (
							svx * (x - spx) +
							svy * (y - spy) +
							svz * (z - spz))

						-- Limited to segment itself
						if t < 0 then t = 0 end
						if t > 1 then t = 1 end

						-- Vector between current pos
						-- and nearest segment point ([#1] + subtract)
						vx = x - svx * t - spx
						vy = y - svy * t - spy
						vz = z - svz * t - spz

						-- Square length of this vector ([#4])
						d = vx * vx + vy * vy + vz * vz

						-- Thickness for the given t ([#3])
						th = s.th + s.thinc * t

						-- Now do the test
						if d < th then
							-- Get more precise for inside trunc stuff
							dif = sqrt(th) - sqrt(d)
							if not maxdiff or (dif > maxdiff) then
								segment = s
								maxdiff = dif
							end
						end
					end
				end -- Segments loop

				-- Maxdiff is the maximum distance from outside
				if maxdiff then
					if maxdiff < 1.1 then
						cid = segment.cid_bark
					else
						if (maxdiff % 2 > 1) then
							cid = segment.cid_wood_1
						else
							cid = segment.cid_wood_2
						end
					end
				end

				-- Tufts
				if cid == c_air then
					for _, t in ipairs(tuftsxz) do -- 5120 * #segments times loop

						if t.minp.x <= x and t.maxp.x >= x then
							-- Vector between tuft center and current pos
							vx = x - t.center.x
							vy = y - t.center.y
							vz = z - t.center.z

							-- Square length of this vector ([#4])
							d = vx*vx + vy*vy + vz*vz

							-- Now do the test
							if d < t.radius2 and random() < t.density then
								dif = t.radius - sqrt(d)
								if random() * dif < 2 then
									cid = t.cid_leaves
								else
									cid = t.cid_twigs
								end
								break -- No need to check further
							end
						end
					end
				end

				-- Hanging decorations

				-- Terminate last vine if encounter a node
				if hanging_cid and last_cid == hanging_cid and cid ~= c_air then
					node[vmi + area.ystride] = hanging_end_cid
					hanging_len = 0
					hanging_cid = nil
				end

				-- Continue ongoing decoration
				if hanging_len > 0 and cid == c_air then
					hanging_len = hanging_len - 1
					if hanging_len == 0 then
						cid = hanging_end_cid
						hanging_cid = nil
					else
						cid = hanging_cid
					end
				end

				if not dryrun then

					-- Start new decoration
					if hanging_len == 0 and cid == c_air and decorations[last_cid] then
						for ix = 1, #decorations[last_cid] do
							decoration = decorations[last_cid][ix]

							noise_result = max(0, decoration.noise_radius -
								abs(decoration_map[z-minp.z+1][y-minp.y+1][x-minp.x+1] - decoration.noise_point))

							if noise_result > 0 and random() < decoration.density then

								hanging_len = decoration.length_min or 1

								if decoration.length_noise_factor then
									hanging_len = floor( decoration.length_noise_factor * noise_result)
								end

								if decoration.length_random then
									hanging_len = hanging_len + random(1, decoration.length_random)
								end

								if hanging_len >= (decoration.length_min or hanging_len) then
									hanging_cid = decoration.cid_middle
									hanging_end_cid = decoration.cid_end or hanging_cid
									cid = decoration.cid_start or hanging_cid
									hanging_len = hanging_len - 1
									break
								else
									hanging_len = 0
								end
							end
						end
					end

--TODO:MAKE IT A DECORATION
--[[
					-- Top node change
					if cid == c_bark and
							(last_cid == c_air or last_cid == c_leaves)
					then
						local moisty = floor(decoration_map[z-minp.z+1][y-minp.y+1][x-minp.x+1]*3 + 1)
						if moisty > 0 then
							cid = segment.cid_moisty_barks[min(moisty, 3)]
						end
					end
]]

					if cid ~= old_cid and y <= maxp.y then
						node[vmi] = cid
					end
				end

				dryrun = false
				last_cid = cid
				vmi = vmi - area.ystride
			end

			-- Hanging decorations continuation
			if hanging_len > 0 then
				for _ = 1, hanging_len - 1 do
					if node[vmi] == c_air then
						node[vmi] = hanging_cid
					else
						break
					end
					vmi = vmi - area.ystride
				end
				if node[vmi] == c_air then
					node[vmi] = hanging_end_cid
				end
			end
		end
	end
	voxelmanip:set_data(node)
end
