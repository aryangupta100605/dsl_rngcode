// ==========================================
// 1.XOR ALGORITHM (XORSHIFT)
// ==========================================
module simple_xorshift_12bit (
    input wire clk,
    input wire reset,
    input wire [11:0] seed,      // Your 12-bit input seed
    output reg [11:0] rand_out   // Your 12-bit random output
);
    // Xorshift needs a 16-bit internal state to generate good randomness
    reg [15:0] state; 

    // The three pure XOR-shift operations (Shift L7, R9, L8)
    wire [15:0] step1 = state ^ (state << 7);
    wire [15:0] step2 = step1 ^ (step1 >> 9);
    wire [15:0] step3 = step2 ^ (step2 << 8);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Pad your 12-bit seed with 1s to fill the 16-bit engine.
            // Safety catch: Xorshift crashes if the state is exactly 0.
            state <= (seed == 0) ? 16'hFFFF : {4'b1111, seed};
        end 
        else begin
            // Update the state using the XOR logic
            state <= step3;
        end
    end

    // Instantly truncate the 16-bit engine down to your requested 12-bit output
    always @(*) begin
        rand_out = state[11:0]; 
    end
endmodule

// ==========================================
// 2.TESTBENCH
// ==========================================
module tb_simple_xorshift_12bit;


    reg [11:0] MY_SEED = 12'h43b; // can declare seed here

    reg clk;
    reg reset;
    wire [11:0] rand_out;

    simple_xorshift_12bit uut (
        .clk(clk), 
        .reset(reset), 
        .seed(MY_SEED), 
        .rand_out(rand_out)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1; // Instantly loads your seed
        #10;
        reset = 0; // Starts the XOR algorithm
        #400;      // Runs for 30 clock cycles
        $display("Final Random Output: %0d", rand_out);
        
        $finish; 
    end
// If you want to see all outputs fron the xor shift cycles
    //always @(posedge clk) begin
        //if (!reset) $display("XOR Random Output: %h", rand_out);
    //end
endmodule