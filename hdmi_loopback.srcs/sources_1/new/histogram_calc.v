`timescale 1ns / 1ps
`default_nettype none

// HISTOGRAM CALCULATOR
// 
// Reads input address port A of a dual port block ram, increments it and
// writes the modified value back on the B port a clk later.
// Input reset signal only resets the reset counter, the RAM values must be
// reset by the i_reset_histogram input (after detection, the address counter
// will go through all values of the address with write enabled and 0 on the
// input).
//
// During the histogram reset phase, before their value is set to null, values
// from the last histogram are copied into a second block RAM, that can be
// read from the APB bus. This way the last histogram can always be read,
// unless the module is in a state of r_rst = 1.
//
// The histogram can simply be read by directly addressing the second RAM 
// module via the i_apb_addr input. i_apb_read must be driven high while
// reading, to avoid a histogram reset modifying the read values.

module histogram_calc #(
        DATA_WIDTH = 32,
        DEPTH = 256,
        ADDR_WIDTH = $clog2(DEPTH)
    )(
        input wire                      rst,

        input wire                      hdmi_clk,
        input wire [ADDR_WIDTH-1:0]     i_hdmi_addr,
        input wire                      i_hdmi_valid,

        input wire                      apb_clk,
        input wire [ADDR_WIDTH-1:0]     i_apb_addr,
        input wire                      i_apb_read,

        input wire                      i_hist_rst,

        output wire                     o_ready,        // data can currently be read
        output wire [DATA_WIDTH-1:0]    o_data
    );

    // Registers for read-modify-write operations.
    wire [DATA_WIDTH-1:0]       w_curr_val;
    reg  [DATA_WIDTH-1:0]       r_incr_val;
    reg  [1:0]                  r_del_hdmi_valid;
    reg  [ADDR_WIDTH-1:0]       r_del_hdmi_addr0;
    reg  [ADDR_WIDTH-1:0]       r_del_hdmi_addr1;

    always @ (posedge hdmi_clk)
    begin
        r_incr_val <= w_curr_val + 1;
        r_del_hdmi_valid[0] <= i_hdmi_valid;
        r_del_hdmi_valid[1] <= r_del_hdmi_valid[0];
        r_del_hdmi_addr0 <= i_hdmi_addr;
        r_del_hdmi_addr1 <= r_del_hdmi_addr0;
    end

    // Reset and copy to APB interface RAM. (State register is r_rst.)
    reg                         r_rst;
    reg                         r_rst_del;
    reg  [ADDR_WIDTH-1:0]       r_addr_cntr;
    reg  [ADDR_WIDTH-1:0]       r_addr_cntr_del;
    wire                        w_rst_addr_cntr;
    wire [ADDR_WIDTH-1:0]       w_addr_a;
    wire                        w_wr_b;
    wire [ADDR_WIDTH-1:0]       w_addr_b;
    wire [DATA_WIDTH-1:0]       w_din_b;

    assign w_addr_a = r_rst ? r_addr_cntr : i_hdmi_addr;
    assign w_wr_b = (r_del_hdmi_valid[1] | r_rst);
    assign w_addr_b = r_rst ? r_addr_cntr : r_del_hdmi_addr1;
    assign w_din_b = r_rst ? 31'b0 : r_incr_val;
    

    always @ (posedge hdmi_clk)
    begin
        if(rst) begin
            r_rst <= 1'b0;
        end else if(i_hist_rst) begin
            r_rst <= 1'b1;
        end else if(w_rst_addr_cntr) begin
            r_rst <= 1'b0;
        end

        r_rst_del <= r_rst;
    end

    assign o_ready = ~r_rst;

    always @ (posedge hdmi_clk)
    begin
        if(rst) begin
            r_addr_cntr <= 0;
        end else if(r_rst) begin
            r_addr_cntr <= r_addr_cntr + 1;
        end

        r_addr_cntr_del <= r_addr_cntr;
    end

    assign w_rst_addr_cntr = &r_addr_cntr;


    // DUAL PORT BLOCK RAM --> calc histogram
    dp_blockram #(
        .DEPTH(DEPTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) u_dpbram_hist (
        // Read port --> RMW operand, RMW result during reset
        .clk_a(hdmi_clk),
        .we_a(1'b0),
        .en_a(1'b1),
        .addr_a(w_addr_a),
        .din_a(),
        .dout_a(w_curr_val),
        // Write port --> RMW result
        .clk_b(hdmi_clk),
        .we_b(w_wr_b),
        .en_b(1'b1),
        .addr_b(w_addr_b),
        .din_b(w_din_b),
        .dout_b()
    );

    // DUAL PORT BLOCK RAM --> make histogram accessible to APB clock domain
    dp_blockram #(
        .DEPTH(DEPTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) u_dpbram_apb (
        // Write port --> copy histogram during histogram reset (disable while
        // reading)
        .clk_a(hdmi_clk),
        .we_a(r_rst),
        .en_a(~i_apb_read),
        .addr_a(r_addr_cntr_del),
        .din_a(w_curr_val),
        .dout_a(),
        // Read port --> read by the CPU through the APB bus
        .clk_b(apb_clk),
        .we_b(1'b0),
        .en_b(1'b1),
        .addr_b(i_apb_addr),
        .din_b(),
        .dout_b(o_data)
    );


endmodule
