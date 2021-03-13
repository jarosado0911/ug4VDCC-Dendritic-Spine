# VDCC-Spine-Dendrite
This is a proof of concept project for running VDCC experiments on 3D spine morphologies
For this project we need to provide the membrane potential that the VDCC's require.
1. The first way provides the global membrane potential by a function definable in the lua script itself. I used a single typical AP trace (scaled by a factor of 0.8).
2. The second way provides the membrane potential through files that contain (for each time step) coordinates and corresponding voltages. 
   - I suppose the potential is basically the same on the whole spine morphology surface, so one point per file will probably suffice (the VDCC implementation finds the closest coordinates from the file for each point on the plasma membrane).
   - The files can be generated from 1d electrical simulations using the script "cable_neuron_app/single_neuron_somaInjection.lua".
   - I tested this on the "rat1" geometry from our shared data folder using the command:

```
ugshell -ex cable_neuron_app/single_neuron_somaInjection.lua -endTime 0.1 
        -outName /your/output/directory -grid /path/to/your/1d/grid.ugx -dt 1e-5
```
   - For lack of better knowledge, I hard-coded an arbitrary location on the geometry for output of the membrane potential into the script.
I then ran a test simulation on a reconstructed spine with both ways of providing the membrane potential traces for the VDCCs. A variable in the script can be changed to switch between both methods.
The command I used was:

	mpirun -n 4 ugshell -ex calciumDynamics_app/spine/reconstructed_spine_viet_noER.lua
		-grid /path/to/your/reconstructed/3d/grid.ugx -numRefs 1 -tstep 0.0000125
		-endTime 0.005 -outName /your/output/directory -solver ILU -vtk -pstep 0.0001 

In all simulations, the directory given as output directory needs to have the subdirectories "vtk", "meas" and maybe also "grid" to store output in them.
If you use the second way of providing the membrane potential, then the Vm files are expected in a directory "voltageData" relative to the current working directory. You may of course change that to your needs.

James you to do list is the following:
1. :heavy_check_mark: Run a soma injection simulation on the cell
    - I had to switch to the 0-2a.CNG.swc cell because rat1.ugx was difficult to run through AnaMorph
    - I had to scale 0-2a.CNG.swc using a MatLab code because the original 0-2a.CNG.swc was in micrometers, x,y,z and r
    - Note you need to specify the the center of an edge for current influx!
2. :heavy_check_mark: Run simulation in 1. again but this time write the voltage for the entire cell to a file
3. :heavy_check_mark: Make a video of the data in 2. to check
4. [ ] Run the data in 2. in a calcium simulation with the vdcc set to on
    - [ ] Run a constant AP vdcc simulation with calcium first, send it to HPC for complete run, I am first doing this with no ER
