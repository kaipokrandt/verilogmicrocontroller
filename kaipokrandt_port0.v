// port0 is basically a register that can drive the bus AND an external output
// it loads from the system bus adn its stored value can be sent to two places
module kaipokrandt_port0(
    // globals
    input clk,
    input reset,

    input load,    // load from system bus
    input bus,      // drive internal bus
    input extout,  // drive external port 0

    //data
    input[15:0] bus_in,
    output[15:0] bus_out,
    output[15:0] out_port
);
    // stores value
    reg [15:0] p0;
    // on reset it goes to 0000, if load=1 on rising, current bus val put into p0
    always @(posedge clk or negedge reset) begin
        if(!reset)
            p0 <= 16'h0000;
        else if(load)
            p0 <= bus_in;
    end


    
    //tristate !!! outputs, if bus=1 then p0 stores val on system bus, otherwise Z
    // if extout=1, same value is sent
    assign bus_out  = bus ? p0 : 16'hzzzz;
    assign out_port = extout ? p0 : 16'hzzzz;
endmodule
