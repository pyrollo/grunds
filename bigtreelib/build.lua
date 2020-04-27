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
-- TREE CREATION
--
-- Here are function that creates a tree made of segment and tufts, according
-- to registered tree settings.
--
-- =============================================================================

local pi, cos, sin, sqrt = math.pi, math.cos, math.sin, math.sqrt
local ceil, floor, max, random = math.ceil, math.floor, math.max, math.random

-- Add two random numbers, make it a bit gaussian
local function rnd()
	return random() + random() - 1
end

-- Create a new tuft and pre-compute as much as possible
local function new_tuft(center, radius, density)
	return {
		-- Bounding box
		minp = vector.subtract(center, radius),
		maxp = vector.add(center, radius),

		-- Center point
		center = center,

		-- Density
		density = density,

		-- Radius and square radius
		radius = radius,
		radius2 = radius * radius,
	}
end

-- Create a new segment and pre-compute as much as possible
local function new_segment(p1, p2, th1, th2, type)
	if p1.x == p2.x and p1.y == p2.y and p1.z == p2.z then
		return nil -- Not a segment
	end
	local s = {
		-- Bounding box
		--minp = See below
		--maxp = See below

		type = type,
		-- Starting thickness and thickness increment
		th = th1,
		thinc = th2 - th1,

		-- Starting point
		p = table.copy(p1),
		-- Vector to ending point
		v = vector.subtract(p2, p1),
	}

	-- Square of the vector lenght
	s.d2 = s.v.x * s.v.x + s.v.y * s.v.y + s.v.z * s.v.z

	-- Its inverse (used in segmentNearestPoint)
	s.invd2 = 1 / s.d2

	-- Bounding box including thickness
	s.minp, s.maxp = vector.sort(p1, p2)
	local d = math.sqrt(math.max(th1, th2))
	s.minp = vector.add(s.minp, -d)
	s.maxp = vector.add(s.maxp, d)

	return s
end

-- Axis a vector with len 1 around which pos will be rotated by angle
local function rotate(axis, angle, vect)
	local c, s, c1 = cos(angle), sin(angle), 1 - cos(angle)
	local ax, ay, az = axis.x, axis.y, axis.z
	return {
		x =
			vect.x * (c1 * ax * ax + c) +
			vect.y * (c1 * ax * ay - s * az) +
			vect.z * (c1 * ax * az + s * ay),
		y =
			vect.x * (c1 * ay * ax + s * az) +
			vect.y * (c1 * ay * ay + c) +
			vect.z * (c1 * ay * az - s * ax),
		z =
			vect.x * (c1 * az * ax - s * ay) +
			vect.y * (c1 * az * ay + s * ax) +
			vect.z * (c1 * az * az + c),
	}
end

