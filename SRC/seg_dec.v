module seg_dec (IDATA, HEX);
	input [3:0] IDATA;
	output reg [6:0] HEX;	

// 1 = LED OFF
// gfedcba map
// just map each bits
always @(IDATA) begin
	case (IDATA)
		4'b0000 : HEX <= 7'b1000000;
		4'b0001 : HEX <= 7'b1111001;
		4'b0010 : HEX <= 7'b0100100;
		4'b0011 : HEX <= 7'b0110000;
		4'b0100 : HEX <= 7'b0011001;
		4'b0101 : HEX <= 7'b0010010;
		4'b0110 : HEX <= 7'b0000010;
		4'b0111 : HEX <= 7'b1111000;
		4'b1000 : HEX <= 7'b0000000;
		4'b1001 : HEX <= 7'b0010000;
		default : HEX <= 7'b0111111;
	endcase
end

endmodule