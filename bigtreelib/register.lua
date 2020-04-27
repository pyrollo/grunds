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

--[[
Decoration definition:
	place_under -- Node (or list of nodes) that the decoration can be placed under
	density = 0.3,
	noise_point = 1,
	noise_radius = 1,
	length_noise_factor = 5,
	length_min = 2,
	length_random = 5,
	start_node = "grunds:vine_middle",
	middle_node = "grunds:vine_middle",
	end_node = "grunds:vine_end",
]]

btlib.registered_decorations = {}

function btlib.register_decoration(def)
	if not def.place_under then
		return
	end

	local nodes = def.place_under

	if type(nodes) == "string" then
		nodes = { nodes }
	end

	if type(nodes) ~= "table" then
		return
	end

	local def = table.copy(def)
	def.place_under = nil

	if def.middle_node then
		def.cid_middle = minetest.get_content_id(def.middle_node)
		def.cid_start = def.cid_middle
		def.cid_end = def.cid_middle
		def.middle_node = nil
	end

	if def.start_node then
		def.cid_start = minetest.get_content_id(def.start_node)
		def.start_node = nil
	end

	if def.end_node then
		def.cid_end = minetest.get_content_id(def.end_node)
		def.end_node = nil
	end

	for _, node in pairs(nodes) do
		local cid = minetest.get_content_id(node)
		if cid then
			if not btlib.registered_decorations[cid] then
				btlib.registered_decorations[cid] = {}
			end

			btlib.registered_decorations[cid][
				#(btlib.registered_decorations[cid]) + 1] = def
		end
	end
end
