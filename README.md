# Simple SPI RAM controller

A simple verilog SPI RAM controller.  Designed primarily to demonstrate my [RP2040 SPI RAM emulation](https://github.com/MichaelBell/spi-ram-emu), this is a very simple SPI RAM controllwer that transfers one word of data at a time.

The word size and address size are configurable on the spi_ram_controller module.

The module clocks the SPI at the input clock rate - the SPI clock is the input clock inverted.  Note that one negative edge triggered flip flop is required to read the incoming data at the correct time.