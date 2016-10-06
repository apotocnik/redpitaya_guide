`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Anton Potocnik
// 
// Create Date: 05.10.2016 01:03:08
// Design Name: 
// Module Name: reverse_bits
// Project Name: 
// Target Devices: xc7z010clg400-1
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


module reverse_bits(
    input [7:0] in_bits,
    output [7:0] out_bits
    );
    
    reg [3:0] i; // counter
    reg  [7:0] reversed;
    
    // mirror bits in wide 8-bit value    
    always @*
    for(i=0; i<8; i=i+1)
        reversed[i] = in_bits[7-i];
    
    assign out_bits = reversed;
   
endmodule
