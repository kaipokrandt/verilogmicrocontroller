`timescale 1ns/1ps

module tb_kaipokrandt_toplvl;
    //globals
    reg clk;
    reg reset;
    // memory wires toplevel to and frou memory
    wire[15:0] mem_addr;
    wire[15:0] mem_data_out;   // from toplevel to memory
    wire[15:0] mem_data_in;    // from memory to toplevel
    wire mem_EN;
    wire mem_RW;
    wire mem_MFC;

    // ports 0/1
    reg[15:0] p1_value;
    wire[15:0] p0_ctrl;

    // DUT setup
    kaipokrandt_toplvl dut(
        .clk(clk),
        .reset(reset),
        .mem_data_in(mem_data_in),
        .mem_data_out(mem_data_out),
        .mem_addr(mem_addr),
        .mem_EN(mem_EN),
        .mem_RW(mem_RW),
        .mem_MFC(mem_MFC),
        .p1_ext_in(p1_value),
        .p0_ext_out(p0_ctrl)
    );

    // whip up memory in the testbench
    kaipokrandt_bmem mem(
        .clk(clk),
        .dataout(mem_data_in),
        .MFC(mem_MFC),
        .enable(mem_EN),
        .readwrite(mem_RW),
        .address(mem_addr),
        .datain (mem_data_out)
    );

    // clock
    initial clk = 0;
    // 70ns period so i get positive slack in DV
    always #35 clk = ~clk;

    initial begin
        // give port1 an input value
        p1_value = 16'hF0F0;

        // reset
        reset = 0;
        #80;
        reset = 1;

        //  wait a little so bmem finishes before we write over
        #1;

        // load program into memory
        // format: opcode[15:12] | param1[11:6] | param2[5:0]
        // R0=0, R1=1, R2=2, R3=3, P0=4
        /* kmpokran assignment in doc

            MOVI R1, #14  = b1100000001001110
            ADDI R1, #5   = b0001000001000101
            MOV R3, R1    = b1011000011000001
            SUBI R3, #2   = b0011000011000010
            XOR R3, R1    = b0111000011000001
            NOT R3        = b0100000011000000
            STORE R1, (R3)= b1010000001000011
            LOAD (R3), P0 = b1001000100000011

        */
        // load the task given into mem so the toplvl knows what its doing
        // MOVI R1, #14
        mem.mem[16'h0000] = 16'b1100_000001_001110;
        // ADDI R1, #5
        mem.mem[16'h0001] = 16'b0001_000001_000101;
        // MOV R3, R1
        mem.mem[16'h0002] = 16'b1011_000011_000001;
        // SUBI R3, #2
        mem.mem[16'h0003] = 16'b0011_000011_000010;
        // XOR R3, R1
        mem.mem[16'h0004] = 16'b0111_000011_000001;
        // NOT R3
        mem.mem[16'h0005] = 16'b0100_000011_000000;
        // STORE R1, (R3)
        mem.mem[16'h0006] = 16'b1010_000001_000011;
        // LOAD (R3), P0
        mem.mem[16'h0007] = 16'b1001_000100_000011;

        // let it run with a lotttt of extra time
        #20000;
        $finish;
    end
endmodule
