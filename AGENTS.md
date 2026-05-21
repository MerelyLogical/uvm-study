# UVM Study — Curriculum

> Living document. Original plan: 2026-05-20. Revised 2026-05-21 (Phase 1 complete; FIFO project promoted).

## Context

Strong RTL/design background; goal is fluency in UVM — the component model, phasing/factory/TLM machinery, and the *mindset* around constrained-random verification (CRV). No EDA Playground, no commercial SV simulators. Python + cocotb is on the table. Depth target: **read & reason about UVM code**.

The pivot: **PyUVM** (Ray Salemi) is a faithful Python reimplementation of UVM running on cocotb + a free open-source Verilog simulator. Same factory, phases, sequences, sequencers, drivers, monitors, scoreboards, config_db, TLM ports, virtual sequences — written in Python, structurally identical to SV UVM. For *reading* SV UVM (the industry artifact), lean on curated open-source SV testbenches; reading doesn't require executing.

## Toolchain (one-time local setup on macOS — DONE)

```sh
brew install icarus-verilog verilator
/opt/homebrew/opt/python@3.13/bin/python3.13 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install cocotb pyuvm cocotb-test
```

Installed: Icarus 13.0, Verilator 5.048, cocotb 2.0.1, pyuvm 4.0.1. See [README.md](./README.md) for per-session activation.

RTL is written in Verilog/SV; verification is written in Python/PyUVM. The simulator runs the DUT; PyUVM runs the testbench; cocotb glues them.

## Collaboration mode (Claude ↔ user)

This is a **learning project**, not a delivery project. Division of labor:

- **Claude writes**: build infrastructure (Makefiles, repo scaffolding, .gitignore), the DUT/RTL (user has a design background — re-deriving RTL isn't the learning target), and short reference snippets *only when explicitly asked* "how does X work?"
- **User writes**: every piece of verification code — drivers, monitors, scoreboards, sequences, coverage models, the tests themselves. Also any CRV drill code.
- **Per layer**: Claude writes an exercise spec under `fifo/tb/exercises/NN_layer.md` (contract to verify, in-scope APIs, pitfalls). User implements. Claude reviews — bugs, idiom violations, missed edge cases. Hints when stuck, not solutions.

Established 2026-05-21 after Claude over-wrote a directed cocotb test. The rule is: before writing any verification code, Claude asks "is this the user's job to write?"

## ✅ Phase 1 — UVM mental model (COMPLETE)

Read Part of UVM Cookbook. Class hierarchy, phase flow, factory, TLM, sequence/sequencer/driver handshake are internalized. Move on.

Keep as on-demand reference:
- UVM Cookbook (Siemens / Verification Academy) — chapters not yet read.
- ChipVerify UVM tutorial — for quick terminology lookups.

## 📦 Phase 2 — CRV mechanics (DEMOTED to reference)

Originally a separate phase of pure-Python drills. Demoted because CRV intuition sharpens faster *in context* of a real testbench than in isolated drills. Read these *when you hit a question*, not upfront:

- UVM Cookbook chapters on *Randomization* and *Sequences*.
- Sutherland's *SystemVerilog for Verification* (Chris Spear) Ch. 6 — canonical CRV chapter.

Mindset to absorb (and keep absorbing through Phase 3): you are not writing *test cases*, you are writing *a generator and a contract*. The solver is your adversary trying to violate your scoreboard; constraints shape *where* it searches.

## 🚧 Phase 3 — FIFO project with PyUVM (CURRENT)

Goal: touch every UVM component shape exactly once in a setting small enough to fit in your head. **Build incrementally** — each step should leave you with a runnable, passing test before moving on.

DUT: synchronous parameterized FIFO, FWFT-style (read-data is valid whenever `!empty`; `rd_en` consumes the head).

### Build layers (in order)

| # | Layer | Files | What you learn |
|---|---|---|---|
| 1 | **RTL** (warmup) | `fifo/dut/fifo.v` | familiar territory — soft entry into the project's dev loop without new tools |
| 2 | **Directed cocotb test** | `fifo/tb/test_fifo_directed.py`, `fifo/tb/Makefile` | cocotb wiring, signal access, clock generation, basic await idioms. No PyUVM yet. |
| 3 | **PyUVM hello-world test** | `fifo/tb/test_fifo_uvm.py` | `uvm_test`, `run_phase`, raise/drop objections, `run_test()` entry point |
| 4 | **Transaction + sequencer + driver + agent** | `fifo/tb/fifo_pkg.py` | seq_item API, driver `get_next_item`/`item_done` loop, sequencer-driver handshake |
| 5 | **Monitor + analysis port** | (same) | passive sampling, broadcast pattern |
| 6 | **Scoreboard** | (same) | Python `deque` as reference model. **Inject a bug** in the RTL (e.g., off-by-one on `full`) and confirm the scoreboard catches it. |
| 7 | **Sequences** | (same) | `write_only_seq`, `read_only_seq`, `random_seq`, `virtual_seq` orchestrating them |
| 8 | **Coverage** | (same) | functional bins on occupancy + b2b read/write. Run random tests until 100%; notice which bins are hard and tune constraints. |
| 9 | **Factory override** | (same) | derived test swaps in a "naughty" driver that injects protocol violations |

Stop and reflect at each step. The point isn't speed.

## Phase 4 — SV UVM reading fluency (parallel/ongoing)

Reading doesn't require running. Pick *one* well-written open source SV UVM env and study it end-to-end:

- **Accellera UVM 1.2 examples** (github.com/accellera-official/uvm) — `examples/simple/` and `examples/integrated/ubus/`.
- **UVM Cookbook code samples** — small, focused, well-commented.
- **OpenTitan testbenches** (lowRISC) — production-grade. Pick one block-level env (e.g., `hw/ip/uart/dv`) and trace it.

Reading protocol: redraw the agent/env/test diagram for each studied TB. If the diagram comes out clean, you've understood it.

## What to skip (for now)

- `uvm_reg` (register layer) — defer until after the FIFO project.
- Callbacks and `uvm_event` — rarely needed in modern UVM, mostly legacy.
- UVM-SystemC / UVM-e — irrelevant for these goals.

## Verification (how to know it's working)

- ✅ Phase 1: done (interview passed).
- Phase 3, layer 2: `make` in `fifo/tb/` runs the directed cocotb test against the FIFO and passes.
- Phase 3, layer 6: deliberately-bugged FIFO is caught by the scoreboard.
- Phase 3, layer 8: random test closes coverage.
- Phase 4: pick a UVM env on GitHub at random and within ~30 min identify agent boundaries, sequence types, scoreboard model, and analysis port topology.

## Repo layout

```
uvm-study/
  notes/              # ad-hoc reading notes (UVM Cookbook excerpts, etc.)
  crv-drills/         # optional pure-Python CRV drills (Phase 2, on-demand)
  fifo/               # Phase 3 project
    dut/fifo.v
    tb/
      Makefile
      test_fifo_directed.py
      test_fifo_uvm.py
      fifo_pkg.py
  reading-log/        # Phase 4 diagrams + notes on SV envs studied
```
