module EXE_top (
    input  wire        clk,
    input  wire        rst,

    // ID/EX → EX stage signals
    input  wire [31:0] id_ex_pc,
    input  wire [31:0] id_ex_rs1_data,
    input  wire [31:0] id_ex_rs2_data,
    input  wire [31:0] id_ex_ext_imm,
    input  wire [4:0]  id_ex_rd_addr,
    input  wire        id_ex_beq,
    input  wire        id_ex_ALUSrc,
    input  wire [4:0]  id_ex_ALUcont,
    input  wire [3:0]  id_ex_MemWrite,
    input  wire        id_ex_MemtoReg,
    input  wire        id_ex_RegWrite,

    input  wire        btaken_delay,
    input              stall,


    //data forwarding signal
    input wire  [1:0]  afwd,
    input wire  [1:0]  bfwd,

    // MEM -> EXE
    input wire  [1:0]  mem_exe_alu_result,
    
    // WB -> EXE
    input wire  [31:0] wb_exe_rd_data,
 
    // EX/MEM → MEM stage pipeline outputs
    output reg  [31:0] ex_mem_alu_result,
    output reg  [31:0] ex_mem_rs2_data,
    output reg  [4:0]  ex_mem_rd_addr,
    output reg  [3:0]  ex_mem_MemWrite,
    output reg         ex_mem_MemtoReg,
    output reg         ex_mem_RegWrite,

    // (옵션) Branch feedback signals
    output reg  [31:0] ex_mem_branch_target,
    output reg         ex_mem_btaken
);

    // 1) Branch offset: sign-extended imm << 1
    wire [31:0] branch_offset = id_ex_ext_imm << 1;

    // 2) Branch target = PC + branch_offset
    wire [31:0] branch_target;
    adder u_branch_adder (
        .a   (id_ex_pc),
        .b   (branch_offset),
        .sum (branch_target)
    );

    reg [31:0] rs1_fwd_data;
    always @(*) begin
        case (afwd)
            2'b00: rs1_fwd_data = id_ex_rs1_data; // No forwarding
            2'b01: rs1_fwd_data = mem_exe_alu_result; // Forward from MEM stage
            2'b10: rs1_fwd_data = wb_exe_rd_data; // Forward from WB stage
            default: rs1_fwd_data = id_ex_rs1_data; // Default case
        endcase
    end

    reg [31:0] rs2_fwd_data;
    always @(*) begin
        case (bfwd)
            2'b00: rs2_fwd_data = id_ex_rs2_data; // No forwarding
            2'b01: rs2_fwd_data = mem_exe_alu_result; // Forward from MEM stage
            2'b10: rs2_fwd_data = wb_exe_rd_data; // Forward from WB stage
            default: rs2_fwd_data = id_ex_rs2_data; // Default case
        endcase
    end

    // 3) ALU second operand select
    wire [31:0] alu_in2 = id_ex_ALUSrc ? id_ex_ext_imm : id_ex_rs2_data;


    // 4) ALU operation
    wire        zero_flag, n_flag, c_flag, v_flag;
    wire [31:0] alu_result;
    ALU u_alu (
        .A       (id_ex_rs1_data),
        .B       (alu_in2),
        .ALUcont (id_ex_ALUcont),
        .result  (alu_result),
        .Z       (zero_flag),
        .N       (n_flag),
        .C       (c_flag),
        .V       (v_flag)
    );

    // 5) Branch decision: beq & zero
    wire btaken;
    branch_and u_branch_and (
        .beq    (id_ex_beq),
        .zero   (zero_flag),
        .btaken (btaken)
    );

    // 6) EX/MEM pipeline registers (D-FF)
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            ex_mem_alu_result    <= 32'b0;
            ex_mem_rs2_data      <= 32'b0;
            ex_mem_rd_addr       <= 5'b0;
            ex_mem_MemWrite      <= 4'b0;
            ex_mem_MemtoReg      <= 1'b0;
            ex_mem_RegWrite      <= 1'b0;
            ex_mem_branch_target <= 32'b0;
            ex_mem_btaken        <= 1'b0;
        end else if(btaken_delay) begin
            // Branch taken, reset EX/MEM pipeline registers
            ex_mem_alu_result    <= 32'b0;
            ex_mem_rs2_data      <= 32'b0;
            ex_mem_rd_addr       <= 5'b0;
            ex_mem_MemWrite      <= 4'b0;
            ex_mem_MemtoReg      <= 1'b0;
            ex_mem_RegWrite      <= 1'b0;
            ex_mem_branch_target <= 32'b0;
            ex_mem_btaken        <= 1'b0;
        end else if(stall) begin
            ex_mem_alu_result    <= alu_result;
        end else begin
            // 1) ALU 결과
            ex_mem_alu_result    <= alu_result;
            // 2) Store data (rs2)
            ex_mem_rs2_data      <= id_ex_rs2_data;
            // 3) Destination register
            ex_mem_rd_addr       <= id_ex_rd_addr;
            // 4) Control signals
            ex_mem_MemWrite      <= id_ex_MemWrite;
            ex_mem_MemtoReg      <= id_ex_MemtoReg;
            ex_mem_RegWrite      <= id_ex_RegWrite;
            // (옵션) Branch feedback
            ex_mem_branch_target <= branch_target;
            ex_mem_btaken        <= btaken;
        end
    end

endmodule