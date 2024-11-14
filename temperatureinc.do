vlib
work
vlog temperature_incrementor_lut.sv temperature_incrementor_tb.sv +cover
covercells
vsim
voptargs =+acc work.temperature_incrementor_tb cover
add wave *
coverage save temperature_incrementor_tb.ucdb
onexit
run
all
