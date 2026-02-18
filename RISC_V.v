module RISC_V
#(
    parameter integer INST_WIDTH      = 32,
    parameter integer CNT_BIT         = 31,
    parameter integer DNN_WIDTH       = 8,
    
    parameter integer MEM_DWIDTH      = 32,
    parameter integer MEM_AWIDTH      = 32,
    
    // Instruction BRAM
    parameter integer MEM0_MEM_DEPTH  = 64,
    
    // Data BRAM   
    parameter integer MEM1_MEM_DEPTH  = 8192,

    // Control BRAM
    parameter integer MEM_DEPTH       = 32,

    // Input BRAM
    parameter integer MEM3_MEM_DEPTH  = 256,
    
    // Weight memory
    parameter integer MEM4_MEM_DEPTH  = 4096 
)
(   
    input clk,
    input rst,

    // Instruction RAM I/F
    output [MEM_AWIDTH-1:0]       inst_ram_addr0,
    output                        inst_ram_ce0,
    output [3:0]                  inst_ram_we0,
    input  [MEM_DWIDTH-1:0]       inst_ram_q0,
    output [MEM_DWIDTH-1:0]       inst_ram_d0,
  
    // Memory RAM I/F
    output [MEM_AWIDTH-1:0]       mem_ram_addr0,
    output                        mem_ram_ce0,
    output [3:0]                  mem_ram_we0,
    input  [MEM_DWIDTH-1:0]       mem_ram_q0,
    output reg [MEM_DWIDTH-1:0]   mem_ram_d0,

    // Control RAM I/F
    output [MEM_AWIDTH-1:0]       ctrl_ram_addr0,
    output                        ctrl_ram_ce0,
    output [3:0]                  ctrl_ram_we0,
    input  [MEM_DWIDTH-1:0]       ctrl_ram_q0, // [0] : start signal, [5:1] : instruction count 
    output [MEM_DWIDTH-1:0]       ctrl_ram_d0,

    // Input RAM I/F
    output [MEM_AWIDTH-1:0]       input_ram_addr0,
    output                        input_ram_ce0,
    output [3:0]                  input_ram_we0,
    input  [MEM_DWIDTH-1:0]       input_ram_q0,
    output [MEM_DWIDTH-1:0]       input_ram_d0,

    // Weight RAM I/F
    output [MEM_AWIDTH-1:0]       weight_ram_addr0,
    output                        weight_ram_ce0,
    output [3:0]                  weight_ram_we0,
    input  [MEM_DWIDTH-1:0]       weight_ram_q0,
    output [MEM_DWIDTH-1:0]       weight_ram_d0
);

    // nn core signal
    wire                          dnn_done;
    wire   [INST_WIDTH-1:0]       dnn_output;

    // Branch inputs
    wire                          btaken;
    wire   [INST_WIDTH-1:0]       branch_target;

    // Stall signal
    wire                          stall;

    // IF/ID stage outputs
    wire   [INST_WIDTH-1:0]       if_id_pc;
    wire   [MEM_AWIDTH-1:0]       o_pc;
    wire  [INST_WIDTH-1:0]        w_if_id_instr;

    // ID/EX stage outputs 
    wire   [INST_WIDTH-1:0]       id_ex_pc;
    wire   [INST_WIDTH-1:0]       id_ex_rs1_data;
    wire   [INST_WIDTH-1:0]       id_ex_rs2_data;
    wire   [INST_WIDTH-1:0]       id_ex_ext_imm;
    wire   [4:0]                  id_ex_rd_addr;   
    wire                          id_ex_beq;       
    wire                          id_ex_ALUSrc;
    wire   [4:0]                  id_ex_ALUcont;
    wire   [3:0]                  id_ex_MemWrite;
    wire                          id_ex_MemtoReg;
    wire                          id_ex_RegWrite;
    wire                          id_ex_dnn_start;

    // ID -> interlock
    wire   [4:0]                  w_rs1_addr;
    wire   [4:0]                  w_rs2_addr;

    // ID -> data forwarding
    wire   [4:0]                  w_rs1_exe;
    wire   [4:0]                  w_rs2_exe;

    // EX/MEM → MEM stage outputs
    wire   [INST_WIDTH-1:0]       ex_mem_alu_result;
    wire   [INST_WIDTH-1:0]       ex_mem_rs2_data;
    wire   [4:0]                  ex_mem_rd_addr;
    wire   [3:0]                  ex_mem_MemWrite;
    wire                          ex_mem_MemtoReg;
    wire                          ex_mem_RegWrite;               

    // MEM → WB stage outputs
    wire   [INST_WIDTH-1:0]       mem_wb_read_data;
    wire   [INST_WIDTH-1:0]       mem_wb_alu_result;
    wire   [4:0]                  mem_wb_rd_addr;
    wire                          mem_wb_MemtoReg;
    wire                          mem_wb_RegWrite;
    // MEM -> EXE
    wire   [INST_WIDTH-1:0]       w_mem_exe_alu_result;

    // WB stage → Register_File
    wire                          RegWrite;     
    wire   [4:0]                  rd_addr;      
    wire   [INST_WIDTH-1:0]       rd_data;
    wire                          w_inst_ram_ce0;

    // WB -> EXE
    wire                          w_btaken_delay;
    wire   [INST_WIDTH-1:0]       w_wb_exe_rd_data;
    
    // Data forwarding -> EXE
    wire   [1:0]                  w_afwd;
    wire   [1:0]                  w_bfwd;     


    controller  #(
        .MEM_DWIDTH(MEM_DWIDTH),
        .MEM_AWIDTH(MEM_AWIDTH),
        .MEM_DEPTH(MEM0_MEM_DEPTH)
    ) u_controller (
        .clk            (clk),
        .rst            (rst),
        .dnn_done       (dnn_done),
        .ex_mem_alu_result(ex_mem_alu_result), // Memory RAM address

        // Control RAM I/F
        .ctrl_ram_addr0(ctrl_ram_addr0),
        .ctrl_ram_ce0  (ctrl_ram_ce0),
        .ctrl_ram_we0  (ctrl_ram_we0),
        .ctrl_ram_d0   (ctrl_ram_d0),
        .ctrl_ram_q0   (ctrl_ram_q0), // [0] : start signal, [5:1] : instruction count

        // Instruction RAM I/F
        .inst_ram_ce0  (w_inst_ram_ce0),
        .inst_ram_we0  (inst_ram_we0),
        .inst_ram_d0   (inst_ram_d0)
    );
    assign inst_ram_ce0 = (stall == 1'b0) ? w_inst_ram_ce0 : 1'b0;

    // IF stage
    IF_top u_if (
        .clk            (clk),
        .rst            (rst),
        .btaken         (btaken),
        .branch_target  (branch_target),
        .inst_ram_ce0   (inst_ram_ce0),
        .stall          (stall),
        .if_id_pc       (if_id_pc),
        .o_pc           (inst_ram_addr0)
    );

  
    assign w_if_id_instr = (btaken == 1'b1) ? 32'h00000013 : inst_ram_q0; 
    
    // ID stage
    ID_top u_id (
        .clk            (clk),
        .rst            (rst),
        .if_id_pc       (if_id_pc),
        .if_id_instr    (w_if_id_instr),
        .RegWrite       (RegWrite),
        .rd_addr        (rd_addr),
        .rd_data        (rd_data),
        .stall          (stall),
        .id_ex_pc       (id_ex_pc),
        .id_ex_rs1_data (id_ex_rs1_data),
        .id_ex_rs2_data (id_ex_rs2_data),
        .id_ex_ext_imm  (id_ex_ext_imm),
        .id_ex_rd_addr  (id_ex_rd_addr),
        .id_ex_beq      (id_ex_beq),
        .id_ex_ALUSrc   (id_ex_ALUSrc),
        .id_ex_ALUcont  (id_ex_ALUcont),
        .id_ex_MemWrite (id_ex_MemWrite),
        .id_ex_MemtoReg (id_ex_MemtoReg),
        .id_ex_RegWrite (id_ex_RegWrite),
        .id_ex_dnn_start(id_ex_dnn_start),
        .o_rs1_addr     (w_rs1_addr),
        .o_rs2_addr     (w_rs2_addr),
        .rs1_exe        (w_rs1_exe),
        .rs2_exe        (w_rs2_exe)
    );

    // EX stage
    EXE_top u_ex (
        .clk                  (clk),
        .rst                  (rst),
        .id_ex_pc             (id_ex_pc),
        .id_ex_rs1_data       (id_ex_rs1_data),
        .id_ex_rs2_data       (id_ex_rs2_data),
        .id_ex_ext_imm        (id_ex_ext_imm),
        .id_ex_rd_addr        (id_ex_rd_addr),
        .id_ex_beq            (id_ex_beq),
        .id_ex_ALUSrc         (id_ex_ALUSrc),
        .id_ex_ALUcont        (id_ex_ALUcont),
        .id_ex_MemWrite       (id_ex_MemWrite),
        .id_ex_MemtoReg       (id_ex_MemtoReg),
        .id_ex_RegWrite       (id_ex_RegWrite),
        .btaken_delay         (w_btaken_delay),
        .stall                (stall),
        .afwd                 (w_afwd),
        .bfwd                 (w_bfwd),
        .mem_exe_alu_result   (w_mem_exe_alu_result),
        .wb_exe_rd_data       (w_wb_exe_rd_data),
        .ex_mem_alu_result    (ex_mem_alu_result),
        .ex_mem_rs2_data      (ex_mem_rs2_data),
        .ex_mem_rd_addr       (ex_mem_rd_addr),
        .ex_mem_MemWrite      (ex_mem_MemWrite),
        .ex_mem_MemtoReg      (ex_mem_MemtoReg),
        .ex_mem_RegWrite      (ex_mem_RegWrite),
        .ex_mem_branch_target (branch_target),
        .ex_mem_btaken        (btaken)
    );

    // MEM stage
    MEM_top u_mem (
        .clk               (clk),
        .rst               (rst),
        .ex_mem_alu_result (ex_mem_alu_result),
        .ex_mem_rs2_data   (ex_mem_rs2_data),
        .ex_mem_MemWrite   (ex_mem_MemWrite),
        .ex_mem_MemtoReg   (ex_mem_MemtoReg),
        .ex_mem_RegWrite   (ex_mem_RegWrite),
        .ex_mem_rd_addr    (ex_mem_rd_addr),
        .mem_wb_alu_result (mem_wb_alu_result),
        .mem_wb_rd_addr    (mem_wb_rd_addr),
        .mem_wb_MemtoReg   (mem_wb_MemtoReg),
        .mem_wb_RegWrite   (mem_wb_RegWrite)
    );

    wire mem_fwd;
    assign mem_ram_addr0 = ex_mem_alu_result;
    assign mem_ram_ce0   = 1'b1;
    assign mem_ram_we0   = dnn_done ? 1'b1 : ex_mem_MemWrite;

    always @(*) begin
        if(mem_fwd)
            mem_ram_d0 = rd_data;
        else if (dnn_done)
            mem_ram_d0 = dnn_output;
        else
            mem_ram_d0 = ex_mem_rs2_data;
    end
    // WB stage
    WB_top u_wb (
        .clk               (clk),
        .rst               (rst),
        .mem_wb_read_data  (mem_ram_q0),
        .mem_wb_alu_result (mem_wb_alu_result),
        .mem_wb_rd_addr    (mem_wb_rd_addr),
        .mem_wb_MemtoReg   (mem_wb_MemtoReg),
        .mem_wb_RegWrite   (mem_wb_RegWrite),
        .btaken            (btaken),
        .RegWrite          (RegWrite),
        .rd_addr           (rd_addr),
        .rd_data           (rd_data),
        .btaken_delay      (w_btaken_delay)
    );

    interlock u_interlock (
        .rs1_addr       (w_rs1_addr),
        .rs2_addr       (w_rs2_addr),
        .id_ex_rd_addr  (id_ex_rd_addr),
        .id_ex_MemtoReg (id_ex_MemtoReg),
        .id_ex_dnn_start(id_ex_dnn_start),
        .dnn_done       (dnn_done),
        .stall          (stall)
    );

    data_forwarding u_data_forwarding (
        .rs1_exe            (w_rs1_exe),
        .rs2_exe            (w_rs2_exe),
        .ex_mem_rd_addr     (ex_mem_rd_addr),
        .mem_wb_rd_addr     (mem_wb_rd_addr),
        .ex_mem_RegWrite    (ex_mem_RegWrite),
        .mem_wb_RegWrite    (mem_wb_RegWrite),
        .afwd               (w_afwd),
        .bfwd               (w_bfwd),
        .mem_fwd            (mem_fwd)
    );

    nn_core #(
        .DWIDTH(MEM_DWIDTH),
        .AWIDTH0(MEM_AWIDTH),
        .AWIDTH1(MEM_AWIDTH),
        .MEM_SIZE0(MEM3_MEM_DEPTH),
        .MEM_SIZE1(MEM4_MEM_DEPTH),
        .IN_DATA_WIDTH(DNN_WIDTH)
    ) u_nn_core (
        .clk                (clk),
        .reset_n            (rst),
        .i_run              (id_ex_dnn_start), //control unit 변경해야됨

        // Input RAM I/F
        .addr_b0    (input_ram_addr0),
        .ce_b0      (input_ram_ce0),
        .we_b0      (input_ram_we0),
        .q_b0       (input_ram_d0),
        .d_b0       (input_ram_q0),

        // Weight RAM I/F
        .addr_b1   (weight_ram_addr0),
        .ce_b1     (weight_ram_ce0),
        .we_b1     (weight_ram_we0),
        .q_b1      (weight_ram_d0),
        .d_b1      (weight_ram_q0),

        .o_done   (dnn_done),
        .result_0 (dnn_output)
    );

endmodule