# cocotb runner for the directed FIFO test.
#
# From this directory:
#     make            # run the default (directed) test under Icarus
#     make clean      # remove sim_build/, results.xml
#
# Once a PyUVM test exists, override the test module on the command line:
#     make COCOTB_TEST_MODULES=test_fifo_uvm

SIM           ?= icarus
TOPLEVEL_LANG ?= verilog

DUT_DIR := $(abspath ../dut)

VERILOG_SOURCES     := $(DUT_DIR)/fifo.v
COCOTB_TOPLEVEL     := fifo
COCOTB_TEST_MODULES ?= test_fifo_directed

COCOTB_HDL_TIMEUNIT      := 1ns
COCOTB_HDL_TIMEPRECISION := 1ps

include $(shell cocotb-config --makefiles)/Makefile.sim
