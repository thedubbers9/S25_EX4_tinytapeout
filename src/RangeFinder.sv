module RangeFinder (
	input logic [9:0] data_in,
	input logic clock, reset,
	input logic go, finish,
	output logic [9:0] range,
	output logic debug_error
	
	);

	localparam WIDTH = 10;
	
	// flop the current seen highest and lowest values.
	logic [WIDTH-1:0] low_val, high_val;

	assign range = high_val - low_val;

	// state machine ENUM
	typedef enum logic [1:0] {  
		IDLE,
		GO,
		FINISH,
		ERROR
	} state_t;

	state_t current_state, next_state;


	always_comb begin : state_transition_logic
		// default cases to avoid latches.
		next_state = current_state;
		debug_error = 0;

		case (current_state)
			IDLE: begin
				// It's an error if finish is asserted before go.
				if (finish) begin
					next_state = ERROR;
				end else if (go) begin
					next_state = GO;
				end
			end
			GO: begin
				if (finish) begin
					next_state = FINISH;
				end
			end
			FINISH: begin
				// wait a cycle before going back to idle
				next_state = IDLE;
			end
			ERROR: begin
				if (go) begin
					next_state = GO;
				end

				// moore output for debug error
				debug_error = 1;
			end
		endcase
	end

	always_ff @( posedge clock, posedge reset) begin : blockName
		if (reset) begin
			current_state <= IDLE;
			low_val <= 0;
			high_val <= 0;
		end else begin
			current_state <= next_state;
			case (current_state)
				
				IDLE: begin
					// overwrite the current low and high values when go signal is recieved.
					if (go) begin
						low_val <= data_in;
						high_val <= data_in;
					end
				end
				GO: begin
					// update the low and high values if appropriate.
					if (data_in < low_val) begin
						low_val <= data_in;
					end else if (data_in > high_val) begin
						high_val <= data_in;
					end
				end
			endcase
		end
	end

	
	
     

endmodule : RangeFinder