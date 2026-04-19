// adc_xorshift: Modular PRNG (pseudo-random number generator) with UART and 7-segment display output
// - Combines three xorshift PRNGs and an LFSR for entropy mixing
// - Supports reseeding via button and hardware-generated fake signal
// - Outputs random data to UART and 7-segment display
// - Parameters:
//   DATA_WIDTH: Width of ADC input 
//   OUT_WIDTH: Width of random output (default 32 bits)
//   UART_PERIOD: Timer for UART output rate

module adc_xorshift #(
    parameter DATA_WIDTH   = 12, // ADC input width 
    parameter OUT_WIDTH    = 32, // Output width for random_data
    parameter UART_PERIOD  = 24'd500000   // UART output period (controls output rate)
)(
    input  wire                     clk,         // System clock
    input  wire                     rst_n,       // Active-low reset
    input  wire [DATA_WIDTH-1:0]    adc_data,    // ADC input (not used)
    output reg  [OUT_WIDTH-1:0]     random_data, // Main random output
    output wire [3:0]               hex3,        // 7-segment digit 3 (MSB nibble)
    output wire [3:0]               hex2,        // 7-segment digit 2
    output wire [3:0]               hex1,        // 7-segment digit 1
    output wire [3:0]               hex0,        // 7-segment digit 0 (LSB nibble)
    output reg                      uart_ready,  // UART ready flag
    output reg  [7:0]               uart_data,   // UART data byte
    input  wire                     btn0,        // Button 0 for reseeding
    output reg                      led          // LED output
);

    // --- PRNG state registers ---
    reg [31:0] xorshift1; // State for xorshift PRNG 1
    reg [31:0] xorshift2; // State for xorshift PRNG 2
    reg [31:0] xorshift3; // State for xorshift PRNG 3
    reg [31:0] lfsr;      // State for LFSR (linear feedback shift register)
    reg [31:0] combined;  // Combined entropy from all PRNGs
    reg [31:0] mixed;     // Mixed value for extra diffusion
    reg [31:0] hashed;    // Final hashed output
    reg [31:0] sbox_out;  // Output after S-box 
    reg [31:0] latched_value; // Value latched for UART output
    reg [23:0] uart_timer;    // Timer for UART output pacing
    reg [2:0]  send_state;    // UART state machine state
    reg [7:0]  reseed_counter;// Counter for reseeding events

    // --- Output mixing and toggling ---
    reg [11:0] fast_counter;  // Fast counter for output mixing
    reg invert_toggle;        // Toggle for output inversion
    reg [11:0] prev_fake_signal; // Previous value of fake_signal for LED toggle

    // --- 7-segment display assignments ---
    assign hex3 = 4'h0;                  // Unused digit (always 0)
    assign hex2 = random_data[11:8];     // 2nd most significant nibble
    assign hex1 = random_data[7:4];      // 3rd nibble
    assign hex0 = random_data[3:0];      // Least significant nibble

    // --- Internal fake signal and counter for entropy ---
    reg [11:0] fake_signal = 12'h178;    // Simulated entropy source
    reg [9:0] fake_signal_counter = 0;   // Counter for fake_signal increment

    // --- 4-bit S-box function for non-linear mixing (optional) ---
    // Provides non-linear mixing for 4-bit nibbles (can be used for extra diffusion)
    function [3:0] sbox4;
        input [3:0] in; // 4-bit input
        case (in)
            4'h0: sbox4 = 4'hE; 4'h1: sbox4 = 4'h4; 4'h2: sbox4 = 4'hD; 4'h3: sbox4 = 4'h1;
            4'h4: sbox4 = 4'h2; 4'h5: sbox4 = 4'hF; 4'h6: sbox4 = 4'hB; 4'h7: sbox4 = 4'h8;
            4'h8: sbox4 = 4'h3; 4'h9: sbox4 = 4'hA; 4'hA: sbox4 = 4'h6; 4'hB: sbox4 = 4'hC;
            4'hC: sbox4 = 4'h5; 4'hD: sbox4 = 4'h9; 4'hE: sbox4 = 4'h0; 4'hF: sbox4 = 4'h7;
        endcase
    endfunction

    // --- Main always block: Handles PRNG update, reseeding, output mixing, and UART state machine ---
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin // On reset
            // Use ADC output as seed for xorshift and LFSR
            xorshift1 <= {20'hA1B2C, adc_data}; // Seed xorshift1 with constant and ADC data
            xorshift2 <= {20'hD3E4F, adc_data ^ 12'h5A5}; // Seed xorshift2 with constant and XORed ADC data
            xorshift3 <= {20'h13579, ~adc_data}; // Seed xorshift3 with constant and inverted ADC data
            lfsr      <= {20'h2468A, adc_data ^ 12'hC3C}; // Seed LFSR with constant and XORed ADC data
            random_data    <= 0;           // Clear output
            latched_value  <= 0;           // Clear UART latch
            uart_timer     <= UART_PERIOD; // Reset UART timer
            send_state     <= 3'd0;        // Reset UART state machine
            uart_ready     <= 1'b0;        // Clear UART ready
            uart_data      <= 8'h00;       // Clear UART data
            reseed_counter <= 8'd0;        // Reset reseed counter
            fast_counter   <= 0;           // Reset fast counter
            invert_toggle  <= 0;           // Reset invert toggle
            sbox_out      <= 0;            // Reset sbox_out
            led <= 0;
            // Old test/fake_signal-based seeding (commented out):
            // xorshift1 <= {20'hA1B2C, fake_signal}; // Seed xorshift1 with constant and fake_signal
            // xorshift2 <= {20'hD3E4F, fake_signal ^ 12'h5A5}; // Seed xorshift2 with constant and XORed fake_signal
            // xorshift3 <= {20'h13579, ~fake_signal}; // Seed xorshift3 with constant and inverted fake_signal
            // lfsr      <= {20'h2468A, fake_signal ^ 12'hC3C}; // Seed LFSR with constant and XORed fake_signal
        end else begin // On each clock cycle
            // --- Entropy: Increment fake_signal every 1000 clocks ---
            if (fake_signal_counter == 999) begin
                fake_signal <= fake_signal + 1'b1;
                fake_signal_counter <= 0;
            end else begin
                fake_signal_counter <= fake_signal_counter + 1;
            end
            // --- PRNG updates: xorshift and LFSR logic ---
            xorshift1 <= (((xorshift1 ^ (xorshift1 << 6)) ^ (xorshift1 >> 7)) ^ (xorshift1 << 2)) & 32'hFFFFFFFF; // xorshift1 update
            xorshift2 <= (((xorshift2 ^ (xorshift2 << 3)) ^ (xorshift2 >> 5)) ^ (xorshift2 << 8)) & 32'hFFFFFFFF; // xorshift2 update
            xorshift3 <= (((xorshift3 ^ (xorshift3 << 1)) ^ (xorshift3 >> 1)) ^ (xorshift3 << 10)) & 32'hFFFFFFFF; // xorshift3 update
            lfsr      <= {lfsr[30:0], lfsr[31] ^ lfsr[30] ^ lfsr[29] ^ lfsr[3]}; // LFSR update

            // --- Entropy mixing and output hashing ---
            combined <= xorshift1 ^ xorshift2 ^ xorshift3 ^ lfsr; // XOR all PRNGs
            mixed <= (combined + {xorshift1[15:0], xorshift2[15:0]}) ^ (lfsr + xorshift3); // Add and XOR for diffusion
            hashed <= (mixed ^ {mixed[15:0], mixed[31:16]}) + (mixed >> 3); // Final hash: rotate, XOR, add

            // --- Output assignment ---
            random_data <= hashed; // Main output is the hashed value

            // --- Fast counter and toggle for output mixing ---
            fast_counter <= fast_counter + 1;
            invert_toggle <= ~invert_toggle;
            // Use hashed as sbox_out for now (could use sbox4 on nibbles for more diffusion)
            sbox_out <= hashed;

            reseed_counter <= reseed_counter + 1'b1; // Increment reseed counter

            // --- UART state machine for outputting random data ---
            if (send_state == 3'd0) begin // Idle state
                uart_ready <= 1'b0; // Not ready
                if (uart_timer == 0) begin // Time to send
                    uart_timer    <= UART_PERIOD; // Reset timer
                    // Latch the mixed output (with counter/inversion) for UART
                    if (invert_toggle)
                        latched_value <= ~(sbox_out ^ fast_counter); // Optionally invert output
                    else
                        latched_value <= sbox_out ^ fast_counter;    // Output with fast_counter mixed in
                    send_state    <= 3'd1; // Move to next state
                end else begin
                    uart_timer <= uart_timer - 1; // Decrement timer
                end
            end else begin // Sending bytes
                case (send_state)
                    3'd1: uart_data <= 8'hAA;                // Start byte
                    3'd2: uart_data <= latched_value[31:24]; // MSB
                    3'd3: uart_data <= latched_value[23:16]; // 2nd byte
                    3'd4: uart_data <= latched_value[15:8];  // 3rd byte
                    3'd5: uart_data <= latched_value[7:0];   // LSB
                    3'd6: uart_data <= 8'hFF;                // End byte
                    default: uart_data <= 8'h00;             // Default
                endcase

                uart_ready <= 1'b1; // Indicate UART data is ready

                if (send_state == 3'd6)
                    send_state <= 3'd0; // Return to idle after last byte
                else
                    send_state <= send_state + 1; // Next byte
            end
        end
    end

    // --- LED feedback: Toggle the LED every time fake_signal increases ---
    // For visual feedback, toggle the LED every time fake_signal increments (indicating entropy changes) 
    /*
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prev_fake_signal <= 0;
            led <= 0;
        end else begin
            if (fake_signal != prev_fake_signal) begin
                led <= ~led; // Toggle LED every time fake_signal increases
                prev_fake_signal <= fake_signal;
            end
        end
    end
    */
endmodule
