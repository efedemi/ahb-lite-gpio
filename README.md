# AHB-Lite GPIO Peripheral (SystemVerilog)

[![sim](https://github.com/efedemi/ahb-lite-gpio/actions/workflows/ci.yml/badge.svg)](https://github.com/efedemi/ahb-lite-gpio/actions/workflows/ci.yml)

A zero-wait-state **AHB-Lite slave** that exposes a small memory-mapped register
block driving/reading GPIO pins. AHB-Lite is the bus the **APEX** SoC used to
hang peripherals off its ARM Cortex-M0 — this is a clean standalone slave that
implements the AHB address/data pipeline correctly.

## Register map

| Offset | Name | Access | Function |
|---|---|---|---|
| `0x00` | `DATA_OUT` | R/W | drives the `gpio_out` pins |
| `0x04` | `DATA_IN` | RO | reads the `gpio_in` pins |
| `0x08` | `DIR` | R/W | direction register (1 = output) |

## AHB-Lite slave port

`HSEL`, `HADDR`, `HWRITE`, `HTRANS`, `HWDATA`, `HREADY` in; `HRDATA`,
`HREADYOUT`, `HRESP` out. `HREADYOUT` is tied high (zero wait states) and `HRESP`
is always OKAY.

## Simulate

```bash
iverilog -g2012 -o sim.out rtl/ahb_lite_gpio.sv tb/ahb_lite_gpio_tb.sv
vvp sim.out            # an AHB master drives writes/reads, 6/6 self-checking
```

The testbench is a small AHB-Lite master: it writes each register, reads it back,
checks the physical `gpio_out`/`gpio_dir` pins, and reads external `gpio_in`.

## Design notes

- **Address/data pipeline.** AHB transfers are two-phase: the address, control,
  and `HSEL`/`HTRANS` are sampled in the *address phase* and registered; the
  write data (`HWDATA`) and read data (`HRDATA`) belong to the following *data
  phase*. The captured address (`addr_q`) is what indexes the register in the
  data phase.
- **Transfer qualification.** A transfer is only accepted when
  `HSEL & HREADY & HTRANS[1]` — i.e. the slave is selected, the bus is ready, and
  the transfer is NONSEQ/SEQ (not IDLE/BUSY).
- **Zero wait states.** `HREADYOUT = 1` keeps the register block single-cycle;
  inserting waits would just mean holding it low.
- **Read mux on the registered address** (as a net, not a procedural
  part-select) keeps the data-phase read combinational and simulator-clean.

## Related
- [apex-safety-fsm](https://github.com/efedemi/apex-safety-fsm) ·
  [fpga-qos-scheduler](https://github.com/efedemi/fpga-qos-scheduler) ·
  [uart-core](https://github.com/efedemi/uart-core) ·
  [mac-accelerator](https://github.com/efedemi/mac-accelerator)

---
*Built by Efe Demir.*
