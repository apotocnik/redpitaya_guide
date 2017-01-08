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


module selector #
(
    parameter A_WIDTH = 32,
    parameter DIV_WIDTH = 5,
    parameter offset = 26, // Slice bit position 26 ... 1.07 s
    parameter scale = -1 
)
(
    input [A_WIDTH-1:0] A,
    input [DIV_WIDTH-1:0] div,
    output reg S
);

    always @(A,div) begin
        S = A[offset + scale*div];
    end
    
endmodule
