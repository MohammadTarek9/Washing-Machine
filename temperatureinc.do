vlib work

vlog +cover=bcst temperature_incrementor_lut.v temperature_incrementor_tb.v

vsim -c -coverage work.temperature_incrementor_tb.v

run -all

coverage report -details -output coverage_report.txt