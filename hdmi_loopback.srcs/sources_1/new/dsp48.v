`timescale 1ns / 1ps


// DSP48 MODULE FOR SYSTOLIC FIR FILTER

module dsp48
#(
	parameter delay=2
)(
    input wire clk,
    input wire          [17:0] A,           // input data in
    input wire signed   [47:0] B,           // previous result input
    input wire signed   [24:0] C,           // coeff in
    output wire signed  [17:0] A_out,       // systolic, so input data needs to go further
    output wire signed  [47:0] D            // result out
    );


    // DATA IN DELAY
    reg signed [17:0] A_del[delay-1:0];
	genvar j;
	generate
	for(j=0; j<delay; j = j + 1)
	begin
		always @ (posedge clk)
		begin
			if(j==0) begin
				A_del[j]<=A;
			end else
				A_del[j]<=A_del[j-1];
		end
    end
    
    endgenerate
    assign A_out = A_del[delay-1];


    // COEFFICIENT REGISTER
    reg signed [24:0] C_reg;

    always @ (posedge clk)
    begin
        C_reg <= C;
    end


    // MULTIPLIER
    reg signed [47:0] mul;

    always @ (posedge clk)
    begin
        mul <= A_del[delay-1] * C_reg;
    end


    // ADDER
    reg signed [47:0] adder;

    always @ (posedge clk)
    begin
        adder <= mul + B;
    end
    assign D = adder;

endmodule
