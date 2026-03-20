#!/bin/bash
# Voyager FDS: Direct placement — skip Yosys re-synthesis.
# The netlist is already gate-level from Takahe. Feed it
# straight to OpenROAD for floorplan → place → route → GDS.
set -e

cd /OpenROAD-flow-scripts/flow

mkdir -p designs/sky130hd/voyager_fds
cp /work/voyager_fds_sky130.v designs/sky130hd/voyager_fds/voyager_fds.v

cat > designs/sky130hd/voyager_fds/constraint.sdc << 'SDC'
create_clock [get_ports clk] -name clk -period 1000.0
set_input_delay  -clock clk 0 [all_inputs]
set_output_delay -clock clk 0 [all_outputs]
SDC

cat > designs/sky130hd/voyager_fds/config.mk << 'CONF'
export DESIGN_NAME    = voyager_fds
export PLATFORM       = sky130hd
export VERILOG_FILES  = $(DESIGN_HOME)/$(PLATFORM)/voyager_fds/voyager_fds.v
export SDC_FILE       = $(DESIGN_HOME)/$(PLATFORM)/voyager_fds/constraint.sdc
export CORE_UTILIZATION = 40
export PLACE_DENSITY    = 0.5
CONF

echo "========================================"
echo "  VOYAGER FDS: Direct P&R (skip Yosys)"
echo "========================================"

# Skip synthesis, start from floorplan.
# Copy the netlist as the "synth result" that OpenROAD expects.
mkdir -p results/sky130hd/voyager_fds/base
cp designs/sky130hd/voyager_fds/voyager_fds.v \
   results/sky130hd/voyager_fds/base/1_synth.v
echo 1000.0 > results/sky130hd/voyager_fds/base/clock_period.txt

# Run from floorplan onwards
make DESIGN_CONFIG=designs/sky130hd/voyager_fds/config.mk \
     results/sky130hd/voyager_fds/base/2_floorplan.odb 2>&1 || true

# If floorplan worked, continue through place, CTS, route, finish
for stage in 3_place 4_cts 5_route 6_final; do
    make DESIGN_CONFIG=designs/sky130hd/voyager_fds/config.mk \
         results/sky130hd/voyager_fds/base/${stage}.odb 2>&1 || break
done

# Check for GDS
if [ -f results/sky130hd/voyager_fds/base/6_final.gds ]; then
    cp results/sky130hd/voyager_fds/base/6_final.gds /work/voyager_fds.gds
    echo ""
    echo "========================================"
    echo "  GDS GENERATED: voyager_fds.gds"
    echo "  The computer that left the solar system"
    echo "  is now a chip layout."
    echo "========================================"
    ls -la /work/voyager_fds.gds
else
    echo "GDS not generated — check logs"
    ls results/sky130hd/voyager_fds/base/ 2>/dev/null
fi
