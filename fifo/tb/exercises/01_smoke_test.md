# Layer 1 — cocotb smoke test (beginner-friendly)

> Read every section in order. It's deliberately verbose — this is your first cocotb test ever.

## Goal

Write `fifo/tb/test_fifo_smoke.py` — one `@cocotb.test()` function that resets the DUT and confirms the FIFO comes up empty.

## The five things you need to understand about cocotb

1. **A test is a coroutine.** You write `async def my_test(dut): ...` and decorate it with `@cocotb.test()`. cocotb runs it.

2. **`dut` is your handle to the DUT.** `dut.<signal_name>.value = N` writes a signal. `dut.<signal_name>.value` reads it. Names match the Verilog port names exactly (`clk`, `rst_n`, `empty`, etc.).

3. **Signal writes are queued.** This is the gotcha. When you do `dut.rst_n.value = 0`, the simulator doesn't actually see it yet — the write is buffered. It only gets applied the next time you `await` *anything* (a clock edge, a timer, etc.). So if you write a signal and then immediately read another signal, you're reading stale state. **Rule of thumb: after every write, `await` something before you read.**

4. **Triggers make you wait.**
   - `await RisingEdge(dut.clk)` — wait for the next rising edge of the clock.
   - `await FallingEdge(dut.clk)` — wait for the next falling edge.
   - `await Timer(N, unit="ns")` — wait N ns of simulation time.

5. **The Clock helper drives `clk` for you.** You start it once at the top of the test and forget about it. After this line, `clk` toggles 0/1/0/1/... forever in the background — **you do not drive it manually**:
   ```python
   cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
   ```
   (`10` is the period in ns. `cocotb.start_soon` says "run this coroutine in the background.")

## The DUT in 30 seconds

Look at `fifo/dut/fifo.v` for the port list. For this test you care about three signals:

| Signal | Direction | Meaning |
|---|---|---|
| `clk` | in | clock (the Clock helper drives this) |
| `rst_n` | in | **active-low** reset: 0 = reset asserted, 1 = normal operation |
| `empty` | out | 1 when FIFO has no data, 0 otherwise |
| `full` | out | 1 when FIFO is at capacity, 0 otherwise |

After you assert reset (drive `rst_n=0`), hold it for a couple of cycles, then deassert (drive `rst_n=1`), the FIFO should be empty. So `empty=1` and `full=0`.

## The recipe (do these in order)

1. Start the clock (one line — see snippet below).
2. Apply reset:
   - a. Drive `rst_n = 0`.
   - b. Wait two clock edges (so reset is held for ≥1 full cycle).
   - c. Drive `rst_n = 1`.
   - d. Wait one more clock edge (so the deassertion settles in the simulator).
3. Read `dut.empty` and assert it matches the contract above.
4. Read `dut.full` and assert it matches the contract above.

That's the whole test — about 10 lines of body code.

## Reference snippets — cocotb plumbing only

You can copy these patterns. The *content* of your asserts is yours to write.

Imports:
```python
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
```

Start the clock:
```python
cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
```

Wait for a clock edge:
```python
await RisingEdge(dut.clk)
```

Drive a signal and let it propagate:
```python
dut.rst_n.value = 0
await RisingEdge(dut.clk)   # <-- this is what makes the simulator apply the write
```

Read a signal as a Python int:
```python
int(dut.empty.value)
```

## What to assert

After your reset sequence is done:

- What value should `dut.empty` have? (Look at the contract table above.)
- What value should `dut.full` have? (Same.)

Write two `assert ... == ...` statements that check these. Use `int(dut.empty.value)` on the left side so you're comparing Python ints.

## How to run

From `fifo/tb/`, with the venv active:

```sh
make COCOTB_TEST_MODULES=test_fifo_smoke
```

Acceptance: the last line of output reads `TESTS=1 PASS=1 FAIL=0`.

## Common errors and what they mean

- **`Cannot convert Logic('X') to int`** — the signal you read is `X` (unknown). For DUT outputs this almost always means reset wasn't applied properly: either you didn't `await` between driving `rst_n` and reading the output, or you didn't hold reset long enough.

- **`Cannot convert Logic('Z') to int`** — high-impedance, similar root cause to X for our DUT (uninitialized).

- **Test hangs / no output** — somewhere you forgot to `await` and you're spinning. Ctrl-C, read the traceback.

- **`AttributeError: ...has no attribute 'foo'`** — signal name mismatch. Compare your `dut.foo` to the Verilog port list.

- **`assert int(dut.empty.value) == 0` fails with `1 != 0`** — your assertion has the polarity wrong. Re-read the contract.

## When you're ready

Save `fifo/tb/test_fifo_smoke.py`, run `make COCOTB_TEST_MODULES=test_fifo_smoke`, and either:

- it passes — say "ready" and I'll review the code, or
- it fails — paste the error and I'll point you at the issue without giving the fix.
