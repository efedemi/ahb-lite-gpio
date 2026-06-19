# AHB-Lite GPIO — simulation shortcuts
SRC := rtl/ahb_lite_gpio.sv tb/ahb_lite_gpio_tb.sv

sim:          ## Compile + run the self-checking testbench
	iverilog -g2012 -o sim.out $(SRC)
	vvp sim.out

wave: sim     ## Run, then open waveforms in GTKWave
	gtkwave ahb_lite_gpio.vcd

clean:
	rm -f sim.out *.vcd *.log

.PHONY: sim wave clean
