`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/31/2026 08:00:55 PM
// Design Name: 
// Module Name: clk_div
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
module clk_div #(
    // ===== User-configurable parameters (in Hz) =============================
    parameter integer CLK_IN_HZ  = 12_000_000, // Input clock frequency
    parameter integer CLK_OUT_HZ = 1_000       // Desired output clock frequency
)(
    input  wire i_clkin,  // Source clock input
    input  wire i_rstn,   // Asynchronous active-low reset
    output wire o_clkout  // Divided clock output
);

    // ===== Derived parameters (internal use only) ==========================
    // Gets the amount of bit required for the counter
    localparam integer HALF_PERIOD_COUNT = CLK_IN_HZ / (2 * CLK_OUT_HZ);
    // Stores the amount of bits
    localparam integer CNT_WIDTH         = $clog2(HALF_PERIOD_COUNT);

    reg [CNT_WIDTH-1:0] cnt;      // Counter for clock division
    reg                 clkout_r; // Registered divided clock

    assign o_clkout = clkout_r;

    // Asynchronous active-low reset, synchronous clock divider logic
    always @(posedge i_clkin or negedge i_rstn) begin
        if (!i_rstn) begin
            // Reset counter and output clock
            cnt <= 0;
            clkout_r <= 1'b0;
        end
        else begin
            if (cnt == HALF_PERIOD_COUNT - 1) begin
                // Toggle output clock and reset counter at terminal count
                cnt <= 0;
                clkout_r <= ~clkout_r;
            end
            else begin
                // Increment counter
                cnt <= cnt + 1'b1;
            end
        end
    end

endmodule
