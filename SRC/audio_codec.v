/***************************************/
//	Author: Ahmad Alastal 				   
//  Modified by YONGHWAN KWON
//	target board : DE2, original code target DE2-115
//	Completion date: 10/05/2022 AM 12:27  
//	Title: WM8731 Audio CODEC demo
//	Main function: Audio demonstration  
/***************************************/
module audio_codec (
	input clk,
	input irstn,
	input ENABLE,
	inout SDAT,
	output SCLK,
	output [2:0] ACK_LEDR,
	output XCLK,
	output BCLK,
	output reg DAC_LR_CLK,
	output DAC_DATA
);
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
assign DAC_DATA = (ENABLE) ? ROM_out[15-ROM_output_mux_counter]: 0;
//============================================
// Instantiation section
I2C_Protocol I2C(
	.clk(clk),
	.irstn(irstn),
	.ignition(ignition),
	.MUX_input(MUX_input),
	.ACK(ACK_LEDR),
	.SDAT(SDAT),
	.finish_flag(finish_flag),
	.SCLK(SCLK)
	);
testCLK testCLK_inst(
	.inclk0(clk),
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
		1: MUX_input <= 16'h0660; 
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
always @(posedge clk) begin
	if(!irstn) begin
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
		if (DAC_LR_CLK_counter == 63) DAC_LR_CLK <= 1; // about 97.6kHz = twice of sampling frequency
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