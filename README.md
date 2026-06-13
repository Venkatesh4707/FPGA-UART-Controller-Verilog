# FPGA UART Controller — Verilog HDL + Python Automation

**Author:** P. Venkatesh Sagar  
**Date:** June 2026  
**Tools:** Verilog HDL · ModelSim · Xilinx Vivado · Python (pyserial)

---

## Overview

A fully functional, synthesisable **full-duplex UART (Universal Asynchronous Receiver-Transmitter)** controller implemented in Verilog HDL. Includes a self-checking simulation testbench and a Python-based automated loopback test suite.

### Key Features
- Full-duplex Tx and Rx operation
- Configurable baud rate via `CLKS_PER_BIT` parameter
- Frame format: 1 Start bit | 8 Data bits | 1 Stop bit (8N1)
- Double flip-flop synchronizer in RX to prevent metastability
- Stop bit error detection
- Self-checking testbench with **256-byte full sweep** (0x00–0xFF)
- Python automation script for hardware loopback validation

---

## Project Structure

```
FPGA-UART-Controller-Verilog/
├── rtl/
│   ├── uart_tx.v          # UART Transmitter FSM
│   └── uart_rx.v          # UART Receiver FSM
├── tb/
│   └── uart_tb.v          # Self-checking loopback testbench
├── python/
│   └── uart_loopback_test.py  # Automated hardware test (pyserial)
├── sim/
│   └── (waveform screenshots)
└── README.md
```

---

## Block Diagram

```
          ┌─────────────┐      tx_line      ┌─────────────┐
tx_data ──►  uart_tx     ├──────────────────►  uart_rx     ├──► rx_data
tx_start──►  (FSM)       │   Serial Stream   │  (FSM)      │
          └─────────────┘                   └─────────────┘
               │                                   │
            tx_done                             rx_done
            tx_busy                             rx_error
```

---

## UART Frame Format

```
Idle  Start   D0   D1   D2   D3   D4   D5   D6   D7  Stop  Idle
 1  |  0   |  x  |  x  |  x  |  x  |  x  |  x  |  x  |  x  |  1  |  1
          LSB                                             MSB
```

---

## How to Simulate (ModelSim)

```tcl
# Compile
vlog rtl/uart_tx.v rtl/uart_rx.v tb/uart_tb.v

# Simulate
vsim uart_tb

# Run
run -all
```

---

## How to Simulate (Xilinx Vivado)

1. Create new project → Add `rtl/uart_tx.v`, `rtl/uart_rx.v`
2. Add simulation source: `tb/uart_tb.v`
3. Set `uart_tb` as top simulation module
4. Run Behavioral Simulation → Observe waveforms

---

## Configuring Baud Rate

```verilog
// Formula: CLKS_PER_BIT = Clock_Frequency / Baud_Rate
// 50 MHz clock, 115200 baud:
uart_tx #(.CLKS_PER_BIT(434)) u_tx ( ... );

// 100 MHz clock, 9600 baud:
uart_tx #(.CLKS_PER_BIT(10416)) u_tx ( ... );
```

---

## Python Hardware Test

```bash
# Install dependency
pip install pyserial

# Run loopback test (connect TX pin to RX pin on hardware)
python python/uart_loopback_test.py --port COM3 --baud 115200

# Linux
python python/uart_loopback_test.py --port /dev/ttyUSB0 --baud 115200
```

**Expected output:**
```
==================================================
  UART Automated Loopback Test
  Author: P. Venkatesh Sagar
==================================================
  PASS | 0x00 - 0x0F verified
  PASS | 0x10 - 0x1F verified
  ...
  RESULTS: 256 PASSED | 0 FAILED
  ALL 256 BYTES VERIFIED — UART WORKING CORRECTLY
==================================================
```

---

## Testbench Results

| Test | Description | Result |
|------|-------------|--------|
| Key values | 0x00, 0xFF, 0xAA, 0x55, 0xA5 | PASS |
| Full sweep | All 256 values (0x00–0xFF) | PASS |
| Loopback | TX output directly connected to RX input | PASS |

---

## Skills Demonstrated

- RTL design using FSM-based Verilog HDL
- UART protocol implementation (start/data/stop bit timing)
- Metastability prevention (double flip-flop synchronizer)
- Self-checking testbench with automated pass/fail reporting
- Python-based hardware validation using pyserial
- Parameterised design for reusability
