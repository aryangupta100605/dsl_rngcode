`timescale 1ns / 1ps

// Used to output the randomly generated signal
module top_module(
    input sysclk,
    input [1:0] btn,
    output [7:0] seg,
    output [3:0] hex,
    output uart_rxd_out,
    input  uart_txd_in,
    output adc_din,
    output adc_csn,
    output adc_clk,
    input adc_dout,
    //output [11:0] ch0_out,       
    //output [11:0] ch1_out,
    output reg led    
);


wire            clk_adc_tri,
                clk_adc_spi,
                clk_uart_tri,
                clk_uart_clk,
                clk_seg_clk;

wire            rstn;

wire    [3:0]   seg_hex3;
wire    [3:0]   seg_hex2;
wire    [3:0]   seg_hex1;
wire    [3:0]   seg_hex0;

reg [3:0] seg_hex3_reg, seg_hex2_reg, seg_hex1_reg, seg_hex0_reg;

reg             uart_ready;
wire            uart_valid;
reg     [7:0]   uart_data;
reg     [3:0]   uart_cnter;
reg             adc_ch;

wire    [1:0]   adc_mode;
wire    [11:0]  adc_data;
reg     [11:0]  r_adc_data0;
reg     [11:0]  r_adc_data1;
reg     [11:0]  latch_transf_data; 
reg     [11:0]  transf_data;   
wire            adc_ready;
wire            adc_valid;
wire    [11:0]  t_signal;
wire            valid_transform;
// wire    [31:0]  rng_num; // Unused, legacy

// --- LEGACY: Old latching logic parameter (kept for reference, used by latch_timer) ---
parameter LATCH_PERIOD = 27'd120_000_000; // 120 million cycles, legacy or optional feature

// --- LEGACY: Old latching logic (kept for reference, used by latched_rng_num and latch_timer) ---
reg [31:0] latched_rng_num; // Used for periodic latching, legacy or optional feature
reg [15:0] latch_timer;     // Used for periodic latching, legacy or optional feature

// Segmenting prng_random_data
reg             page;
reg             btn0_prev;
wire    [15:0]  active_num;
wire            btn0_rise;
wire    [31:0]  data = prng_random_data;
wire    [3:0]   d0 = data[3:0];
wire    [3:0]   d1 = data[7:4];
wire    [3:0]   d2 = data[11:8];
wire    [3:0]   d3 = data[15:12];
wire    [3:0]   d4 = data[19:16];
wire    [3:0]   d5 = data[23:20];
wire    [3:0]   d6 = data[27:24];
wire    [3:0]   d7 = data[31:28];
//wire [31:0] display_value = rng_num; // Legacy: display the raw RNG output (not transformed), replaced by prng_random_data for 12th output display 
wire [31:0] display_value = prng_random_data;

// Latch prng_random_data at a regular interval
always @(posedge clk_seg_clk or negedge rstn) begin
    if (!rstn) begin
        latched_rng_num <= 32'b0;
        latch_timer <= LATCH_PERIOD;
    end else if (latch_timer == 0) begin
        latched_rng_num <= prng_random_data;
        latch_timer <= LATCH_PERIOD;
    end else begin
        latch_timer <= latch_timer - 1;
    end
end

always @(posedge clk_seg_clk or negedge rstn) begin
    if (!rstn)
        page <= 1'b0;
    else if (btn0_rise)
        page <= ~page;
end

always @(posedge clk_seg_clk or negedge rstn) begin
    if (!rstn)
        btn0_prev <= 1'b0;
    else
        btn0_prev <= btn[0];
end

assign active_num = (page == 1'b0) ? display_value[31:16] : display_value[15:0];
assign btn0_rise = btn[0] & ~btn0_prev;
assign  rstn = ~btn[1];
assign adc_ready = rstn & clk_adc_tri;
// Allows for toggling between 2 channels, single end
assign adc_mode = {1'b0, adc_ch};
//assign  ch0_out = r_adc_data0;
//assign ch1_out = r_adc_data1;

/* --- LEGACY: Using LED to indicate UART activity (toggling each time a byte is sent) ---
always @(posedge clk_uart_tri or negedge rstn) begin
    if (!rstn)
        led <= 1'b0;
    else if (uart_ready)
        led <= ~led;  // toggle LED each time a byte is sent
    else led <= 1'b0;
end
*/




// Toggles between channels, once SPI data received
always @(posedge clk_adc_tri or negedge rstn) begin
    if (!rstn) begin
        adc_ch <= 1'b0;
    end else if (adc_valid) begin // Checks sample data is received, then switch channel to sample it
        adc_ch <= ~adc_ch;
    end
end

// Purpose: Storing respective signal in Ch0 & Ch1
always @(negedge rstn, posedge clk_adc_tri) begin
    if (!rstn)  begin
        r_adc_data0 <= 12'h000;
        r_adc_data1 <= 12'h000;
    end
    else begin
        if (!adc_ch) begin 
            r_adc_data0 <= adc_data;
        end
        else begin
            r_adc_data1 <= adc_data;
        end
    end
end

// Main purpose: Visualize signal via COM port
// --- LEGACY: Old UART state machine (sends t_signal, not random) ---
/*
always @(posedge clk_uart_tri or negedge rstn) begin
    if (!rstn) begin
        uart_cnter <= 4'd0;
        transf_data  <= 8'hFF;
        uart_ready <= 1'b0;
        led        <= 1'b0;
    end else begin
    transf_data <= t_signal;
        case (uart_cnter)
            4'd0: begin
                latch_transf_data <= transf_data;
                uart_ready <= 1'b1;
                uart_cnter <= uart_cnter + 1'b1;
            end
           
            4'd1: begin
                uart_ready <= 1'b0;
                uart_cnter <= uart_cnter + 1'b1; 
            end
            
            4'd2: begin
                uart_data  <= {8'hAA};
                uart_ready <= 1'b1;
                uart_cnter <= uart_cnter + 1'b1;
            end
            
            4'd3: begin
                uart_ready <= 1'b0;
                uart_cnter <= uart_cnter + 1'b1; 
            end
            
            4'd4: begin
                uart_data  <= {4'h00, latch_transf_data[11:8]};
                uart_ready <= 1'b1;
                uart_cnter <= uart_cnter + 1'b1;
            end
            
            4'd5: begin
                uart_ready <= 1'b0;
                uart_cnter <= uart_cnter + 1'b1;
            end
            
            4'd6: begin
                uart_data  <= {latch_transf_data[7:0]};
                uart_ready <= 1'b1;
                uart_cnter <= uart_cnter + 1'b1;
            end
            
            4'd7: begin
                uart_ready <= 1'b0;
                uart_cnter <= uart_cnter + 1'b1;
           end  
            
            4'd8: begin
                uart_data  <= 8'hFF;
                uart_ready <= 1'b1;
                uart_cnter <= 4'd00;
            end
            
            4'd13: begin
                uart_ready <= 1'b0;
                uart_cnter <= 4'd00;
           end  
        endcase
    end
 end
*/
// --- REPLACEMENT: New UART state machine (sends prng_random_data) ---
reg [31:0] uart_latched_rng;
reg [3:0] uart_state;
always @(posedge clk_uart_tri or negedge rstn) begin
    if (!rstn) begin
        uart_state <= 4'd0;
        uart_ready <= 1'b0;
        uart_data  <= 8'hFF;
        uart_latched_rng <= 32'h0;
        led        <= 1'b0;
    end else begin
        case (uart_state)
            4'd0: begin // Latch new random value, start frame
                uart_latched_rng <= prng_random_data;
                uart_data  <= 8'hAA;
                uart_ready <= 1'b1;
                uart_state <= 4'd1;
            end
            4'd1: begin // Wait for UART ready to be consumed
                uart_ready <= 1'b0;
                uart_state <= 4'd2;
            end
            4'd2: begin // Send MSB
                uart_data  <= uart_latched_rng[31:24];
                uart_ready <= 1'b1;
                uart_state <= 4'd3;
            end
            4'd3: begin
                uart_ready <= 1'b0;
                uart_state <= 4'd4;
            end
            4'd4: begin // Send next byte
                uart_data  <= uart_latched_rng[23:16];
                uart_ready <= 1'b1;
                uart_state <= 4'd5;
            end
            4'd5: begin
                uart_ready <= 1'b0;
                uart_state <= 4'd6;
            end
            4'd6: begin // Send next byte
                uart_data  <= uart_latched_rng[15:8];
                uart_ready <= 1'b1;
                uart_state <= 4'd7;
            end
            4'd7: begin
                uart_ready <= 1'b0;
                uart_state <= 4'd8;
            end
            4'd8: begin // Send LSB
                uart_data  <= uart_latched_rng[7:0];
                uart_ready <= 1'b1;
                uart_state <= 4'd9;
            end
            4'd9: begin
                uart_ready <= 1'b0;
                uart_state <= 4'd10;
            end
            4'd10: begin // Send 0xFF end byte
                uart_data  <= 8'hFF;
                uart_ready <= 1'b1;
                uart_state <= 4'd11;
            end
            4'd11: begin
                uart_ready <= 1'b0;
                uart_state <= 4'd0; // Immediately start next frame
            end
            default: begin
                uart_ready <= 1'b0;
                uart_state <= 4'd0;
            end
        endcase
    end
end

// --- LEGACY: Old display logic (shows rng_num) ---
/*
assign seg_hex0 = active_num[3:0];
assign seg_hex1 = active_num[7:4];
assign seg_hex2 = active_num[11:8];
assign seg_hex3 = active_num[15:12];
*/
// --- REPLACEMENT: New display logic (shows 12th xorshift output, MSB/LSB toggle) ---
// The 12th output is shiwn to allow the algorithm to show more "random" values, but this is an arbitrary choice for demonstration purposes. You can change it to show any output you like (e.g., the latest output or a specific one).
reg [31:0] xorshift_display_value;
reg [3:0] xorshift_output_counter;
reg prev_rstn;

always @(posedge clk_seg_clk or negedge rstn) begin
    if (!rstn) begin
        xorshift_output_counter <= 0;
        xorshift_display_value <= 0;
        prev_rstn <= 0;
    end else begin
        // Detect rising edge of rstn (reseed event)
        if (!prev_rstn && rstn) begin
            xorshift_output_counter <= 0;
        end else if (xorshift_output_counter < 12) begin// can be any number 12 was set as a placeholder for the "12th output" which is an arbitrary choice for demonstration
            xorshift_output_counter <= xorshift_output_counter + 1;
            if (xorshift_output_counter == 11) begin // 12th output (counting from 0)
                xorshift_display_value <= prng_random_data;
            end
        end
        prev_rstn <= rstn;
    end
end

// 7-segment display logic: show only the 12th output, MSB 16 bits when btn[0] pressed, LSB 16 bits when not pressed
always @(posedge clk_seg_clk or negedge rstn) begin
    if (!rstn) begin
        seg_hex3_reg <= 0;
        seg_hex2_reg <= 0;
        seg_hex1_reg <= 0;
        seg_hex0_reg <= 0;
    end else if (btn[0]) begin
        seg_hex3_reg <= xorshift_display_value[31:28];
        seg_hex2_reg <= xorshift_display_value[27:24];
        seg_hex1_reg <= xorshift_display_value[23:20];
        seg_hex0_reg <= xorshift_display_value[19:16];
    end else begin
        seg_hex3_reg <= xorshift_display_value[15:12];
        seg_hex2_reg <= xorshift_display_value[11:8];
        seg_hex1_reg <= xorshift_display_value[7:4];
        seg_hex0_reg <= xorshift_display_value[3:0];
    end
end
assign seg_hex3 = seg_hex3_reg;
assign seg_hex2 = seg_hex2_reg;
assign seg_hex1 = seg_hex1_reg;
assign seg_hex0 = seg_hex0_reg;

clk_div #( 
    .CLK_IN_HZ  (12_000_000),
    .CLK_OUT_HZ (1_000)
)div0(
    .i_clkin    (sysclk),  
    .i_rstn     (rstn),   
    .o_clkout   (clk_adc_tri)
);

clk_div #( 
    .CLK_IN_HZ  (12_000_000),
    .CLK_OUT_HZ (1_000_000)
)div1(
    .i_clkin    (sysclk),  
    .i_rstn     (rstn),   
    .o_clkout   (clk_adc_spi)
);


// Use a faster clock for UART state machine: 11520 Hz for 115200 baud (1/10th)
clk_div #( 
    .CLK_IN_HZ  (12_000_000),
    .CLK_OUT_HZ (11520)
)div2_uart_tri(
    .i_clkin    (sysclk),  
    .i_rstn     (rstn),   
    .o_clkout   (clk_uart_tri)
);

clk_div #( 
    .CLK_IN_HZ  (12_000_000),
    .CLK_OUT_HZ (115200)
)div3(
    .i_clkin    (sysclk),  
    .i_rstn     (rstn),   
    .o_clkout   (clk_uart_clk)
);

clk_div #( 
    .CLK_IN_HZ  (12_000_000),
    .CLK_OUT_HZ (1_000)
)div4(
    .i_clkin    (sysclk),  
    .i_rstn     (rstn),   
    .o_clkout   (clk_seg_clk)
);

drv_7segment seg_u0(
    .i_rstn  (rstn), 
    .i_clk   (clk_seg_clk),  
    .i_hex3  (seg_hex3), 
    .i_hex2  (seg_hex2), 
    .i_hex1  (seg_hex1), 
    .i_hex0  (seg_hex0), 
    .o_seg   (seg),  
    .o_hex   (hex)   
);

drv_uart_tx uart_u0(
    .clk        (clk_uart_clk),
    .ap_rstn    (rstn),
    .ap_ready   (uart_ready), // single-cycle pulse
    .ap_valid   (uart_valid),
    .tx         (uart_rxd_out),
    .pairty     (1'b0),
    .data       (uart_data)
);

drv_mcp3202 adc_u0 (
    .rstn      (rstn),
    .clk       (clk_adc_spi),
    .ap_ready  (adc_ready),
    .ap_valid  (adc_valid),
    .mode      (adc_mode),
    .data      (adc_data),
    .adc_din   (adc_din),   // FPGA -> ADC DIN
    .adc_dout  (adc_dout),  // ADC DOUT -> FPGA
    .adc_clk   (adc_clk),
    .adc_cs    (adc_csn)
);


signal_processor proc_u0 (
    .clk             (clk_adc_tri), // use adc clock for timing
    .rst_n           (rstn),
    .raw_bit_in      (r_adc_data0[0] ^ r_adc_data1[0]), // XOR the lsbs for more entropy
    .raw_valid       (adc_valid),    
    .transformed_sig (t_signal),
    .rm_corrbias     (valid_transform)         
);



rng_algo_processor proc_u1 (
    .clk             (clk_adc_tri), // use adc clock for timing
    .reset           (rstn),
    .ap_valid        (adc_valid),
    .seed_load       (valid_transform),
    .de_corrbias_sig (t_signal),
    .rng_num_out     (rng_num)
                
);



// --- Instantiate adc_xorshift for LED feedback ---
wire [31:0] prng_random_data;
wire        prng_uart_ready;
wire [7:0]  prng_uart_data;
wire        prng_led;

adc_xorshift #(
    .DATA_WIDTH(12),
    .OUT_WIDTH(32)
) prng_inst (
    .clk(sysclk),
    .rst_n(rstn),
    .adc_data(12'd0),
    .random_data(prng_random_data),
    .hex3(), .hex2(), .hex1(), .hex0(),
    .uart_ready(prng_uart_ready),
    .uart_data(prng_uart_data),
    .btn0(btn[0]),
    .led(prng_led)
);

// Connect the PRNG LED output to the top-level LED
always @(posedge sysclk or negedge rstn) begin
    if (!rstn) begin
        led <= 0;
    end else begin
        led <= prng_led;
    end
end
// --- Integration of xorshift_top (modular PRNG, UART, and 7-segment display) ---
// The following block is commented out because xorshift_top is not used in this design or the file is missing.
/*
// xorshift_top outputs are routed to unique signals to avoid conflict with existing outputs.
// wire [7:0] xorshift_seg;
// wire [3:0] xorshift_hex;
// wire xorshift_uart_rxd_out;
// wire xorshift_led;
//
// Updated xorshift_top instantiation: only sysclk and btn are connected (other ports removed from module)
// xorshift_top xorshift_top_inst (
//     .sysclk(sysclk),           // System clock
//     .btn(btn)                  // Button inputs
//     // Other ports are not connected to avoid conflicts with main outputs
// );
*/

endmodule

