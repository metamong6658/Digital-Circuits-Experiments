module pulse_FSM (Clock, Resetn, i_pulse, o_pulse);
	input Clock, Resetn, i_pulse;
	output reg o_pulse;
	reg [1:0] y_Q, Y_D;	// present and next state variable
	reg [1:0] pulse_reg;
	parameter S0 = 0, S1 = 1, S2 = 2;

	always @(y_Q, pulse_reg)
	begin: state_table
		case (y_Q)
			S0:		if (pulse_reg[1]) 
							Y_D = S1;
						else
							Y_D = S0;		// wait for incoming pulse to start
			S1:		Y_D = S2;			// one clock cycle delay to produce output pulse
			S2:		if (pulse_reg[1])
					  		Y_D = S2;		// wait for incoming pulse to end
						else 
							Y_D = S0;
			default:	Y_D = 2'bxx;
		endcase
	end // state_table

	always @(y_Q)
	begin: state_outputs
		case (y_Q)
			S0:		o_pulse = 1'b0;
			S1:		o_pulse = 1'b1;	// one-clock-cycle output pulse
			S2:		o_pulse = 1'b0;
			default: o_pulse = 1'bx;
		endcase
	end // f_state_outputs

	always @(posedge Clock)
	begin
		pulse_reg[1] <= pulse_reg[0];
		pulse_reg[0] <= i_pulse;
		if (Resetn == 1'b0)	// synchronous clear
			y_Q <= S0;
		else
			y_Q <= Y_D;
	end
endmodule
