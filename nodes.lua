-- support for MT game translation.
local S = default.get_translator

minetest.register_node("grunds:bark", {
	description = S("Grund bark"),
	tiles = {"grunds_bark.png"},
	is_ground_content = false,
	groups = {tree = 1, choppy = 2, oddly_breakable_by_hand = 1, flammable = 2},
	sounds = default.node_sound_wood_defaults(),
})

minetest.register_node("grunds:bark_moisty", {
	description = S("Grund moisty bark"),
	tiles = {"grunds_bark_moisty_top.png", "grunds_bark.png", "grunds_bark_moisty_side.png"},
	is_ground_content = false,
	groups = {tree = 1, choppy = 2, oddly_breakable_by_hand = 1, flammable = 2},
	sounds = default.node_sound_wood_defaults(),
})

minetest.register_node("grunds:bark_moisty_2", {
	description = S("Grund moisty bark"),
	tiles = {"grunds_bark_moisty_top_2.png", "grunds_bark.png", "grunds_bark_moisty_side_2.png"},
	is_ground_content = false,
	groups = {tree = 1, choppy = 2, oddly_breakable_by_hand = 1, flammable = 2},
	sounds = default.node_sound_wood_defaults(),
})

minetest.register_node("grunds:bark_moisty_3", {
	description = S("Grund moisty bark"),
	tiles = {"grunds_bark_moisty_top_3.png", "grunds_bark.png", "grunds_bark_moisty_side_3.png"},
	is_ground_content = false,
	groups = {tree = 1, choppy = 2, oddly_breakable_by_hand = 1, flammable = 2},
	sounds = default.node_sound_wood_defaults(),
})

minetest.register_node("grunds:tree", {
	description = S("Grund wood"),
	tiles = {"grunds_wood_1.png"},
	is_ground_content = false,
	groups = {tree = 1, choppy = 2, oddly_breakable_by_hand = 1, flammable = 2},
	sounds = default.node_sound_wood_defaults(),
})
