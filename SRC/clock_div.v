module clock_div(
  input clk50,
	output reg clk1
);
	reg [4:0]cnt;
  initial cnt <= 5'd0;

always @(posedge clk50) begin    
      cnt <= cnt + 1'b1 ;
      if(cnt == 5'd24) begin
        clk1 <= ~clk1;
        cnt <= 5'd0;
      end
end  

endmodule
