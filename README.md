# UART Controller — Verilog Implementation

A lightweight, fully synthesizable UART (Universal Asynchronous Receiver-Transmitter) implementation in Verilog, supporting configurable clock frequency and baud rate. Includes a transmitter, receiver, and self-checking testbench.

---

## File Structure

```
├── uart_tx.v      # UART Transmitter
├── uart_rx.v      # UART Receiver
└── uart_tb.v      # Simulation Testbench
```

---

## Protocol Details

This implementation uses the standard **8N1** UART frame format:

```
[IDLE=1] → [START=0] → [D0 D1 D2 D3 D4 D5 D6 D7] → [STOP=1] → [IDLE=1]
           |<-1 bit->| |<-------- 8 bits ---------->| |<-1 bit->|
```

| Parameter     | Value         |
|---------------|---------------|
| Data bits     | 8             |
| Parity        | None          |
| Stop bits     | 1             |
| Bit order     | LSB first     |

---

## Parameters

Both `uart_tx` and `uart_rx` share the same configurable parameters:

| Parameter   | Default      | Description                          |
|-------------|--------------|--------------------------------------|
| `CLK_FREQ`  | `50_000_000` | System clock frequency in Hz (50 MHz)|
| `BAUD_RATE` | `9600`       | Desired baud rate in bits per second |

The bit period is derived automatically:
```
BIT_PERIOD = CLK_FREQ / BAUD_RATE  →  50,000,000 / 9600 = 5208 clock cycles/bit
```

---

## Module: `uart_tx`

Serializes an 8-bit byte and transmits it over the `tx` line.

### Ports

| Port           | Direction | Width | Description                          |
|----------------|-----------|-------|--------------------------------------|
| `clk`          | Input     | 1     | System clock                         |
| `reset`        | Input     | 1     | Synchronous active-high reset        |
| `data_in`      | Input     | 8     | Byte to transmit                     |
| `send_trigger` | Input     | 1     | Pulse high for one cycle to transmit |
| `tx`           | Output    | 1     | Serial output line                   |
| `ready`        | Output    | 1     | High when idle and ready for new data|

### State Machine

```
         send_trigger=1                  all bits sent
  IDLE ──────────────────► START ──────► DATA ──────────► STOP
   ▲                                                         │
   └─────────────────────────────────────────────────────────┘
                         BIT_PERIOD elapsed
```

| State   | Action                                             |
|---------|----------------------------------------------------|
| `IDLE`  | `tx=1`, `ready=1`. Waits for `send_trigger`.       |
| `START` | `tx=0` for one full `BIT_PERIOD`.                  |
| `DATA`  | Sends bits D0–D7 LSB-first, one per `BIT_PERIOD`.  |
| `STOP`  | `tx=1` for one full `BIT_PERIOD`, then back to IDLE.|

---

## Module: `uart_rx`

Samples the `rx` line and reconstructs the 8-bit byte.

### Ports

| Port         | Direction | Width | Description                              |
|--------------|-----------|-------|------------------------------------------|
| `clk`        | Input     | 1     | System clock                             |
| `reset`      | Input     | 1     | Synchronous active-high reset            |
| `rx`         | Input     | 1     | Serial input line                        |
| `data_out`   | Output    | 8     | Received byte                            |
| `data_valid` | Output    | 1     | Pulses high when a valid byte is ready   |

### State Machine

```
        rx=0 detected                  rx=0 confirmed            all bits sampled
  IDLE ─────────────► START ──────────────────────────► DATA ──────────────► STOP
   ▲                    │ rx=1 (glitch)                                         │
   │                    └──────────────────────────────────────────────────────►│
   └───────────────────────────────────────────────────────────────────────────┘
                                  data_valid=1
```

| State   | Action                                                                  |
|---------|-------------------------------------------------------------------------|
| `IDLE`  | `data_valid=0`. Watches for `rx` to go LOW (start bit).                 |
| `START` | Waits `BIT_PERIOD/2` (half-bit delay), then re-samples `rx` to confirm the start bit is genuine and not a glitch. |
| `DATA`  | Samples `rx` at the center of each bit period into a shift register.    |
| `STOP`  | Waits one full `BIT_PERIOD`, then asserts `data_valid=1` and latches `data_out`. |

> **Mid-bit Sampling:** The `BIT_PERIOD/2` wait in the START state is critical. It shifts all subsequent sample points to the **center** of each bit, maximizing noise margin and tolerance to clock drift between TX and RX.

---

## Module: `uart_tb`

A simulation-only testbench that wires the TX and RX modules together in a loopback configuration.

### What it tests

1. Resets both modules for 100 ns.
2. Sends the byte `0x41` (ASCII `'A'`) by pulsing `send_trigger`.
3. Waits for `rx_valid` to assert (reception complete).
4. Compares the received byte against the sent byte and prints `TEST PASSED` or `TEST FAILED`.

### Running the Simulation

Using **Icarus Verilog**:
```bash
iverilog -o uart_sim uart_tb.v uart_tx.v uart_rx.v
vvp uart_sim
```

Using **ModelSim / QuestaSim**:
```bash
vlog uart_tx.v uart_rx.v uart_tb.v
vsim uart_tb
run -all
```

Expected console output:
```
Starting Transmission: Sending 'A' (0x41)...
Reception Complete.
Sent: 0x41 | Received: 0x41
TEST PASSED
```

---

## Instantiation Example

```verilog
uart_tx #(
    .CLK_FREQ(50000000),
    .BAUD_RATE(9600)
) tx_inst (
    .clk(clk),
    .reset(reset),
    .data_in(tx_byte),
    .send_trigger(trigger),
    .tx(tx_line),
    .ready(tx_ready)
);

uart_rx #(
    .CLK_FREQ(50000000),
    .BAUD_RATE(9600)
) rx_inst (
    .clk(clk),
    .reset(reset),
    .rx(rx_line),
    .data_out(rx_byte),
    .data_valid(rx_valid)
);
```

---

## Known Limitations

- **No parity support** — 8N1 only.
- **Single byte at a time** — No FIFO buffering; `send_trigger` should not be re-asserted until `ready` goes high.
- **`clk_count` not reset in STOP state** — In `uart_tx`, the counter is not explicitly zeroed on the STOP→IDLE transition. This does not affect single transmissions but may cause a one-cycle timing offset on back-to-back sends.
- **No overrun/framing error detection** — The receiver does not flag invalid stop bits or data overruns.

---
