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
    input [7:0] div,
    output reg S
);

    parameter integer offset = 25; // Slice bit position 25 ... 0.94 s
    parameter integer scale = -1; 

    always @(A,div) begin
        S = A[offset + scale*div];
    end
    
endmodule
