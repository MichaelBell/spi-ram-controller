/* Copyright 2023 (c) Michael Bell

   A simple SPI RAM controller
   
   To perform a read:
   - Set addr_in and set start_read high for 1 cycle
   - Wait for busy to go low
   - The read data is now available on data_out

   To perform a write:
   - Set addr_in, data_in and set start_write high for 1 cycle
   - Wait for busy to go low before starting another operation

   If the controller is configured to transfer multiple bytes, then
   note that the word transferred in data_in/data_out is in big
   endian order, i.e. the byte with the lowest address is aligned to 
   the MSB of the word. 
   */
module spi_ram_controller #(parameter DATA_WIDTH_BYTES=4, parameter ADDR_BITS=16) (
    input clk,
    input rstn,

    // External SPI interface
    input  spi_miso,
    output spi_select,
    output spi_clk_out,
    output spi_mosi,

    // Internal interface for reading/writing data
    input [ADDR_BITS-1:0]           addr_in,
    input [DATA_WIDTH_BYTES*8-1:0]  data_in,
    input                           start_read,
    input                           start_write,
    output [DATA_WIDTH_BYTES*8-1:0] data_out,
    output                          busy
);

`ifdef COCOTB_SIM
initial begin
  $dumpfile ("spi.vcd");
  $dumpvars (0, spi_ram_controller);
  #1;
end
`endif

    localparam DATA_WIDTH_BITS = DATA_WIDTH_BYTES * 8;

    localparam FSM_IDLE = 0;
    localparam FSM_CMD  = 1;
    localparam FSM_ADDR = 2;
    localparam FSM_DATA = 3;

    reg [1:0] fsm_state;
    reg writing;
    reg spi_miso_buf;
    reg [ADDR_BITS-1:0]       addr;
    reg [DATA_WIDTH_BITS-1:0] data;
    reg [$clog2($max(DATA_WIDTH_BITS,ADDR_BITS))-1:0] bits_remaining;

    assign data_out = data;
    assign busy = fsm_state != FSM_IDLE;

    always @(posedge clk) begin
        if (!rstn) begin
            fsm_state <= FSM_IDLE;
            bits_remaining <= 0;
        end else begin
            if (fsm_state == FSM_IDLE) begin
                if (start_read || start_write) begin
                    fsm_state <= FSM_CMD;
                    bits_remaining <= 8-1;
                end
            end else begin
                if (bits_remaining == 0) begin
                    fsm_state <= fsm_state + 1;
                    if (fsm_state == FSM_CMD)       bits_remaining <= ADDR_BITS-1;
                    else if (fsm_state == FSM_ADDR) bits_remaining <= DATA_WIDTH_BITS-1;
                end else begin
                    bits_remaining <= bits_remaining - 1;
                end
            end
        end
    end

    always @(posedge clk) begin
        if (fsm_state == FSM_IDLE && (start_read || start_write)) begin
            addr <= addr_in;
            writing <= start_write;
        end else if (fsm_state == FSM_ADDR) begin
            addr <= {addr[ADDR_BITS-2:0], 1'b0};
        end
    end

    always @(negedge clk) begin
        spi_miso_buf <= spi_miso;
    end

    always @(posedge clk) begin
        if (fsm_state == FSM_IDLE && start_write) begin
            data <= data_in;
        end else if (fsm_state == FSM_DATA) begin
            data <= {data[DATA_WIDTH_BITS-2:0], spi_miso_buf};
        end
    end

    assign spi_select = fsm_state == FSM_IDLE;
    assign spi_clk_out = !clk;

    assign spi_mosi = fsm_state == FSM_IDLE ? 1'b0 :
                      fsm_state == FSM_CMD  ? (bits_remaining == 1 || (bits_remaining == 0 && !writing)) :
                      fsm_state == FSM_ADDR ? addr[ADDR_BITS-1] :
                                              data[DATA_WIDTH_BITS-1];

endmodule