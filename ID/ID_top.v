module ID_top (
    input  wire        clk,           // system clock
    input  wire        rst,           // asynchronous reset

    // IF/ID stage inputs
    input  wire [31:0] if_id_pc,
    input  wire [31:0] if_id_instr,

    // WB stage → Register_File 쓰기 포트 (RegWrite, rd_addr, rd_data)
    input  wire        RegWrite,      // write enable
    input  wire [4:0]  rd_addr,       // WB stage 쓰기 대상 레지스터 주소
    input  wire [31:0] rd_data,       // WB stage 쓰기 데이터
    input  wire        stall,         // stall signal

    // ID/EX stage outputs (6 data + 6 control)
    output reg  [31:0] id_ex_pc,
    output reg  [31:0] id_ex_rs1_data,
    output reg  [31:0] id_ex_rs2_data,
    output reg  [31:0] id_ex_ext_imm,
    output reg  [4:0]  id_ex_rd_addr,   // IF/ID에서 뽑은 dest_addr
    output reg         id_ex_beq,       // Control signals
    output reg         id_ex_ALUSrc,
    output reg  [4:0]  id_ex_ALUcont,
    output reg  [3:0]  id_ex_MemWrite,
    output reg         id_ex_MemtoReg,
    output reg         id_ex_RegWrite,
    output reg         id_ex_dnn_start,

    output      [4:0]  o_rs1_addr,
    output      [4:0]  o_rs2_addr,
    
    output reg  [4:0]  rs1_exe,
    output reg  [4:0]  rs2_exe
);

    // 1) IF/ID instr 필드 분리 (내부용 dest_addr)
    wire [6:0]  opcode;
    reg  [4:0]  rs1_addr;
    reg  [4:0]  rs2_addr;
    reg  [4:0]  dest_addr;    // 여기 이름 변경
    reg  [11:0] imm12;
    reg  [2:0]  funct3;
    reg  [6:0]  funct7;

    
    assign opcode = if_id_instr[6:0];

    always @(*) begin
        case(opcode)
            7'b1100011: begin
                // Branch instructions
                rs1_addr = if_id_instr[19:15];
                rs2_addr = if_id_instr[24:20];
                dest_addr = 5'b0;  // Branch instructions do not write to rd
                imm12 = {if_id_instr[31], if_id_instr[7], if_id_instr[30:25], if_id_instr[11:8], 1'b0}; // Branch immediate
                funct3 = if_id_instr[14:12];
                funct7 = 7'b0;  // Branch instructions do not use funct7
            end
            7'b0000011: begin
                // Load instructions
                rs1_addr = if_id_instr[19:15];
                rs2_addr = 5'b0;  // Load instructions do not use rs2
                dest_addr = if_id_instr[11:7];
                imm12 = if_id_instr[31:20]; // Load immediate
                funct3 = if_id_instr[14:12];
                funct7 = 7'b0;  // Load instructions do not use funct7
            end
            7'b0100011: begin
                // Store instructions
                rs1_addr = if_id_instr[19:15];
                rs2_addr = if_id_instr[24:20];
                dest_addr = 5'b0;  // Store instructions do not write to rd
                imm12 = {if_id_instr[31:25], if_id_instr[11:7]}; // Store immediate
                funct3 = if_id_instr[14:12];
                funct7 = 7'b0;
            end
            7'b0010011: begin
                // I-type ALU instructions
                rs1_addr = if_id_instr[19:15];
                rs2_addr = 5'b0;  // I-type ALU instructions do not use rs2
                dest_addr = if_id_instr[11:7];
                imm12 = if_id_instr[31:20]; // I-type immediate
                funct3 = if_id_instr[14:12];
                funct7 = 7'b0;
            end
            7'b0110011: begin
                // R-type ALU instructions
                rs1_addr = if_id_instr[19:15];
                rs2_addr = if_id_instr[24:20];
                dest_addr = if_id_instr[11:7];
                imm12 = 12'b0; // R-type instructions do not use immediate
                funct3 = if_id_instr[14:12];
                funct7 = if_id_instr[31:25]; // R-type ALU instructions use funct7
            end
            7'b0001011: begin
                // nn custom instructions
                rs1_addr = 5'b0; // nn instructions do not use rs1
                rs2_addr = 5'b0; // nn instructions do not use rs2
                dest_addr = 5'b0; // nn instructions write to rd
                imm12 = if_id_instr[31:20]; // nn immediate
                funct3 = 3'b0; // nn instructions use funct3
                funct7 = 7'b0; // nn instructions do not use funct7
            end
            default: begin
                // Default case for unsupported instructions
                rs1_addr = 5'b0;
                rs2_addr = 5'b0;
                dest_addr = 5'b0;
                imm12 = 12'b0;
                funct3 = 3'b0;
                funct7 = 7'b0;
            end
        endcase
    end
    
    // 2) Register File 인스턴스 (읽기 비동기, 쓰기 동기)
    wire [31:0] rs1_data, rs2_data;

    Register_File u_rf (
    .clk      (clk),
    .rst      (rst),
    .RegWrite (RegWrite),
    .instr    (if_id_instr),  // ★ 여기만 수정하면 됩니다
    .rd_addr  (rd_addr),
    .rd_data  (rd_data),
    .rs1_data (rs1_data),
    .rs2_data (rs2_data)
    );


    // 3) Extension Unit
    wire [31:0] ext_imm;
    Extension_Unit u_ext (
        .imm     (imm12),
        .ext_imm (ext_imm)
    );

    // 4) Control Unit
    wire        ctrl_beq, ctrl_ALUSrc, ctrl_MemWrite, ctrl_MemtoReg, ctrl_RegWrite_ctrl;
    wire [4:0]  ctrl_ALUcont;
    wire        w_id_ex_dnn_start;
    
    Control_Unit u_ctrl (
        .opcode   (opcode),
        .funct3   (funct3),
        .funct7   (funct7),
        .beq      (ctrl_beq),
        .ALUSrc   (ctrl_ALUSrc),
        .ALUcont  (ctrl_ALUcont),
        .MemWrite (ctrl_MemWrite),
        .MemtoReg (ctrl_MemtoReg),
        .RegWrite (ctrl_RegWrite_ctrl),
        .dnn_start(w_id_ex_dnn_start)
    );
    
    // 5) ID → EX 파이프라인 레지스터
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            id_ex_pc        <= 32'b0;
            id_ex_rs1_data  <= 32'b0;
            id_ex_rs2_data  <= 32'b0;
            id_ex_ext_imm   <= 32'b0;
            id_ex_rd_addr   <= 5'b0;
            id_ex_beq       <= 1'b0;
            id_ex_ALUSrc    <= 1'b0;
            id_ex_ALUcont   <= 5'b0;
            id_ex_MemWrite  <= 4'b0;
            id_ex_MemtoReg  <= 1'b0;
            id_ex_RegWrite  <= 1'b0;
            rs1_exe         <= 5'b0;
            rs2_exe         <= 5'b0;
        end else if (stall) begin
            id_ex_beq       <= 1'b0;
            id_ex_ALUSrc    <= 1'b1;
            id_ex_ALUcont   <= 5'b0;
            id_ex_MemWrite  <= 4'b0;
            id_ex_MemtoReg  <= 1'b0;
            id_ex_RegWrite  <= 1'b0;
        end else begin
            // 데이터 신호
            id_ex_pc        <= if_id_pc;
            id_ex_rs1_data  <= rs1_data;
            id_ex_rs2_data  <= rs2_data;
            id_ex_ext_imm   <= ext_imm;
            id_ex_rd_addr   <= dest_addr;

            // 제어 신호
            id_ex_beq       <= ctrl_beq;
            id_ex_ALUSrc    <= ctrl_ALUSrc;
            id_ex_ALUcont   <= ctrl_ALUcont;
            id_ex_MemWrite  <= ctrl_MemWrite;
            id_ex_MemtoReg  <= ctrl_MemtoReg;
            id_ex_RegWrite  <= ctrl_RegWrite_ctrl;
            id_ex_dnn_start <= w_id_ex_dnn_start;

            // data forwarding 신호
            rs1_exe         <= rs1_addr;
            rs2_exe         <= rs2_addr;
        end
    end

    assign o_rs1_addr = rs1_addr;
    assign o_rs2_addr = rs2_addr;

endmodule