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


local Buffer = {
	__newindex = function(self, key, value)
		self.elements[key] = value;
		self.keys[#self.keys + 1] = key;

		if #self.keys > self.maxsize then
			self.elements[table.remove(self.keys, 1)] = nil
		end
	end,

	__index = function(self, key)
		return self.elements[key]
	end,
}

function grunds.new_buffer(maxsize)
	local buffer = {
		maxsize = maxsize,
		stamp = 1,
		elements = {},
		keys = {},
	}
	setmetatable(buffer, Buffer)
	return buffer
end
