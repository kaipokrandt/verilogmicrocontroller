// memory address register MAR.v
// writes address to memory / can load from system bus
`timescale 1ns/1ps
module kaipokrandt_mar(
    //globals 
    input clk,
    input reset,
    input load,
    input[15:0] bus_in,
    output[15:0] addr_out
);

    reg[15:0] mar_reg;    // register with the address

    // when load = 1, dupe busin into the mar
    always @(posedge clk or negedge reset) begin
        if(!reset)
            mar_reg<= 16'h0000;
        else if(load)
            mar_reg<= bus_in;
    end

    // NO TRISTATE !!!! *** just set addr out to the mar register
    assign addr_out = mar_reg;
endmodule
