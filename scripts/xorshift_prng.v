module xorshift_prng (
    input wire clk,           
    input wire rstn,          
    input wire seed_valid,    
    input wire [11:0] seed,   
    output reg [11:0] rand_out 
);
    reg [15:0] state; 

    wire [15:0] step1 = state ^ (state << 7);
    wire [15:0] step2 = step1 ^ (step1 >> 9);
    wire [15:0] step3 = step2 ^ (step2 << 8);

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            state <= 16'hFFFF;
        end 
        else if (seed_valid) begin
            // Grabs the physical seed from your teammate's sampler exactly when it fires
            state <= (seed == 0) ? 16'hFFFF : {4'b1111, seed};
        end
        else begin
            state <= step3;
        end
    end

    always @(*) begin
        rand_out = state[11:0]; 
    end
endmodule