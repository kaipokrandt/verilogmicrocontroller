// instruction register IR.v
// takes instruction from the system bus and hangs onto it 
`timescale 1ns/1ps
module kaipokrandt_IR(
    input clk,
    input reset,
    input load,        // load IR from bus when this is 1
    input[15:0] bus_in,

    // full instruction out
    output[15:0] ir_out,

    // decoded
    output[3:0] opcode,  // [15:12]
    output[5:0] param1, // [11:6]
    output[5:0] param2   // [5:0]
);

    reg[15:0] ir_reg;

    // synchronous load from bus
    always @(posedge clk or negedge reset) begin
        if(!reset)
            ir_reg <= 16'h0000;
        else if(load)
            ir_reg <= bus_in;
        // otherwise hold old instruction
    end

    // just wire stuff out
    assign ir_out = ir_reg;

    // split into fields 4b 6b 6b opcode | param1 | param2
    assign opcode = ir_reg[15:12];
    assign param1 = ir_reg[11:6];
    assign param2 = ir_reg[5:0];
endmodule
