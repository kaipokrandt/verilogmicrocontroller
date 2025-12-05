// immeidiate FSM for SUBIADDI
// handles specifically sub immediate and add immediate 
// take op in 1 from reg then in2 is immediate value given
`timescale 1ns/1ps


module kaipokrandt_fsm_alu_imm(
    // globals
    input clk,
    input reset,
    input start,
    input dec_alu_imm,
    input uses_imm,      // <from instruc decoder should be 1 here>
    input[3:0] alu_op_in,
    // checking on or off
    output reg busy,
    output reg done,
    // ALU control
    output reg alu_in1_ld,
    output reg alu_in2_ld,
    output reg alu_out_ld,
    output reg alu_out_en,
    output reg[3:0] alu_op,
    // reg bank control
    output reg dst_reg_en,
    output reg dst_reg_ld,

    // immediates
    output reg imm_to_bus_en
);

    localparam S_IDLE = 3'd0;
    localparam S_LOADA = 3'd1;
    localparam S_LOADIMM = 3'd2;
    localparam S_EXEC = 3'd3;
    localparam S_WRITEBACK = 3'd4;
    localparam S_DONE = 3'd5;

    reg [2:0] state, next_state;

    // on rising or falling, if not reset then hold idle
    // otherwise go to the next state
    always @(posedge clk or negedge reset) begin
        if(!reset)
            state <= S_IDLE;
        else
            state <= next_state;
    end

    always @* begin
        // set everything to 0
        busy = 1'b0;
        done = 1'b0;
        alu_in1_ld = 1'b0;
        alu_in2_ld = 1'b0;
        alu_out_ld = 1'b0;
        alu_out_en = 1'b0;
        dst_reg_en = 1'b0;
        dst_reg_ld = 1'b0;
        imm_to_bus_en = 1'b0;
        alu_op = alu_op_in;
        // state is idle
        next_state = state;

        case (state)
            // idling, next loads param1
            S_IDLE: begin
                if (start && dec_alu_imm)
                    next_state = S_LOADA;
            end

            // loads parma1
            S_LOADA: begin
                busy = 1'b1;
                dst_reg_en = 1'b1;   // get old Rdst
                alu_in1_ld = 1'b1;
                next_state = S_LOADIMM;
            end

            // loads imm value param2
            S_LOADIMM: begin
                busy = 1'b1;
                imm_to_bus_en = 1'b1;  // param2 immediate out to bus
                alu_in2_ld = 1'b1;
                next_state = S_EXEC;
            end

            // executes to writeback
            S_EXEC: begin
                busy = 1'b1;
                alu_out_ld = 1'b1;
                next_state = S_WRITEBACK;
            end
            // write back
            S_WRITEBACK: begin
                busy = 1'b1;
                alu_out_en = 1'b1;
                dst_reg_ld = 1'b1;
                next_state = S_DONE;
            end
            // tell everything its done
            S_DONE: begin
                done = 1'b1;
                next_state = S_IDLE;
            end
            default: next_state = S_IDLE;
        endcase
    end
endmodule
