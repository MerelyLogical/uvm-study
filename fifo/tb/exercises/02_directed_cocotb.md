# Layer 2 — Directed cocotb test (no PyUVM yet)

Goal: write `fifo/tb/test_fifo_directed.py` that verifies the FIFO DUT's behavioral contract using **cocotb only**. The point is to internalize cocotb idioms (clock, await, value access, `@cocotb.test()`) before the PyUVM layer adds its own machinery on top.

## The contract (what the DUT promises)

The DUT is at `fifo/dut/fifo.v`. Read its header comment for full detail. Summary:

- After `rst_n` goes low for ≥1 cycle then high, the FIFO is **empty**, **not full**.
- FWFT: when `empty` is low, `rd_data` is already the head value; `rd_en` for one cycle **consumes** it (head advances on the next rising edge).
- A write with `wr_en` while `full` is high is **silently dropped** — contents must not be corrupted.
- A read with `rd_en` while `empty` is high is **silently ignored** — pointers must not move.
- FIFO order: values come out in the order they went in.

Design your own test plan from this contract. Aim for ≥4 distinct `@cocotb.test()` functions, each verifying one property.

## In-scope cocotb APIs

You will need (and should not need much beyond):

- `import cocotb`
- `from cocotb.clock import Clock` — `Clock(dut.clk, period, unit="ns").start()` returned a coroutine; spawn it with `cocotb.start_soon(...)`.
- `from cocotb.triggers import RisingEdge, FallingEdge, Timer` — `await RisingEdge(dut.clk)` etc.
- Signal access: `dut.sig.value = N` to drive, `int(dut.sig.value)` to read.
- `@cocotb.test()` decorator on `async def` functions taking `dut`.
- Standard Python `assert` for checks.

The DUT's `DEPTH` parameter is exposed indirectly: `len(dut.mem)` gives you 16.

## Pitfalls specific to this layer

1. **Sampling output on the wrong edge**: if you read `rd_data` on a rising edge while also driving `rd_en` on the same edge, you may sample the *next* head, not the current one. Prefer sampling on `FallingEdge(dut.clk)` (mid-cycle, stable) or *before* asserting the strobe.
2. **Forgetting to deassert strobes**: a one-cycle pulse means `wr_en = 1` *then `await RisingEdge` then* `wr_en = 0`. If you leave `wr_en = 1` you'll keep writing every cycle.
3. **Reset that doesn't reset**: drive `rst_n = 0`, hold for ≥1 clock, then `rst_n = 1`. Also clear the input strobes during reset so they don't fire on the first post-reset edge.
4. **FWFT off-by-one**: easy to write a "pop" helper that returns the *next* value instead of the current one. Read the contract again — what is `rd_data` showing right *now*, before you assert `rd_en`?

See [the project README](../../../README.md#running-tests) for generic cocotb run commands and debug tips.

Acceptance: every test you write passes; `make` shows `FAIL=0`.

## Stretch (optional)

- Add a test that interleaves push and pop and confirms FIFO order across the interleave.
- Add a test that reads while empty and confirms `empty` stays high and no garbage propagates.
- Try inserting an obvious bug in `fifo.v` (e.g., change `wr_ptr + 1'b1` to `wr_ptr + 2'd2`) and confirm your tests catch it. Revert when done.

## When you're ready

Push the file (or just say "ready") and I'll review. I'll point out idiom slips, missed edge cases, or anything that would bite you when we add the PyUVM layer on top.
