// behavioral memory (do not put through DesignViz REMEMBER)
`timescale 1ns/1ps


module kaipokrandt_bmem(
    input clk,
    output reg[15:0] dataout,  // 16 bit memory return
    output reg MFC,              // 1bit register output (complete or not)
    input enable,               // enable 
    input readwrite,            // 1 = read, 0 = write
    input[15:0] address,           // 16bit addy input
    input[15:0] datain         // 16bit input for writing
);
    // 64k words of 16bits each, 0 to 65535 index
    reg[15:0] mem[0:65535];
    integer i;

    // loop over all 65536 locations and sets=0, then set addy 0=1111, addy 1=2222
    // behavioral code with preloaded machine codes
    initial begin
        dataout = 16'h0000;
        MFC = 1'b0;
        for(i=0; i<65536; i=i+1)
            mem[i] = 16'h0000;
        // written over by toplvl test bench anyway
        mem[16'h0000] = 16'h1111; // give address 0000 the value 1111
        mem[16'h0001] = 16'h2222; // give address 0001 the value 2222
    end

    // on rising edge of clk, if readwrite=1, it reads into datout, else it writes from datin
    always @(posedge clk) begin
        MFC <= 1'b0;
        if(enable) begin
            if(readwrite) begin
                dataout <= mem[address];
            end else begin
                mem[address] <= datain;
            end
            MFC <= 1'b1;
        end
    end
endmodule
