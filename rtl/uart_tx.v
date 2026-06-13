// ============================================================
// Module      : uart_tx
// Description : UART Transmitter with configurable baud rate
// Author      : P. Venkatesh Sagar
// Date        : June 2026
// ============================================================
// Frame Format: 1 Start bit | 8 Data bits | 1 Stop bit
// Baud Rate   : Configurable via CLKS_PER_BIT parameter
// Usage       : CLKS_PER_BIT = Clock_Freq / Baud_Rate
//               Example: 50MHz clock, 115200 baud
//               CLKS_PER_BIT = 50_000_000 / 115_200 = 434
// ============================================================

module uart_tx #(
    parameter CLKS_PER_BIT = 434
)(
    input        clk,
    input        rst_n,
    input        tx_start,
    input  [7:0] tx_data,
    output reg   tx,
    output reg   tx_busy,
    output reg   tx_done
);

    localparam IDLE  = 3'd0;
    localparam START = 3'd1;
    localparam DATA  = 3'd2;
    localparam STOP  = 3'd3;
    localparam DONE  = 3'd4;

    reg [2:0]  state;
    reg [8:0]  clk_count;
    reg [2:0]  bit_index;
    reg [7:0]  tx_data_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state       <= IDLE;
            tx          <= 1'b1;
            tx_busy     <= 1'b0;
            tx_done     <= 1'b0;
            clk_count   <= 0;
            bit_index   <= 0;
            tx_data_reg <= 8'd0;
        end else begin
            tx_done <= 1'b0;
            case (state)
                IDLE: begin
                    tx        <= 1'b1;
                    tx_busy   <= 1'b0;
                    clk_count <= 0;
                    bit_index <= 0;
                    if (tx_start) begin
                        tx_data_reg <= tx_data;
                        tx_busy     <= 1'b1;
                        state       <= START;
                    end
                end
                START: begin
                    tx <= 1'b0;
                    if (clk_count < CLKS_PER_BIT - 1)
                        clk_count <= clk_count + 1;
                    else begin
                        clk_count <= 0;
                        state     <= DATA;
                    end
                end
                DATA: begin
                    tx <= tx_data_reg[bit_index];
                    if (clk_count < CLKS_PER_BIT - 1)
                        clk_count <= clk_count + 1;
                    else begin
                        clk_count <= 0;
                        if (bit_index < 7)
                            bit_index <= bit_index + 1;
                        else begin
                            bit_index <= 0;
                            state     <= STOP;
                        end
                    end
                end
                STOP: begin
                    tx <= 1'b1;
                    if (clk_count < CLKS_PER_BIT - 1)
                        clk_count <= clk_count + 1;
                    else begin
                        clk_count <= 0;
                        state     <= DONE;
                    end
                end
                DONE: begin
                    tx_done <= 1'b1;
                    tx_busy <= 1'b0;
                    state   <= IDLE;
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule
