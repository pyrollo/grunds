# Tree description

A table containing four items.

* `nodes`: Materials to be used for tree (WIP - Not yet stable)
* `trunk`: Description of the tree trunk, a single segment connecting the
branches to the roots.
* `branches`: Description of branches. Branches are segment dividing into
smaller segments, starting from the top of the trunk.
* `roots`: Description of roots. Roots are like branches, in the oposite
direction, starting from the base of the trunk.

Many parameters are divided into two values :
* "param_name" average value.
* "param_name_rnd" random variation around average value.

## Trunk

Trunk segment is a vertical segment, larger on its bottom than on its top.
From bottom starts roots and from top starts branches.

* `pitch_rnd`: Random pitch variation (in randians). 0 gives a perfectly
vertical trunc. pi/2 would make trees that could have horizontal trunk.
* `thickness`: Average bottom thickness.
* `thickness_rnd`: Random bottom thickness variation (average value
multiplicator).
* `thickness_factor`: Average top-thickness/bottom-thickness factor. Top
thickness is calculated by multiplying bottom thickness by this factor.
* `thickness_factor_rnd`: Random variation of top/bottom factor (average value
multiplicator).
* `altitude`: Average altitude of the bottom point of the segment (from mapgen
level).
* `altitude_rnd`: Random variation of altitude (added to average value).

* `length_min`
* `length_factor`
* `length_factor_rnd`

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
