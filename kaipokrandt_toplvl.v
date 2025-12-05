// top-level microcontroller to glue all these evil files together
// connects _PC.v _MAR.v _MDR.v _IR.v _ID.v _ALU.v _regtristate.v ports1/0.v 
// and fsm_FETCH/IMM/MEM/MOV/MOVI/REG
// traffic cop that opens memory for them
`timescale 1ns/1ps


module kaipokrandt_toplvl(
    // globals
    input clk,
    input reset,

    // mem data related
    input[15:0] mem_data_in,
    output[15:0] mem_data_out,
    output[15:0] mem_addr,
    output mem_EN,
    output mem_RW,
    input mem_MFC,

    // external ports P0 P1 for I/o
    input[15:0] p1_ext_in,
    output[15:0] p0_ext_out
); // end of toplvl

    // shared bus
    wire[15:0] bus;

    // _PC.v programe counter
    wire[15:0] pc_bus_out;
    wire pc_enable;
    wire pc_increment;
    kaipokrandt_pc u_pc(
        .clk(clk),
        .reset(reset),
        .increment(pc_increment),
        .enable(pc_enable),
        .bus_out(pc_bus_out)
    );
    // end of program count



    // mem register MAR.v
    wire [15:0] mar_out;
    reg mar_load;
    kaipokrandt_mar u_mar(
        .clk(clk),
        .reset(reset),
        .load(mar_load),
        .bus_in(bus),
        .addr_out(mar_out)
    );
    assign mem_addr = mar_out;
    // end of mem reg


    // MDR.v mem data register
    wire[15:0] mdr_bus_out;
    wire[15:0] mdr_mem_din;
    reg mdr_load_bus;
    reg mdr_load_mem;
    reg mdr_enable_bus;
    kaipokrandt_mdr u_mdr(
        .clk(clk),
        .reset(reset),
        .load_bus(mdr_load_bus),
        .enable_bus(mdr_enable_bus),
        .bus_in(bus),
        .bus_out(mdr_bus_out),
        .load_mem(mdr_load_mem),
        .mem_dout(mem_data_in),
        .mem_din(mdr_mem_din)
    );
    assign mem_data_out = mdr_mem_din;
    // end of mdr.v



    // IR.v instruction register
    wire[15:0] ir_out;
    wire[3:0] ir_opcode;
    wire[5:0] ir_param1, ir_param2;
    wire ir_load;
    kaipokrandt_IR u_ir(
        .clk(clk),
        .reset(reset),
        .load(ir_load),
        .bus_in(bus),
        .ir_out(ir_out),
        .opcode(ir_opcode),
        .param1(ir_param1),
        .param2(ir_param2)
    );
    //end of ir.v



    // instruction decoder
    wire[3:0] dec_opcode;
    wire[5:0] dec_p1, dec_p2;
    wire dec_alu_reg, dec_alu_imm, dec_load, dec_store, dec_mov, dec_movi;
    wire[3:0] alu_op_dec;
    wire uses_imm;
    kaipokrandt_ID u_id(
        .instr(ir_out),
        .opcode(dec_opcode),
        .param1(dec_p1),
        .param2(dec_p2),
        .dec_alu_reg(dec_alu_reg),
        .dec_alu_imm(dec_alu_imm),
        .dec_load(dec_load),
        .dec_store(dec_store),
        .dec_mov(dec_mov),
        .dec_movi(dec_movi),
        .alu_op(alu_op_dec),
        .uses_imm(uses_imm)
    );
    // params to manip mem 6bit 6bit
    wire[5:0] destinationr = ir_param1;  // regdest / destination register
    wire[5:0] sourcer = ir_param2;  // regsrc / source register




    // ALU.v creation
    wire[15:0] alu_bus_out;
    reg alu_in1_ld, alu_in2_ld, alu_out_ld, alu_out_en;
    wire[3:0] alu_op = alu_op_dec;  // decoder already picked the op
    kaipokrandt_ALU_core u_alu(
        .clk(clk),
        .reset(reset),
        .bus_in(bus),
        .bus_out(alu_bus_out),
        .alu_out_en(alu_out_en),
        .in1_ld(alu_in1_ld),
        .in2_ld(alu_in2_ld),
        .out_ld(alu_out_ld),
        .alu_op(alu_op)
    );
    // end of ALU.v




    // _regtristate.v register bank creation
    // R0 R1 R2 R3 creation
    wire [15:0] R0_bus_out, R1_bus_out, R2_bus_out, R3_bus_out;
    reg R0_load, R0_en;
    reg R1_load, R1_en;
    reg R2_load, R2_en;
    reg R3_load, R3_en;
    // setup R0
    kaipokrandt_regtristate R0(
        .clk(clk),
        .reset(reset),
        .load(R0_load),
        .enable(R0_en),
        .bus_in(bus),
        .bus_out(R0_bus_out)
    );
    // setup R1
    kaipokrandt_regtristate R1(
        .clk(clk),
        .reset(reset),
        .load(R1_load),
        .enable(R1_en),
        .bus_in(bus),
        .bus_out(R1_bus_out)
    );
    // setup R2
    kaipokrandt_regtristate R2(
        .clk(clk),
        .reset(reset),
        .load(R2_load),
        .enable(R2_en),
        .bus_in(bus),
        .bus_out(R2_bus_out)
    );
    // set up R3
    kaipokrandt_regtristate R3(
        .clk(clk),
        .reset(reset),
        .load(R3_load),
        .enable(R3_en),
        .bus_in(bus),
        .bus_out(R3_bus_out)
    );
    // end of reg bank tristate.v



    // _port0.v creation
    wire[15:0] p0_bus_out;
    reg p0_load;
    wire p0_bus_en;
    wire p0_ext_en;
    kaipokrandt_port0 u_p0(
        .clk(clk),
        .reset(reset),
        .load(p0_load),
        .bus(p0_bus_en),
        .extout(p0_ext_en),
        .bus_in(bus),
        .bus_out(p0_bus_out),
        .out_port(p0_ext_out)
    );
    //end of port 0



    // _port1.v creation
    wire[15:0] p1_bus_out;
    wire p1_load_ext;
    wire p1_bus_en;
    kaipokrandt_port1 u_p1(
        .clk(clk),
        .reset(reset),
        .load_ext(p1_load_ext),
        .bus(p1_bus_en),
        .ext_in(p1_ext_in),
        .bus_out(p1_bus_out)
    );
    // end of port1



    // for immediate value on bus for immediate opcodes
    wire[15:0] imm_val = {10'b0, sourcer};
    reg imm_bus_en;




    // fsm_FETCH.v FSM !!! *** !!!
    wire fetch_busy, fetch_done;
    reg  fetch_start;
    wire fetch_pc_enable, fetch_pc_increment;
    wire fetch_mar_load;
    wire fetch_mdr_load_mem, fetch_mdr_enable_bus;
    wire fetch_mem_EN, fetch_mem_RW;
    wire fetch_ir_load;
    kaipokrandt_fsm_fetch u_fetch(
        .clk(clk),
        .reset(reset),
        .start(fetch_start),
        .MFC(mem_MFC),
        .busy(fetch_busy),
        .done(fetch_done),
        .pc_enable(fetch_pc_enable),
        .pc_increment(fetch_pc_increment),
        .mar_load(fetch_mar_load),
        .mdr_load_mem(fetch_mdr_load_mem),
        .mdr_enable_bus(fetch_mdr_enable_bus),
        .mem_EN(fetch_mem_EN),
        .mem_RW(fetch_mem_RW),
        .ir_load(fetch_ir_load)
    );
    // end of fsm_FETCH.v 




    // fsm_REG.v ALU FSM is fsm for ADD, SUB, AND, OR, XOR, XNOR, NOT
    wire reg_busy, reg_done;
    reg reg_start;
    wire reg_alu_in1_ld, reg_alu_in2_ld, reg_alu_out_ld, reg_alu_out_en;
    wire reg_dst_reg_en, reg_dst_reg_ld, reg_src_reg_en;
    kaipokrandt_fsm_alu_reg u_fsm_reg(
        .clk(clk),
        .reset(reset),
        .start(reg_start),
        .dec_alu_reg(dec_alu_reg),
        .alu_op_in(alu_op_dec),
        .busy(reg_busy),
        .done(reg_done),
        .alu_in1_ld(reg_alu_in1_ld),
        .alu_in2_ld(reg_alu_in2_ld),
        .alu_out_ld(reg_alu_out_ld),
        .alu_out_en(reg_alu_out_en),
        .dst_reg_en(reg_dst_reg_en),
        .dst_reg_ld(reg_dst_reg_ld),
        .src_reg_en(reg_src_reg_en)
    );
    // end of fsm_REG.v AND,OR, XOR, etc etc etc





    // fsm_IMM.v ALU FSM for ADDI/SUBI
    wire imm_busy, imm_done;
    reg imm_start;
    wire imm_alu_in1_ld, imm_alu_in2_ld, imm_alu_out_ld, imm_alu_out_en;
    wire imm_dst_reg_en, imm_dst_reg_ld;
    wire imm_to_bus_fsm;
    kaipokrandt_fsm_alu_imm u_fsm_imm(
        .clk(clk),
        .reset(reset),
        .start(imm_start),
        .dec_alu_imm(dec_alu_imm),
        .uses_imm(uses_imm),
        .alu_op_in(alu_op_dec),
        .busy(imm_busy),
        .done(imm_done),
        .alu_in1_ld(imm_alu_in1_ld),
        .alu_in2_ld(imm_alu_in2_ld),
        .alu_out_ld(imm_alu_out_ld),
        .alu_out_en(imm_alu_out_en),
        .dst_reg_en(imm_dst_reg_en),
        .dst_reg_ld(imm_dst_reg_ld),
        .imm_to_bus_en(imm_to_bus_fsm)
    );
    // end of fsm_IMM.v immediates


    // fsm_MEM.v FSM for (load/store)
    wire mem_busy_fsm, mem_done_fsm;
    reg  mem_start_fsm;
    wire mem_mar_load_fsm;
    wire mem_mdr_load_bus_fsm, mem_mdr_load_mem_fsm, mem_mdr_en_bus_fsm;
    wire mem_en_fsm, mem_rw_fsm;
    wire mem_addr_reg_en, mem_src_reg_en, mem_dst_reg_ld;
    kaipokrandt_fsm_mem u_fsm_mem(
        .clk(clk),
        .reset(reset),
        .start(mem_start_fsm),
        .dec_load(dec_load),
        .dec_store(dec_store),
        .MFC(mem_MFC),
        .busy(mem_busy_fsm),
        .done(mem_done_fsm),
        .mar_load(mem_mar_load_fsm),
        .mdr_load_bus(mem_mdr_load_bus_fsm),
        .mdr_load_mem(mem_mdr_load_mem_fsm),
        .mdr_en_bus(mem_mdr_en_bus_fsm),
        .mem_en(mem_en_fsm),
        .mem_rw(mem_rw_fsm),
        .addr_reg_en(mem_addr_reg_en),
        .src_reg_en(mem_src_reg_en),
        .dst_reg_ld(mem_dst_reg_ld)
    );
    // end of fsm.MEM.v



    // fsm_MOV.v FSM for moving in memory
    wire mov_busy, mov_done;
    reg mov_start;
    wire mov_src_reg_en, mov_dst_reg_ld;
    kaipokrandt_fsm_mov u_fsm_mov(
        .clk(clk),
        .reset(reset),
        .start(mov_start),
        .dec_mov(dec_mov),
        .busy(mov_busy),
        .done(mov_done),
        .src_reg_en(mov_src_reg_en),
        .dst_reg_ld(mov_dst_reg_ld)
    );
    // END fsm_mov.v



    // fsm_MOVI.v FSM for moving immedidiates in memory
    wire movi_busy, movi_done;
    reg movi_start;
    wire movi_imm_to_bus_en, movi_dst_reg_ld;
    kaipokrandt_fsm_movi u_fsm_movi(
        .clk(clk),
        .reset(reset),
        .start(movi_start),
        .dec_movi(dec_movi),
        .uses_imm(uses_imm),
        .busy(movi_busy),
        .done(movi_done),
        .imm_to_bus_en(movi_imm_to_bus_en),
        .dst_reg_ld(movi_dst_reg_ld)
    );
    // end of fsm MOVI


    // program FETCH/EXEC states
    localparam CPU_FETCH = 2'd0;
    localparam CPU_EXEC = 2'd1;
    reg[1:0] cpu_state, cpu_next;
    // PC from FETCH 
    assign pc_enable = fetch_pc_enable;
    assign pc_increment = fetch_pc_increment;



    // MAR/MDR mem address register and mdat reg manip from FETCH and MEM machines
    always @* begin
        mar_load = fetch_mar_load | mem_mar_load_fsm;
        mdr_load_mem = fetch_mdr_load_mem | mem_mdr_load_mem_fsm;
        mdr_load_bus = mem_mdr_load_bus_fsm;
        // gate MDR bus enable so it only drives in FETCH or MEM (load/store) had issues with this
        mdr_enable_bus = 1'b0;
        // if cpu is doing instruction fetch, make sure fetch can drive data reg to bus for inst reg
        if (cpu_state == CPU_FETCH)
            mdr_enable_bus = fetch_mdr_enable_bus;
        // during EXEC state for load/store, allow MEM FSM to drive data register to bus
        else if (cpu_state == CPU_EXEC && (dec_load || dec_store))
            mdr_enable_bus = mem_mdr_en_bus_fsm;
    end




    // memory enable/readwrite (for instruction fetching and  load/storing)
    wire inst_EN = fetch_mem_EN;
    wire inst_RW = fetch_mem_RW;
    wire loadstore_EN = mem_en_fsm;
    wire loadstore_RW = mem_rw_fsm;
    assign mem_EN = inst_EN | loadstore_EN;
    assign mem_RW = loadstore_EN ? loadstore_RW : inst_RW;
    assign ir_load = fetch_ir_load;




    // ALU control from REG and IMM FSMs
    always @* begin
        alu_in1_ld = reg_alu_in1_ld | imm_alu_in1_ld;
        alu_in2_ld = reg_alu_in2_ld | imm_alu_in2_ld;
        alu_out_ld = reg_alu_out_ld | imm_alu_out_ld;
        alu_out_en = reg_alu_out_en | imm_alu_out_en;
    end
    // immediate bus enable (IMM and MOVI need this)
    always @* begin
        imm_bus_en = imm_to_bus_fsm | movi_imm_to_bus_en;
    end


    // ports0/1 on for bus and load give
    assign p1_load_ext = 1'b0;
    assign p1_bus_en = 1'b0; // p1 never drives bus

    assign p0_bus_en = 1'b0; // p0 never drives internal bus
    assign p0_ext_en = 1'b1; // drive external p0 with stored val




    // p0_load is handled with register decoding below when destinationr = 4
    // Register bank decode (R0..R3 + P0)
    // figure out what opcode wants to give data to a reg
    wire dst_write_any = reg_dst_reg_ld | imm_dst_reg_ld | mem_dst_reg_ld | mov_dst_reg_ld | movi_dst_reg_ld;


    // figure out what fsm needs to read based on MEM dest reg index 
    wire dst_out_any = reg_dst_reg_en | mem_src_reg_en | imm_dst_reg_en;   // store data uses destinationr as source


    // find out what fsm need to read based on MEM source index 
    wire src_out_any = reg_src_reg_en | mov_src_reg_en | mem_addr_reg_en;
    // port0 is REG 4 for LOAD (R0->R1->R2->R3->P0)
    // only loads memory into P0 when in EXEC, is a LOAD, mem FSM is pulsing, and MDR is driving
    always @* begin
        p0_load = (cpu_state == CPU_EXEC) && dec_load && mem_dst_reg_ld && mem_mdr_en_bus_fsm && (destinationr == 6'd4);
    end



    // reg control for R0/1/2/3 from regtristate
    always @* begin
        R0_load = 1'b0;
        R0_en = 1'b0; 
        R1_load = 1'b0; 
        R1_en = 1'b0;
        R2_load = 1'b0; 
        R2_en = 1'b0; 
        R3_load = 1'b0;
        R3_en = 1'b0;
        // loads only if destinationreg < 4 (0..3) otherwise bounded
        if (dst_write_any) begin
            case (destinationr[1:0])    // only care about low bits for 0..3
                2'd0: if (destinationr < 6'd4) R0_load = 1'b1; //if R0, then load
                2'd1: if (destinationr < 6'd4) R1_load = 1'b1; // if R1, then load
                2'd2: if (destinationr < 6'd4) R2_load = 1'b1; // if R2, then load
                2'd3: if (destinationr < 6'd4) R3_load = 1'b1; // if R3 then load
            endcase
        end
        // outputs for dest and src registers banks
        if (dst_out_any) begin
            case (destinationr[1:0])
                2'd0: R0_en = 1'b1; // R0
                2'd1: R1_en = 1'b1; // R1
                2'd2: R2_en = 1'b1; // R2
                2'd3: R3_en = 1'b1; // R3
            endcase
        end
        if (src_out_any) begin
            case (sourcer[1:0])
                2'd0: R0_en = 1'b1; // R0
                2'd1: R1_en = 1'b1; // R1
                2'd2: R2_en = 1'b1; // R2
                2'd3: R3_en = 1'b1; // R3
            endcase
        end
    end



    // CPU FETCH/EXEC control
    // state reg + edge detect
    reg[1:0] cpu_state_prev;

    always @(posedge clk or negedge reset) begin
        if (!reset) begin
            cpu_state <= CPU_FETCH;
            cpu_state_prev <= CPU_EXEC;
        end else begin
            cpu_state_prev <= cpu_state;
            cpu_state <= cpu_next;
        end
    end
    // nextstate logic ONLY
    always @* begin
        cpu_next = cpu_state;

        // fetch
        case (cpu_state)
            CPU_FETCH: begin
                if (fetch_done)
                    cpu_next = CPU_EXEC;
            end
            
            // exec the fetch if it worked
            CPU_EXEC: begin
                // pick exactly one FSM based on decoder flags
                // regular alu stuff
                if (dec_alu_reg) begin
                    if (reg_done)
                        cpu_next = CPU_FETCH;
                end
                // immediate
                else if (dec_alu_imm) begin
                    if (imm_done)
                        cpu_next = CPU_FETCH;
                end
                // gatekeep so 1 load or store at a time
                else if (dec_load || dec_store) begin
                    if (mem_done_fsm)
                        cpu_next = CPU_FETCH;
                end
                // start MOV
                else if (dec_mov) begin
                    if (mov_done)
                        cpu_next = CPU_FETCH;
                end
                // start MOVImm
                else if (dec_movi) begin
                    if (movi_done)
                        cpu_next = CPU_FETCH;
                end
                else begin
                    // unknown op, just go fetch again there shouldnt be
                    cpu_next = CPU_FETCH;
                end
            end
            default: 
                // fetch again
                cpu_next = CPU_FETCH;
        endcase
    end
    // end of starting stuff



    always @(posedge clk or negedge reset) begin
        if (!reset) begin
            // everything to 0..
            fetch_start <= 1'b0;
            reg_start <= 1'b0;
            imm_start <= 1'b0;
            mem_start_fsm <= 1'b0;
            mov_start <= 1'b0;
            movi_start <= 1'b0;
        end else begin
            // default,,, no starts
            fetch_start <= 1'b0;
            reg_start <= 1'b0;
            imm_start <= 1'b0;
            mem_start_fsm <= 1'b0;
            mov_start <= 1'b0;
            movi_start <= 1'b0;

            // entering FETCH start off a new instruction fetch
            if (cpu_state == CPU_FETCH && cpu_state_prev != CPU_FETCH) begin
                fetch_start <= 1'b1;
            end

            // entering EXEC kick one of the instruction FSMs
            if (cpu_state == CPU_EXEC && cpu_state_prev != CPU_EXEC) begin
                if (dec_alu_reg)
                    reg_start <= 1'b1;
                else if (dec_alu_imm)
                    imm_start <= 1'b1;
                else if (dec_load || dec_store)
                    mem_start_fsm <= 1'b1;
                else if (dec_mov)
                    mov_start <= 1'b1;
                else if (dec_movi)
                    movi_start <= 1'b1;
            end
        end
    end

    // SINGLE bus driver !!!!!!  (basically a priority encoder)
    // give immediate value higher priority than MDR as a safety net to avoid issues
    reg[15:0] bus_r;
    always @* begin
        bus_r = 16'hzzzz;



        if (pc_enable)
            bus_r = pc_bus_out;
        else if (imm_bus_en)
            bus_r = imm_val;
        else if (mdr_enable_bus)
            bus_r = mdr_bus_out;
        else if (alu_out_en)
            bus_r = alu_bus_out;
        else if (R0_en)
            bus_r = R0_bus_out;
        else if (R1_en)
            bus_r = R1_bus_out;
        else if (R2_en)
            bus_r = R2_bus_out;
        else if (R3_en)
            bus_r = R3_bus_out;
        else if (p0_bus_en)
            bus_r = p0_bus_out;
        else if (p1_bus_en)
            bus_r = p1_bus_out;
    end
    assign bus = bus_r;


endmodule
