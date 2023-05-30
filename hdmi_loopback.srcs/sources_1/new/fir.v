`timescale 1ns / 1ps
`default_nettype none


// FIR MODULE
// Built from four circular buffers, realized by four block RAM modules.
// The modules write to each other in circular fashion, each time
// a new pixel is received.



module fir(
    input wire clk,
    input wire rst,
    input wire i_hsync,
    input wire i_vsync,
    input wire i_valid,
    input wire [7:0] i_pixel,
    output wire o_hsync,
    output wire o_vsync,
    output wire o_valid,
    output wire [7:0] o_pixel,
    
    input wire apb_clk,
    input wire apb_rstn,
    input wire apb_penable,
    input wire apb_paddr[31:0],
    input wire apb_psel,
    input wire apb_pwdata[31:0],
    input wire apb_pwrite,
    
    output wire apb_prdata[31:0],
    output wire apb_pslverr,
    output wire apb_pready,
    
    input wire rec_en,
    output wire irq
    
    
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
   
   reg irq_reg; 
   always @ (posedge clk)
   begin
	if(rst)
		irq<=1'b0;
	else
	
   end
    
    assign irq=irq_reg;
    
    //coeff reg
    reg [15:0] coeff_in [31:0];
    reg [24:0] coeff [24:0]; 
    
    //APB interface
    
    wire apb_read;
    wire apb_write;
    wire write_en;
    
    wire reg_addr;
    
    assign apb_read=apb_penable & apb_psel & ~ apb_pwrite;
    assign apb_write=apb_penable & apb_psel &  apb_pwrite;
    assign apb_pready=apb_penable & apb_psel;
    assign apb_pslverr=1'b0;
    assign write_en=apb_write & apb_paddr[31:8]==24'h412000;
    assign reg_addr=apb_paddr [4:0];
   
   //writing coeff registers
    always @ (posedge apb_clk)
    begin
	if(apb_write)
	    coeff_in[reg_addr]<=apb_pwdata;
    end
    
    //reading
    assign apb_prdata=coeff_in[reg_addr];
    
    genvar i;
    generate
    	for(i = 0; i < 25; i++) begin
    	    always @ (posedge clk)
    	    begin
    	    	coeff[i] <= {{9{coeff[15]}}, coeff_in[i]};        // pad 16 bit signed coeff to 25 bit signed coeff
    	    end
    	end
    endgenerate
	

    // CIRCULAR BUFFERS

    wire [7:0] buff_din[3:0];
    wire [7:0] buff_dout[3:0];

    
    generate
        for(i = 0; i < 4; i = i + 1) begin
            sp_ram#(
                .DEPTH(2048),
                .WIDTH(8)
            )  (  
                .clk(clk),
                .we(1'b1),
                .en(1'b1),
                .addr(addr_cntr),
                .din(buff_din[i]),
                .dout(buff_dout[i])
            );

            if(i == 0) begin
				
                assign buff_din[i] = i_valid ?i_pixel:8'b0;
            end else begin
                assign buff_din[i] = buff_dout[i-1];
            end
        end
    endgenerate


    // ARRANGE SYSTOLIC FIR INPUT
    wire [7:0] dsp_in[4:0];
    reg [7:0] del_input[3:0];
    reg [7:0] del_dout0[2:0];
    reg [7:0] del_dout1[1:0];
    reg [7:0] del_dout2;


    genvar j;
    generate
        for(j = 0; j < 4; j = j + 1) begin
            always @ (posedge clk) begin
                if(j == 0) begin
                    del_input[j] <= i_pixel;
                end else if(j == 1) begin
                    del_input[j] <= del_input[j-1];
                    del_dout0[j-1] <= buff_dout[0];
                end else if(j == 2) begin
                    del_input[j] <= del_input[j-1];
                    del_dout0[j-1] <= del_dout0[j-2];
                    del_dout1[j-2] <= buff_dout[1];
                end else begin
                    del_input[j] <= del_input[j-1];
                    del_dout0[j-1] <= del_dout0[j-2];
                    del_dout1[j-2] <= del_dout1[j-3];
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

    //C input wiring is incorrect
    generate
    	for(i = 0; i < 5; i++)begin
    	    systolic_fir # (
                .LENGTH(5))
            (
                .clk(clk), 
                .A({2'b0, dsp_in[i], 8'b0}),                    // zero padded pixel
                .C({dsp_coeff_in_padded[i*5+4], 
                    dsp_coeff_in_padded[i*5+3], 
                    dsp_coeff_in_padded[i*5+2], 
                    dsp_coeff_in_padded[i*5+1], 
                    dsp_coeff_in_padded[i*5+0]}),                   // most significant is the last stage
                .D(dsp_out[i]) 
            );
    	end
    endgenerate



 

    // DETECT HSYNC EDGE & DELAY
    reg [1:0] hsync_del;
    reg [1:0] vsync_del;

    always @ (posedge clk)
    begin
        
            hsync_del <= {hsync_del[0], i_hsync};
            vsync_del <= {vsync_del[0], i_vsync};
        
    end

    assign o_hsync = hsync_del[1];
    assign o_vsync = vsync_del[1];

    wire hsync_rising;
    assign hsync_rising = (hsync_del == 1'b01) ? 1'b1 : 1'b0;   // resets address counters


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




