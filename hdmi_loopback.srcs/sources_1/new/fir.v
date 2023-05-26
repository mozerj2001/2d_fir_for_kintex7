`timescale 1ns / 1ps
`default_nettype none


// FIR MODULE
// Built from four circular buffers, realized by four block RAM modules.
// The modules write to each other in circular fashion, each time
// a new pixel is received.



module fir(
    input wire clk,
    input wire rst,
    input wire i_hsync,
    input wire i_vsync,
    input wire i_valid,
    input wire [7:0] i_pixel,
    output wire o_hsync,
    output wire o_vsync,
    output wire o_valid,
    output wire [7:0] o_pixel
    );

    // CIRCULAR BUFFERS

    wire [7:0] buff_din[3:0];
    wire [7:0] buff_dout[3:0];

    genvar i;
    generate
        for(i = 0; i < 4; i = i + 1) begin
            sp_ram#(
                .DEPTH(2048),
                .WIDTH(8)
            ) buff (  
                .clk(clk),
                .we(i_valid),
                .en(1'b1),
                .addr(addr_cntr),
                .din(buff_din[i]),
                .dout(buff_dout[i])
            );

            if(i == 0) begin
                assign buff_din[i] = i_pixel;
            end else begin
                assign buff_din[i] = buff_dout[i-1];
            end
        end
    endgenerate


    // ARRANGE SYSTOLIC FIR INPUT
    wire [7:0] dsp_in[4:0];
    reg [7:0] del_input[3:0];
    reg [7:0] del_dout0[2:0];
    reg [7:0] del_dout1[1:0];
    reg [7:0] del_dout2;


    genvar j;
    generate
        for(j = 0; j < 4; j = j + 1) begin
            always @ (posedge clk) begin
                if(j == 0) begin
                    del_input[j] <= i_pixel;
                end else if(j == 1) begin
                    del_input[j] <= del_input[j-1];
                    del_dout0[j-1] <= buff_dout[0];
                end else if(j == 2) begin
                    del_input[j] <= del_input[j-1];
                    del_dout0[j-1] <= del_dout0[j-2];
                    del_dout1[j-2] <= buff_dout[1];
                end else begin
                    del_input[j] <= del_input[j-1];
                    del_dout0[j-1] <= del_dout0[j-2];
                    del_dout1[j-2] <= del_dout1[j-3];
                    del_dout2 <= buff_dout[2];
                end
            end
        end
    endgenerate


    assign dsp_in[0] = del_input[3];
    assign dsp_in[1] = del_dout0[2];
    assign dsp_in[2] = del_dout1[1];
    assign dsp_in[3] = del_dout2;
    assign dsp_in[4] = buff_dout[3];


    // DETECT HSYNC EDGE & DELAY
    reg [1:0] hsync_del;
    reg [1:0] vsync_del;

    always @ (posedge clk)
    begin
        if(i_valid) begin
            hsync_del <= {hsync_del[0], i_hsync};
            vsync_del <= {vsync_del[0], i_vsync};
        end
    end

    assign o_hsync = hsync_del[1];
    assign o_vsync = vsync_del[1];

    wire hsync_rising;
    assign hsync_rising = (hsync_del == 1'b01) ? 1'b1 : 1'b0;   // resets address counters


    // ADDRESS COUNTER
    reg [10:0] addr_cntr;

    always @ (posedge clk)
    begin
        if(rst) begin
            addr_cntr <= 0;
        end else if(hsync_rising) begin
            addr_cntr <= 0;
        end else if(i_valid) begin
            addr_cntr <= addr_cntr + 1;
        end
    end


endmodule


















