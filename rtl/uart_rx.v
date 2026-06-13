// ============================================================
// Module      : uart_rx
// Description : UART Receiver with configurable baud rate
// Author      : P. Venkatesh Sagar
// Date        : June 2026
// ============================================================

module uart_rx #(
    parameter CLKS_PER_BIT = 434
)(
    input        clk,
    input        rst_n,
    input        rx,
    output reg [7:0] rx_data,
    output reg       rx_done,
    output reg       rx_error
);

    localparam IDLE  = 3'd0;
    localparam START = 3'd1;
    localparam DATA  = 3'd2;
    localparam STOP  = 3'd3;
    localparam DONE  = 3'd4;

    reg [2:0]  state;
    reg [8:0]  clk_count;
    reg [2:0]  bit_index;
    reg [7:0]  rx_data_reg;
    reg        rx_sync1, rx_sync2; // Double flip-flop synchronizer

    // Double flop synchronizer to avoid metastability
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_sync1 <= 1'b1;
            rx_sync2 <= 1'b1;
        end else begin
            rx_sync1 <= rx;
            rx_sync2 <= rx_sync1;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state      <= IDLE;
            clk_count  <= 0;
            bit_index  <= 0;
            rx_data    <= 8'd0;
            rx_data_reg<= 8'd0;
            rx_done    <= 1'b0;
            rx_error   <= 1'b0;
        end else begin
            rx_done  <= 1'b0;
            rx_error <= 1'b0;
            case (state)
                IDLE: begin
                    clk_count <= 0;
                    bit_index <= 0;
                    if (rx_sync2 == 1'b0) // Start bit detected
                        state <= START;
                end
                START: begin
                    // Sample at middle of start bit
                    if (clk_count == (CLKS_PER_BIT/2) - 1) begin
                        if (rx_sync2 == 1'b0) begin
                            clk_count <= 0;
                            state     <= DATA;
                        end else
                            state <= IDLE; // False start
                    end else
                        clk_count <= clk_count + 1;
                end
                DATA: begin
                    if (clk_count < CLKS_PER_BIT - 1)
                        clk_count <= clk_count + 1;
                    else begin
                        clk_count              <= 0;
                        rx_data_reg[bit_index] <= rx_sync2;
                        if (bit_index < 7)
                            bit_index <= bit_index + 1;
                        else begin
                            bit_index <= 0;
                            state     <= STOP;
                        end
                    end
                end
                STOP: begin
                    if (clk_count < CLKS_PER_BIT - 1)
                        clk_count <= clk_count + 1;
                    else begin
                        clk_count <= 0;
                        if (rx_sync2 == 1'b1) begin
                            rx_data <= rx_data_reg;
                            rx_done <= 1'b1;
                            state   <= DONE;
                        end else begin
                            rx_error <= 1'b1; // Missing stop bit
                            state    <= IDLE;
                        end
                    end
                end
                DONE: begin
                    state <= IDLE;
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule
