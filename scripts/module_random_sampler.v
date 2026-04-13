module random_sampler #(
    parameter DATA_WIDTH = 12,
    parameter COUNTER_WIDTH = 17   // 2^17 = 131072 > 100000
)(
    input wire clk,                 // 12 MHz
    input wire rst_n,
    input wire [DATA_WIDTH-1:0] processed_signal,
    output reg [DATA_WIDTH-1:0] seed,
    output reg seed_valid
);

    reg [COUNTER_WIDTH-1:0] counter;
    reg [COUNTER_WIDTH-1:0] lfsr;
    wire sample_trigger;

    // LFSR polynomial: x^17 + x^14 + 1 (maximal length)
    wire feedback = lfsr[16] ^ lfsr[13];

    // Free-running counter (0 to 100000, then wraps)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            counter <= 0;
        else if (counter == 100000)
            counter <= 0;
        else
            counter <= counter + 1;
    end

    // Free-running LFSR
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            lfsr <= {COUNTER_WIDTH{1'b1}};  // avoid all-zeros lockup
        else
            lfsr <= {lfsr[COUNTER_WIDTH-2:0], feedback};
    end

    // FIX #1 & #3: Removed redundant bit-slice and ternary.
    // FIX #3: Gate the trigger so it only fires when LFSR is within
    //         the counter range (<=100000), ensuring all trigger intervals
    //         are equally reachable and sampling is uniformly random.
    assign sample_trigger = (lfsr <= 100000) && (counter == lfsr);

    // Sample the processed_signal on trigger
    // FIX #2: Replaced double NBA pattern with explicit if-else
    //         to make intent clear and avoid relying on NBA ordering.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            seed       <= 0;
            seed_valid <= 0;
        end else begin
            if (sample_trigger) begin
                seed       <= processed_signal;
                seed_valid <= 1'b1;
            end else begin
                seed_valid <= 1'b0;
            end
        end
    end

endmodule
