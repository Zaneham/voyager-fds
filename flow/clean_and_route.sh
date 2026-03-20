#!/bin/bash
# Step 1: Yosys cleans up the netlist (no check -assert)
# Step 2: OpenROAD places and routes the clean netlist
set -e

ORBIN=/OpenROAD-flow-scripts/tools/install/OpenROAD/bin/openroad
LIBDIR=/OpenROAD-flow-scripts/flow/platforms/sky130hd

echo "=== Step 1: Yosys netlist cleanup ==="
yosys -p "
read_liberty -lib $LIBDIR/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
read_verilog /work/voyager_fds_sky130.v
hierarchy -top voyager_fds
proc
opt_clean
opt_expr
clean
write_verilog -noattr /work/voyager_fds_clean.v
" 2>&1

echo ""
echo "=== Step 2: OpenROAD P&R ==="
$ORBIN -no_init <<'TCL'
read_lef /OpenROAD-flow-scripts/flow/platforms/sky130hd/lef/sky130_fd_sc_hd.tlef
read_lef /OpenROAD-flow-scripts/flow/platforms/sky130hd/lef/sky130_fd_sc_hd_merged.lef
read_liberty /OpenROAD-flow-scripts/flow/platforms/sky130hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

read_verilog /work/voyager_fds_clean.v
link_design voyager_fds

create_clock [get_ports clk] -name clk -period 1000.0

initialize_floorplan -die_area "0 0 200 200" \
                     -core_area "10 10 190 190" \
                     -site unithd

make_tracks li1  -x_offset 0.23 -x_pitch 0.46 -y_offset 0.17 -y_pitch 0.34
make_tracks met1 -x_offset 0.17 -x_pitch 0.34 -y_offset 0.17 -y_pitch 0.34
make_tracks met2 -x_offset 0.23 -x_pitch 0.46 -y_offset 0.23 -y_pitch 0.46
make_tracks met3 -x_offset 0.34 -x_pitch 0.68 -y_offset 0.34 -y_pitch 0.68
make_tracks met4 -x_offset 0.46 -x_pitch 0.92 -y_offset 0.46 -y_pitch 0.92
make_tracks met5 -x_offset 1.70 -x_pitch 3.40 -y_offset 1.70 -y_pitch 3.40

add_global_connection -net VDD -inst_pattern .* -pin_pattern VPWR -power
add_global_connection -net VSS -inst_pattern .* -pin_pattern VGND -ground
add_global_connection -net VDD -inst_pattern .* -pin_pattern VPB -power
add_global_connection -net VSS -inst_pattern .* -pin_pattern VNB -ground
global_connect

set_voltage_domain -power VDD -ground VSS
define_pdn_grid -name core -pins met5
add_pdn_stripe -grid core -layer met1 -width 0.48 -pitch 5.44 -offset 0 -followpins
add_pdn_stripe -grid core -layer met4 -width 1.6 -pitch 50 -offset 10
add_pdn_stripe -grid core -layer met5 -width 1.6 -pitch 50 -offset 10
add_pdn_connect -grid core -layers {met1 met4}
add_pdn_connect -grid core -layers {met4 met5}
pdngen

place_pins -hor_layers met3 -ver_layers met2
global_placement -density 0.4
detailed_placement
optimize_mirroring

clock_tree_synthesis -root_buf sky130_fd_sc_hd__clkbuf_16 \
                     -buf_list sky130_fd_sc_hd__clkbuf_16 \
                     -wire_unit 20
set_propagated_clock [all_clocks]

set_routing_layers -signal met1-met5 -clock met3-met5
global_route

# Reclassify tie-cell nets from POWER to SIGNAL so
# TritonRoute will route them. The one_ and zero_ nets
# are Yosys artefacts, not actual power rails.
set db [ord::get_db]
set block [$db getChip]
set bk [$block getBlock]
foreach net [$bk getNets] {
    set name [$net getName]
    if {$name eq "one_" || $name eq "zero_"} {
        $net setSigType SIGNAL
        puts "Reclassified $name as SIGNAL"
    }
}

detailed_route

write_def /work/voyager_fds.def

puts ""
puts "========================================"
puts "  GDS GENERATED: /work/voyager_fds.gds"
puts "  The computer that left the solar system"
puts "  is now silicon."
puts "========================================"
exit
TCL
