`timescale 1ns / 1ps
`default_nettype none

// DUAL PORT BLOCK RAM (asynchronous read, synchronous write)
module dp_blockram #(
        DEPTH = 2048, 
        ADDR_WIDTH = $clog2(DEPTH),
        DATA_WIDTH = 8
    )
    (
        input wire clk_a, we_a, en_a, clk_b, we_b, en_b,
        input wire [ADDR_WIDTH-1:0] addr_a, addr_b,
        input wire [DATA_WIDTH-1:0] din_a, din_b,
        output wire [DATA_WIDTH-1:0] dout_a, dout_b
    );


    reg [DATA_WIDTH-1:0] mem[DEPTH-1:0];

    //PORT A
    reg [31:0] dout_a_reg;
    always @ (posedge clk_a)
    begin
        if(en_a) begin
            if(we_a) begin
                mem[addr_a] <= din_a;
            end
            dout_a_reg <= mem[addr_a];
        end
    end

    assign dout_a = dout_a_reg;


    //PORT B
    reg [31:0] dout_b_reg;
    always @ (posedge clk_b)
    begin
        if(en_b) begin
            if(we_b) begin
                mem[addr_b] <= din_b;
            end
            dout_b_reg <= mem[addr_b];
        end
    end

    assign dout_b = dout_b_reg;

endmodule
