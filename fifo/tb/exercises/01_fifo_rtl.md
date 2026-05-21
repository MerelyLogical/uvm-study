# Layer 1 — FIFO RTL warmup

Goal: write `fifo/dut/fifo.v` — a synchronous parameterized FIFO. This is the warm-up: same dev loop you're already comfortable with (Verilog + compile), zero new tools, so it's a soft entry into the project before cocotb shows up in Layer 2.

## Required module interface

Use these exact names — Layers 2+ will be written against this interface.

```verilog
module fifo #(
    parameter WIDTH = 8,
    parameter DEPTH = 16    // assume power of 2
) (
    input  wire             clk,
    input  wire             rst_n,      // active-low reset (sync or async, your call)

    input  wire             wr_en,
    input  wire [WIDTH-1:0] wr_data,

    input  wire             rd_en,
    output wire [WIDTH-1:0] rd_data,

    output wire             full,
    output wire             empty
);
```

If you want to deviate (extra ports like `count`, `almost_full`, etc.) — sure, just keep the required ones above.

## Behavioral contract

- After `rst_n` is held low for ≥1 cycle then released high: `empty=1`, `full=0`, pointers cleared.
- **FWFT (first-word-fall-through)**: when `empty=0`, `rd_data` already shows the head value; `rd_en` for one cycle **consumes** it (head advances on the next rising clock edge).
- A `wr_en` pulse while `full=1` is **silently dropped** — contents must not be corrupted.
- A `rd_en` pulse while `empty=1` is **silently ignored** — pointers must not move.
- FIFO order: values come out in the order they went in.
- Simultaneous `wr_en` and `rd_en` in the same cycle when neither full nor empty: both succeed (occupancy unchanged).

## Implementation choices (yours to make)

You'll likely pick one of:

1. **Extra-MSB pointers**: `wr_ptr` and `rd_ptr` are each `$clog2(DEPTH)+1` bits. Empty when they match exactly; full when low bits match but MSBs differ. Compact, classic textbook approach.
2. **Count register**: separate `count` register tracks occupancy, increments on write, decrements on read. Easier to reason about, slightly more area.

Both are fine. Pick the one you find clearer to write.

## Pitfalls to watch

1. **`full` deassertion timing**: easy to assert `full` one cycle too late (after the entry that filled the FIFO has settled). Trace the worst case on paper.
2. **Reset polarity / style**: `rst_n` is active-low. If you go async (`always @(posedge clk or negedge rst_n)`), make sure both sensitivity edges are listed.
3. **Mem read latency**: in FWFT, `rd_data` must be combinatorially driven from `mem[rd_ptr]`. If you accidentally register it, you'll have a 1-cycle latency that the contract doesn't allow.
4. **Don't write when full / don't read when empty**: gate `wr_en` with `!full` and `rd_en` with `!empty` *inside* the FSM logic. Don't trust the caller.
5. **Initial values on power-up**: in simulation, pointers come up as `x` without reset. Always reset before the first test cycle (the test bench will handle this; just make sure your reset clears the pointers).

## Immediate feedback (no test bench yet)

To check the file compiles without errors before Layer 2 exists:

```sh
iverilog -g2012 -o /tmp/fifo_compile fifo/dut/fifo.v && echo OK
```

That'll catch syntax errors, missing semicolons, undeclared signals, etc. Lint-level checks (latches, sensitivity list issues) won't fire — those will be caught when behavior is wrong in Layer 2.

## Acceptance

- `iverilog -g2012 -o /tmp/fifo_compile fifo/dut/fifo.v` compiles clean.
- The module name is `fifo` and the required ports are present with the names above.
- You can articulate which pointer-style you picked and why (I'll ask in review).

## When you're done

Say "ready" and I'll review. I'll look for: contract violations, the listed pitfalls, anything weird that would bite us in Layer 2.
