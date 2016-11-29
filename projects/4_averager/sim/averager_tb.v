`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.10.2016 13:22:57
// Design Name: 
// Module Name: comparator_tb
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


module comparator_tb();

reg [31:0] a, b;
wire s;

selector cp (a,b,s);
                            
integer i;

initial begin
    for (i = 0; i<32; i = i+1) begin
        a <= 'h2FFFFFF;
        b <= i;
        #5;
    end
end                   
                   
endmodule
