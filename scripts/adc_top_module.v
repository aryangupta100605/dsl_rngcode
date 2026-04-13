`timescale 1ns / 1ps

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
//    output [11:0] ch0_out,       UNCOMMENT TO INSERT EXTRACT ADC_DATA
//    output [11:0] ch1_out,
    output reg led    
);

//ADC Data Trigger    @40KHz;
//ADC SPI Clock       @1MHz;
//UART Data Trigger   @40KHz;
//UART Data Rate      @921600Hz;
//7Segment Display    @1KHz;

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

reg             uart_ready;
wire            uart_valid;
reg     [7:0]   uart_data;
reg     [3:0]   uart_cnter;
reg             adc_ch;

wire             adc_mode;
wire    [11:0]  adc_data;
reg     [11:0]  r_adc_data0;
reg     [11:0]  r_adc_data1;
reg     [11:0]  latch_adc_data0;
reg     [11:0]  latch_adc_data1;   
wire             adc_ready;
wire            adc_valid;
wire    [11:0]  seed_from_sampler;
wire            seed_valid;


assign  rstn = ~btn[1];
assign adc_ready = rstn & clk_adc_tri;
assign adc_mode = {1'b0, adc_ch};
//assign  ch0_out = r_adc_data0;   UNCOMMENT TO INSERT EXTRACT ADC_DATA
//assign ch1_out = r_adc_data1;


always @(posedge clk_uart_tri or negedge rstn) begin
    if (!rstn)
        led <= 1'b0;
    else if (uart_ready)
        led <= ~led;  // toggle LED each time a byte is sent
    else led <= 1'b0;
end

always @(posedge clk_adc_tri or negedge rstn) begin
    if (!rstn) begin
        adc_ch <= 1'b0;
    end else if (adc_valid) begin // Checks sample data is received, then switch channel to sample it
        adc_ch <= ~adc_ch;
    end
end

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

always @(posedge clk_uart_tri or negedge rstn) begin
    if (!rstn) begin
        uart_cnter <= 4'd0;
        uart_data  <= 8'hFF;
        uart_ready <= 1'b0;
        led        <= 1'b0;
    end else begin
//        uart_ready <= 1'b0;  // default low
        case (uart_cnter)
            4'd0: begin
                latch_adc_data0 <= r_adc_data0;
                latch_adc_data1 <= r_adc_data1;
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
                uart_data  <= {4'h00, latch_adc_data0[11:8]};
                uart_ready <= 1'b1;
                uart_cnter <= uart_cnter + 1'b1;
            end
            
            4'd5: begin
                uart_ready <= 1'b0;
                uart_cnter <= uart_cnter + 1'b1;
            end
            
            4'd6: begin
                uart_data  <= {latch_adc_data0[7:0]};
                uart_ready <= 1'b1;
                uart_cnter <= uart_cnter + 1'b1;
            end
            
           4'd7: begin
                uart_ready <= 1'b0;
                uart_cnter <= uart_cnter + 1'b1;
           end  
           
            4'd8: begin
                uart_data  <= {4'h00, latch_adc_data1[11:8]};
                uart_ready <= 1'b1;
                uart_cnter <= uart_cnter + 1'b1;
            end
            
            4'd9: begin
                uart_ready <= 1'b0;
                uart_cnter <= uart_cnter + 1'b1;
           end  
            
            4'd10: begin
                uart_data  <= {latch_adc_data1[7:0]};
                uart_ready <= 1'b1;
                uart_cnter <= uart_cnter + 1'b1;
            end
            
            4'd11: begin
                uart_ready <= 1'b0;
                uart_cnter <= uart_cnter + 1'b1;
           end  
            
            4'd12: begin
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


// Displays ch0 
assign seg_hex3 = 4'h0;
assign seg_hex2 = r_adc_data0[11:8];
assign seg_hex1 = r_adc_data0[7:4];
assign seg_hex0 = r_adc_data0[3:0];

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

clk_div #( 
    .CLK_IN_HZ  (12_000_000),
    .CLK_OUT_HZ (20)
)div2(
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

random_sampler #(.DATA_WIDTH(12), .COUNTER_WIDTH(17)) rng_sampler (
    .clk(sysclk),
    .rst_n(rstn),
    .processed_signal(adc_data),   // or whatever signal they provide
    .seed(seed_from_sampler),
    .seed_valid(seed_valid)
);

endmodule

