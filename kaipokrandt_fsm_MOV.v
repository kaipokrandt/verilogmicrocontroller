// MOV.v fsm
// turn on source reg so regsource drives bus
// turn on dest reg to load reg dest from bus
// done
// reg to reg copying
`timescale 1ns/1ps


module kaipokrandt_fsm_mov(
    // globals
    input clk,
    input reset,
    input start,
    input dec_mov,
    // on or off
    output reg busy,
    output reg done,
    // registers
    output reg src_reg_en,
    output reg dst_reg_ld
);
    // three states, IDLE, MOVE1, DONE
    localparam S_IDLE = 2'd0;
    localparam S_MOVE1 = 2'd1;
    localparam S_DONE = 2'd2;
    // state assignment
    reg[1:0] state, next_state;

    // state register, async reset sets back to idle
    always @(posedge clk or negedge reset) begin
        if(!reset)
            state <= S_IDLE;
        else
            state <= next_state;
    end

    always @* begin
        // default everything to 0 and hold state
        busy = 1'b0;
        done = 1'b0;
        src_reg_en = 1'b0;
        dst_reg_ld = 1'b0;
        next_state = state;

        case (state)
            // wait until start given and mov opcode given
            S_IDLE: begin
                if (start && dec_mov)
                    next_state = S_MOVE1;
            end

            // drive bus and load bus
            S_MOVE1: begin
                busy = 1'b1;
                src_reg_en = 1'b1;
                dst_reg_ld = 1'b1;
                next_state = S_DONE;
            end

            // show done so we go back to fetching
            S_DONE: begin
                done = 1'b1;
                next_state = S_IDLE;
            end

            default: next_state = S_IDLE;
        endcase
    end

endmodule
