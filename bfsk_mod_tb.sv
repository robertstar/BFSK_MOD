`timescale 1ns / 1ps
`define EOF -1
`define NULL 0

module bfsk_mod_tb;

// duration for each bit = 20 * timescale = 20 * 1 ns  = 20ns for 50Mhz
localparam period_50Mhz = 10;  
localparam period_200k = 2500;
localparam period_48k  = 10416;
localparam period_480k = 1042;


//reg clk_48k;
reg clk_480k;
//reg clk_50Mhz;
	

wire signed [7:0] mod_out;
wire [15:0] delay_cnt;
wire [31:0] ph1;
wire [31:0] ph2;
integer   fd;       //file descriptors
reg [8*10:1] str; 
integer samples;
integer code;

// Inputs
reg [7:0] signal=0;   //register declaration for storing each line of file.
wire signed [16:0] discr_out;
wire det;
wire en;
wire sync;


//discr #( .DEPTH_D(20), .DEPTH_S(1) ) discr_inst( .clk(clk_48k), .din(signal), .dout(out), .det(det), .en(en) , .sync(sync) );
bfsk_mod bfsk_mod_inst(.clk(clk_480k), .dout(mod_out), .delay_cnt(delay_cnt), .ph1(ph1), .ph2(ph2));

discr #( .DEPTH_D(200), .DEPTH_S(1) ) bfsk_demod( .clk(clk_480k), .din(mod_out), .dout(discr_out), .det(det), .en(en) , .sync(sync) );

initial begin
    //clk_48k    =0;
    clk_480k    =0;
	//clk_50Mhz  =0;
	samples    =480000;
end

always
	#period_480k clk_480k = !clk_480k;// wait for period
	
//always 
	//#period_50Mhz clk_50Mhz = !clk_50Mhz;


initial begin
	@(posedge clk_480k); 
	fd=$fopen("bfsk_out_signal.bin","a+");
	while(samples>0) begin
		@(posedge clk_480k);
		//$fwrite(fd,"%c%c",cic_d_out_real[7:0], cic_d_out_real[15:8]);
		//$fwrite(fd,"%c%c",SINout2[7:0], SINout2[15:8]);
		$fwrite(fd,"%c",mod_out);
		samples<=samples-1'b1;
	end
	$fclose(fd);
	$finish;
end		
	

initial begin
 	$dumpfile("bfsk_mod.vcd");
  	$dumpvars(0,bfsk_mod_tb);
end
	
// Monitor the output
//initial
//$monitor($time, , COSout, , SINout, , angle, , A);
	
endmodule
