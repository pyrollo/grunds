local pi = math.pi

btlib.register_decoration({
	place_under = "grunds:bark",
	density = 0.3,
	noise_point = 1,
	noise_radius = 1,
--			length_noise_factor = 5,
	length_min = 2,
	length_random = 5,
	middle_node = "grunds:vine_middle",
	end_node = "grunds:vine_end",
})

btlib.register_decoration({
	place_under = "grunds:bark",
	density = 0.2,
	noise_point = -1,
	noise_radius = 0.2,
	middle_node = "grunds:red_fruit",
})

btlib.register_decoration({
	place_under = "grunds:bark",
	density = 0.3,
	noise_point = -1,
	noise_radius = 0.2,
	middle_node = "grunds:blue_fruit",
})

grunds.trees = {}
grunds.trees.grund = {
	nodes = {
		bark_node = "grunds:bark",

		-- TODO: Should be a list
		tree_1_node = "grunds:tree_1",
		tree_2_node = "grunds:tree_2",

		-- TODO: Should be a decoration
		moisty_bark_nodes = {
			"grunds:bark_moisty_1",
			"grunds:bark_moisty_2",
			"grunds:bark_moisty_3"
		},

		leave_node = "grunds:leaves",
		twigs_node = "grunds:twigs",
	},

	trunk = {
		-- Trunk pitch random. If 0, trunk will start perfectly vertical
		pitch_rnd = pi/15,

		-- Trunk thickness (value + random) this will give thickness for
		-- branches and roots
		thickness = 120,
		thickness_rnd = 100,
		thickness_factor = 0.8, -- Factor between base and top thickness
		thickness_factor_rnd = 0.1,

		altitude = 10,
		altitude_rnd = 10,

		length_min = 5,
		length_factor = 4,
		length_factor_rnd = 1,
	},

	branches = {
		rotate_each_node_by = pi/2,
		rotate_each_node_by_rnd = pi/10,

		yaw_rnd = pi/10,

		pitch = pi,
		pitch_rnd = pi/10,

		lenght_min = 5,
		lenght_factor = 2,
		lenght_factor_rnd = 1,

		thinckess_min = 0.8,

		splits = {
			{ thickness = 10, random = 2 },
			{ thickness = 10, random = 10 },
		},

		gravity_effect = -0.2,
		tuft = {
			radius = 8,
			density = 0.05,
		}
	},

	roots = {
		rotate_each_node_by = pi/2,
		rotate_each_node_by_rnd = pi/10,

		yaw_rnd = pi/10,

		pitch = 3*pi/4,
		pitch_rnd = pi/10,

		lenght_min = 5,
		lenght_factor = 3,
		lenght_factor_rnd = 0.5,

		thinckess_min = 2,

		gravity_effect = 0.8,

		splits = {
			{ thickness = 10, random = 5 },
			{ thickness = 10, random = 5 },
			{ thickness = 10, random = 5 },
		},
	},

}
