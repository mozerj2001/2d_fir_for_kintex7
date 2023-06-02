`timescale 1ns / 1ps
`default_nettype none

// HISTOGRAM CALCULATOR
// 
// Reads input address port A of a dual port block ram, increments it and
// writes the modified value back on the B port a clk later.
// Input reset signal only resets the reset counter, the RAM values must be
// reset by the i_reset_histogram input (after detection, the address counter
// will go through all values of the address with write enabled and 0 on the
// input). During reset, i_valid must be driven low.
//
// The histogram can simply be read by directly addressing the RAM module via
// the i_addr input.

module histogram_calc #(
        DATA_WIDTH = 32,
        DEPTH = 256,
        ADDR_WIDTH = $clog2(DEPTH)
    )(
        input wire              clk,
        input wire              rst,
        input wire [7:0]        i_addr,
        input wire              i_valid,
        input wire              i_reset_histogram,
        output wire [31:0]      o_data
    );

    // Increment read value, write zero when input is not valid.
    wire [31:0] w_curr_val;
    reg [31:0] r_next_val;

    always @ (posedge clk)
    begin
        if(i_valid) begin
            r_next_val <= w_curr_val + 1;
        end else begin
            r_next_val <= 32'b0;
        end
    end

    // Reset state machine and write logic.
    wire w_rst_addr_cntr;
    reg [ADDR_WIDTH-1:0] r_addr_cntr;
    reg r_rst_hist;
    wire [ADDR_WIDTH-1:0] w_wr_addr;

    always @ (posedge clk)
    begin
        if(rst) begin
            r_rst_hist <= 1'b0;
        end else if(i_reset_histogram) begin
            r_rst_hist <= 1'b1;
        end else if(w_rst_addr_cntr) begin
            r_rst_hist <= 1'b0;
        end
    end

    always @ (posedge clk)
    begin
        if(rst) begin
            r_addr_cntr <= 0;
        end else if(r_rst_hist) begin
            r_addr_cntr <= r_addr_cntr + 1;
        end
    end

    assign w_rst_addr_cntr = &r_addr_cntr;
    assign w_wr_addr = r_rst_hist ? r_addr_cntr : i_addr;


    reg r_wr_en;
    always @ (posedge clk)
    begin
        if(i_valid | r_rst_hist) begin
            r_wr_en <= 1'b1;
        end else begin
            r_wr_en <= 1'b0;
        end
    end

    // DUAL PORT BLOCK RAM
    dp_blockram #(
        .DEPTH(DEPTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) u_dpbram (
        .clk_a(clk),
        .we_a(),
        .en_a(1'b1),
        .addr_a(i_addr),
        .din_a(),
        .dout_a(w_curr_val),
        .clk_b(clk),
        .we_b(r_wr_en),
        .en_b(1'b1),
        .addr_b(w_wr_addr),
        .din_b(r_next_val),
        .dout_b()
    );

    assign o_data = w_curr_val;


endmodule
