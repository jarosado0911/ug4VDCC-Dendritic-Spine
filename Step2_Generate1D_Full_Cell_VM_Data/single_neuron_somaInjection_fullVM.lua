--------------------------------------------------------------------------------
-- This script solves the cable equation with HH channels on a pyramidal cell --
-- without axon with an injection electrode at the soma.                      --
-- The potential at a specified point is written to file.                     --
--                                                                            --
-- Author: Markus Breit                                                       --
-- Date:   2019-05-17                                                         --
--------------------------------------------------------------------------------

ug_load_script("ug_util.lua")
AssertPluginsLoaded({"cable_neuron"})

-- init UG
InitUG(3, AlgebraType("CPU", 1))


---------------------------------
-- read command line arguments --
---------------------------------
-- choice of grid
gridName = util.GetParam("-grid")

-- parameters steering simulation
numRefs = util.GetParamNumber("-numRefs", 0)
dt = util.GetParamNumber("-dt", 1e-5) -- in s
endTime = util.GetParamNumber("-endTime", 0.01)

-- specify "-verbose" to output linear solver convergence
verbose	= util.HasParamOption("-verbose")

-- vtk output?
generateVTKoutput = util.HasParamOption("-vtk")
pstep = util.GetParamNumber("-pstep", dt, "plotting interval")

-- file handling
outputPath = util.GetParam("-outName", ".")
outputPath = outputPath.."/"


-------------------------
-- biological settings --
-------------------------
-- settings are according to T. Branco

-- membrane conductances (in units of S/m^2)
g_k_ax = 400.0	-- axon
g_k_so = 200.0	-- soma
g_k_de = 30		-- dendrite

g_na_ax = 3.0e4
g_na_so = 1.5e3
g_na_de = 40.0

g_l_ax = 200.0
g_l_so = 1.0
g_l_de = 1.0

-- specific capacitance (in units of F/m^2)
spec_cap = 1.0e-2

-- resistivity (in units of Ohm m)
spec_res = 3.0

-- reversal potentials (in units of V)
e_k  = -0.09
e_na = 0.06
e_ca = 0.14

-- equilibrium concentrations (in units of mM)
-- comment: these concentrations will not yield Nernst potentials
-- as given above pumps will have to be introduced to achieve this
-- in the case where Nernst potentials are calculated from concentrations!
k_out  = 4.0
na_out = 150.0
ca_out = 1.5

k_in   = 140.0
na_in  = 10.0
ca_in  = 5e-5

-- equilibrium potential (in units of V)
v_eq = -0.07

-- diffusion coefficients (in units of m^2/s)
diff_k 	= 1.0e-9
diff_na	= 1.0e-9
diff_ca	= 2.2e-10

-- temperature in units of deg Celsius
temp = 37.0


------------------------------------
-- create domain and approx space --
------------------------------------
dom = Domain()
requiredSubsets = {"soma", "dend", "apic"}
dom = util.CreateDomain(gridName, numRefs, requiredSubsets)

approxSpace = ApproximationSpace(dom)
approxSpace:add_fct("v", "Lagrange", 1)

approxSpace:init_levels()
approxSpace:init_surfaces()
approxSpace:init_top_surface()
approxSpace:print_layout_statistic()
approxSpace:print_statistic()
OrderCuthillMcKee(approxSpace, true)


------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
-- save refined domain to .txt, .ugx, and .swc formats 
-- os.execute("mkdir " .. "dom-data-output")
fout_name = "outDom"
SaveDomain(dom, outputPath .. fout_name .. ".txt")
print("Checkpoint --> Successfully Saved Domain to txt format")
SaveDomain(dom, outputPath .. fout_name .. ".ugx")
print("Checkpoint --> Successfully Saved Domain to ugx format")
SaveDomain(dom, outputPath .. fout_name .. ".swc")
print("Checkpoint --> Successfully Saved Domain to swc format")

