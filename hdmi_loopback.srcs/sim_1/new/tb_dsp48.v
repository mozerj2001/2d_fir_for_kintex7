`timescale 1ns / 1ps
`default_nettype none

module tb_dsp48(

    );

    localparam CLK_PERIOD = 10;
    localparam HALF_CLK_PERIOD = CLK_PERIOD/2;

    reg clk = 1'b0;
    reg [17:0] A;
    reg [19:0] B = 0;
    reg [17:0] C;
    wire [17:0] i_A;
    wire [19:0] i_B;
    wire [17:0] i_C;

    assign i_A = A;
    assign i_B = B;
    assign i_C = C;

    wire [17:0] o_A;
    wire [19:0] o_D;

    dsp48 dut(
        .clk(clk),
        .A(i_A),               // input data in
        .B(i_B),               // previous result input
        .C(i_C),               // coeff in
        .A_out(o_A),           // systolic, so input data needs to go further
        .D(o_D)                // result out
        );


    // STIMULUS
    always
    begin
        clk <= ~clk;
        #HALF_CLK_PERIOD;
    end

    initial begin
        A <= 18'b000000100000000000;
        C <= 18'b000000001000000000;
        #CLK_PERIOD;
        A <= 18'b000000001000000000;
        #CLK_PERIOD;
        A <= 18'b000000001000000000;
        #CLK_PERIOD;
        A <= 18'b000000100000000000;
        #CLK_PERIOD;
        #CLK_PERIOD;
        #CLK_PERIOD;
        #CLK_PERIOD;
        C <= 18'b000000000000000010;
        #CLK_PERIOD;
        B <= o_D;
        #CLK_PERIOD;
        B <= o_D;
        #CLK_PERIOD;
        B <= o_D;
        #CLK_PERIOD;
        B <= o_D;
    end


endmodule
