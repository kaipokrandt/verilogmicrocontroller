// program counter PC.v
// can increment, tristates to bus as output, keeps track of instructions
`timescale 1ns/1ps


module kaipokrandt_pc(
    //globals
    input clk,
    input reset,
    // count up 
    input increment,
    input enable,
    // output
    output [15:0] bus_out
);
    // register that holds the counter vals
    reg[15:0] pc;

    // on reset, pc = 0, elseif increment is high or 1, PC adds 1 like PC+1
    // if both are low it holds the value
    always @(posedge clk or negedge reset) begin
        if(!reset)
            pc <= 16'h0000;
        else if(increment)
            pc <= pc + 16'h0001;
    end
    // tristate !!! the PC into bus if enable is 1
    assign bus_out = (enable) ? pc : 16'hzzzz;
endmodule