-- Creates a tree made out of segments and tufts. This tree can be rendered.
function btlib.build_tree(startpos, params, seed)
	if seed then math.randomseed(seed) end

	local c_bark = minetest.get_content_id(params.nodes.bark_node)
	local c_wood_1 = minetest.get_content_id(params.nodes.tree_1_node)
	local c_wood_2 = minetest.get_content_id(params.nodes.tree_2_node)
	local c_moisty_barks = {
		minetest.get_content_id(params.nodes.moisty_bark_nodes[1]),
		minetest.get_content_id(params.nodes.moisty_bark_nodes[2]),
		minetest.get_content_id(params.nodes.moisty_bark_nodes[3]),
	}
	local c_leaves = minetest.get_content_id(params.nodes.leave_node)
	local c_twigs = minetest.get_content_id(params.nodes.twigs_node)

	local segments = {}
	local tufts = {}

	-- TODO : add a counter limitation
	-- rotax and dirax MUST be normalized
	local function grow(params, pos, rotax, dirax, length, thickness, type)

		local sum = 0
		local splits = {}
		-- Choose divisions
		-- Randomize
		for _, split in ipairs(params.splits) do
			local thickness = split.thickness +
				split.random * rnd()
			if thickness > 0 then
				splits[#splits + 1] = thickness
				sum = sum + thickness
			end
		end

		-- Normalize
		for i = 1, #splits do
			splits[i] = splits[i] / sum
		end

		-- Rotate around branch axe
		local yaw = params.rotate_each_node_by +
			rnd() * params.rotate_each_node_by_rnd

		-- Make branches
		for _, split in ipairs(splits) do
			-- Put branches evenly around 360°
			yaw = yaw + 2 * pi / #splits +
					rnd() * params.yaw_rnd

			local pitch = (1 - split) * (1 - split)
					* (params.pitch +
					rnd() * params.pitch_rnd)

			-- All "next" values are named "value"2

			-- Next len and thickness
			local thickness2 = split * thickness
			local length2 = math.log(thickness2 + 1)
				* (params.lenght_factor  +
					rnd() * params.lenght_factor_rnd)
				+ params.lenght_min

			-- New axes
			local rotax2 = rotate(dirax, yaw, rotax)
			local dirax2 = rotate(rotax2, pitch, dirax)

			if (params.gravity_effect) then
				dirax2 = vector.normalize(vector.add(dirax2,
					{ x = 0, y = -params.gravity_effect, z = 0}))
			end

			local pos2 = vector.add(pos,
					vector.multiply(dirax2, length2))

			-- Create segment
			local segment = new_segment(pos, pos2, thickness, thickness2, type)
			segment.cid_bark = c_bark
			segment.cid_wood_1 = c_wood_1
			segment.cid_wood_2 = c_wood_2
			segment.cid_moisty_barks = c_moisty_barks

			segments[ #segments + 1 ] = segment

			if thickness2 < params.thinckess_min
					or length2 < params.lenght_min then
				-- Branch ends
				if params.tuft then
					local tuft = new_tuft(pos2, params.tuft.radius, params.tuft.density)
					tuft.cid_leaves = c_leaves
					tuft.cid_twigs = c_twigs
					tufts[ #tufts + 1 ] = tuft
				end
			else
				-- Branch continues
				grow(params, pos2, rotax2, dirax2, length2, thickness2, type)
			end

		end
	end

	-- Trunk
	--------
	local trunk = params.trunk
	startpos.y = startpos.y + trunk.altitude + trunk.altitude_rnd * rnd()

	-- Random yaw
	local rotax = rotate({ x = 0, y = 1, z = 0}, math.random() * pi * 2, { x = 0, y = 0, z = 1})

	-- Start with some pitch and given lenght
	local dirax = rotate(rotax, trunk.pitch_rnd * rnd(), { x = 0, y = 1, z = 0})

	-- Length and thickness
	local thickness = trunk.thickness + trunk.thickness_rnd * rnd()
	local thickness_top = thickness *
		(trunk.thickness_factor + trunk.thickness_factor_rnd * rnd())

	local length = math.log(thickness) * trunk.length_factor + trunk.length_min

	-- Segment
	local pos = vector.add(startpos, vector.multiply(dirax, length))

	local segment = new_segment(startpos, pos, thickness, thickness_top, "trunk")
	segment.cid_bark = c_bark
	segment.cid_wood_1 = c_wood_1
	segment.cid_wood_2 = c_wood_2
	segment.cid_moisty_barks = c_moisty_barks
	segments[1] = segment

	-- Branches and roots
	---------------------
	grow(params.branches, pos, rotax, dirax, length, thickness_top, "branch")

	-- Turn upside down
	dirax = rotate(rotax, pi, { x = 0, y = 1, z = 0})
	grow(params.roots, startpos, rotax, dirax, length, thickness, "root")

	return {
		params = params,
		segments = segments,
		tufts = tufts,
	}
end

function btlib.intersects(b, minp, maxp)
	return
		b.minp.x <= maxp.x and b.maxp.x >= minp.x and
		b.minp.y <= maxp.y and b.maxp.y >= minp.y and
		b.minp.z <= maxp.z and b.maxp.z >= minp.z
end

local function adjust_minmaxp(minp, maxp, boxes)
	for _, b in pairs(boxes) do
		if not minp.x or minp.x > b.minp.x then
			minp.x = b.minp.x
		end
		if not minp.y or minp.y > b.minp.y then
			minp.y = b.minp.y
		end
		if not minp.z or minp.z > b.minp.z then
			minp.z = b.minp.z
		end
		if not maxp.x or maxp.x < b.maxp.x then
			maxp.x = b.maxp.x
		end
		if not maxp.y or maxp.y < b.maxp.y then
			maxp.y = b.maxp.y
		end
		if not maxp.z or maxp.z < b.maxp.z then
			maxp.z = b.maxp.z
		end
	end
end

function btlib.get_minmaxp(tree)
	local minp, maxp = {}, {}
	adjust_minmaxp(minp, maxp, tree.segments or {})
	adjust_minmaxp(minp, maxp, tree.tufts or {})
	return
		{ x = floor(minp.x), y = floor(minp.y), z = floor(minp.z) },
		{ x = ceil(maxp.x),  y = ceil(maxp.y),  z = ceil(maxp.z) }
end
