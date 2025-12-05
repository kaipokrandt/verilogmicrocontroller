// MEM.v fsm
// handles load and store stuff
// store uses source reg to grab data into dat reg from bus
// load starts mem with read and awaits MFC then pushes value and dest to bus and loads regdest or p0 

`timescale 1ns/1ps


module kaipokrandt_fsm_mem(
    // globals
    input clk,
    input reset,
    input start,
    input dec_load,
    input dec_store,
    input MFC,          // from memory
    // on or off flags
    output reg busy,
    output reg done,
    // MAR stuff
    output reg mar_load,
    // MDR stuff
    output reg mdr_load_bus,
    output reg mdr_load_mem,
    output reg mdr_en_bus,
    // memory stuff
    output reg mem_en,
    output reg mem_rw,       // 1 = read, 0 = write
    // reg bank setup
    output reg addr_reg_en,  // address register onto bus
    output reg src_reg_en,   // for store
    output reg dst_reg_ld    // for load
);

    localparam S_IDLE = 3'd0;
    localparam S_ADDR2MAR = 3'd1;
    localparam S_MEM_START = 3'd2;
    localparam S_WAIT_MFC = 3'd3;
    localparam S_LOAD_MDR = 3'd4;
    localparam S_WRITEBACK = 3'd5;
    localparam S_DONE = 3'd6;

    reg[2:0] state, next_state;

    // state register
    always @(posedge clk or negedge reset) begin
        if(!reset)
            state <= S_IDLE;
        else
            state <= next_state;
    end

    always @* begin
        // default everything to 0
        busy = 1'b0;
        done = 1'b0;
        mar_load = 1'b0;
        mdr_load_bus = 1'b0;
        mdr_load_mem = 1'b0;
        mdr_en_bus = 1'b0;
        mem_en = 1'b0;
        mem_rw = 1'b0;
        addr_reg_en = 1'b0;
        src_reg_en = 1'b0;
        dst_reg_ld = 1'b0;
        next_state = state;

        case (state)
            // wait until we’re told to do a load or store
            S_IDLE: begin
                if (start && (dec_load || dec_store))
                    next_state = S_ADDR2MAR;
            end

            // put address register on the bus and load MAR
            S_ADDR2MAR: begin
                busy = 1'b1;
                addr_reg_en = 1'b1;  // address reg drives bus
                mar_load = 1'b1;  // MAR grabs it

                // next step depends on load vs store
                if (dec_load)
                    next_state = S_MEM_START;   // go straight to memory read
                else if (dec_store)
                    next_state = S_LOAD_MDR;    // first load data into MDR
            end

            // start memory operation
            // LOAD MAR drives address memory read EN=1, RW=1
            // STORE MAR drives address memory write EN=1, RW=0
            S_MEM_START: begin
                busy = 1'b1;
                mem_en = 1'b1;      // pulse EN to kick memory
                mem_rw = dec_load ? 1'b1 : 1'b0;  // 1=read, 0=write
                next_state = S_WAIT_MFC;
            end

            // wait for memory to finish
            S_WAIT_MFC: begin
                busy = 1'b1;
                mem_en = 1'b1;
                mem_rw = dec_load ? 1'b1 : 1'b0;
                if (MFC) begin
                    if (dec_load)
                        next_state = S_LOAD_MDR;   // read path
                    else if (dec_store)
                        next_state = S_DONE;       // write path
                end
            end

            // this state is used differently for load compared to store
            // LOAD latches from memory into MDR
            // STORE latches from source into MDR to write dat
            S_LOAD_MDR: begin
                busy = 1'b1;

                if (dec_load) begin
                    // coming from WAIT_MFC after a read
                    mdr_load_mem = 1'b1;      // take data from memory into MDR
                    next_state = S_WRITEBACK;
                end
                else if (dec_store) begin
                    // right after address, before starting write
                    src_reg_en = 1'b1;      // source reg drives bus
                    mdr_load_bus = 1'b1;      // MDR_in grabs it
                    next_state = S_MEM_START;  // then go start the write
                end
            end
            // for LOAD only
            // MDR drives bus, destination register loads from bus
            S_WRITEBACK: begin
                busy = 1'b1;
                mdr_en_bus = 1'b1;   // MDR_out -> bus
                dst_reg_ld = 1'b1;   // Rdst <- bus
                next_state = S_DONE;
            end
            // final state one cycle done pulse, back to idle
            S_DONE: begin
                done = 1'b1;
                next_state = S_IDLE;
            end

            default: begin
                next_state = S_IDLE;
            end
        endcase
    end
endmodule
