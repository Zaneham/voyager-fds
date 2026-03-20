# Voyager FDS: direct OpenROAD TCL script
# Bypasses ORFS Makefile — feeds gate-level Verilog straight
# to OpenROAD for floorplan → place → route → GDS.
#
# The computer that left the solar system, becoming silicon.

# Read technology
read_lef /OpenROAD-flow-scripts/flow/platforms/sky130hd/lef/sky130_fd_sc_hd.tlef
read_lef /OpenROAD-flow-scripts/flow/platforms/sky130hd/lef/sky130_fd_sc_hd_merged.lef
read_liberty /OpenROAD-flow-scripts/flow/platforms/sky130hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

# Read the gate-level netlist from Takahe
read_verilog /work/voyager_fds_sky130.v
link_design voyager_fds

# Read timing constraints
read_sdc /work/flow/constraint.sdc

# Floorplan: 200um x 200um (generous for 628 gates)
initialize_floorplan -die_area "0 0 200 200" \
                     -core_area "10 10 190 190" \
                     -site unithd

# Define routing tracks (required for pin placement)
make_tracks li1   -x_offset 0.23 -x_pitch 0.46  -y_offset 0.17 -y_pitch 0.34
make_tracks met1  -x_offset 0.17 -x_pitch 0.34  -y_offset 0.17 -y_pitch 0.34
make_tracks met2  -x_offset 0.23 -x_pitch 0.46  -y_offset 0.23 -y_pitch 0.46
make_tracks met3  -x_offset 0.34 -x_pitch 0.68  -y_offset 0.34 -y_pitch 0.68
make_tracks met4  -x_offset 0.46 -x_pitch 0.92  -y_offset 0.46 -y_pitch 0.92
make_tracks met5  -x_offset 1.70 -x_pitch 3.40  -y_offset 1.70 -y_pitch 3.40

# Place I/O pins
place_pins -hor_layers met3 -ver_layers met2

# Global placement
global_placement -density 0.4

# Detailed placement
detailed_placement
optimize_mirroring

# Clock tree synthesis
clock_tree_synthesis -root_buf sky130_fd_sc_hd__clkbuf_16 \
                     -buf_list sky130_fd_sc_hd__clkbuf_16 \
                     -wire_unit 20
set_propagated_clock [all_clocks]

# Add power/ground network
add_global_connection -net VDD -inst_pattern .* -pin_pattern VPWR -power
add_global_connection -net VSS -inst_pattern .* -pin_pattern VGND -ground
add_global_connection -net VDD -inst_pattern .* -pin_pattern VPB -power
add_global_connection -net VSS -inst_pattern .* -pin_pattern VNB -ground
global_connect

# Power distribution
set_voltage_domain -power VDD -ground VSS
define_pdn_grid -name core_grid -pins met5
add_pdn_stripe -grid core_grid -layer met1 -width 0.48 -pitch 5.44 -offset 0 -followpins
add_pdn_stripe -grid core_grid -layer met4 -width 1.6 -pitch 50 -offset 10
add_pdn_stripe -grid core_grid -layer met5 -width 1.6 -pitch 50 -offset 10
add_pdn_connect -grid core_grid -layers {met1 met4}
add_pdn_connect -grid core_grid -layers {met4 met5}
pdngen

# Global routing
set_routing_layers -signal met1-met5 -clock met3-met5
global_route

# Detailed routing
detailed_route

# Write outputs
write_def /work/voyager_fds.def
write_verilog /work/voyager_fds_final.v
write_gds /work/voyager_fds.gds

puts ""
puts "========================================"
puts "  VOYAGER FDS GDS GENERATED"
puts "  The computer that left the solar system"
puts "  is now a chip layout at /work/voyager_fds.gds"
puts "========================================"
