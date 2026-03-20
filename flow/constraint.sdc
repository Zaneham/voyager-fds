create_clock [get_ports clk] -name clk -period 1000.0
set_input_delay  -clock clk 0 [all_inputs]
set_output_delay -clock clk 0 [all_outputs]
