#!/bin/sh
#PBS -l walltime=10:00:00
#PBS -N FullCellTestSimpleER
#PBS -q normal
#PBS -l nodes=2:ppn=28
#PBS -e error.txt
#PBS -o output.txt
cd $PBS_O_WORKDIR

mpirun -np 56 ugshell -ex full_cell_wER.lua -grid fullgeometryFinal1_wsyn.ugx -numRefs 0 -tstep 5.0e-6 -endTime 0.030 -setting ryrserca -ryrDensity 3.75 -solver GS -outName output -vtk -pstep 0.0001 