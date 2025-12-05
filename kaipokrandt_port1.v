// port1 is input-only, as it does not drive the bus without telling it to
module kaipokrandt_port1(
    input clk,
    input reset,
    input load_ext,        // latch external input
    input bus,            // put value onto bus
    input[15:0] ext_in,
    output[15:0] bus_out
);
    // stores external value
    reg[15:0] p1;

    // external can change ext_in but the main device only sees value when loadext=1
    always @(posedge clk or negedge reset) begin
        if(!reset)
            p1 <= 16'h0000;
        else if(load_ext)
            p1 <= ext_in;
    end



    // TRISTATE !!! *** bus=1, port1 drives bus with stored ext value p1
    // bus=0, Z value
    assign bus_out = bus ? p1 : 16'hzzzz;
endmodule
