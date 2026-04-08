`timescale 1ns / 1ps

module drv_uart_tx(
    input   clk,
    input   ap_rstn,
    input   ap_ready,
    output  reg ap_valid,
    output  reg tx,
    input   pairty,
    input  [7:0] data
);

localparam  FSM_IDLE = 3'b000,
            FSM_STAR = 3'b001,
            FSM_TRSF = 3'b010,
            FSM_PARI = 3'b011,
            FSM_STOP = 3'b100;

reg [2:0] fsm_statu;
reg [2:0] fsm_next;
reg [2:0] cnter;

//fsm statu transfer;
always @(posedge clk, negedge ap_rstn) begin
    if (!ap_rstn)begin
        fsm_statu <= FSM_IDLE;
    end else begin
        fsm_statu <= fsm_next;
    end
end

//fsm conditional transfer;
always @(*)begin
    if(!ap_rstn)begin
        fsm_next <= FSM_IDLE;
    end else begin
        case(fsm_statu)
            FSM_IDLE:begin
                fsm_next <= (ap_ready) ? FSM_STAR : FSM_IDLE;
            end
            FSM_STAR: fsm_next <= FSM_TRSF;
            FSM_TRSF:begin
                fsm_next <= (cnter == 3'h7) ? (pairty?FSM_PARI:FSM_STOP) : FSM_TRSF;
            end
            FSM_PARI: fsm_next <= FSM_STOP;
            FSM_STOP:begin
                fsm_next <= (!ap_ready) ? FSM_IDLE : FSM_STOP;
            end
            default: fsm_next <= FSM_IDLE;
        endcase
    end
end

//fsm - output
always @(posedge clk, negedge ap_rstn)begin
    if(!ap_rstn)begin
        ap_valid <= 1'b0;
        tx <= 1'b1;
        cnter <= 3'h0;
    end else begin
        case (fsm_statu)
            FSM_IDLE: begin
                tx <= 1'b1;
                ap_valid <= 1'b0;
            end
            FSM_STAR: begin
                tx <= 1'b0;
                cnter <= 3'h0;
            end
            FSM_TRSF: begin
                tx <= data[cnter];
                cnter <= cnter + 1'b1;
            end
            FSM_PARI: tx <= (^data); //Parity Check - ODD Check;
            FSM_STOP: begin
                tx <= 1'b1;         //Stop Bit;
                ap_valid <= 1'b1;
            end
        endcase
    end
end

endmodule
