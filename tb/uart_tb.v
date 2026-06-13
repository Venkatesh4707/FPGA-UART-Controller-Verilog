// ============================================================
// Module      : uart_tb
// Description : Self-checking testbench for UART Tx/Rx
// Author      : P. Venkatesh Sagar
// Date        : June 2026
// ============================================================

`timescale 1ns/1ps

module uart_tb;

    parameter CLKS_PER_BIT = 10;
    parameter CLK_PERIOD   = 10;

    reg        clk, rst_n;
    reg        tx_start;
    reg  [7:0] tx_data;
    wire       tx_line;
    wire       tx_busy, tx_done;
    wire [7:0] rx_data;
    wire       rx_done, rx_error;

    integer pass_count = 0;
    integer fail_count = 0;
    integer i;

    uart_tx #(.CLKS_PER_BIT(CLKS_PER_BIT)) u_tx (
        .clk(clk), .rst_n(rst_n), .tx_start(tx_start),
        .tx_data(tx_data), .tx(tx_line), .tx_busy(tx_busy), .tx_done(tx_done)
    );

    uart_rx #(.CLKS_PER_BIT(CLKS_PER_BIT)) u_rx (
        .clk(clk), .rst_n(rst_n), .rx(tx_line),
        .rx_data(rx_data), .rx_done(rx_done), .rx_error(rx_error)
    );

    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    task send_and_check;
        input [7:0] data;
        begin
            @(posedge clk);
            tx_data  = data;
            tx_start = 1'b1;
            @(posedge clk);
            tx_start = 1'b0;
            wait(rx_done == 1'b1);
            @(posedge clk);
            if (rx_data === data) begin
                $display("PASS | Sent: 0x%02X | Received: 0x%02X", data, rx_data);
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL | Sent: 0x%02X | Received: 0x%02X", data, rx_data);
                fail_count = fail_count + 1;
            end
            wait(tx_busy == 1'b0);
            repeat(5) @(posedge clk);
        end
    endtask

    initial begin
        rst_n = 0; tx_start = 0; tx_data = 0;
        repeat(5) @(posedge clk);
        rst_n = 1;
        repeat(3) @(posedge clk);
        $display("======================================");
        $display("  UART Loopback TB - Venkatesh Sagar");
        $display("======================================");
        send_and_check(8'h00);
        send_and_check(8'hFF);
        send_and_check(8'hAA);
        send_and_check(8'h55);
        send_and_check(8'hA5);
        for (i = 0; i < 256; i = i + 1)
            send_and_check(i[7:0]);
        $display("RESULTS: %0d PASSED | %0d FAILED", pass_count, fail_count);
        $finish;
    end

    initial begin
        $dumpfile("uart_sim.vcd");
        $dumpvars(0, uart_tb);
    end

    initial #10_000_000 $finish;

endmodule
