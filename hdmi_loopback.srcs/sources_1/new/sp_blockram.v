`timescale 1ns / 1ps

module sp_ram
	#(
		parameter DEPTH = 2048,
		parameter WIDTH = 8,
		
		//
		parameter ADDR_WIDTH = $clog2(DEPTH)
	)
	(  
        input wire clk,
        input wire we,
        input wire en,
        input wire [ADDR_WIDTH-1:0] addr,
        input wire [WIDTH-1:0] din,
        output wire [WIDTH-1:0] dout
    
    );
    
    reg [WIDTH-1:0] memory[DEPTH-1:0];
    reg [WIDTH-1:0] dout_reg;
    
    always @ (posedge clk)
    begin
        if(en) begin
            if(we) begin
                memory[addr] <= din;
            end
    
            dout_reg <= memory[addr];
        end
    end
    
    assign dout = dout_reg;
endmodule

