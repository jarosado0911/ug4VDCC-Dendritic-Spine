--------------------------------------------------------------------------------
-- This script will create a .ugx file from various other neuronal file       --
-- formats, namely:                                                           --
--   - SWC                                                                    --
--   - HOC (might not be fully supported)                                     --
--   - TXT, NGX (as exported from NeuGen)                                     --
--                                                                            --
-- Author: Markus Breit                                                       --
-- Date:   2015-09-07                                                         --
--------------------------------------------------------------------------------

ug_load_script("ug_util.lua")

-- set debug level
GetLogAssistant():set_debug_level("NETI_DID.import_geometry", 6)
GetLogAssistant():set_debug_level("NETI_DID.generate_grid", 6)

-- get the default geometry importer
neti = NeuronalTopologyImporter()

-- base name
baseName = util.GetParam("-name", "testNetwork")
-- import
method = util.GetParam("-method", "txt")

if method == "hoc" or method == "ngx" then
	--[[
	-- for import of bAP cells
	--neti:add_joining_criterion("Rad_thick_prox")
	--neti:add_joining_criterion("Rad_thick_med")
	--neti:add_joining_criterion("Rad_thick_dist")
	--neti:add_joining_criterion("Rad_thin")
	neti:add_joining_criterion("Rad")
	--neti:add_joining_criterion("L_M_thick")
	--neti:add_joining_criterion("L_M_med")
	--neti:add_joining_criterion("L_M_thin")
	neti:add_joining_criterion("L_M")
	neti:add_joining_criterion("soma")
	--neti:add_joining_criterion("basal_prox")
	--neti:add_joining_criterion("basal_dist")
	neti:add_joining_criterion("basal")
	neti:add_joining_criterion("hill")
	neti:add_joining_criterion("iseg")
	neti:add_joining_criterion("inode")
	--neti:add_joining_criterion("node")
	--]]
	---[[
	neti:add_joining_criterion("soma")
	neti:add_joining_criterion("dend")
	neti:add_joining_criterion("apic")
	neti:add_joining_criterion("axon")
	--]]
end

neti:import_geometry_and_generate_grid(baseName, method)

