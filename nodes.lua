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

-- support for MT game translation.
local S = default.get_translator

minetest.register_node("grunds:bark", {
	description = S("Grund bark"),
	tiles = {"grunds_bark.png"},
	is_ground_content = false,
	groups = {tree = 1, choppy = 2, flammable = 2},
	sounds = default.node_sound_wood_defaults(),
})

minetest.register_node("grunds:bark_moisty_1", {
	description = S("Grund moisty bark"),
	tiles = {"grunds_bark_moisty_top_1.png", "grunds_bark.png", "grunds_bark_moisty_side_1.png"},
	is_ground_content = false,
	drop = "grunds:bark",
	groups = {tree = 1, choppy = 2, flammable = 2 },
	sounds = default.node_sound_wood_defaults(),
})

minetest.register_node("grunds:bark_moisty_2", {
	description = S("Grund moisty bark"),
	tiles = {"grunds_bark_moisty_top_2.png", "grunds_bark.png", "grunds_bark_moisty_side_2.png"},
	is_ground_content = false,
	drop = "grunds:bark",
	groups = {tree = 1, choppy = 2, flammable = 2, slippery = 1},
	sounds = default.node_sound_wood_defaults(),
})

minetest.register_node("grunds:bark_moisty_3", {
	description = S("Grund moisty bark"),
	tiles = {"grunds_bark_moisty_top_3.png", "grunds_bark.png", "grunds_bark_moisty_side_3.png"},
	is_ground_content = false,
	drop = "grunds:bark",
	groups = {tree = 1, choppy = 2, flammable = 2, slippery = 2},
	sounds = default.node_sound_wood_defaults(),
})

minetest.register_node("grunds:tree_1", {
	description = S("Grund wood"),
	tiles = {"grunds_wood_1.png"},
	is_ground_content = false,
	groups = {tree = 1, choppy = 2, flammable = 2},
	sounds = default.node_sound_wood_defaults(),
})

minetest.register_node("grunds:tree_2", {
	description = S("Grund wood"),
	tiles = {"grunds_wood_2.png"},
	is_ground_content = false,
	groups = {tree = 1, choppy = 2, flammable = 2},
	sounds = default.node_sound_wood_defaults(),
})

minetest.register_node("grunds:leaves", {
	description = S("Grunds Leaves"),
	drawtype = "allfaces_optional",
	waving = 1,
	tiles = {"grunds_leaves.png"},
	paramtype = "light",
	is_ground_content = false,
	sunlight_propagates = true,
	groups = {snappy = 3, flammable = 2, leaves = 1},
	sounds = default.node_sound_leaves_defaults(),
})

minetest.register_node("grunds:twigs", {
	description = S("Grunds Twigs"),
	drawtype = "allfaces_optional",
	waving = 1,
	tiles = {"grunds_twigs.png"},
	paramtype = "light",
	is_ground_content = false,
	sunlight_propagates = true,
	drop = "default:stick",
	sunlight_propagates = true,
	groups = {snappy = 3, flammable = 2, leaves = 1},
	sounds = default.node_sound_leaves_defaults(),
})

minetest.register_node("grunds:vine_middle", {
	description = S("Grunds Vine"),
	drawtype = "plantlike",
	tiles = {"grunds_vine_middle.png"},
	paramtype = "light",
	selection_box = {
		type = "fixed",
		fixed = {
			{ -5/16, -0.5, -5/16, 5/16, 0.5, 5/16 },
		},
	},
	is_ground_content = false,
	sunlight_propagates = true,
	walkable = false,
	climbable = true,
	groups = {snappy = 3, flammable = 2},
	sounds = default.node_sound_leaves_defaults(),
})

minetest.register_node("grunds:vine_end", {
	description = S("Grunds Vine"),
	drawtype = "plantlike",
	tiles = {"grunds_vine_end.png"},
	paramtype = "light",
	selection_box = {
		type = "fixed",
		fixed = {
			{ -5/16, -2/8, -5/16, 5/16, 0.5, 5/16 },
		},
	},
	is_ground_content = false,
	sunlight_propagates = true,
	walkable = false,
	climbable = true,
	groups = {snappy = 3, flammable = 2},
	drop = "grunds:vine_middle",
	sounds = default.node_sound_leaves_defaults(),
})

minetest.register_node("grunds:red_plant", {
	description = S("Grunds Red Plant"),
	drawtype = "plantlike",
	tiles = {"grunds_red_plant.png"},
	paramtype = "light",
	selection_box = {
		type = "fixed",
		fixed = {
			{ -3 / 8, -0.5, -3 / 8, 3 / 8, 0.5, 3 / 8 },
		},
	},
	is_ground_content = false,
	sunlight_propagates = true,
	groups = {snappy = 3, flammable = 2},
})

minetest.register_node("grunds:red_fruit", {
	description = S("Grunds Red Fruit"),
	drawtype = "plantlike",
	tiles = {"grunds_red_fruit.png"},
	paramtype = "light",
	is_ground_content = false,
	sunlight_propagates = true,
	groups = {snappy = 3, flammable = 2},
})
minetest.register_node("grunds:blue_fruit", {
	description = S("Grunds Blue Fruit"),
	drawtype = "plantlike",
	tiles = {"grunds_blue_fruit.png"},
	paramtype = "light",
	is_ground_content = false,
	sunlight_propagates = true,
	groups = {snappy = 3, flammable = 2},
})
