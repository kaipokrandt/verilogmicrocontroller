// instruction fetch FSM
// PC -> MAR -> memory -> MDR -> IR then bumps PC
`timescale 1ns/1ps
module kaipokrandt_fsm_fetch(
    // globals
    input clk,
    input reset,
    input start,     // go high when time to fetch an instruction
    input MFC,       // memory function complete from bmem

    // checking
    output reg busy,
    output reg done,

    // PC control
    output reg pc_enable,
    output reg pc_increment,

    // MAR control
    output reg mar_load,

    // MDR control
    output reg mdr_load_mem,
    output reg mdr_enable_bus,

    // memory control
    output reg mem_EN,
    output reg mem_RW, // 1 = read, 0 = write

    // IR control
    output reg ir_load
);

    // states for fetch steps
    localparam S_IDLE = 3'd0;
    localparam S_PCONBUS = 3'd1;  
    localparam S_PC2MAR = 3'd2;  
    localparam S_STARTMEM = 3'd3;
    localparam S_WAITMFC = 3'd4;
    localparam S_MDR2IR = 3'd5;
    localparam S_PCINC = 3'd6;
    localparam S_DONE = 3'd7;

    reg[2:0] state, next_state;

    // state register
    always @(posedge clk or negedge reset) begin
        if (!reset)
            state <= S_IDLE;
        else
            state <= next_state;
    end

    // next state and outputs
    always @* begin
        // default everything as 0
        busy = 1'b0;
        done = 1'b0;
        pc_enable = 1'b0;
        pc_increment = 1'b0;
        mar_load = 1'b0;
        mdr_load_mem = 1'b0;
        mdr_enable_bus= 1'b0;
        mem_EN = 1'b0;
        mem_RW = 1'b0;
        ir_load = 1'b0;

        next_state = state;

        case (state)
            // wait until top says to fetch next instruction IDLE
            S_IDLE: begin
                if (start) begin
                    busy = 1'b1;
                    next_state = S_PCONBUS;
                end
            end

            // drive PC onto bus for a full cycle
            S_PCONBUS: begin
                busy = 1'b1;
                pc_enable = 1'b1;   // pc -> bus
                next_state = S_PC2MAR;
            end

            // after PC send to bus, load the MAR
            S_PC2MAR: begin
                busy = 1'b1;
                pc_enable = 1'b1;   // keep pc on bus
                mar_load = 1'b1;   // bus -> MAR
                next_state = S_STARTMEM;
            end

            // MAR drives address bus, mem_EN high with RW=1 to read
            S_STARTMEM: begin
                busy = 1'b1;
                mem_EN = 1'b1;   // rising edge kicks bmem
                mem_RW = 1'b1;   // read
                next_state = S_WAITMFC;
            end

            // wait for memory to collect the data is ready
            S_WAITMFC: begin
                busy = 1'b1;
                mem_EN = 1'b1;   // hold enable high
                mem_RW = 1'b1;
                if (MFC) begin
                    mdr_load_mem = 1'b1; // grab memory data into MDR
                    next_state = S_MDR2IR;
                end
            end

            // mdr drives bus, ir takes instruction from bus
            S_MDR2IR: begin
                busy = 1'b1;
                mdr_enable_bus = 1'b1; // MDR to bus
                ir_load = 1'b1; // bus to IR
                next_state = S_PCINC;
            end

            // touch PC so it goes to next instruction
            S_PCINC: begin
                busy = 1'b1;
                pc_increment = 1'b1;
                next_state = S_DONE;
            end

            // tell everything its done finished with fetch
            S_DONE: begin
                done = 1'b1; // one-cycle pulse
                next_state = S_IDLE;
            end
            default: begin
                next_state = S_IDLE;
            end
        endcase
    end
endmodule
