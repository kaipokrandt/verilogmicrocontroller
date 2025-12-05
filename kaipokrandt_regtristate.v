// register bank creator with tristate !!! output
// loads from bus when load=1 and drives bus when enable=1
`timescale 1ns/1ps




module kaipokrandt_regtristate(
    input clk,
    input reset,
    input load,
    input enable,
    input[15:0] bus_in,
    output[15:0] bus_out
);
    // the register
    reg [15:0] regi;

    // on reset set regi=0, when load=1 it takes busin
    always @(posedge clk or negedge reset) begin
        if(!reset)
            regi <= 16'h0000;
        else if(load)
            regi <= bus_in;
    end

    // tristate !!! and drive the bus when enabled, if not, Z
    assign bus_out = enable ? regi : 16'hzzzz;
endmodule
