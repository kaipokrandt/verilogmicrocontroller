// mov immediate fsm
// for moving an immediate value to a register
`timescale 1ns/1ps



module kaipokrandt_fsm_movi(
    // globals
    input clk,
    input reset,
    // high when movi starts
    input start,
    // movi imm flags
    input dec_movi,
    input uses_imm,
    // on or off
    output reg busy,
    output reg done,
    output reg imm_to_bus_en,
    output reg dst_reg_ld
);

    // IDLE wait for movi instruction
    // MOVE1 put the imm val on the bus and load dest
    // DONE signal done then go back to idle
    localparam S_IDLE = 2'd0;
    localparam S_MOVE1 = 2'd1;
    localparam S_DONE = 2'd2;

    reg[1:0] state, next_state;

    // state register
    always @(posedge clk or negedge reset) begin
        if(!reset)
            state <= S_IDLE;
        else
            state <= next_state;
    end

    // next state and output logic
    always @* begin
        // set everything to 0 but hold the state
        busy = 1'b0;
        done = 1'b0;
        imm_to_bus_en = 1'b0;
        dst_reg_ld = 1'b0;
        next_state = state;

        case (state)
            // stay here until movi is given
            S_IDLE: begin
                if (start && dec_movi)
                    next_state = S_MOVE1;
            end

            // imm_to_bus_en drives values onto bus
            // loads immediate from bus
            S_MOVE1: begin
                busy = 1'b1;
                imm_to_bus_en = 1'b1;
                dst_reg_ld = 1'b1;
                next_state = S_DONE;
            end

            // signal done for the rest of the fsms
            S_DONE: begin
                done = 1'b1;
                next_state = S_IDLE;
            end

            default: next_state = S_IDLE;
        endcase
    end

endmodule
