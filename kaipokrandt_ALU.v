// 16-bit ALU block core with input regs, output reg and tristate !!! to bus
// immediates ADDI/SUBI are loaded from the bus into in2 (param2)
`timescale 1ns/1ps

module kaipokrandt_ALU_core (
    // globals
    input wire clk,
    input wire reset,

    // shared system bus
    input wire[15:0] bus_in,
    output wire[15:0] bus_out,

    // control ins and outs and opcode
    input wire alu_out_en,   // tri-state driver enable
    input wire in1_ld,     // load In1 from bus_in
    input wire in2_ld,   // load In2 from bus_in (also for immediates)
    input wire out_ld,       // latch ALU result to output register
    input wire[3:0] alu_op        // operation select
);

    // opcode map down the list
    localparam OP_ADD = 4'h0;
    localparam OP_ADDI = 4'h1;
    localparam OP_SUB = 4'h2;
    localparam OP_SUBI = 4'h3;
    localparam OP_NOT = 4'h4;
    localparam OP_AND = 4'h5;
    localparam OP_OR = 4'h6;
    localparam OP_XOR = 4'h7;
    localparam OP_XNOR = 4'h8;

    // input registers
    reg[15:0] in1_q, in2_q;

    //on either edge
    always @(posedge clk or negedge reset) begin
        if (!reset)
            in1_q <= 16'h0000;
        else if (in1_ld)  
            in1_q <= bus_in;
    end
     //on either edge
    always @(posedge clk or negedge reset) begin
        if (!reset)       
            in2_q <= 16'h0000;
        else if (in2_ld)  
            in2_q <= bus_in; // immediates and R2 both load here
    end

    // ALU core
    wire[15:0] op_a = in1_q; // param1
    wire[15:0] op_b = in2_q; // param2
    reg[15:0] alu_y; // RESULT of ALU
    always @* begin
        case (alu_op)
            OP_ADD, OP_ADDI: alu_y = op_a + op_b;
            OP_SUB, OP_SUBI: alu_y = op_a - op_b;
            OP_NOT: alu_y = ~op_a;
            OP_AND: alu_y = op_a & op_b;
            OP_OR: alu_y = op_a | op_b;
            OP_XOR: alu_y = op_a ^ op_b;
            OP_XNOR: alu_y = ~(op_a ^ op_b);
            default: alu_y = 16'h0000;
        endcase
    end

    // output register
    reg[15:0] out_q;
    always @(posedge clk or negedge reset) begin
        if (!reset)  
            out_q <= 16'h0000;
        else if (out_ld) 
            out_q <= alu_y;
    end

    // tristate !!! sends to the bus
    assign bus_out = alu_out_en ? out_q : 16'hzzzz;
endmodule
