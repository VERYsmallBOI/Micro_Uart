# Micro-UART

A parameterized Verilog implementation of a **Micro UART (Universal Asynchronous Receiver/Transmitter)** supporting configurable baud rates and data widths using the standard **8N1 UART frame format**.

---

# Project Structure

```text
.
├── docs
│   ├── test_plan.md
│   └── verification_report.md
├── src
│   ├── Design
│   │   ├── baud.v
│   │   ├── inc.h
│   │   ├── u_rec.v
│   │   ├── u_xmit.v
│   │   └── uart.v
│   └── TestBench
│       └── tESTBENCH.v
```

---

# What is UART?

**UART (Universal Asynchronous Receiver/Transmitter)** is a hardware communication interface used for asynchronous serial communication.

Unlike protocols such as SPI or I2C, UART does not use a shared clock signal between transmitter and receiver. Instead, both sides agree beforehand on a common **baud rate**.

Typical baud rates include:

- 1200
- 2400
- 9600
- 19200

UART communication is asynchronous, meaning timing synchronization is achieved through agreed transmission timing and start-bit detection.

---

# UART Frame Format

This implementation follows the **8N1 UART format**:

| Field | Description |
|---|---|
| Start Bit | 1 bit, always `0` |
| Data Bits | Configurable (6–8 bits, default 8) |
| Parity | None |
| Stop Bit | 1 bit, always `1` |

Idle line state remains logic `1`.

Example frame:

```text
Idle  Start   Data Bits         Stop
 1      0     D0 D1 D2 ...      1
```

---

# Features

- Parameterized data width (6–8 bits)
- Configurable baud rates
- Separate UART transmitter and receiver modules
- 16× oversampling receiver synchronization
- 8N1 UART frame support
- Verilog RTL implementation
- Testbench included

---

# Supported Baud Rates

| Baud Rate |
|---|
| 1200 |
| 2400 (default) |
| 9600 |
| 19200 |

---

# Oversampling and Synchronization

The UART receiver internally operates at:

```text
16 × Baud Rate
```

This allows accurate sampling of incoming serial data.

The receiver:

1. Detects the falling edge of the start bit
2. Synchronizes to the incoming frame
3. Samples each bit at the center of the bit period
4. Uses the 8th tick of the 16× clock for center sampling

This improves reliability against timing mismatches and noise.

---

# Top Module Pins

## Inputs

| Signal | Width | Description |
|---|---|---|
| `sys_clk` | 1 | Main system clock |
| `sys_rst_l` | 1 | Active-low reset |
| `xmitH` | 1 | Active-high transmit start pulse |
| `xmit_dataH` | Parameterized | Parallel transmit data |
| `uart_REC_dataH` | 1 | Serial receive input |

---

## Outputs

| Signal | Width | Description |
|---|---|---|
| `uart_XMIT_dataH` | 1 | Serial transmit output |
| `xmit_doneH` | 1 | Transmission complete indicator |
| `rec_dataH` | Parameterized | Received parallel data |
| `rec_readyH` | 1 | Receiver ready indicator |
| `xmit_active` | 1 | Transmitter active status |
| `rec_busy` | 1 | Receiver busy status |

---

# Module Description

## `uart.v`

Top-level UART module integrating:

- UART transmitter
- UART receiver
- Baud rate generator

---

## `u_xmit.v`

UART transmitter module responsible for:

- Serializing parallel input data
- Generating UART frame
- Managing transmit timing

---

## `u_rec.v`

UART receiver module responsible for:

- Start-bit detection
- Oversampling synchronization
- Serial-to-parallel conversion
- Receive status handling

---

## `baud.v`

Generates internal baud timing clocks used by:

- Transmitter
- Receiver oversampling logic

---

## `inc.h`

Contains project-wide:

- Parameters
- Macros
- Configuration definitions

---

# Verification

Testbench and verification collateral are available under:

```text
src/TestBench/
```

Files:

| File | Description |
|---|---|
| `TESTBENCH.v` | Main UART testbench |


Documentation:

| File | Description |
|---|---|
| `docs/test_plan.md` | Verification strategy and testcases |
| `docs/verification_report.md` | Verification results and observations |

---

# Simulation

Example using Icarus Verilog:

```bash
iverilog -o uart_tb \
src/Design/*.v \
src/TestBench/*.v

vvp uart_tb
```

Generate waveform:

```bash
iverilog -o uart_tb \
src/Design/*.v \
src/TestBench/*.v

vvp uart_tb

gtkwave dump.vcd
```

---

# Default Configuration

| Parameter | Default Value |
|---|---|
| Data Width | 8 bits |
| Baud Rate | 2400 |
| Frame Format | 8N1 |
| Oversampling | 16× |

---

# Applications

- Embedded systems
- FPGA serial communication
- Debug interfaces
- Microcontroller communication
- ASIC UART integration
- Educational UART design/reference

---

# Future Improvements

- Parity support
- FIFO buffering
- Configurable stop bits
- Interrupt support
- AXI/APB wrapper integration
- Error detection flags

---

# Author
*TAMIL SELVAN E*
Micro-UART Design and Verification Project.