`timescale 1ns / 1ps
`default_nettype none

// SYSTOLIC FIR FILTER

module systolic_fir
#(
parameter LENGTH=5
)(
    input wire clk,
    input wire [17:0] A,                // input data in
    input wire [(LENGTH*25)-1:0] C,     // coeffs in
    output wire [47:0] D                // result out
    );
    
    wire [17:0] data_in_bus [LENGTH-1:0];
    wire [47:0] result_bus [LENGTH-1:0];
    
    genvar i;
    
    generate
        for(i = 0; i < LENGTH ; i = i + 1) begin
            if (i==0) begin
                dsp48 #(.delay(1)) u_dsp48d1 (
                            .clk(clk),
                            .A(A), 
                            .B(48'b0), 
                            .C(C[(i+1)*25-1:i*25]), 
                            .A_out(data_in_bus[i]), 
                            .D(result_bus[i])
                        );
            end else begin
                dsp48 #(.delay(2)) u_dsp48d2 (
                            .clk(clk),
                            .A(data_in_bus[i-1]), 
                            .B(result_bus[i-1]), 
                            .C(C[(i+1)*25-1:i*25]), 
                            .A_out(data_in_bus[i]), 
                            .D(result_bus[i])
                        );
            end
        end
    endgenerate


endmodule
