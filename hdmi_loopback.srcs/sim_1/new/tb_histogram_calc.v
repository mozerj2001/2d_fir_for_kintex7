`timescale 1ns / 1ps
`default_nettype none

module tb_histogram_calc(

    );

    // TEST IMAGE: 16x9
    // TEST IMAGE FULL: 20x12

    
    localparam CLK_PERIOD = 10;
    localparam HALF_CLK_PERIOD = CLK_PERIOD/2;

    localparam APB_CLK_PERIOD = 18;
    localparam HALF_APB_CLK_PERIOD = APB_CLK_PERIOD/2;

    reg clk = 1'b0;
    reg apb_clk = 1'b0;
    reg rst = 1'b1;
    reg valid = 1'b0;
    reg [7:0] pixel = 8'b0;
    reg [7:0] apb_addr = 8'b0;
    reg apb_read = 1'b0;
    reg reset_histogram = 1'b0;

    wire [31:0] o_hist;

    reg [7:0] img[19:0][11:0];

    integer i, j;
    initial begin
        for(i = 0; i < 20; i = i + 1) begin
            for(j = 0; j < 12; j = j + 1) begin
                img[i][j] <= i+j;
            end
        end
    end

    // STIMULUS
    always
    begin
        clk <= ~clk;
        #HALF_CLK_PERIOD;
    end

    always 
    begin
        apb_clk <= ~apb_clk;
        #HALF_APB_CLK_PERIOD;
    end

    initial begin
        #CLK_PERIOD;
        #CLK_PERIOD;
        #CLK_PERIOD;
        #CLK_PERIOD;
        #CLK_PERIOD;
        rst <= 1'b0;

        // Reset histogram, then check all memory cells.
        reset_histogram <= 1'b1;
        #CLK_PERIOD;
        reset_histogram <= 1'b0;

        for(j = 0; j < 256; j = j + 1) begin
            #CLK_PERIOD;
        end
        for(j = 0; j < 256; j = j + 1) begin
            pixel <= pixel + 1;
            #CLK_PERIOD;
        end


        // Create histogram by feeding a simulated image.
        valid <= 1'b1;

        for(j = 0; j < 12; j = j + 1) begin
            for(i = 0; i < 20; i = i + 1) begin
                pixel <= img[i][j];
                #CLK_PERIOD;
            end
        end

        valid <= 1'b0;
        pixel <= 8'b0;

        #CLK_PERIOD;
        #CLK_PERIOD;
        #CLK_PERIOD;
        #CLK_PERIOD;
        #CLK_PERIOD;

        // Check new histogram values.
        for(j = 0; j < 256; j = j + 1) begin
            pixel <= pixel + 1;
            #CLK_PERIOD;
        end

        #CLK_PERIOD;
        #CLK_PERIOD;
        #CLK_PERIOD;
        #CLK_PERIOD;
        #CLK_PERIOD;

        // Reset histogram and check all memory cells.
        // Check BRAM reserved for APB read.
        reset_histogram <= 1'b1;
        #CLK_PERIOD;
        reset_histogram <= 1'b0;

        #CLK_PERIOD;
        #CLK_PERIOD;
        #CLK_PERIOD;
        #CLK_PERIOD;
        #CLK_PERIOD;

        for(j = 0; j < 256; j = j + 1) begin
            #CLK_PERIOD;
        end
        for(j = 0; j < 256; j = j + 1) begin
            pixel <= pixel + 1;
            #CLK_PERIOD;
        end
        apb_read <= 1'b1;
        for(j = 0; j < 256; j = j + 1) begin
            apb_addr <= apb_addr + 1;
            #APB_CLK_PERIOD;
        end
        apb_read <= 1'b0;

        #1000;
    end


    histogram_calc #(
            .DATA_WIDTH(32),
            .DEPTH(256)
        ) u_dut (
            .rst(rst),
            .hdmi_clk(clk),
            .i_hdmi_addr(pixel),
            .i_hdmi_valid(valid),

            .apb_clk(apb_clk),
            .i_apb_addr(apb_addr),
            .i_apb_read(apb_read),

            .i_hist_rst(reset_histogram),

            .o_data(o_hist)
        );






endmodule
