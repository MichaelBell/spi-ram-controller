# Makefile
# See https://docs.cocotb.org/en/stable/quickstart.html for more info

# defaults
SIM ?= icarus
TOPLEVEL_LANG ?= verilog

VERILOG_SOURCES += $(PWD)/spi.v
COMPILE_ARGS    += -DSIM

TOPLEVEL = spi_ram_controller

# MODULE is the basename of the Python test file
MODULE = test_spi

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim
