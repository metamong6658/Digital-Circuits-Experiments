module Digital_Clock (
	// clock_50Mhz map
	input clk50,
	// KEY3 map
	input KEY_inc,
	// KEY2 map
	input KEY_dec,
	// KEY1 map
	input rstn,
	// KEY0 map
	input KEY_mode,
	// LEDG[1..0] map
	output reg [1:0] mode,
	// SW17 map
	input SWITCH,
	// SW1 map
	input alaramRESET,
	output increase,
	output decrease,
	// segment map
	output [6:0] seg_h1,
	output [6:0] seg_h0,
	output [6:0] seg_m1,
	output [6:0] seg_m0,
	output [6:0] seg_s1,
	output [6:0] seg_s0,
	// LEDR[17] map
	output trg_alarm,
	inout SDAT,
	output SCLK,
	// LEDR[2..0] map
	output [2:0] ACK_LEDR,
	output XCLK,
	output BCLK,
	output reg DAC_LR_CLK,
	output DAC_DATA
);
	// 1Mhz clock generation
	wire clk1;
	clock_div clk1_generator(clk50,clk1);
	
	// mode selection
	always @(posedge KEY_mode) begin
			if (mode == 2'b00) mode <= 2'b01; // set hour selection mode
			else if (mode == 2'b01) mode <= 2'b10; // set minute selection mode
			else if (mode == 2'b10) mode <= 2'b11; // Alaram selection mode
			else if (mode == 2'b11) mode <= 2'b00; // set clock mode
			else mode <= 2'b00;
		end
	// increase, decrease
	pulse_FSM increase_generation(clk1,rstn,~KEY_inc,increase);
	pulse_FSM decrease_generation(clk1,rstn,~KEY_dec,decrease);
	// hour, minute, second generation
	wire [5:0] hour;
	wire [5:0] min;
	wire [5:0] sec;
	time_blk time_generator(
		.clk(clk1),
		.rstn(rstn),
		.mode(mode),
		.SWITCH(SWITCH),
		.alramRESET(alaramRESET),
		.increase(increase),
		.decrease(decrease),
		.hour(hour),
		.min(min),
		.sec(sec),
		.trg_alarm(trg_alarm)
	);

	// divde hour -> h1 | h0
	// divde min  -> m1 | m0
	// divde sec  -> s1 | s0
	wire [3:0] div_h1;
	wire [3:0] div_h0;
	wire [3:0] div_m1;
	wire [3:0] div_m0;
	wire [3:0] div_s1;
	wire [3:0] div_s0;
	divider divh(hour,div_h1,div_h0);
	divider divm(min,div_m1,div_m0);
	divider divs(sec,div_s1,div_s0);
	
	// segment decoding
	seg_dec dec_h1(div_h1,seg_h1);
	seg_dec dec_h0(div_h0,seg_h0);
	seg_dec dec_m1(div_m1,seg_m1);
	seg_dec dec_m0(div_m0,seg_m0);
	seg_dec dec_s1(div_s1,seg_s1);
	seg_dec dec_s0(div_s0,seg_s0);

	// Audiocodec
	//===========================================
// parameter
reg [3:0] counter; // transition mode
reg counting_state; // I2C, Read ROM
reg ignition; // Read ROM -> ignition : 0
reg read_enable; 	
reg [15:0] MUX_input;
reg [17:0] read_counter;
reg [3:0] ROM_output_mux_counter;
reg [5:0] DAC_LR_CLK_counter;
wire [15:0]ROM_out;
wire finish_flag;
assign DAC_DATA = (trg_alarm) ? ROM_out[15-ROM_output_mux_counter]: 0;
//============================================
// Instantiation section
I2C_Protocol I2C(
	.clk(clk50),
	.irstn(rstn),
	.ignition(ignition),
	.MUX_input(MUX_input),
	.ACK(ACK_LEDR),
	.SDAT(SDAT),
	.finish_flag(finish_flag),
	.SCLK(SCLK)
	);
testCLK testCLK_inst(
	.inclk0(clk50),
	.c0(XCLK),
	.c1(BCLK)
	);
testROM testROM_inst(
	.address(read_counter),
	.clken(read_enable),
	.clock(DAC_LR_CLK),
	.q(ROM_out)
	);
//============================================
// Switch registers
always @(posedge finish_flag) counter <= counter + 1;
always @(posedge SCLK) begin
		case(counter) 
		0: MUX_input <= 16'h0460; 
		//1: MUX_input <= 16'h0660; 
		//MUX_input[15:9] register address, MUX_input[8:0] register data
		// MUX_input <= 16'h1201; // activate interface
		// MUX_input <= 16'h0460; // left headphone out
		// MUX_input <= 16'h0C00; // power down control
		// MUX_input <= 16'h0812; // analog audio path control
		// MUX_input <= 16'h0A00; // digital audio path control
		// MUX_input <= 16'h102F; // sampling control
		// MUX_input <= 16'h0E23; // digital audio interface format
		// MUX_input <= 16'h0660; // right headphone out
		// MUX_input <= 16'h1E00; // reset device
		endcase
	end
//============================================
// readenable & couting_state
always @(posedge clk50) begin
	if(!rstn) begin
		counting_state <= 0;
		read_enable <= 0;
		end
	else begin
		case(counting_state)
		0:
			begin
			ignition <= 1;
			read_enable <= 0;
			if(counter == 1) counting_state <= 1;
			end
		1:
			begin
			read_enable <= 1;
			ignition <= 0;
			end
		endcase
	end
end
//============================================
// ROM_output_mux_counter & DACLRCLK
always @(posedge BCLK) begin
	if(read_enable) DAC_LR_CLK_counter <= DAC_LR_CLK_counter + 1;
end
always @(posedge BCLK) begin
	if(read_enable) begin
		ROM_output_mux_counter <= ROM_output_mux_counter + 1;
		if (DAC_LR_CLK_counter == 63) DAC_LR_CLK <= 1; // 8khz
		else DAC_LR_CLK <= 0;
	end
end
//============================================
// address for ROM
always @(posedge DAC_LR_CLK) begin
	if(read_enable) begin
		read_counter <= read_counter + 1;
		// #data + 1
		if (read_counter == 14969) read_counter <= 0;
	end
end
endmodule