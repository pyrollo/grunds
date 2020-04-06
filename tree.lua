local pi, cos, sin, sqrt = math.pi, math.cos, math.sin, math.sqrt
local max, random = math.max, math.random

-- Add two random numbers, make it a bit gaussian
local function rnd()
	return random() + random() - 1
end

-- Create a new tuft and pre-compute as much as possible
local function new_tuft(center, radius)
	return {
		-- Bounding box
		minp = vector.subtract(center, radius),
		maxp = vector.add(center, radius),

		-- Center point
		p = center,

		-- Radius and square radius
		radius = radius,
		r2 = radius * radius,
	}
end

-- Create a new segment and pre-compute as much as possible
local function new_segment(p1, p2, th1, th2)
	if p1.x == p2.x and p1.y == p2.y and p1.z == p2.z then
		return nil -- Not a segment
	end
	local s = {
		-- Bounding box
		--minp = See below
		--maxp = See below

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

local function intersects(b, minp, maxp)
	return
		b.minp.x <= maxp.x and b.maxp.x >= minp.y and
		b.minp.y <= maxp.y and b.maxp.y >= minp.y and
		b.minp.z <= maxp.z and b.maxp.z >= minp.z
end

function grunds.make_tree(startpos, params, minp, maxp)

	local segments = {}
	local tufts = {}

	-- TODO : add a counter limitation
	-- rotax and dirax MUST be normalized
	local function grow(pos, rotax, dirax, length, thickness)

		local sum = 0
		local branches = {}
		-- Choose divisions
		-- Randomize
		for _, branch in ipairs(params.branches) do
			local thickness = branch.thickness +
				branch.random * rnd()
			if thickness > 0 then
				branches[#branches + 1] = thickness
				sum = sum + thickness
			end
		end

		-- Normalize
		for i = 1, #branches do
			branches[i] = branches[i] / sum
		end

		-- Rotate around branch axe
		local yaw = params.rotate_each_node_by +
			rnd() * params.rotate_each_node_by_rnd

		-- Make branches
		for _, part in ipairs(branches) do
			-- Put branches evenly around 360°
			yaw = yaw + 2 * pi / #branches +
					rnd() * params.branch_yaw_rnd

			local pitch = (1 - part) * (1 - part)
					* (params.branch_pitch +
					rnd() * params.branch_pitch_rnd)

			-- All "next" values are named "value"2

			-- Next len and thickness
			local thickness2 = part * thickness
			local length2 = math.log(thickness2 + 1)
				* (params.branch_len_factor  +
					rnd() * params.branch_len_factor_rnd)
				+ params.branch_len_min

			-- New axes
			local rotax2 = rotate(dirax, yaw, rotax)
			local dirax2 = rotate(rotax2, pitch, dirax)

			local pos2 = vector.add(pos,
					vector.multiply(dirax2, length2))

			-- Create segment
			local segment = new_segment(pos, pos2, thickness, thickness2)
			if intersects(segment, minp, maxp) then
				segments[ #segments + 1 ] = segment
			end

			if thickness2 < 0.5 or length2 < params.branch_len_min then
				-- Branch ends
				local tuft = new_tuft(pos2, params.tuft_radius)
				if intersects(tuft, minp, maxp) then
					tufts[ #tufts + 1 ] = tuft
				end
			else
				-- Branch continues
				grow(pos2, rotax2, dirax2, length2, thickness2)
			end

		end
	end

	-- Start conditions
	-------------------

	-- Random yaw
	local rotax = rotate({ x = 0, y = 1, z = 0}, math.random() * pi * 2, { x = 0, y = 0, z = 1})

	-- Start with some pitch and given lenght
	local dirax = rotate(rotax, params.start_pitch_rnd * rnd(), { x = 0, y = 1, z = 0})

	-- Length and thickness
	local thickness = params.start_thickness + params.start_thickness_rnd * rnd()
	local length = math.log(thickness)
		* params.branch_len_factor + params.branch_len_min

	-- First (trunk) segment
	local pos = vector.add(startpos, vector.multiply(dirax, length))
	segments[1] = new_segment(startpos, pos, thickness, thickness)

	grow(pos, rotax, dirax, length, thickness)

	return {
		params = params,
		segments = segments,
		tufts = tufts,
	}
end
