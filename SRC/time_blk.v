module time_blk (
	input clk,
	input rstn,
	input [1:0] mode,
	input SWITCH,
	input alramRESET,
	input increase,
	input decrease,
	output reg [5:0] hour,
	output reg [5:0] min,
	output reg [5:0] sec,
	output reg trg_alarm
);
	reg inc_hour;
	reg dec_hour;
	reg inc_min;
	reg dec_min;
	reg [5:0] v_sec;
	reg [5:0] v_min;
	reg [5:0] v_hour;
	reg [5:0] s_sec;
	reg [5:0] s_min;
	reg [5:0] s_hour;
	reg [5:0] t_min;
	reg [5:0] t_hour;

// inc_hour, dec_hour, inc_min, dec_min
always @(mode or increase or decrease) begin : set_gen
	case (mode)
		2'b00 : 
		begin
			inc_hour <= 0;
			dec_hour <= 0;
			inc_min <= 0;
			dec_min <= 0;
		end
		2'b01 :
		begin
		if(increase) inc_hour <= 1;
		else inc_hour <= 0;
		if(decrease) dec_hour <= 1;
		else dec_hour <= 0;
		end
		2'b10 :
		begin
		if(increase) inc_min <= 1;
		else inc_min <= 0;
		if(decrease) dec_min <= 1;
		else dec_min <= 0;
		end
		2'b11 :
		begin
			if(increase) begin
				if(SWITCH) begin inc_min <= 1; inc_hour <= 0; end
				else begin inc_hour <= 1; inc_min <= 0; end
			end
			else begin
				inc_min <= 0;
				inc_hour <= 0;
			end
			if(decrease) begin
				if(SWITCH) begin dec_min <= 1; dec_hour <= 0; end
				else begin dec_hour <= 1; dec_min <= 0; end
			end
			else begin
				dec_min <= 0;
				dec_hour <= 0;
			end
		end
		default: begin
			inc_hour <= 0;
			dec_hour <= 0;
			inc_min <= 0;
			dec_min <= 0;
		end
	endcase
end

// 1hz clock generation
reg [19:0] cnt_sec;
reg clk1;
initial begin
	cnt_sec = 20'd0;
	clk1 <= 1'b0;
end
always @(posedge clk) begin
	cnt_sec <= cnt_sec + 1'b1;
	if(cnt_sec == 20'd499999) begin 
		cnt_sec <= 20'd0;
		clk1 <= ~clk1;
	end
end

// initialize temp
initial begin
	v_sec <= 0;
	v_min <= 0;
	v_hour <= 0;
	s_sec <= 0;
	s_min <= 0;
	s_hour <= 0;
end

// on-going time
always @(posedge clk1 or negedge rstn) begin
	if(!rstn) begin
		v_sec <= 0;
		v_min <= 0;
		v_hour <= 0;
	end
	else begin
	v_sec <= v_sec + 1;
	if (v_sec == 6'd59) begin
		v_min <= v_min + 1;
		v_sec <= 6'd0;
	end
	if(mode == 2'b10) begin
		v_min <= s_min;
	end
	else begin
		if (v_min == 6'd59 && v_sec == 59) begin
		v_hour <= v_hour + 1;
		v_min <= 6'd0;
		end	
	end
	if(mode == 2'b01) begin
		v_hour <= s_hour;
	end
	else begin
		if (v_hour == 5'd23 && v_min == 59 && v_sec == 59) v_hour <= 5'd0;	
	end
	end
end

// selection time
always @(posedge clk or negedge rstn) begin
	if(!rstn) begin
		s_hour <= 0;
		s_min <= 0;
	end
	else begin
	if(mode == 2'b01) begin
		if (inc_hour == 1) begin
			if (s_hour == 5'd23) s_hour <= 5'd0;
			else s_hour <= s_hour + 1;
		end
		else if(dec_hour == 1) begin
			if(s_hour == 0) s_hour <= 5'd23;
			else s_hour <= s_hour - 1;
		end
		end
	else s_hour <= v_hour;
	if(mode == 2'b10) begin
		if (inc_min == 1) begin
			if (s_min == 6'd59) s_min <= 6'd0;
			else s_min <= s_min + 1;
		end
		else if (dec_min == 1) begin
			if (s_min == 0) s_min <= 6'd59;
			else s_min <= s_min - 1;
		end
	end
	else s_min <= v_min; 
	end
end

// Alarm selection
always @(posedge clk) begin
	if(alramRESET) begin
		t_hour <= 63;
		t_min <= 63;
		trg_alarm <= 0;
	end
	else begin
		if(mode == 2'b11) begin
			if(inc_hour) begin
				if(t_hour >= 5'd23) t_hour <= 5'd0;
				else t_hour <= t_hour + 1;
			end
			else if(dec_hour) begin
				if(t_hour == 0) t_hour <= 5'd23;
				else t_hour <= t_hour - 1;
			end
			if(inc_min) begin
				if (t_min >= 6'd59) t_min <= 6'd0;
				else t_min <= t_min + 1;
			end
			else if (dec_min == 1) begin
				if (t_min == 0) t_min <= 6'd59;
				else t_min <= t_min - 1;
		end
		end
		else begin
			if(t_hour == v_hour && t_min == v_min) begin
				trg_alarm <= 1;
				if(v_sec == 59) begin
					t_hour <= 63;
					t_min <= 63;
				end
			end
			else trg_alarm <= 0;
		end
	end
end

// output
always @(posedge clk) begin
	sec <= v_sec;
	if(mode == 2'b11) begin
		min <= t_min;
		hour <= t_hour;
	end
	else begin
	min <= s_min;
	hour <= s_hour;
	end
end
endmodule
