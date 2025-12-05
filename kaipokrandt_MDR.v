// memory data register MDR.v
// deals with data going in and out of memory
`timescale 1ns/1ps
module kaipokrandt_mdr(
    // globals
    input clk,
    input reset,
    // stuff from bus
    input load_bus,         // latch bus
    input enable_bus,       // driver for busout
    input[15:0] bus_in,    // bus conn
    output[15:0] bus_out,  // bus conn
    // from memory
    input load_mem,         // latch FROM mem
    input[15:0] mem_dout,  // get data out FROM memory
    output[15:0] mem_din   // put data IN to memory
);

    reg[15:0] mdr_in;      // holds the dat going IN memory
    reg[15:0] mdr_out;     // holds the dat going FROM memory

    // on reset, mdrin is cleared. if not reset, when loadbus=1, take data from bus_in
    always @(posedge clk or negedge reset) begin
        if(!reset)
            mdr_in <= 16'h0000;
        else if(load_bus)
            mdr_in <= bus_in;
    end

    // similar to above, on reset mdrout is cleared, otherwise gets dat from mem when loadmem=1
    always @(posedge clk or negedge reset) begin
        if(!reset)
            mdr_out <= 16'h0000;
        else if(load_mem)
            mdr_out <= mem_dout;
    end

    // outputs, memory write data comes from mdrin
    assign mem_din = mdr_in;
    // tristate, mdr out is driven when enablebus=1
    assign bus_out = enable_bus ? mdr_out : 16'hzzzz;
endmodule
