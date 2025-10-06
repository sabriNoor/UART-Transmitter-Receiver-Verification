module Baud_Gen (
  input logic clk, reset,
  output logic bclk
  );
  
  parameter Baud_Rate=9600; // 9600 bps
  parameter Clk_Freq= 576 * (10**3); // 576kh
  parameter OverSampling= 16; // x16
  
  localparam Divisor= (Clk_Freq/(Baud_Rate*OverSampling))+0.5; 
  
  localparam Counter_Width=$clog2(Divisor);
  logic [Counter_Width-1:0] counter = 0;
  
  always @(posedge clk or negedge reset) begin
    
    if(reset==0) begin 
      bclk<=0;
      counter<=0;  
    end
    
    else begin
      
      if(counter >= (Divisor/2) -1 ) begin
        bclk<= ~bclk; // toggle the bclk
        counter<=0;
      end
      
      else begin
        counter<=counter+1;
      end 
      
    end
        
  end
  
    
endmodule 