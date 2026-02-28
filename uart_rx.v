`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 25.02.2026 15:17:27
// Design Name: 
// Module Name: uart_tx
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

module uart_rx #(
    parameter CLK_FREQ = 50000000,
    parameter BAUD_RATE = 9600
)(
    input wire clk,           
    input wire reset,         
    input wire rx,            
    output reg [7:0] data_out,
    output reg data_valid     
);

    localparam BIT_PERIOD = CLK_FREQ / BAUD_RATE;
    localparam IDLE = 2'b00, START = 2'b01, DATA = 2'b10, STOP = 2'b11;

    reg [1:0] state = IDLE;
    reg [31:0] clk_count = 0;
    reg [2:0] bit_index = 0;
    reg [7:0] rx_shift_reg = 0;

    always @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            data_valid <= 0;
            data_out <= 0;
            clk_count <= 0;
            bit_index <= 0;
        end else begin
            case (state)
                IDLE: begin
                    data_valid <= 0;
                    clk_count <= 0;
                    bit_index <= 0;
                    
                    if (rx == 1'b0) begin 
                        state <= START;
                    end
                end

                START: begin
                    if (clk_count < (BIT_PERIOD / 2)) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        if (rx == 1'b0) begin 
                            clk_count <= 0;
                            state <= DATA;
                        end else begin
                            state <= IDLE; 
                        end
                    end
                end

                DATA: begin
                    if (clk_count < BIT_PERIOD - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= 0;
                        rx_shift_reg[bit_index] <= rx;
                        
                        if (bit_index < 7) begin
                            bit_index <= bit_index + 1;
                        end else begin
                            bit_index <= 0;
                            state <= STOP;
                        end
                    end
                end

                STOP: begin
                    if (clk_count < BIT_PERIOD - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        data_valid <= 1'b1;     
                        data_out <= rx_shift_reg;
                        state <= IDLE;
                    end
                end
            endcase
        end
    end
endmodule
