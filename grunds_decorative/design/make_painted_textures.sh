#!/bin/sh

txtdir=../textures
basetxt=../../grunds/textures/grunds_plank.png
color="blue green red white yellow"
patterns="empty_losange four_dots frieze plain_losange top_arks top_arks_dots torsade"

for color in $color
do
	cp colors/$color.png ${txtdir}/grunds_${color}_painted_plank.png

	for pattern in $patterns
	do
		convert colors/$color.png \
			patterns/$pattern.png -compose CopyOpacity -composite \
			${txtdir}/grunds_pattern_${color}_${pattern}.png
	done
done
