#!/bin/bash
# Run OpenROAD flow for Voyager FDS
# Usage: docker run -v $(pwd)/..:/work openroad/flow-scripts bash /work/flow/run.sh

set -e
cd /OpenROAD-flow-scripts/flow

# Copy our design files
cp /work/voyager_fds_sky130.v designs/sky130hd/voyager_fds/voyager_fds.v 2>/dev/null || true
mkdir -p designs/sky130hd/voyager_fds

cat > designs/sky130hd/voyager_fds/config.mk << 'CONF'
export DESIGN_NAME = voyager_fds
export PLATFORM    = sky130hd
export VERILOG_FILES = $(DESIGN_HOME)/$(PLATFORM)/voyager_fds/voyager_fds.v
export SDC_FILE      = $(DESIGN_HOME)/$(PLATFORM)/voyager_fds/constraint.sdc
export CORE_UTILIZATION = 40
export PLACE_DENSITY    = 0.5
CONF

cat > designs/sky130hd/voyager_fds/constraint.sdc << 'SDC'
create_clock [get_ports clk] -name clk -period 1000.0
set_input_delay  -clock clk 0 [all_inputs]
set_output_delay -clock clk 0 [all_outputs]
SDC

cp /work/voyager_fds_sky130.v designs/sky130hd/voyager_fds/voyager_fds.v

# Run the full flow: synthesis check → floorplan → place → CTS → route → finish
echo "=== VOYAGER FDS: RTL to GDS ==="
echo "=== The computer that left the solar system ==="
make DESIGN_CONFIG=designs/sky130hd/voyager_fds/config.mk

echo ""
echo "=== DONE ==="
echo "GDS at: results/sky130hd/voyager_fds/6_final.gds"
echo "Copy it out: cp results/sky130hd/voyager_fds/6_final.gds /work/"
