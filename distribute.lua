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

local sectorsize = 80

local abs = math.abs

local sectormax = math.ceil(32768 / sectorsize) * 2

local function get_sector_seed(x, y)
	return grunds.baseseed + x * sectormax + y
end

-- Return area, in sectors coordiates, of all sectors overlaping area
local function get_sectors_area_2d(minp, maxp)
	return {
			x = math.floor(minp.x / sectorsize),
			y = math.floor(minp.y / sectorsize)
		}, {
			x = math.ceil(maxp.x / sectorsize),
			y = math.ceil(maxp.y / sectorsize)
		}
end

function grunds.distribute(minp2d, maxp2d, distance, surrounds, tries)
	local mins, maxs = get_sectors_area_2d(minp2d, maxp2d)
--	local d2 = distance * distance

	-- fetch all needed points in all sector (including sectors around)
	local pts = {}
	for x = mins.x - surrounds, maxs.x + surrounds do
		pts[x] = {}
		local xx = x * sectorsize
		for y = mins.y - surrounds, maxs.y + surrounds do
			pts[x][y] = {}
			local yy = y * sectorsize
			local inside = x >= mins.x and x <= maxs.x and y >= mins.y and y <= maxs.y
			-- All sector related random number must be fetched here
			math.randomseed(get_sector_seed(x, y))
			for try = 1, tries do
				pts[x][y][try] = {
					x = xx + math.random(0, sectorsize - 1),
					y = yy + math.random(0, sectorsize - 1),
					inside = inside,
				}
			end
		end
	end

	-- Eliminate points that are too close to each other
	-- We cant predict accurately which will be points in surrounding
	-- sectors but we can eliminate a bit too much considering surrounding
	-- points that wont be there at last

	local kept = {}

	for try = 1, tries do
		for x =  mins.x - surrounds, maxs.x + surrounds do
			for y = mins.y - surrounds, maxs.y + surrounds do
				local p = pts[x][y][try]
				--Have to test if we have to eliminate only inside points
				--if p.inside then
				local xt, yt = p.x, p.y

				for i = 1, #kept do
					local xf, yf = kept[i].x, kept[i].y
					-- Use manathan distance for perf purpose
					local d = abs(xt - xf) + abs(yt - yf)
--					local d = (xt - xf)*(xt -xf) + (yt - yf)*(yt -yf)
					if (d < distance) then
						goto reject
					end
				end
				kept[#kept + 1] = p
				::reject::
			end
		end
	end

	local result = {}
	for i = 1, #kept do
		if kept[i].inside then
			result[#result + 1] = kept[i]
		end
	end

	return result
end
