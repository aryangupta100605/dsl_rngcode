`timescale 1ns / 1ps
module drv_mcp3202(
    input        rstn,
    input        clk,
    input        ap_ready,
    output reg   ap_valid,
    input  [1:0] mode,
    output [11:0] data,

    // === SPI pins to MCP3202 ===
    // adc_din  : FPGA -> ADC (MOSI, goes to MCP3202 DIN)
    // adc_dout : ADC  -> FPGA (MISO, comes from MCP3202 DOUT)
    output reg  adc_din,
    input       adc_dout,
    output      adc_clk,
    output reg  adc_cs
);

    // 4-bit control word to send to MCP3202
    wire [3:0]  Data_Transmit;  // [START, SGL/DIFF, ODD/SIGN, MSBF]
    // 1 dummy bit + 12 data bits from MCP3202
    reg  [12:0] Data_Receive;

    assign Data_Transmit[3]   = 1'b1;      // START bit
    assign Data_Transmit[0]   = 1'b1;      // MSBF (always 1 for MCP3202)
    assign Data_Transmit[2:1] = mode;      // channel / mode select

    reg [1:0] fsm_statu, fsm_next;
    localparam FSM_IDLE = 2'b00;
    localparam FSM_WRIT = 2'b10;
    localparam FSM_READ = 2'b11;
    localparam FSM_STOP = 2'b01;

    reg [1:0] cnter_writ;
    reg [3:0] cnter_read;

    //===========================================================
    // FSM state register
    //===========================================================
    always @(posedge clk or negedge rstn) begin
        if (!rstn)
            fsm_statu <= FSM_IDLE;
        else
            fsm_statu <= fsm_next;
    end

    //===========================================================
    // FSM next-state logic
    //===========================================================
    always @(*) begin
        if (!rstn) begin
            fsm_next = FSM_IDLE;
        end else begin
            case (fsm_statu)
                FSM_IDLE: fsm_next = (ap_ready)          ? FSM_WRIT : FSM_IDLE;
                FSM_WRIT: fsm_next = (cnter_writ == 2'd0)? FSM_READ : FSM_WRIT;
                FSM_READ: fsm_next = (cnter_read == 4'd0)? FSM_STOP : FSM_READ;
                FSM_STOP: fsm_next = (!ap_ready)         ? FSM_STOP : FSM_IDLE;
                default:  fsm_next = FSM_IDLE;
            endcase
        end
    end

    //===========================================================
    // FSM outputs - SPI write (MOSI, CS) on falling edge of clk
    //===========================================================
    always @(negedge clk or negedge rstn) begin
        if (!rstn) begin
            cnter_writ <= 2'd3;
            adc_din    <= 1'b1;
            adc_cs     <= 1'b1;
        end else begin
            case (fsm_statu)
                FSM_IDLE: begin
                    cnter_writ <= 2'd3;
                    adc_din    <= 1'b1;
                    adc_cs     <= 1'b1;
                end
                FSM_WRIT: begin
                    adc_cs     <= 1'b0;
                    adc_din    <= Data_Transmit[cnter_writ];  // MOSI
                    cnter_writ <= cnter_writ - 1'b1;
                end
                FSM_READ: begin
                    adc_cs     <= 1'b0;
                    adc_din    <= 1'b1;                       // keep MOSI high
                end
                FSM_STOP: begin
                    adc_cs     <= 1'b1;
                end
                default: ; // do nothing
            endcase
        end
    end

    //===========================================================
    // FSM outputs - SPI read (MISO) and ap_valid on rising edge
    //===========================================================
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            cnter_read   <= 4'd13;
            Data_Receive <= 13'h0000;
            ap_valid     <= 1'b0;
        end else begin
            case (fsm_statu)
                FSM_IDLE: begin
                    ap_valid   <= 1'b0;
                    cnter_read <= 4'd13;
                end

                FSM_WRIT: begin
                    Data_Receive <= 13'h0000;
                    ap_valid     <= 1'b0;
                end

                FSM_READ: begin
                    cnter_read                 <= cnter_read - 1'b1;
                    Data_Receive[cnter_read]   <= adc_dout;   // sample MISO
                    ap_valid                   <= 1'b0;
                end

                FSM_STOP: begin
                    ap_valid <= 1'b1;  // one conversion word ready
                end

                default: begin
                    ap_valid <= 1'b0;
                end
            endcase
        end
    end

    //===========================================================
    // SPI clock and data output
    //===========================================================
    assign adc_clk = clk | adc_cs;         // stop toggling when CS is high
    assign data    = Data_Receive[11:0];   // 12-bit ADC result

endmodule
