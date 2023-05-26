`timescale 1ns / 1ps
`default_nettype none

// DSP48 MODULE FOR SYSTOLIC FIR FILTER

module dsp48(
    input wire clk,
    input wire [17:0] A,                // input data in
    input wire [19:0] B,                // previous result input
    input wire [17:0] C,                // coeff in
    output wire [17:0] A_out,           // systolic, so input data needs to go further
    output wire [19:0] D                // result out
    );


    // DATA IN DELAY
    reg [17:0] A_del[1:0];

    always @ (posedge clk)
    begin
        A_del[0] <= A;
        A_del[1] <= A_del[0];
    end
    assign A_out = A_del[1];


    // COEFFICIENT REGISTER
    reg [17:0] C_reg;

    always @ (posedge clk)
    begin
        C_reg <= C;
    end


    // MULTIPLIER
    reg [19:0] mul;

    always @ (posedge clk)
    begin
        mul <= A_del[1] * C_reg;
    end


    // ADDER
    reg [19:0] adder;

    always @ (posedge clk)
    begin
        adder <= mul + B;
    end
    assign D = adder;

endmodule
