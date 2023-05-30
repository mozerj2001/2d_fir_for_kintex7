`timescale 1ns/1ps
`default_nettype none


module rgb2y(
    input  wire          		clk,
    
    input  wire signed 	[17:0] 	kr_i,
    input  wire signed 	[17:0] 	kb_i,
    
    input  wire          		dv_i,
    input  wire          		hs_i,
    input  wire          		vs_i,
    input  wire    		[7:0] 	r_i,
    input  wire    		[7:0] 	g_i,
    input  wire    		[7:0] 	b_i,
					
    output wire    		      	dv_o,
    output wire    		      	hs_o,
    output wire    		      	vs_o,
    output wire    		[7:0] 	y_o
);
    integer i;
    
    wire signed [31:0] p[1:0];
    
    reg [7:0] r[0:0];
    reg [7:0] g[1:0];
    reg [7:0] b[0:0];
    
    always @(posedge clk)
    begin
        r[0] <= r_i;
        g[0] <= g_i;
        b[0] <= b_i;
        g[1] <= g[0];
    end
    
    dsp_gyak #(
        .USE_PCI (0)
    )
    dsp0(
        .clk     (clk),
        .a       (r_i),
        .d       (g_i),
        .b       (kr_i),
        .c       ({7'b0, g[1], 17'b0}),
        .pci     (0),
        .p       (p[0])
    );
    dsp_gyak #(
        .USE_PCI (1)
    )
    dsp1(
        .clk     (clk),
        .a       (b[0]),
        .d       (g[0]),
        .b       (kb_i),
        .c       (0),
        .pci     (p[0]),
        .p       (p[1])
    );
    
    reg [7:0] y_reg;
    always @(posedge clk)
    if (p[1][31])
        y_reg <= 8'b0;
    else
        y_reg <= p[1][24:17];
    
    assign y_o = y_reg;
    
    
    reg [2:0] cntrl_dl[5:0];
    always @ (posedge clk)
    for (i=0; i<6; i=i+1)
        cntrl_dl[i] <= (i==0) ? {dv_i, hs_i, vs_i} : cntrl_dl[i-1];
    
    assign dv_o = cntrl_dl[5][2];
    assign hs_o = cntrl_dl[5][1];
    assign vs_o = cntrl_dl[5][0];
    
endmodule
