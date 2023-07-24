module spi_demo_top (
    input clk12MHz,
    input rstn,

    input spi_miso,
    output spi_select,
    output spi_clk_out,
    output spi_mosi,

    input button1,   // When pressed, increases time between read operations
    input button2,   // When pressed, writes data to the SPI RAM instead of reading it
    input button3,   // When pressed, increments address by 1 each cycle instead of 4

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

    reg [23:0] counter;
    reg [15:0] spi_addr;
    wire [31:0] spi_data_out;
    wire [31:0] spi_data_in = {spi_addr, counter[23:8]};

    reg [31:0] data;

    reg spi_start_read;
    reg spi_start_write;
    reg spi_read_done;
    wire busy;

    spi_ram_controller spi (
                .clk(clk12MHz),
                .rstn(rstn),

                .spi_miso(spi_miso),
                .spi_select(spi_select),
                .spi_clk_out(spi_clk_out),
                .spi_mosi(spi_mosi),

                .addr_in(spi_addr),
                .data_in(spi_data_in),
                .start_read(spi_start_read),
                .start_write(spi_start_write),
                .data_out(spi_data_out),
                .busy(busy)
        );

    always @(posedge clk12MHz) begin
        if (!rstn) begin
            spi_addr <= 0;
            counter <= 0;
            spi_start_read <= 0;
            spi_start_write <= 0;
            spi_read_done <= 0;
            data <= 1;
        end else begin
            counter <= counter + 1;
            if (!button2) begin
                spi_start_read <= 0;
                spi_read_done <= 0;
                spi_addr[1:0] <= 0;
                if (!busy && counter[7:0] == 0 && spi_addr[1:0] == 0) begin
                    spi_start_write <= 1;
                    spi_addr <= spi_addr + 4;
                end else begin
                    spi_start_write <= 0;
                end
            end else begin
                spi_start_write <= 0;
                if ((button1 ? (counter[15:0] == 0) : (counter[22:0] == 0)) && !busy) begin
                    spi_start_read <= 1;
                    spi_read_done <= 0;
                    spi_addr <= spi_addr + (button3 ? 4 : 1);
                end else begin
                    spi_start_read <= 0;
                    if (!busy && !spi_read_done) begin
                        spi_read_done <= 1;
                        data <= spi_data_out;
                    end
                end
            end
        end
    end

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
