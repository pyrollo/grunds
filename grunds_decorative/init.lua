--[[
	Grunds - Giant trees for Minetest
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

-- support for MT game translation.
local S = minetest.get_translator("grunds")

local patterns = {
	empty_losange =  { desc = S("Empty Losanges"),    sides = "pattern", top = "pattern",    bottom = "pattern"    },
	four_dots =      { desc = S("Four Dots"),         sides = "pattern", top = "pattern",    bottom = "pattern"    },
	frieze =         { desc = S("Frieze"),            sides = "pattern", top = "background", bottom = "background" },
	plain_losange =  { desc = S("Plain Losanges"),    sides = "pattern", top = "pattern",    bottom = "pattern"    },
	top_arks =       { desc = S("Top Arks"),          sides = "pattern", top = "foreground", bottom = "background" },
	top_arks_dots =  { desc = S("Top Arks And Dots"), sides = "pattern", top = "foreground", bottom = "background" },
	torsade =        { desc = S("Torsade"),           sides = "pattern", top = "background", bottom = "background" },
}

local colors = {
	blue   = S("Blue"),
	green  = S("Green"),
	red    = S("Red"),
	white  = S("White"),
	yellow = S("Yellow"),
}

local function tile(type, pattern, fgcolor, bgcolor)
	if type == "background" then
		return ("grunds_%s_painted_plank.png"):format(bgcolor)
	elseif type == "foreground" then
		return ("grunds_%s_painted_plank.png"):format(fgcolor)
	else
		return ("grunds_%s_painted_plank.png^grunds_pattern_%s_%s.png"):format(bgcolor,fgcolor,pattern)
	end
end

for color, desc in pairs(colors) do
	print(color)
	minetest.register_node(
		("grunds_decorative:%s_painted_planks"):format(color),
		{
			description = S("Grund @1 Painted Wood Planks", desc),
			paramtype2 = "facedir",
			place_param2 = 0,
			tiles =  {("grunds_%s_painted_plank.png"):format(color)},
			is_ground_content = false,
			groups = {choppy = 2, oddly_breakable_by_hand = 2, flammable = 2, wood = 1},
			sounds = default.node_sound_wood_defaults(),
		}
	)
end

for bgcolor, bgdesc in pairs(colors) do
	for fgcolor, fgdesc in pairs(colors) do
		if bgcolor ~= fgcolor then
			for name, def in pairs(patterns) do
				minetest.register_node(
					("grunds_decorative:%s_painted_planks_%s_%s"):format(bgcolor, fgcolor, name),
					{
						description = S("Grund @1 Painted Wood Planks @2 @3", bgdesc, fgdesc, def.desc),
						paramtype2 = "facedir",
						place_param2 = 0,
						tiles = {
							tile(def.top,    name, fgcolor, bgcolor),
							tile(def.bottom, name, fgcolor, bgcolor),
							tile(def.sides,  name, fgcolor, bgcolor),
							tile(def.sides,  name, fgcolor, bgcolor),
							tile(def.sides,  name, fgcolor, bgcolor),
							tile(def.sides,  name, fgcolor, bgcolor),
						},
						is_ground_content = false,
						groups = {choppy = 2, oddly_breakable_by_hand = 2, flammable = 2, wood = 1},
						sounds = default.node_sound_wood_defaults(),
					}
				)
			end
		end
	end
end
