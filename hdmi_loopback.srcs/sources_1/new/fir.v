`timescale 1ns / 1ps
`default_nettype none


// FIR MODULE
// Built from four circular buffers, realized by four block RAM modules.
// The modules write to each other in circular fashion, each time
// a new pixel is received.



module fir(
    input wire          clk,
    input wire          rst,
    input wire          i_hsync,
    input wire          i_vsync,
    input wire          i_valid,
    input wire [7:0]    i_pixel,
    output wire         o_hsync,
    output wire         o_vsync,
    output wire         o_valid,
    output wire [7:0]   o_pixel,
    
    input wire          apb_clk,
    input wire          apb_rstn,
    input wire          apb_penable,
    input wire [31:0]   apb_paddr,
    input wire          apb_psel,
    input wire [31:0]   apb_pwdata,
    input wire          apb_pwrite,
    
    output wire [31:0]  apb_prdata,
    output wire         apb_pslverr,
    output wire         apb_pready,
    
    input wire          rec_en,
    output reg          irq
    
    
    );
    
    
 
    //enable signal edge
    
    
    reg rec_en_in;
    reg rec_en_reg_prev;
    reg rec_en_reg;
    
    wire rec_en_edge;
    always @ (posedge clk)
    begin
	if (rst) begin
	    rec_en_in<=1'b0;
	    rec_en_reg_prev<=1'b0;
	    rec_en_reg<=1'b0;
	end else begin
	    rec_en_in<=rec_en;
	    rec_en_reg<=rec_en_in;
	    rec_en_reg_prev<=rec_en_reg;
	end
    end
    
   assign rec_en_edge= rec_en_reg & ~rec_en_reg_prev;
   
   always @ (posedge clk)
   begin
	if(rst)
	    irq <= 1'b0;
   end
    
    
    //coeff reg
    reg signed [15:0] coeff_in [24:0];
    reg signed [24:0] coeff [24:0]; 
    
    //APB interface
    
    wire apb_read;
    wire apb_write;
    wire write_en;
    
    wire reg_addr;
    
    assign apb_read     = apb_penable & apb_psel & ~ apb_pwrite;
    assign apb_write    = apb_penable & apb_psel &  apb_pwrite;
    assign apb_pready   = apb_penable & apb_psel;
    assign apb_pslverr  = 1'b0;
    assign write_en     = apb_write & (apb_paddr[31:8] == 24'h412000);
    assign reg_addr     = apb_paddr[4:0];
   
    //writing coeff registers
    reg [15:0] w_coeff[24:0];

    genvar i;
    generate
        for(i = 0; i < 25; i = i + 1) begin
            always @ (posedge clk)
            begin
                if(apb_write & apb_clk) begin
                    coeff_in[i] <= w_coeff[i];
                end
            end
        end
    endgenerate

    always @ (*)
    begin
        case(reg_addr)
            0:  w_coeff[0]      <= apb_pwdata[15:0];
            1:  w_coeff[1]      <= apb_pwdata[15:0];
            2:  w_coeff[2]      <= apb_pwdata[15:0];
            3:  w_coeff[3]      <= apb_pwdata[15:0];
            4:  w_coeff[4]      <= apb_pwdata[15:0];
            5:  w_coeff[5]      <= apb_pwdata[15:0];
            6:  w_coeff[6]      <= apb_pwdata[15:0];
            7:  w_coeff[7]      <= apb_pwdata[15:0];
            8:  w_coeff[8]      <= apb_pwdata[15:0];
            9:  w_coeff[9]      <= apb_pwdata[15:0];
            10: w_coeff[10]     <= apb_pwdata[15:0];
            11: w_coeff[11]     <= apb_pwdata[15:0];
            12: w_coeff[12]     <= apb_pwdata[15:0];
            13: w_coeff[13]     <= apb_pwdata[15:0];
            14: w_coeff[14]     <= apb_pwdata[15:0];
            15: w_coeff[15]     <= apb_pwdata[15:0];
            16: w_coeff[16]     <= apb_pwdata[15:0];
            17: w_coeff[17]     <= apb_pwdata[15:0];
            18: w_coeff[18]     <= apb_pwdata[15:0];
            19: w_coeff[19]     <= apb_pwdata[15:0];
            20: w_coeff[20]     <= apb_pwdata[15:0];
            21: w_coeff[21]     <= apb_pwdata[15:0];
            22: w_coeff[22]     <= apb_pwdata[15:0];
            23: w_coeff[23]     <= apb_pwdata[15:0];
            24: w_coeff[24]     <= apb_pwdata[15:0];
        endcase
    end

    
    //reading
    assign apb_prdata = coeff_in[reg_addr];
    
    //genvar j;
    //generate
    //    for(j = 0; j < 25; j = j + 1) begin
    //	    always @ (posedge clk)
    //	    begin
    //	    	coeff[j] <= {{9{coeff[15]}}, coeff_in[j]};        // pad 16 bit signed coeff to 25 bit signed coeff
    //	    end
    //	end
    //endgenerate
    
    genvar j;
    generate
        for(j = 0; j < 25; j = j + 1) begin
    	    always @ (posedge clk)
    	    begin
    	    	coeff[j] <= 25'b000000000000000000000011111;        // pad 16 bit signed coeff to 25 bit signed coeff
    	    end
    	end
    endgenerate
	

    // CIRCULAR BUFFERS

    wire [7:0] buff_din[3:0];
    wire [7:0] buff_dout[3:0];

    
    genvar k;
    generate
        for(k = 0; k < 4; k = k + 1) begin
            sp_ram#(
                .DEPTH(2048),
                .WIDTH(8)
            )  (  
                .clk(clk),
                .we(1'b1),
                .en(1'b1),
                .addr(addr_cntr),
                .din(buff_din[k]),
                .dout(buff_dout[k])
            );

            if(k == 0) begin
                assign buff_din[k] = i_valid ? i_pixel : 8'b0;
            end else begin
                assign buff_din[k] = buff_dout[k-1];
            end
        end
    endgenerate


    // ARRANGE SYSTOLIC FIR INPUT
    wire [7:0] dsp_in[4:0];
    reg [7:0] del_input[3:0];
    reg [7:0] del_dout0[2:0];
    reg [7:0] del_dout1[1:0];
    reg [7:0] del_dout2;


    genvar l;
    generate
        for(l = 0; l < 4; l = l + 1) begin
            always @ (posedge clk) begin
                if(l == 0) begin
                    del_input[l] <= i_pixel;
                end else if(l == 1) begin
                    del_input[l] <= del_input[l-1];
                    del_dout0[l-1] <= buff_dout[0];
                end else if(l == 2) begin
                    del_input[l] <= del_input[l-1];
                    del_dout0[l-1] <= del_dout0[l-2];
                    del_dout1[l-2] <= buff_dout[1];
                end else begin
                    del_input[l] <= del_input[l-1];
                    del_dout0[l-1] <= del_dout0[l-2];
                    del_dout1[l-2] <= del_dout1[l-3];
                    del_dout2 <= buff_dout[2];
                end
            end
        end
    endgenerate


    assign dsp_in[0] = del_input[3];
    assign dsp_in[1] = del_dout0[2];
    assign dsp_in[2] = del_dout1[1];
    assign dsp_in[3] = del_dout2;
    assign dsp_in[4] = buff_dout[3];

    // 5 systolic FIR filters
    wire [47:0] dsp_out[4:0];

    //C input wiring is HOPEFULLY correct
    genvar m;
    generate
    	for(m = 0; m < 5; m = m + 1)begin
    	    systolic_fir # (
                .LENGTH(5)
            ) u_systolic_fir (
                .clk(clk), 
                .A({2'b0, dsp_in[m], 8'b0}),                    // zero padded pixel
                .C({coeff[m*5+4], 
                    coeff[m*5+3], 
                    coeff[m*5+2], 
                    coeff[m*5+1], 
                    coeff[m*5+0]}),                             // most significant is the last stage
                .D(dsp_out[m]) 
            );
    	end
    endgenerate

    // INSANITY
    reg [47:0] fir_out;
    

    always @(posedge clk)
    begin
        fir_out = fir_out + dsp_out[0];
        fir_out = fir_out + dsp_out[1];
        fir_out = fir_out + dsp_out[2];
        fir_out = fir_out + dsp_out[3];
        fir_out = fir_out + dsp_out[4];
    end

    //assign o_pixel = fir_out[15:8];
    assign o_pixel = del_dout1[1];

    // DETECT HSYNC EDGE & DELAY DUE TO BUFFER
    reg [2:0] hsync_del;
    reg [2:0] vsync_del;
    reg [2:0] valid_del;

    always @ (posedge clk)
    begin
        hsync_del <= {hsync_del[1:0], i_hsync};
        vsync_del <= {vsync_del[1:0], i_vsync};
        valid_del <= {valid_del[1:0], i_valid}; 
    end

    wire hsync_rising;
    assign hsync_rising = (hsync_del[1:0] == 1'b01) ? 1'b1 : 1'b0;   // resets address counters
    
    // DELAY SYNC DUE TO FIR
    reg [10:0] hsync_firdel;
    reg [10:0] vsync_firdel;
    reg [10:0] valid_firdel;
    
    always @ (posedge clk)
    begin
        hsync_firdel <= {hsync_firdel[9:0], hsync_del};
        vsync_firdel <= {vsync_firdel[9:0], vsync_del};
        valid_firdel <= {valid_firdel[9:0], valid_del}; 
    end
    
    //assign o_hsync = hsync_firdel[10];
    //assign o_vsync = vsync_firdel[10];
    //assign o_valid = valid_firdel[10];
    
    assign o_hsync = hsync_del[1]; 
    assign o_vsync = vsync_del[1]; 
    assign o_valid = valid_del[1]; 
    
    
    // ADDRESS COUNTER
    reg [10:0] addr_cntr;

    always @ (posedge clk)
    begin
        if(rst) begin
            addr_cntr <= 0;
        end else if(hsync_rising) begin
            addr_cntr <= 0;
        end else begin
            addr_cntr <= addr_cntr + 1;
        end
    end


endmodule




