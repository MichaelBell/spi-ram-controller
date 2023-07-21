import random

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, ClockCycles, RisingEdge, FallingEdge

async def do_start(spi):
    clock = Clock(spi.clk, 4, units="ns")
    cocotb.start_soon(clock.start())
    spi.rstn.value = 0
    spi.addr_in.value = 0
    spi.data_in.value = 0
    spi.start_read.value = 0
    spi.start_write.value = 0
    await ClockCycles(spi.clk, 2)
    spi.rstn.value = 1
    assert spi.spi_select.value == 1
    await ClockCycles(spi.clk, 30)
    assert spi.spi_select.value == 1

async def expect_spi_cmd(spi, addr, cmd):
    for i in range(8):
        await RisingEdge(spi.spi_clk_out)
        assert spi.spi_select.value == 0
        assert spi.spi_mosi.value == (1 if (cmd & (0x80 >> i)) != 0 else 0)

    # Address after reset is 0.
    for i in range(16):    
        await RisingEdge(spi.spi_clk_out)
        assert spi.spi_select.value == 0
        assert spi.spi_mosi.value == (1 if (addr & (0x8000 >> i)) != 0 else 0)

async def do_read(spi, addr, data):
    spi.addr_in.value = addr
    spi.start_read.value = 1
    await ClockCycles(spi.clk, 1)
    spi.start_read.value = 0
    await Timer(1, "ns")
    assert spi.busy.value == 1
    
    await expect_spi_cmd(spi, addr, 3)
    for d in data:
        for i in range(8):
            assert spi.busy.value == 1
            await FallingEdge(spi.spi_clk_out)
            assert spi.spi_select.value == 0
            spi.spi_miso.value = (1 if (d & (0x80 >> i)) != 0 else 0)

    await ClockCycles(spi.clk, 1)
    await Timer(1, "ns")
    assert spi.spi_select.value == 1
    assert spi.busy.value == 0
    assert spi.data_out.value == (data[0] << 24) | (data[1] << 16) | (data[2] << 8) | data[3]

async def do_write(spi, addr, data):
    spi.addr_in.value = addr
    spi.data_in.value = (data[0] << 24) | (data[1] << 16) | (data[2] << 8) | data[3]
    spi.start_write.value = 1
    await ClockCycles(spi.clk, 1)
    spi.start_write.value = 0
    await Timer(1, "ns")
    assert spi.busy.value == 1
    
    await expect_spi_cmd(spi, addr, 2)

    for d in data:
        for i in range(8):
            await RisingEdge(spi.spi_clk_out)
            assert spi.spi_select.value == 0
            assert spi.spi_mosi.value == (1 if (d & (0x80 >> i)) != 0 else 0)

    await ClockCycles(spi.clk, 1)
    await Timer(1, "ns")
    assert spi.spi_select.value == 1
    assert spi.busy.value == 0

@cocotb.test()
async def test_spi(spi):
    await do_start(spi)
    await do_read(spi, 0, [1, 2, 3, 4])
    await do_write(spi, 0, [5, 6, 7, 8])

    for i in range(100):
        addr = random.randint(0, 65536-4)
        data = [random.randint(0, 255), random.randint(0, 255), random.randint(0, 255), random.randint(0, 255)]
        if (random.randint(0, 1) == 0):
            await do_read(spi, addr, data)
        else:
            await do_write(spi, addr, data)
