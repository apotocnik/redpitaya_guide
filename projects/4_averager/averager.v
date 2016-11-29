`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 25.10.2016 22:44:52
// Design Name: 
// Module Name: sample_hold
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


module averager(
    input clk,
    input trig,
    input [31:0] data_in,
    input [31:0] data_r,
    input [15:0] nsamples,
    input [31:0] naverages,
    input reset,
    output wire [31:0] addr,
    output wire [31:0] data_w,
    output wire [3:0] we,
    output wire finished,
    output averages
    );
    
    //parameter NSAMPLES = 3;
    //parameter NAVERAGES = 3;
    parameter ADC_DATA_WIDTH = 16;
    parameter AXIS_TDATA_WIDTH = 32;
    reg [31:0] averages = 0;     // averages
    reg [15:0] sample = 0;  // samples
    reg [15:0] pos = 0;  // writing position
    reg wait4trigger = 1;     // 0 .. dont wait, 1 ... wait
    reg [31:0] measurement;
    reg d_trig = 0;           
    wire trigger;    
    
    always@(posedge clk) begin
         if (reset == 1) d_trig <= 0;
         else d_trig <= trig;
    end
    assign trigger = (trig == 1) && (d_trig == 0) ? 1 : 0;
        
    
    always@(posedge clk) begin
        if (reset == 1) begin
            averages <= 0;
            sample <= 0;
            wait4trigger <= 1;
            pos <= nsamples-1;
        end
        else  begin
            if (trigger == 1) begin
                wait4trigger <= 0;
                sample <= 0;
                if (pos < nsamples-1)  pos <= pos + 1;
                else                   pos <= 0;
            end 
//            else begin
//                wait4trigger <= 1;
//                sample <= sample;
//            end
            
            //measurement <= {{(AXIS_TDATA_WIDTH-ADC_DATA_WIDTH+1){data_in[ADC_DATA_WIDTH-1]}},data_in[ADC_DATA_WIDTH-1:0]};
            measurement <= data_in;
            
            if (averages < naverages && wait4trigger == 0) begin  
                if (sample < nsamples-1) begin
                    sample <= sample + 1;
                    //averages <= averages;
                    wait4trigger <= 0;
                end
                else begin
                    //sample <= sample;
                    averages <= averages + 1;
                    wait4trigger <= 1;
               end
               
               if (pos < nsamples-1)  pos <= pos + 1;
               else                   pos <= 0;
            end
//            else begin
//                sample <= sample;
//                averages <= averages;
//                wait4trigger <= wait4trigger;
//            end
        end
    end
      
    assign data_w = averages == 0 ? measurement : (measurement + data_r);
    //assign data_w = averages == 0 ? (nsamples-sample) : (sample + data_r);
    
    assign finished = averages == naverages ? 1 : 0;
    assign addr = 4*pos;
    
    assign we = wait4trigger == 0 && finished == 0 ? 15 : 0;
    
endmodule
