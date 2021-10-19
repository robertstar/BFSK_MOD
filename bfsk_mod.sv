module bfsk_mod ( clk, dout, delay_cnt, ph1, ph2);

input  wire clk;
output wire signed [7:0]  dout; 
output wire        [15:0] delay_cnt; 
output wire        [31:0] ph1; 
output wire        [31:0] ph2; 

reg [15:0] sin_table1 [0:4095];
initial $readmemh("sin2.rom", sin_table1);

reg [15:0] sin_table2 [0:4095];
initial $readmemh("sin2.rom", sin_table2);

reg [31:0]  count;
reg [3:0]   state_fsk;
reg [95:0]  shift_reg;
reg         data_bit;
reg [7:0]   cnt_bits;
reg [31:0]  delay_bit;
reg         tx_en;
reg [7:0]   bitpos;
reg [7:0]   DAC_r;

reg [31:0]  ph1_1k2;
reg [31:0]  ph2_2k2;

reg [31:0]  ph1_inc;
reg [31:0]  ph2_inc;

reg [15:0]  sine1;
reg [15:0]  sine2;

initial begin
    state_fsk   <=4'd0;
    shift_reg   <=96'd0;
    data_bit    <=1'b0;
    cnt_bits    <=8'd0;
    delay_bit   <=32'd0;
    bitpos      <=8'd0;
    tx_en       <=1'b0; 
    count       <=32'd0;
    DAC_r       <=8'd128;
    
    ph1_1k2      <=0;
    ph2_2k2      <=0;
    ph1_inc      <=0;
    ph2_inc      <=0;
    
    sine1<=0;
    sine2<=0;
end


assign dout      = DAC_r;
assign delay_cnt = delay_bit[15:0];
assign ph1       = ph1_1k2;
assign ph2       = ph2_2k2;

always@(posedge clk) begin 

    count <=count+32'd1;
    case (count)
        32'd12000: begin 
            count       <=32'd0; 
            state_fsk   <=4'd2;
        end
    endcase 


    //alg state bfsk
    case(state_fsk)
        4'd0: begin //IDLE
            DAC_r       <=8'd0;
            cnt_bits    <=8'd0;
            delay_bit   <=32'd0;
            bitpos      <=8'd0;
            tx_en       <=1'b0;
            shift_reg   <={8'hAA, 8'hCF, 8'hFC, 8'h1D, 8'h55, 8'h12, 8'h47, 8'h00, 8'hE4, 8'hA2, 8'h09, 8'h00};  

            ph1_1k2     <=0;
            ph2_2k2     <=0;
            
            ph1_inc     <=32'd0;
            ph2_inc     <=32'd0;
            
        end
        
        4'd1: begin 
            state_fsk <=4'd2;               
        end
        
        4'd2: begin //Transfer one bit to bfsk modulator          

            case(shift_reg[95])
            
                1: begin
                    ph1_1k2 <=ph1_1k2 + 32'd10737418; //1200 480000
                    //ph1_1k2 <=ph1_1k2 + 32'd21474836;   //2400 480000
                    if(delay_bit<32'd1599) begin
                        delay_bit   <=delay_bit+1'b1;
                    end
                    else begin
                        cnt_bits  <=cnt_bits+1'b1;
                        delay_bit <=0;
                        shift_reg <= {shift_reg[94:0],1'b0};

                        if(cnt_bits >= 8'd96) 
                            state_fsk<=4'd0;    
                    end 

                    DAC_r <=sin_table2[ph1_1k2[31-:12]][15-:8]+128;
                    
                end
                
                0: begin
                    ph2_2k2 <=ph2_2k2 + 32'd21474836; //2400 480000
                    //ph2_2k2 <=ph2_2k2 + 32'd42949673;   //4800 480000
                    
                    if(delay_bit<32'd1599) begin
                        delay_bit <=delay_bit+1'b1;  
                    end
                    else begin
                        cnt_bits  <=cnt_bits+1'b1;
                        delay_bit <=0;
                        shift_reg <={shift_reg[94:0],1'b0};

                        if(cnt_bits >= 8'd96) 
                            state_fsk<=4'd0;   
                    end
                    
                    //DAC_r<= sine2[15-:8];
                    //sine2<=sin_table2[ph2_2k2[31-:12]];
                    DAC_r <=sin_table2[ph2_2k2[31-:12]][15-:8]-128;
  
                end

            endcase

        end
        
        4'd15: begin
            //STOP TX
        end
        
        default:state_fsk<=4'd0; 
    endcase

end


endmodule
