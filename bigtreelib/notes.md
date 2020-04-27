# Geometric formulas

Here are some geometric formulas used in this lib. Some references can be found
in code ([\#1], [\#2], ...).

## Lines

Spatial representation of a straight line [\#1]:
```
{
	x = vx * t + px
	y = vy * t + py
	z = vz * t + pz
}
```

  * `t` is the "parameter". `(x, y, z)` is on line if a `t` exists.
  * `(vx, vy, vz)` is a vector along the line direction.
  * `(px, py, pz)` is one of the line point.

This formula gives coordinates of point from parameter.

### Segments

Our segments are quite simple if we take starting point as `(px, py, pz)` and
segment vector (from start to end) as `(vx, vy, vz)`.

The segment is constitued of every point for `t` varying from 0.0 to 1.0.

### Nearest point

To determine the parameter of nearest point of line to position `(x0, y0, z0)` is
given by:
```
t = (vx, vy, vz) * ((x0, y0, z0) - (px, py, pz)) / len((vx, vy, vz))
```
So:
```
t = (vx * (x0 - px) + vy * (y0 - py) + vz * (z0 + pz)) / (vx² + vy² +vz²)
```

Quotient is not depending on (x0, y0, z0) so it can be computed once when
creating segment. Final formula is [\#2] :

```
t = (vx * (x0 - px) + vy * (y0 - py) + vz * (z0 + pz)) * k
```

	with `k = 1 / (vx² + vy² +vz²)`

## Thickness

Thickness is a simple linear variation from one end of the segment to the other.
Formula has this form [\#3]:

```
thickness = thickness1 * t + (thickness2 - thickness1)
```

Thickness is something like the surface of a slice. It is compared to square
distances.

## Distance

Distance between `(x1, y1, z1)` and `(x2, y2, z2)` is given by [\#4] :

```
d = squareroot( (x2-x1)² + (y2-y1)² + (z2-z1)² )
```

To avoid useless calculation, square distance is used as much as possible. For
example, comparing two distances is the same as comparing their squares.

If exact distance is not required, Manhatan distance can be used (much faster):

```
d = abs(x2-x1) + abs(y2-y1) + abs(z2-z1)
```
