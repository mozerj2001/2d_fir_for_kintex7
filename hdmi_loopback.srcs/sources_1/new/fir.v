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


















