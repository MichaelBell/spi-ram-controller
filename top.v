module spi_demo_top (
    input clk12MHz,
    input rstn,

    input spi_miso,
    output spi_select,
    output spi_clk_out,
    output spi_mosi,

    output led1,
    output led2,
    output led3,
    output led4,
    output led5,
    output led6,
    output led7,
    output led8,
    output lcol1,
    output lcol2,
    output lcol3,
    output lcol4);

    reg [15:0] spi_addr;
    

    // map the output of ledscan to the port pins
    wire [7:0] leds_out;
    wire [3:0] lcol;
    assign { led8, led7, led6, led5, led4, led3, led2, led1 } = leds_out[7:0];
    assign { lcol4, lcol3, lcol2, lcol1 } = lcol[3:0];

    LedScan scan (
                .clk12MHz(clk12MHz),
                .leds1(data[31:24]),
                .leds2(data[23:16]),
                .leds3(data[15:8]),
                .leds4(data[7:0]),
                .leds(leds_out),
                .lcol(lcol)
        );

endmodule