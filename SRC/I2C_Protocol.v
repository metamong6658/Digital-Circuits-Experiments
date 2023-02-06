module I2C_Protocol(
	input clk,
	input irstn,
	input ignition,
	input [15:0] MUX_input,	
	inout SDAT,
	output reg finish_flag,
	output reg [2:0] ACK,
	output reg SCLK
	);
//===========================================
// parameter	
//to generate 2.5kHz clock
reg [13:0] counter;		
//to measure number of clock ticks
reg [4:0] tick_counter; 
reg serial_data;
reg start_condition;
reg out;
assign SDAT = (out)? serial_data: 1'bz;
//============================================	
// Design structure:
// state:0 start condition
// state:1 send 0x34 address
// state:2 wait for ACK
// state:3 send register address
// state:4 wait for ACK
// state:5 send data to registers
// state:6 wait for ACK
// state:7 stop conition
//============================================
//	clock generation and number of clock ticks
always @(posedge clk)
	begin
	if (!irstn) 
		begin
		counter <= 0;
		SCLK <= 1;		
		end 
	else if (start_condition && ignition)	 
		begin
		counter <= counter + 1;
		if (counter <= 9999) SCLK <= 1; 		   	
		else if (counter == 19999) counter <= 0;	
		else if (tick_counter == 29) SCLK <= 1;
		else SCLK <= 0;
		end
	else if (ignition == 0) counter <= 0;
	else SCLK <= 1; 
	end
always @(negedge SCLK) 
	begin
	if(!irstn) tick_counter <= 0;
	else
		begin
		tick_counter <= tick_counter + 1;
		// 28 clock cycles needed to complete configuration cycle from I2C bus
		if (tick_counter == 28) tick_counter <= 0; 
		end
	end
//============================================
always @(posedge clk)
	begin
	if (tick_counter == 9 || tick_counter == 18 || tick_counter == 27) out <= 0; // ACK ticks
	else out <= 1;
	end
//============================================
always @(posedge clk)
	begin
		case(tick_counter)
		0://SDAT will be high for 60us then low until SCLK goes high
			begin
			ACK <= 3'b000;
			finish_flag <= 0;
			start_condition <= 1;
			serial_data <= 1;	//SDAT idle condition
			if (counter > 3000) serial_data <= 0; // was 3000
			end
		1://push 0x34 address through I2C data bus, 0x34 = 00110100
		  //push 0
			begin
			serial_data <= 0;
			end
		2://push 0
			begin
			serial_data <= 0;
			end
		3://push 1
			begin
			serial_data <= 1;
			end
		4://push 1
			begin
			serial_data <= 1;
			end
		5://push 0
			begin
			serial_data <= 0;
			end
		6://push 1
			begin
			serial_data <= 1;
			end
		7://push 0
			begin
			serial_data <= 0;
			end
		8://push 0
			begin
			serial_data <= 0;
			end
		9://wait for ACK
			begin
			ACK[0] <= !SDAT; //was SDAT
			end
		10://start sending register address, 7 bits each address
			//push MSB first (MUX_input[15])
			begin
			serial_data <= MUX_input[15];
			end
		11://push MUX_input[14]
			begin
			serial_data <= MUX_input[14];
			end
		12://push MUX_input[13]
			begin
			serial_data <= MUX_input[13];
			end
		13://push MUX_input[12]
			begin
			serial_data <= MUX_input[12];
			end
		14://push MUX_input[11]
			begin
			serial_data <= MUX_input[11];
			end
		15://push MUX_input[10]
			begin
			serial_data <= MUX_input[10];
			end
		16://push MUX_input[9]
			begin
			serial_data <= MUX_input[9];
			end
		17://start filling control registers, 9 bits each register
			//push MUX_input[8]
			begin
			serial_data <= MUX_input[8];
			end
		18://wait for ACK
			begin
			ACK[1] <= !SDAT;
			end
		19://push MUX_input[7]
			begin
			serial_data <= MUX_input[7];
			end
		20://push MUX_input[6]
			begin
			serial_data <= MUX_input[6];
			end
		21://push MUX_input[5]
			begin
			serial_data <= MUX_input[5];
			end
		22://push MUX_input[4]
			begin
			serial_data <= MUX_input[4];
			end
		23://push MUX_input[3]
			begin
			serial_data <= MUX_input[3];
			end
		24://push MUX_input[2]
			begin
			serial_data <= MUX_input[2];
			end
		25://push MUX_input[1]
			begin
			serial_data <= MUX_input[1];
			end
		26://push MUX_input[0]
			begin
			serial_data <= MUX_input[0];
			end	
		27://wait for ACK
			begin
			ACK[2] <= !SDAT;
			end
		28://bring serial_data to low and stop condition
			begin
			serial_data <= 0;
			finish_flag <= 1;
			if (counter > 3000 && SCLK == 1 /*|| counter == 0*/) serial_data <= 1;
			end
		endcase
	end
endmodule 