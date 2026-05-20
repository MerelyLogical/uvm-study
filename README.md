# uvm-study

Learn me some good UVM with Python.

A local-only UVM study repo. Curriculum lives in [`AGENTS.md`](./AGENTS.md).

## Quick start

```sh
# One-time toolchain install (macOS)
brew install icarus-verilog verilator
/opt/homebrew/opt/python@3.13/bin/python3.13 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install cocotb pyuvm cocotb-test
```

> Python 3.13 is pinned because cocotb does not yet ship wheels for 3.14. If you already have Python 3.13 elsewhere, point `python -m venv` at it.

## Every-session activation

```sh
source .venv/bin/activate
```

Sanity check the toolchain:

```sh
iverilog -V | head -1
verilator --version | head -1
python -c "import cocotb, pyuvm; print(cocotb.__version__, pyuvm.__version__)"
```

## Running tests

All cocotb-based projects in this repo follow the same pattern: `cd` into the project's `tb/` directory and `make`.

```sh
# from any <project>/tb/ directory, with venv active
make                                        # run all tests in the default module
make clean && make                          # clean rebuild (use if behavior looks stale)
make COCOTB_TEST_FILTER=test_reset_state    # run a single test (regex match on test name)
make COCOTB_TEST_MODULES=test_fifo_uvm      # override which python module holds the tests
python -m py_compile <file>.py              # syntax-check a python test without running sim
```

Debug tips that apply to any cocotb test:

- The pass/fail summary at the end of `make` is your scoreboard — `FAIL=0` means green.
- On failure, scroll up: the traceback shows the exact `assert` that fired with the offending value.
- `dut.<signal>.value` returns a `BinaryValue`-ish object — wrap with `int(...)` before comparing to a Python int, otherwise you'll get truthy/falsy surprises on multi-bit signals.
- If the sim hangs, you forgot to advance the clock somewhere (missing `await RisingEdge(dut.clk)`). Ctrl-C and look for awaits.
- cocotb 2.x prefers `unit=` (singular) over `units=` on `Clock` and `Timer`.

## Layout

```
notes/        # Phase 1 reading notes
crv-drills/   # Phase 2 small Python exercises
fifo/         # Phase 3 PyUVM project (sync FIFO DUT + testbench)
reading-log/  # Phase 4 notes on SV UVM environments studied
AGENTS.md     # Curriculum (read this first)
```
