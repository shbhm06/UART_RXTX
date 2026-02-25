`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 25.02.2026 15:17:27
// Design Name: 
// Module Name: uart_tb
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


`timescale 1ns / 1ps

module uart_tb;

    parameter CLK_FREQ = 50000000;
    parameter BAUD_RATE = 9600;

    reg clk;
    reg reset;    
    reg [7:0] tx_data;
    reg send_trigger;
    wire tx_ready;
    wire tx_line; 
    wire [7:0] rx_data;
    wire rx_valid;

    uart_tx #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) TX_UNIT (
        .clk(clk),
        .reset(reset),
        .data_in(tx_data),
        .send_trigger(send_trigger),
        .tx(tx_line),
        .ready(tx_ready)
    );

    uart_rx #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) RX_UNIT (
        .clk(clk),
        .reset(reset),
        .rx(tx_line), 
        .data_out(rx_data),
        .data_valid(rx_valid)
    );

    always #10 clk = ~clk;

    initial begin

        clk = 0;
        reset = 1;
        tx_data = 0;
        send_trigger = 0;
        #100;
        reset = 0;
        #100;
        $display("Starting Transmission: Sending 'A' (0x41)...");
        tx_data = 8'h41;
        send_trigger = 1;
        #20; 
        send_trigger = 0;

        wait(rx_valid == 1);
        
        $display("Reception Complete.");
        $display("Sent: 0x41 | Received: 0x%h", rx_data);

        if (rx_data == 8'h41)
            $display("TEST PASSED");
        else
            $display("TEST FAILED");

        #1000;
        $finish;
    end

endmodule
