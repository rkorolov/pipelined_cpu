# Create work library
vlib work

# Compile Verilog
#     All Verilog files that are part of this design should have
#     their own "vlog" line below.
#vlog *.sv
vlog alu.sv
vlog control.sv
vlog cpu.sv
vlog d_flip_flop.sv
vlog datamem.sv
vlog decoder.sv
vlog execute.sv
vlog flag_register.sv
vlog full_adder.sv
vlog instruction_decode.sv
vlog instruction_fetch.sv
vlog instructmem.sv
vlog math.sv
vlog multi_bit_adder.sv
vlog mux.sv
vlog nor.sv
vlog operand_fetch.sv
vlog reg64.sv
vlog regfile.sv
vlog sign_extend.sv
vlog xor.sv
vlog pipeline_registers.sv
vlog forwarding_unit.sv
vlog hazard_detection.sv


# Call vsim to invoke simulator
#     Make sure the last item on the line is the name of the
#     testbench module you want to execute.
vsim -voptargs="+acc" -t 1ps -lib work cpu_testbench

# Source the wave do file
#     This should be the file that sets up the signal window for
#     the module you are testing.
do cpu_wave.do

# Set the window types
view wave
view structure
view signals

# Run the simulation
run -all

# End
