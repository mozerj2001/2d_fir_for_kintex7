`timescale 1ns / 1ps
`default_nettype none

module fir(
    input clk,
    input rst,
    input i_hsync,
    input i_vsync,
    input i_valid,
    input [7:0] i_pixel,
    output o_hsync,
    output o_vsync,
    output o_valid,
    output [7:0] o_pixel
    );

    // CIRCULAR BUFFERS
    genvar i;
    generate
        for(i = 0; i < 4; i = i + 1) begin 
            sp_ram#(
                .DEPTH(1600),
                .WIDTH(8)
            ) buff[i] (  
                .clk(clk),
                .we(wr_sel_shr[i]),
                .en(1'b1),
                .addr(addr_cntr),
                .din(),
                .dout(buff_dout[i])
            );
        end
    endgenerate

    wire [7:0] buff_dout[3:0];

    // CALC SHIFTREGISTERS
    reg [7:0] buff_shr[4:0][4:0];

    genvar j, k;
    generate
        for(j = 0; j < 4; j = j + 1) begin
            if(j != 4) begin
                for(k = 0; k < 4; k = k + 1) begin
                    always @ (posedge clk)
                    begin
                        if(i_valid) begin
                            if(k == 0) begin
                                buff_shr[j][k] <= buff_dout[j];
                            end else begin
                                buff_shr[j][k] <= buff_shr[j][k-1];
                            end
                        end
                    end
                end
            end else begin
                for(k = 0; k < 4; k = k + 1) begin
                    always @ (posedge clk)
                    begin
                        if(i_valid) begin
                            if(k == 0) begin
                                buff_shr[j][k] <= i_pixel;
                            end else begin
                                buff_shr[j][k] <= buff_shr[j][k-1];
                            end
                        end
                    end
                end
            end
        end
    endgenerate

    // COEFFICIENT REGISTERS
    reg [15:0] coeff_reg[4:0][4:0];

    genvar x, y;
    generate
        for(x = 0; x < 4; x = x + 1) begin
            for(y = 0; y < 4; y = y + 1) begin
                always @ (posedge clk)
                begin
                    if(x == y) begin
                        coeff_reg[i][j] <= 16'h0800;
                    end else begin
                        coeff_reg[i][j] <= 16'h000F;
                    end
                end
            end
        end
    endgenerate

    // CALCULATE OUTPUT
    reg [23:0] mul_out[4:0][4:0];

    generate
        for(i = 0; i < 4; i = i + 1) begin
            for(j = 0; j < 4; j = j + 1) begin
                case(wr_sel_shr) begin
                    1'b0001:
                        mul_out[i][j] <= coeff_reg[i][j] * {buff_shr[][], 8'h00};
                    1'b0010:
                    1'b0100:
                    1'b1000:
                endcase
            end
        end
    endgenerate

    // addr counter (mindenki ugyanott cimzett) --> hsync eldetektalas
    // wr_en (select) -> melyik blokk ramot irjuk felul
    // 4 shiftreg amibe a blokkrambol irunk
    // 1 shiftreg amibe a legujabb pixel kerul
    //          shiftregeket akkor shifteljuk, amikor pixelt irunk be (valid)
    // szamolast vegzo modul maga
    // --> coeff tarolo (regiszterekben, mert az osszeshez egyszerre hozza
    // kell ferni)
    // vezerlojel kesleltetes

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

    // WRITE ENABLE SELECT
    reg [3:0] wr_sel_shr;

    always @ (posedge clk)
    begin
        if(rst) begin
            wr_sel_shr <= 4'b0001;
        end else if(hsync_rising) begin
            wr_sel_shr <= {wr_sel_shr[2:0], wr_sel_shr[3]};
        end
    end
    

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


















