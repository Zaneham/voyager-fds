# OpenROAD flow configuration for Voyager FDS
# The computer that left the solar system, on SKY130.

export DESIGN_NAME = voyager_fds
export PLATFORM    = sky130hd

# Source files
export VERILOG_FILES = ../voyager_fds_sky130.v

# Clock: 1 MHz (the original ran at 806.4 kHz)
export CLOCK_PERIOD = 1000.0
export CLOCK_PORT   = clk

# Die area: 100um x 100um is plenty for 628 gates
export DIE_AREA    = 0 0 100 100
export CORE_AREA   = 5 5 95 95

# Utilisation: 50% (plenty of room for routing)
export CORE_UTILIZATION = 50
export PLACE_DENSITY    = 0.6
