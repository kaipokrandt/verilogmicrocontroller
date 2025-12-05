// fsm for ADD, SUB, AND, OR, XOR, XNOR, NOT
// handles all the regular ALU stuff and things for math

`timescale 1ns/1ps


module kaipokrandt_fsm_alu_reg(
    // globals
    input clk,
    input reset,
    // go high when regALU found
    input start,        
    input dec_alu_reg,  // from ID
    input[3:0] alu_op_in,    // decoded ALU operation
    // on or off
    output reg busy,
    output reg done,
    // control to ALU
    output reg alu_in1_ld,
    output reg alu_in2_ld,
    output reg alu_out_ld,
    output reg alu_out_en,
    output reg[3:0] alu_op,   // drive ALU alu_op input
    // control to register bank
    output reg dst_reg_en,   // put dest on bus
    output reg dst_reg_ld,   // load dest from bus
    output reg src_reg_en    // put src on bus
);

    // create state assignments
    localparam S_IDLE = 3'd0;
    localparam S_LOAD_A = 3'd1;
    localparam S_LOAD_B = 3'd2;
    localparam S_EXEC = 3'd3;
    localparam S_WRITEBACK = 3'd4;
    localparam S_DONE = 3'd5;
    reg[2:0] state, next_state;

    // state register
    always @(posedge clk or negedge reset) begin
        if (!reset)
            state <= S_IDLE;
        else
            state <= next_state;
    end

    // outputs and next state logic
    always @* begin
        // defaults to 0
        busy = 1'b0;
        done = 1'b0;
        alu_in1_ld = 1'b0;
        alu_in2_ld = 1'b0;
        alu_out_ld = 1'b0;
        alu_out_en = 1'b0;
        dst_reg_en = 1'b0;
        dst_reg_ld = 1'b0;
        src_reg_en = 1'b0;
        alu_op = alu_op_in;   // just pass through decoded op
        next_state = state;

        case (state)
            S_IDLE: begin
                // sit here until its gotta start a regALU instruc
                if (start && dec_alu_reg) begin
                    busy = 1'b1;
                    next_state = S_LOAD_A;
                end
            end
            // load param1
            S_LOAD_A: begin
                busy = 1'b1;
                dst_reg_en = 1'b1;  // regdst drives bus
                alu_in1_ld = 1'b1;   // latch into ALU In1
                next_state = S_LOAD_B;
            end
            // load param2
            S_LOAD_B: begin
                busy = 1'b1;
                src_reg_en = 1'b1;   // regsrc drives bus
                alu_in2_ld = 1'b1;   // latch into ALU In2
                next_state = S_EXEC;
            end
            // finds result
            S_EXEC: begin
                busy = 1'b1;
                alu_out_ld = 1'b1;   // takes ALU result into its output reg
                next_state = S_WRITEBACK;
            end
            // result to bus
            S_WRITEBACK: begin
                busy = 1'b1;
                alu_out_en = 1'b1;  // result on bus
                dst_reg_ld = 1'b1;  // write back into regdst
                next_state = S_DONE;
            end
            // done announcement
            S_DONE: begin
                done = 1'b1;   // one cycle pulse to show done
                next_state = S_IDLE;
            end
            default: begin
                next_state = S_IDLE;
            end
        endcase
    end
endmodule
