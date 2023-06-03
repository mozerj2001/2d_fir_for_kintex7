`timescale 1ns / 1ps


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
    always @ (posedge clk_a)
    begin
        if(en_a) begin
            if(we_a) begin
                mem[addr_a] <= din_a;
            end
        end
    end

    assign dout_a = mem[addr_a];


    //PORT B
    always @ (posedge clk_b)
    begin
        if(en_b) begin
            if(we_b) begin
                mem[addr_b] <= din_b;
            end
        end
    end

    assign dout_b = mem[addr_b];

endmodule
