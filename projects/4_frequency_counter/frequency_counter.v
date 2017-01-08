`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Anton Potocnik
// 
// Create Date: 07.01.2017 22:50:51
// Design Name: 
// Module Name: frequency_counter
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


module frequency_counter #
(
    parameter ADC_WIDTH = 14,
    parameter AXIS_TDATA_WIDTH = 32,
    parameter COUNT_WIDTH = 32,
    parameter HIGH_THRESHOLD = -100,
    parameter LOW_THRESHOLD = -150
)
(
    (* X_INTERFACE_PARAMETER = "FREQ_HZ 125000000" *)
    input [AXIS_TDATA_WIDTH-1:0]   S_AXIS_IN_tdata,
    input                          S_AXIS_IN_tvalid,
    input                          clk,
    input                          rst,
    input                          trigger,
    output [AXIS_TDATA_WIDTH-1:0]  M_AXIS_OUT_tdata,
    output                         M_AXIS_OUT_tvalid,
	output reg [COUNT_WIDTH-1:0]   counter_output
);
    wire signed [ADC_WIDTH-1:0]    data;
    reg                            state, state_next, trigger_d;
    wire                           trig;
    reg [COUNT_WIDTH-1:0]          counter=0, counter_next, counter_output_next;
    reg [COUNT_WIDTH-1:0]          counter_output = 0;
    
    // Wire AXIS IN to AXIS OUT
    assign  M_AXIS_OUT_tdata[ADC_WIDTH-1:0] = S_AXIS_IN_tdata[ADC_WIDTH-1:0];
    assign  M_AXIS_OUT_tvalid = S_AXIS_IN_tvalid;
    
    // extract only the 14-bits of ADC data 
    assign  data = S_AXIS_IN_tdata[ADC_WIDTH-1:0];
 
    
    always @(posedge clk) // handling of state buffer
    begin
        if (~rst) 
            state <= 1'b0;
        else
            state <= state_next;
    end
    
    always @*            // logic for state buffer
    begin
        if (data > HIGH_THRESHOLD)
            state_next = 1;
        else if (data < LOW_THRESHOLD)
            state_next = 0;
        else
            state_next = state;
    end
    
    
    
    always @(posedge clk) // handling of trigger.
        trigger_d <= trigger; // trigger_d is trigger delayed by one clk cycle
    
    assign trig = (trigger == 1 && trigger_d == 0) ? 1 : 0;  //Get a pulse on posedge trigger change
    //assign trig = 0;


    always @(posedge clk) // handling of counter and counter_output buffer
    begin
        if (~rst) 
        begin
            counter <= 0;
            counter_output <= 0;
        end
        else
        begin
            counter <= counter_next;
            counter_output <= counter_output_next;
        end
    end


    always @* // logic for counter and counter_output buffer
    begin
        counter_next = counter;
        counter_output_next = counter_output;
        
        if (state < state_next)
            counter_next = counter + 1;
            
        if (trig == 1'b1) 
        begin
            counter_next = 0;
            counter_output_next = counter;
        end
   end

    
endmodule
