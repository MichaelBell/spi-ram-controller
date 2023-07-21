# Simple SPI RAM controller

A verilog SPI RAM controller, for use with SPI flash or RAM chips, such as the [23LC512](https://ww1.microchip.com/downloads/aemDocuments/documents/MPD/ProductDocuments/DataSheets/23A512-23LC512-512-Kbit-SPI-Serial-SRAM-with-SDI-and-SQI-Interface-20005155C.pdf).  Designed primarily to demonstrate my [RP2040 SPI RAM emulation](https://github.com/MichaelBell/spi-ram-emu), this is a very simple SPI RAM controller that transfers one word of data at a time.

The word size and address size are configurable on the spi_ram_controller module.

The module clocks the SPI at the input clock rate - the SPI clock is the input clock inverted.  Note that one negative edge triggered flip flop is required to sample the incoming data at the correct time.
