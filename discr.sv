module discr ( clk, din, dout, det, en, sync);

parameter DEPTH_D  = 22; //DISCRIMINATOR DELAY
parameter DEPTH_S  = 11; //ADDER         DELAY
parameter IWIDTH   = 8;  //Input  data (signal) width
parameter OWIDTH   = 17; //Output data

input  wire clk;
input  wire signed [IWIDTH-1:0]din;
output wire signed [OWIDTH-1:0]dout; 
output wire det;
output wire en;
output wire sync;

reg signed [7:0]  line_d [DEPTH_D:0]; 
reg signed [15:0] line_s [DEPTH_S:0]; 

reg signed [16:0] mult=0;
reg signed [16:0] add=0;
reg        [7:0]  i=0;
reg               det_r=0;
reg               en_r=0;
reg        [31:0] div=0;
reg               sync_r=0;

assign dout      = add;
assign det       = det_r;
assign en        = en_r;
assign sync      = sync_r;

initial begin
    //DISCRIMINATOR
    for (i=0; i <= DEPTH_D; i=i+1) begin
        line_d[i]  <= 0;
    end
    
     //ADDER
    for (i=0; i <= DEPTH_S; i=i+1) begin
        line_s[i]  <= 0;
    end
end


always @(posedge clk) begin
    
    line_d[0]  <= din;
    for (i=1; i <= DEPTH_D; i=i+1) begin
        line_d[i]  <= line_d[i-1];
    end

    mult<= din * line_d[DEPTH_D];
    
    line_s[0]  <= mult;
    for (i=1; i <= DEPTH_S; i=i+1) begin
        line_s[i]  <= line_s[i-1];
    end
    
    add<= mult + line_s[DEPTH_S];
    
    //sign
    if(add > 0) begin
        det_r<= 1;
    end
    else if(add < 0) begin
        det_r<= 0;
    end
    
    
    //Create 1200 HZ
    if(en) begin
        
        case(div)
            199: begin
                div<=0;
                sync_r<=~sync_r;
            end
            
            default: begin
                div<=div+1;
            end
            
        endcase
    end
    
end


reg st1=0;

always @(negedge det_r) begin
    
    case(st1)
    
        0: begin
            sync_r<=1;
            st1<=1;
        end
        
        1: begin
        
        end
        
    endcase
    
    en_r<=1;
    
end

endmodule
