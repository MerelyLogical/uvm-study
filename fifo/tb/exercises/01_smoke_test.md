# Layer 1 — cocotb smoke test

Goal: write `fifo/tb/test_fifo_smoke.py` — the tiniest possible cocotb test that confirms the simulator, cocotb, the Makefile, and the DUT all wire up and that reset works. **One** `@cocotb.test()`, ~25 lines of Python.

You're not verifying FIFO behavior here. You're verifying that the *plumbing* works before investing real test logic on top of it.

## What to verify

After holding `rst_n` low for a couple of clock cycles and then releasing it high:

- `empty == 1`
- `full == 0`

That's it. One assert pair.

## In-scope cocotb APIs

You need (and shouldn't need anything beyond):

- `import cocotb`
- `from cocotb.clock import Clock` — start a 10 ns clock with `cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())`
- `from cocotb.triggers import RisingEdge` — `await RisingEdge(dut.clk)` to step a cycle
- `dut.<signal>.value = N` to drive, `int(dut.<signal>.value)` to read
- `@cocotb.test()` on an `async def` taking `dut`
- `assert`

## Pitfalls specific to this layer

1. **Reset polarity**: `rst_n` is **active-low**. Drive `0` to assert, `1` to deassert.
2. **Initial X**: before reset, all flops in the DUT are `x`. Driving inputs and waiting one edge of reset isn't enough — hold `rst_n=0` for ≥1 full clock cycle, *then* release.
3. **Sampling immediately after the edge**: after `await RisingEdge(dut.clk)`, signals have just transitioned. If you check `empty` on the same `await` that releases reset, you might catch a stale value. Easiest fix: do one more `await RisingEdge(dut.clk)` before asserting.
4. **`int(...)` wrap**: `dut.empty.value` is a cocotb `BinaryValue`, not a Python int. `dut.empty.value == 1` works but is fragile; `int(dut.empty.value) == 1` is safer.

## How to run

See [the README — Running tests](../../../README.md#running-tests). For just this layer, `make COCOTB_TEST_MODULES=test_fifo_smoke` will run only your file (the default in the Makefile is still `test_fifo_directed`, which doesn't exist yet).

Or update the Makefile's `COCOTB_TEST_MODULES ?= test_fifo_directed` default to `test_fifo_smoke` while you're working on this layer.

## Acceptance

- `make COCOTB_TEST_MODULES=test_fifo_smoke` ends with `TESTS=1 PASS=1 FAIL=0`.

## Stretch (only if curious)

- Add a second `@cocotb.test()` that holds reset and confirms `empty==1` doesn't depend on `wr_en` being low first (i.e., reset dominates).
- That's already getting into "directed test" territory — save it for Layer 2.

## When you're ready

Say "ready" and I'll review. I'll look for: idiom slips, missed pitfalls, anything that wouldn't scale to the directed tests in Layer 2.
