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


module signal_split(
    (* X_INTERFACE_PARAMETER = "FREQ_HZ 125000000" *)
    input [31:0]       S_AXIS_tdata,
    input              S_AXIS_tvalid,
    (* X_INTERFACE_PARAMETER = "FREQ_HZ 125000000" *)
    output wire [31:0] M_AXIS_tdata_PORT1,
    output wire        M_AXIS_tvalid_PORT1,
    (* X_INTERFACE_PARAMETER = "FREQ_HZ 125000000" *)
    output wire [31:0] M_AXIS_tdata_PORT2,
    output wire        M_AXIS_tvalid_PORT2
    );
    
    parameter ADC_DATA_WIDTH = 16;
    parameter AXIS_TDATA_WIDTH = 32;
    
    assign M_AXIS_tdata_PORT1 = {{(AXIS_TDATA_WIDTH-ADC_DATA_WIDTH+1){S_AXIS_tdata[ADC_DATA_WIDTH-1]}},S_AXIS_tdata[ADC_DATA_WIDTH-1:0]};
    assign M_AXIS_tdata_PORT2 = {{(AXIS_TDATA_WIDTH-ADC_DATA_WIDTH+1){S_AXIS_tdata[AXIS_TDATA_WIDTH-1]}},S_AXIS_tdata[AXIS_TDATA_WIDTH-1:ADC_DATA_WIDTH]};
    assign M_AXIS_tvalid_PORT1 = S_AXIS_tvalid;
    assign M_AXIS_tvalid_PORT2 = S_AXIS_tvalid;

endmodule
