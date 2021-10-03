`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05.08.2021 23:45:58
// Design Name: 
// Module Name: controller
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module controller(
	input clock,
    input [31:0] instruct,
    output reg [31:0] out = 0,
	output reg [4:0] sliceSelector = 0,
	output reg [5:0] writeEnableKey = 0
    );
	
	reg [3:0] selectRead = 0;
	reg [15:0] writeEnable = 0;
	reg [255:0] writeBus = 0;
	wire [255:0] dataOut;
	
	reg [1:0] state = 0;
	reg [1:0] nextState = 0;

	integer roundNumber = 0;
	integer counter = 0;
	
main datapath (clock, writeEnable, writeBus, selectRead, dataOut);

always @(posedge clock) begin

	state <= nextState;

	case (state)

	0: begin
		counter <= 0;
		sliceSelector <= 0;
		writeEnableKey <= 0;
		out <= 0;
		writeEnable <= 0;
		writeBus <= 0;
		selectRead <= instruct[3:0];
		
		if (instruct[31:30] == 0) //Read
			nextState <= 1;
		else if (instruct[31:30] == 1) begin //Write data
			case (selectRead)
				0,1,2,8,9: begin
					roundNumber <= 4;
				end
				5,6: begin
					roundNumber <= 8;
				end
				12,13,14: begin
					roundNumber <= 5;
				end
				4: begin
					roundNumber <= 14;
				end
				7: begin
					roundNumber <= 2;
				end
				default: begin
					roundNumber <= 1;
				end
			endcase
			nextState <= 2;
		end
		else if (instruct[31:30] == 2) begin //Write key
			case (selectRead)
				0,1: begin
					roundNumber <= 4;
				end
				2: begin
					roundNumber <= 5;
				end
				3,4,5: begin
					roundNumber <= 32;
				end
				
				default: begin
					roundNumber <= 1;
				end
			endcase
			nextState <= 4;
		end
		else //Forbidden instruction
			nextState <= 0;
	end

	1: begin //Read case
		writeEnable <= 0;
		writeBus <= 0;
		sliceSelector <= 0;
		writeEnableKey <= 0;
		if (counter < roundNumber) begin
			out <= dataOut[32*counter+31 -:32];
			nextState <= 1;
		end
		else begin
			nextState <= 0;
		end
		counter <= counter + 1;
		
		end //end case 1


	2: begin //Write case
		out <= 0;
		writeEnable <= 0;
		sliceSelector <= 0;
		writeEnableKey <= 0;
		if (counter < roundNumber) begin
			writeBus[32*counter+31 -:32] <= instruct;
			nextState <= 2;
		end
		else begin
			nextState <= 3;
		end
		counter <= counter + 1;
	end

	3: begin
		writeEnable[selectRead] <= 1; 
		nextState <= 0;
		out <= 0;
		sliceSelector <= 0;
		writeEnableKey <= 0;
	end
	
	4: begin
		out <= 0;
		writeEnableKey[selectRead] <= 1;
		if (counter < roundNumber) begin
			sliceSelector <= counter;
			nextState <= 4;
		end
		else begin
			sliceSelector <= 0;
			nextState <= 0;
			writeEnableKey <= 0;
		end
		counter <= counter + 1;
	end

	endcase //end case states
	end
	


endmodule
