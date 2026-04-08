`timescale 1ns / 1ps

module drv_7segment(
    input           i_rstn, //  ASync Reset;
    input           i_clk,  //1Khz - Drive Hex Scan;
    input  [3:0]    i_hex3, // HEX3 - Data;
    input  [3:0]    i_hex2, // HEX2 - Data;
    input  [3:0]    i_hex1, // HEX1 - Data;
    input  [3:0]    i_hex0, // HEX0 - Data;
    output [7:0]    o_seg,  // Output Segment Data;
    output [3:0]    o_hex   // Output Hex (Digits) Data;
);

reg [1:0]   r_cnter     ;
reg [7:0]   r_seg       ;
reg [3:0]   r_hex       ;
reg [3:0]   r_hexdata   ;

assign o_hex = ~ r_hex;
assign o_seg = r_seg;

always @(negedge i_rstn, posedge i_clk) begin 
    if (!i_rstn)    r_cnter <= 2'b00;
    else            r_cnter <= r_cnter + 1'b1;
end

always @(r_cnter) begin
    case (r_cnter)
        2'b00   : r_hex <= 4'b0001;
        2'b01   : r_hex <= 4'b0010;
        2'b10   : r_hex <= 4'b0100;
        2'b11   : r_hex <= 4'b1000;
        default : r_hex <= 4'b0000;
    endcase
end

always @(r_cnter) begin
    case (r_cnter)
        2'b00   : r_hexdata <= i_hex0;
        2'b01   : r_hexdata <= i_hex1;
        2'b10   : r_hexdata <= i_hex2;
        2'b11   : r_hexdata <= i_hex3;
        default : r_hexdata <= 4'h0;
    endcase
end 

always @(*) begin
    case (r_hexdata)
        4'h0: r_seg = 8'b0_0111111; // 0
        4'h1: r_seg = 8'b0_0000110; // 1
        4'h2: r_seg = 8'b0_1011011; // 2
        4'h3: r_seg = 8'b0_1001111; // 3
        4'h4: r_seg = 8'b0_1100110; // 4
        4'h5: r_seg = 8'b0_1101101; // 5
        4'h6: r_seg = 8'b0_1111101; // 6
        4'h7: r_seg = 8'b0_0000111; // 7
        4'h8: r_seg = 8'b0_1111111; // 8
        4'h9: r_seg = 8'b0_1101111; // 9
        4'hA: r_seg = 8'b0_1110111; // A
        4'hB: r_seg = 8'b0_1111100; // b
        4'hC: r_seg = 8'b0_0111001; // C
        4'hD: r_seg = 8'b0_1011110; // d
        4'hE: r_seg = 8'b0_1111001; // E
        4'hF: r_seg = 8'b0_1110001; // F
        default: r_seg = 8'b0_0000000; // all off
    endcase
end

endmodule
