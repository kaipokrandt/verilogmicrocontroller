// instruction decoder _ID.v
// takes the 16-bit instruction or fields from IR and finds out what kind of instruction it is
`timescale 1ns/1ps
module kaipokrandt_ID(
    input [15:0] instr,       // straight from IR (ir_out)
    // field outputs (so top level doesn't have to slice again)
    output[3:0] opcode, //4b
    output[5:0] param1, //6b
    output[5:0] param2, //6b
    // type flags for the many control FSMs
    output reg dec_alu_reg,  // ADD/SUB/AND/OR/XOR/XNOR/NOT using regs
    output reg dec_alu_imm,  // ADDI/SUBI
    output reg dec_load,      // memory load
    output reg dec_store,    // memory store
    output reg dec_mov,     // MOV regdest, regsource
    output reg dec_movi,   // MOVI regdest, # immediate
    // ALU op code  decider to feed into the ALU 
    output reg[3:0] alu_op,
    // helper
    output reg uses_imm       // 1 if instruction uses immediate in param2
);

    // split instruction up for digestion
    assign opcode = instr[15:12];
    assign param1 = instr[11:6];
    assign param2 = instr[5:0];

    // keep ALU opcodes consistent with ALU module
    localparam OP_ADD = 4'h0;
    localparam OP_ADDI = 4'h1;
    localparam OP_SUB = 4'h2;
    localparam OP_SUBI = 4'h3;
    localparam OP_NOT = 4'h4;
    localparam OP_AND = 4'h5;
    localparam OP_OR = 4'h6;
    localparam OP_XOR = 4'h7;
    localparam OP_XNOR = 4'h8;

    // opcodes for non-ALU stuff
    localparam OP_LOAD = 4'h9;
    localparam OP_STORE = 4'hA;
    localparam OP_MOV = 4'hB;
    localparam OP_MOVI = 4'hC;

    always @* begin
        // set everything 0
        dec_alu_reg = 1'b0;
        dec_alu_imm = 1'b0;
        dec_load = 1'b0;
        dec_store = 1'b0;
        dec_mov = 1'b0;
        dec_movi = 1'b0;
        uses_imm = 1'b0;
        alu_op = 4'h0;


        case (opcode)
            // regular ALU reg-reg ops
            OP_ADD: 
            begin
                dec_alu_reg = 1'b1;
                alu_op = OP_ADD;
            end
            OP_SUB: 
            begin
                dec_alu_reg = 1'b1;
                alu_op = OP_SUB;
            end
            OP_AND: 
            begin
                dec_alu_reg = 1'b1;
                alu_op = OP_AND;
            end
            OP_OR: 
            begin
                dec_alu_reg = 1'b1;
                alu_op = OP_OR;
            end
            OP_XOR: 
            begin
                dec_alu_reg = 1'b1;
                alu_op = OP_XOR;
            end
            OP_XNOR: 
            begin
                dec_alu_reg = 1'b1;
                alu_op = OP_XNOR;
            end
            OP_NOT: 
            begin
                dec_alu_reg = 1'b1;
                alu_op = OP_NOT;
            end



            // immediate ALU stuff
            OP_ADDI: 
            begin
                dec_alu_imm = 1'b1;
                uses_imm = 1'b1;
                alu_op = OP_ADDI;
            end
            OP_SUBI: 
            begin
                dec_alu_imm = 1'b1;
                uses_imm = 1'b1;
                alu_op = OP_SUBI;
            end


            // memory access
            OP_LOAD: 
            begin
                dec_load = 1'b1;
            end

            OP_STORE: 
            begin
                dec_store = 1'b1;
            end



            // simple data movement
            OP_MOV: 
            begin
                dec_mov = 1'b1;
            end
            OP_MOVI: 
            begin
                dec_movi = 1'b1;
                uses_imm = 1'b1;
            end
            default: 
            begin
                // goes here if the op code isnt known and nothing happens
            end
        endcase
    end
endmodule
