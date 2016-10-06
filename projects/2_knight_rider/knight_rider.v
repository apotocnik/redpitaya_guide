`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Anton Potocnik
// 
// Create Date: 05.10.2016 00:09:16
// Design Name: 
// Module Name: knight_rider
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


module knight_rider(
    input clk,
    output [7:0] led_out
    );
    
    reg [9:0] leds = 10'b0000000011;
    reg direction = 0;
    
    always @ (posedge clk) begin
        if (direction == 0) begin 
            leds = leds << 1;
        end
        if (direction == 1) begin 
            leds = leds >> 1;
        end
        if (leds == 10'b0000000011) begin
            direction = 0;
        end
        if (leds == 10'b1100000000) begin
            direction = 1;
        end
    end
    assign led_out = leds[8:1]; 
    
endmodule