-- this function removes the header in the .txt file for later use
function remove( filename, starting_line, num_lines )
    local fp = io.open( filename, "r" )
    if fp == nil then return nil end
 
    content = {}
    i = 1;
    for line in fp:lines() do
        if i < starting_line or i >= starting_line + num_lines then
	    content[#content+1] = line
	end
	i = i + 1
    end
 
    if i > starting_line and i < starting_line + num_lines then
	print( "Warning: Tried to remove lines after EOF." )
    end
 
    fp:close()
    fp = io.open( filename, "w+" )
 
    for i = 1, #content do
	fp:write( string.format( "%s\n", content[i] ) )
    end
 	print("Checkpoint --> Removed Header in TXT file!")
    fp:close()
end

file = outputPath .. fout_name .. ".swc"
remove(file,1,1)

file = outputPath .. fout_name .. ".txt"
remove(file,1,1)

-- the reads the .txt data into tables
-- the tables for x,y,z will be used with the evaluate at nearest coordinate
io.input(file)	-- initialize file
index = {}		-- initialize empty tables
xcrd = {}
ycrd = {}
zcrd = {}
 while true do
 	  -- read in the data to temporary variables
      local n0, n1, n2, n3 = io.read("*number","*number", "*number","*number")
      if not n0 then 
      	break 
      end
      
      -- append the read in values to the tables
      table.insert(index,n0)
      table.insert(xcrd,n1)
      table.insert(ycrd,n2)
      table.insert(zcrd,n3)
end
io.close() -- close the file

-- print the data to check
print("Checkpoint --> Check that (ind,x,y,z) saved: ")
print ("  Index  " .. "     x     " .. "     y     " .. "     z     ")
for i=1,table.getn(index) do
	print("      " .. index[i] .. "  " .. xcrd[i] .. "  " .. ycrd[i] .. "  " .. zcrd[i])
end

------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------


--------------------
-- discretization --
--------------------
-- cable equation
CE = CableEquation("soma, dend, apic", false)

CE:set_spec_cap(spec_cap)
CE:set_spec_res(spec_res)

CE:set_rev_pot_k(e_k)
CE:set_rev_pot_na(e_na)
CE:set_rev_pot_ca(e_ca)

CE:set_k_out(k_out)
CE:set_na_out(na_out)
CE:set_ca_out(ca_out)

CE:set_diff_coeffs({diff_k, diff_na, diff_ca})

CE:set_temperature_celsius(temp)

ss_dend = "dend, apic"

-- Hodgkin and Huxley channels
HH = ChannelHH("v", "soma, dend, apic")
HH:set_conductances(g_k_so, g_na_so, "soma")
HH:set_conductances(g_k_de, g_na_de, ss_dend)

CE:add(HH)

-- leakage (exactly calibrated to achieve zero net current in equilibrium)
tmp_fct = math.pow(2.3,(temp-23.0)/10.0)

leak = ChannelLeak("v", "soma, dend, apic")
leak:set_cond(g_l_so*tmp_fct, "soma")
leak:set_rev_pot(-0.0592363968739, "soma")
leak:set_cond(g_l_de*tmp_fct, ss_dend)
leak:set_rev_pot(-0.0679474583084, ss_dend)

CE:add(leak)

-- electrode stimulation
-- current, x, y, z, begin, duration
-- the (x,y,z) coords need to specify an edge center!
CE:set_influx(1e-9, 0.649282*1e-3, -0.3343175*1e-3, -0.0076*1e-3, 0.0, endTime)


domainDisc = DomainDiscretization(approxSpace)
domainDisc:add(CE)

-- some tuning for speed
assTuner = domainDisc:ass_tuner()

-- create time discretization
timeDisc = ThetaTimeStep(domainDisc)
timeDisc:set_theta(1.0)

-- create operator from discretization
linOp = AssembledLinearOperator(timeDisc)


------------------
-- solver setup	--
------------------
-- linear solver --
linConvCheck = CompositeConvCheck(approxSpace, 20, 2e-26, 1e-08)
linConvCheck:set_component_check("v", 1e-21, 1e-12)
linConvCheck:set_verbose(verbose)

ilu = ILU()
linSolver = LinearSolver()
linSolver:set_preconditioner(ilu)
linSolver:set_convergence_check(linConvCheck)

-------------------
-- time stepping --
-------------------
time = 0.0

-- init solution (equilibrium)
u = GridFunction(approxSpace)
b = GridFunction(approxSpace)
u:set(v_eq)

-- prepare measurement point and write first measurement
spineCoords = {1.12205e-4, 1.2571e-5, -8e-7}
spinePos = MakeVec(spineCoords[1], spineCoords[2], spineCoords[3]) -- some arbitrary dendrite vertex pos

measFileVm = outputPath .. "meas/vm_" .. string.format("%.5f", time) .. ".dat"
measOutVm = assert(io.open(measFileVm, "w"))
vm_at_spine = EvaluateAtClosestVertex(spinePos, u, "v", "dend", dom:subset_handler())
-- VDCC_BG_VM2UG expects voltages in mV
measOutVm:write(spineCoords[1], "\t", spineCoords[2], "\t", spineCoords[3], "\t", 1e3*vm_at_spine, "\n")
measOutVm:close()

-- write start solution
-- NOTE: subdirectory "vtk" needs to exist in output path
if generateVTKoutput then 
	out = VTKOutput()
	out:print(outputPath.."vtk/solution", u, 0, time)
end

-- store grid function in vector of old solutions
uOld = u:clone()
solTimeSeries = SolutionTimeSeries()
solTimeSeries:push(uOld, time)

min_dt = 1e-10
curr_dt = dt
dtred = 2

lv = 0
cb_counter = {}
cb_counter[lv] = 0
while endTime-time > 0.001*curr_dt do
		-- setup time disc for old solutions and timestep
	timeDisc:prepare_step(solTimeSeries, curr_dt)
	
	-- reduce time step if cfl < curr_dt
	-- (this needs to be done AFTER prepare_step as channels are updated there)
	dtChanged = false
	cfl = CE:estimate_cfl_cond(solTimeSeries:latest())
	if cfl < min_dt then
		print("Required time step size is lower than admissible. Aborting.")
		break
	end
	print("estimated CFL condition: dt < " .. cfl)
	while (curr_dt > cfl) do
		curr_dt = curr_dt/dtred
		lv = lv + 1
		cb_counter[lv] = 0
		print("estimated CFL condition: dt < " .. cfl .. " - reducing time step to " .. curr_dt)
		dtChanged = true
	end
	
	-- increase time step if cfl > curr_dt / dtred (and if time is aligned with new bigger step size)
	while curr_dt*dtred < cfl and lv > 0 and cb_counter[lv] % (dtred) == 0 do
		curr_dt = curr_dt*dtred
		lv = lv - 1
		cb_counter[lv] = cb_counter[lv] + cb_counter[lv+1]/dtred
		cb_counter[lv+1] = 0
		print ("estimated CFL condition: dt < " .. cfl .. " - increasing time step to " .. curr_dt)
		dtChanged = true
	end
	
	print("++++++ POINT IN TIME " .. math.floor((time+curr_dt)/curr_dt+0.5)*curr_dt .. " BEGIN ++++++")
	
	-- prepare again with new time step size
	if dtChanged == true then 
		timeDisc:prepare_step(solTimeSeries, curr_dt)
	end

	-- assemble linear problem
	matrixIsConst = time ~= 0.0 and dtChanged == false
	assTuner:set_matrix_is_const(matrixIsConst)
	AssembleLinearOperatorRhsAndSolution(linOp, u, b)
	
	-- apply linear solver
	ilu:set_disable_preprocessing(matrixIsConst)
	if ApplyLinearSolver(linOp, u, b, linSolver) == false then
		print("Could not apply linear solver.")
		if (generateVTKoutput) then 
			out:write_time_pvd(outputPath.."vtk/solution", u) 
		end
		exit()
	end
	
	-- update to new time
	time = solTimeSeries:time(0) + curr_dt
	
	-- log vm and calcium at soma
	if math.abs(time/dt - math.floor(time/dt+0.5)) < 1e-5 then
		measFileVm = outputPath .. "meas/vm_" .. string.format("%.5f", time) .. ".dat"
		measOutVm = assert(io.open(measFileVm, "w"))
		vm_at_spine = EvaluateAtClosestVertex(spinePos, u, "v", "dend", dom:subset_handler())
		-- VDCC_BG_VM2UG expects voltages in mV
		measOutVm:write(spineCoords[1], "\t", spineCoords[2], "\t", spineCoords[3], "\t", 1e3*vm_at_spine, "\n")
		measOutVm:close()
	end
	
	-- vtk output
	if generateVTKoutput then 
		if math.abs(time/pstep - math.floor(time/pstep+0.5)) < 1e-5 then
			out:print(outputPath.."vtk/solution", u, math.floor(time/pstep+0.5), time)
		end
	end
	
	-- updte time series (reuse memory)
	oldestSol = solTimeSeries:oldest()
	VecScaleAssign(oldestSol, 1.0, u)
	solTimeSeries:push_discard_oldest(oldestSol, time)
	
	-- increment check-back counter
	cb_counter[lv] = cb_counter[lv] + 1

	print("++++++ POINT IN TIME " .. math.floor((time)/curr_dt+0.5)*curr_dt .. "  END ++++++")
end

-- end timeseries, produce gathering file
if generateVTKoutput then 
	out:write_time_pvd(outputPath.."vtk/solution", u) 
end

	
