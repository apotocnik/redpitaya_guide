`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Anton Potocnik
// 
// Create Date: 19.11.2016 22:45:53
// Design Name: 
// Module Name: simple_ddc
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


module signal_route(
    input [31:0] data_in,
    output wire [31:0] data_o1,
    output wire [31:0] data_o2
    );
    
    parameter ADC_DATA_WIDTH = 16;
    parameter AXIS_TDATA_WIDTH = 32;
    
    assign data_o1 = {{(AXIS_TDATA_WIDTH-ADC_DATA_WIDTH+1){data_in[ADC_DATA_WIDTH-1]}},data_in[ADC_DATA_WIDTH-1:0]};
    assign data_o2 = {{(AXIS_TDATA_WIDTH-ADC_DATA_WIDTH+1){data_in[AXIS_TDATA_WIDTH-1]}},data_in[AXIS_TDATA_WIDTH-1:ADC_DATA_WIDTH]};

endmodule
