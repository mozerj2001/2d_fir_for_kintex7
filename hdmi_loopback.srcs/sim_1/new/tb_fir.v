`timescale 1ns / 1ps
`default_nettype none

module tb_fir(

    );
    // TEST IMAGE: 16x9
    // TEST IMAGE FULL: 20x12

    
    localparam CLK_PERIOD = 10;
    localparam HALF_CLK_PERIOD = CLK_PERIOD/2;

    reg clk = 1'b0;
    reg rst = 1'b1;
    reg valid = 1'b1;
    reg [7:0] pixel;

    wire o_hsync, o_vsync, o_valid, o_pixel;

    reg [19:0] hsync_shr = 20'b0000000000000000110;
    reg [11:0] vsync_shr = 12'b000000000010;

    reg [7:0] img[19:0][11:0];

    integer i, j;
    initial begin
        for(i = 0; i < 20; i = i + 1) begin
            for(j = 0; j < 12; j = j + 1) begin
                img[i][j] <= i;
            end
        end
    end

    // STIMULUS
    always
    begin
        clk <= ~clk;
        #HALF_CLK_PERIOD;
    end

    always @ (posedge clk) begin
        hsync_shr <= {hsync_shr[18:0], hsync_shr[19]}; 
        vsync_shr <= {vsync_shr[10:0], vsync_shr[11]}; 
    end

    initial begin
        #CLK_PERIOD;
        #CLK_PERIOD;
        #CLK_PERIOD;
        #CLK_PERIOD;
        #CLK_PERIOD;
        rst <= 1'b0;
        valid <= 1'b1;

        for(j = 0; j < 12; j = j + 1) begin
            for(i = 0; i < 20; i = i + 1) begin
                pixel <= img[i][j];
                #CLK_PERIOD;
            end
        end
    end


    fir dut (
        .clk(clk),
        .rst(rst),
        .i_hsync(hsync_shr[19]),
        .i_vsync(vsync_shr[11]),
        .i_valid(valid),
        .i_pixel(pixel),
        .o_hsync(o_hsync),
        .o_vsync(o_vsync),
        .o_valid(o_valid),
        .o_pixel(o_pixel)
    );














endmodule
