module divider (div_in, div_ten, div_1);
	input [5:0] div_in;
	output reg [3:0] div_ten;
	output reg [3:0] div_1;
	
always @(div_in)
begin
	if (div_in < 10) begin
		div_ten <= 0; div_1 <= div_in;
	end
	else if (div_in >= 10 && div_in < 20) begin
		div_ten <= 1; div_1 <= div_in - 10;
	end
	else if (div_in >= 20 && div_in < 30) begin
		div_ten <= 2; div_1 <= div_in - 20;
	end
	else if (div_in >= 30 && div_in < 40) begin
		div_ten <= 3; div_1 <= div_in - 30;
	end
	else if (div_in >= 40 && div_in < 50) begin
		div_ten <= 4; div_1 <= div_in - 40;
	end
	else if (div_in >= 50 && div_in < 60) begin
		div_ten <= 5; div_1 <= div_in - 50;
	end
	else begin
		div_ten <= 0;
		div_1 <= 0;
	end
end
endmodule