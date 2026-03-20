#!/bin/bash
# Voyager FDS: RTL to GDS via OpenROAD
# The computer that left the solar system, becoming silicon.
set -e

DESIGN_DIR=/OpenROAD-flow-scripts/flow/designs/sky130hd/voyager_fds
mkdir -p $DESIGN_DIR

# Copy the gate-level netlist
cp /work/voyager_fds_sky130.v $DESIGN_DIR/voyager_fds.v

# Create config
cat > $DESIGN_DIR/config.mk << 'CONF'
export DESIGN_NAME    = voyager_fds
export PLATFORM       = sky130hd
export VERILOG_FILES  = $(DESIGN_HOME)/$(PLATFORM)/voyager_fds/voyager_fds.v
export SDC_FILE       = $(DESIGN_HOME)/$(PLATFORM)/voyager_fds/constraint.sdc
export CORE_UTILIZATION = 40
export PLACE_DENSITY    = 0.5
CONF

# Create timing constraints
cat > $DESIGN_DIR/constraint.sdc << 'SDC'
create_clock [get_ports clk] -name clk -period 1000.0
set_input_delay  -clock clk 0 [all_inputs]
set_output_delay -clock clk 0 [all_outputs]
SDC

echo "========================================"
echo "  VOYAGER FDS: RTL to GDS"
echo "  628 gates → silicon"
echo "  The computer that left the solar system"
echo "========================================"

cd /OpenROAD-flow-scripts/flow
make DESIGN_CONFIG=$DESIGN_DIR/config.mk

echo ""
echo "=== DONE ==="
ls -la results/sky130hd/voyager_fds/6_final.gds 2>/dev/null && \
    cp results/sky130hd/voyager_fds/6_final.gds /work/voyager_fds.gds && \
    echo "GDS copied to /work/voyager_fds.gds" || \
    echo "Check results/ for output files"
