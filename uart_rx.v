`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 25.02.2026 15:17:27
// Design Name: 
// Module Name: uart_rx
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


// Filename: uart_tx.v
module uart_tx #(
    parameter CLK_FREQ = 50000000, 
    parameter BAUD_RATE = 9600    
)(
    input wire clk,           
    input wire reset,         
    input wire [7:0] data_in, 
    input wire send_trigger,  
    output reg tx,            
    output reg ready       
);

    localparam BIT_PERIOD = CLK_FREQ / BAUD_RATE;
    
    localparam IDLE = 2'b00, START = 2'b01, DATA = 2'b10, STOP = 2'b11;

    reg [1:0] state = IDLE;
    reg [31:0] clk_count = 0;
    reg [2:0] bit_index = 0;
    reg [7:0] tx_buffer = 0;

    always @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            tx <= 1'b1;
            ready <= 1'b1;
            clk_count <= 0;
            bit_index <= 0;
        end else begin
            case (state)
                IDLE: begin
                    tx <= 1'b1;
                    ready <= 1'b1;
                    if (send_trigger) begin
                        tx_buffer <= data_in;
                        ready <= 0;
                        state <= START;
                        clk_count <= 0;
                    end
                end

                START: begin
                    tx <= 1'b0;
                    if (clk_count < BIT_PERIOD - 1)
                        clk_count <= clk_count + 1;
                    else begin
                        clk_count <= 0;
                        state <= DATA;
                    end
                end

                DATA: begin
                    tx <= tx_buffer[bit_index];
                    if (clk_count < BIT_PERIOD - 1)
                        clk_count <= clk_count + 1;
                    else begin
                        clk_count <= 0;
                        if (bit_index < 7)
                            bit_index <= bit_index + 1;
                        else begin
                            bit_index <= 0;
                            state <= STOP;
                        end
                    end
                end

                STOP: begin
                    tx <= 1'b1; 
                    if (clk_count < BIT_PERIOD - 1)
                        clk_count <= clk_count + 1;
                    else begin
                        state <= IDLE; 
                    end
                end
            endcase
        end
    end
endmodule
