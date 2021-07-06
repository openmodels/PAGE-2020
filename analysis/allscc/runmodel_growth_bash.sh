#!/bin/bash

for jj_ge in {0..10}
do
    for jj_geadapt in {0..8}
    do
	echo $jj_ge $jj_geadapt
	nice ~/added/julia-1.6.1/bin/julia runmodel_growth_bash.jl $jj_ge $jj_geadapt &
	sleep 30
    done
done
