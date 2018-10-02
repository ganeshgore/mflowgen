#=========================================================================
# post_signoff.tcl
#=========================================================================
# This plug-in script is called after the corresponding Innovus flow step

# Write SDF for back-annotated gate-level simulation

write_sdf $vars(results_dir)/$vars(design).sdf

# Write netlist for LVS
#
# Exclude physical cells that have no devices in them (or else LVS will
# have issues). Specifically for filler cells, the extracted layout will
# not have any trace of the fillers because there are no devices in them.
# Meanwhile, the schematic generated from the netlist will show filler
# cells instances with VDD/VSS ports, and this will cause LVS to flag a
# "mismatch" with the layout.

# FIXME: This list should be refactored into stdcells.tcl

set lvs_exclude_list "[dbGet -u -e top.physInsts.cell.name FILL*] \
                      [dbGet -u -e top.physInsts.cell.name TAPCELL*] \
                      [dbGet -u -e top.physInsts.cell.name PAD80LU_OBV] \
                      [dbGet -u -e top.physInsts.cell.name PCORNER] \
                      [dbGet -u -e top.physInsts.cell.name PFILLER*] \
                      [dbGet -u -e top.physInsts.cell.name PRCUT]"

saveNetlist -excludeLeafCell -phys -excludeCellInst $lvs_exclude_list $vars(results_dir)/$vars(design).lvs.v

# Write netlist for Virtuoso simulation
#
# This is the same as the lvs netlist but does not have decaps to speed up
# simulation.

set virtuoso_exclude_list "[dbGet -u -e top.physInsts.cell.name FILL*] \
                           [dbGet -u -e top.physInsts.cell.name TAPCELL*] \
                           [dbGet -u -e top.physInsts.cell.name PAD80LU_OBV] \
                           [dbGet -u -e top.physInsts.cell.name PCORNER] \
                           [dbGet -u -e top.physInsts.cell.name PFILLER*] \
                           [dbGet -u -e top.physInsts.cell.name PRCUT] \
                           [dbGet -u -e top.physInsts.cell.name DCAP*]"

saveNetlist -excludeLeafCell -phys -excludeCellInst $virtuoso_exclude_list $vars(results_dir)/$vars(design).virtuoso.v

# Write netlist for GL simulation

saveNetlist -excludeLeafCell $vars(results_dir)/$vars(design).vcs.v

# Write LEF for hierarchical bottom-up design

write_lef_abstract -specifyTopLayer $vars(max_route_layer) \
                   -PGPinLayers {4 5}                      \
                   -noCutObs -stripePin                    \
                   $vars(results_dir)/$vars(design).lef

# Save DEF for use in running DC again

defOut $vars(results_dir)/$vars(design).def.gz
