`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.10.2016 22:09:33
// Design Name: 
// Module Name: selector
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


module selector(
    input [31:0] A,
    input [31:0] div,
    output reg S
);

    parameter reg [31:0] slice_pos = 26; // Slice bit position 26 ... 0.94 s

    always @(A,div) begin
        S <= A[slice_pos - 1 - div];
    end
    
endmodule
