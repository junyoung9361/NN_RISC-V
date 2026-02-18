// ---------- Opcode defines ----------------------------------------------------
`define OP_R        7'b0110011
`define OP_I_ARITH  7'b0010011
`define OP_I_LOAD   7'b0000011
`define OP_I_JALR   7'b1100111
`define OP_S        7'b0100011
`define OP_B        7'b1100011
`define OP_LUI      7'b0110111
`define OP_AUIPC    7'b0010111
`define OP_JAL      7'b1101111
`define OP_NN       7'b0001011

module Control_Unit(
    input  wire [6:0] opcode,
    input  wire [2:0] funct3,
    input  wire [6:0] funct7,

    output reg        beq,       // 1 → conditional branch active (BEQ/BNE …)
    output reg        ALUSrc,    // 1 → ALU B operand = immediate
    output reg [4:0]  ALUcont,   // ALU control
    output reg [3:0]  MemWrite,  // 1 → store to data memory
    output reg        MemtoReg,  // 1 → rd_data = memory (LOAD)
    output reg        RegWrite,  // 1 → write back to register file
    output reg        dnn_start
);

    // -----------------------------------------------------------------------------
    // 1) RegWrite : STORE & BRANCH 제외 모두 1
    // -----------------------------------------------------------------------------
    always @(*) begin
        case (opcode)
            `OP_I_ARITH,
            `OP_I_LOAD,
            `OP_I_JALR,
            `OP_R,      
            `OP_LUI,
            `OP_AUIPC,
            `OP_JAL 
            : RegWrite = 1'b1;
            default      : RegWrite = 1'b0; // R, I?arith, LOAD, LUI, AUIPC, JAL, JALR
        endcase
    end

    // -----------------------------------------------------------------------------
    // 2) beq : BRANCH 류만 1 (Zero 플래그와 AND)
    // -----------------------------------------------------------------------------
    always @(*) begin
        if(opcode == `OP_B) begin
            case (funct3)
                3'b000: beq = 1'b1; // BEQ
                3'b001: beq = 1'b0; // BNE
                3'b100: beq = 1'b0; // BLT
                3'b101: beq = 1'b0; // BGE
                3'b110: beq = 1'b0; // BLTU
                3'b111: beq = 1'b0; // BGEU
                default: beq = 1'b0;
            endcase
        end else begin
            beq = 1'b0;
        end
    end

    // -----------------------------------------------------------------------------
    // 3) ALUSrc : R?type & BRANCH만 0, 그 외 1 (immediate 사용)
    // -----------------------------------------------------------------------------
    always @(*) begin
        case (opcode)
            `OP_I_ARITH,
            `OP_I_LOAD,
            `OP_I_JALR,
            `OP_S,      
            `OP_LUI,
            `OP_AUIPC,
            `OP_JAL,
            `OP_NN       
            : ALUSrc = 1'b1;
            default : ALUSrc = 1'b0;
        endcase
    end

    // -----------------------------------------------------------------------------
    // 4) MemWrite : STORE, DNN
    // -----------------------------------------------------------------------------
    always @(*) begin
        case (opcode)
            `OP_S:  MemWrite =  4'b1111; // STORE
            `OP_NN: MemWrite =  4'b1111; // DNN operation, no memory write
            default: MemWrite = 4'b0000; // R, I?arith, LOAD, LUI, AUIPC, JAL, JALR, BRANCH
        endcase
    end

    // -----------------------------------------------------------------------------
    // 5) MemtoReg : LOAD 만 1 (DataMem → rd)
    // -----------------------------------------------------------------------------
    always @(*) begin
        case(opcode)
            `OP_I_LOAD: MemtoReg = 1'b1;
            // `OP_R: MemtoReg = 1'b1;
            default: MemtoReg = 1'b0;
        endcase
    end

    // -----------------------------------------------------------------------------
    // 6) ALU control (ALUcont)
    //     5?bit encoding ? 기존 설계 유지
    // -----------------------------------------------------------------------------
    always @(*) begin
        case (opcode)
            // ----------------- R?type -------------------------------------------
            `OP_R: begin
                case ({funct7, funct3})
                    10'b0000000_000: ALUcont = 5'b00000; // ADD
                    10'b0100000_000: ALUcont = 5'b10000; // SUB
                    10'b0000000_001: ALUcont = 5'b00100; // SLL
                    10'b0000000_010: ALUcont = 5'b10111; // SLT
                    10'b0000000_011: ALUcont = 5'b11000; // SLTU
                    10'b0000000_100: ALUcont = 5'b00011; // XOR
                    10'b0000000_101: ALUcont = 5'b00101; // SRL
                    10'b0100000_101: ALUcont = 5'b00110; // SRA
                    10'b0000000_110: ALUcont = 5'b00010; // OR
                    10'b0000000_111: ALUcont = 5'b00001; // AND
                    default         : ALUcont = 5'b00000;
                endcase
            end
            // ----------------- I?type Arithmetic --------------------------------
            `OP_I_ARITH: begin
                if (funct3 == 3'b001 && funct7 == 7'b0000000)         ALUcont = 5'b00100; // SLLI
                else if (funct3 == 3'b101 && funct7 == 7'b0000000)    ALUcont = 5'b00101; // SRLI
                else if (funct3 == 3'b101 && funct7 == 7'b0100000)    ALUcont = 5'b00110; // SRAI
                else begin
                    case (funct3)
                        3'b000: ALUcont = 5'b00000; // ADDI
                        3'b010: ALUcont = 5'b10111; // SLTI
                        3'b011: ALUcont = 5'b11000; // SLTIU
                        3'b100: ALUcont = 5'b00011; // XORI
                        3'b110: ALUcont = 5'b00010; // ORI
                        3'b111: ALUcont = 5'b00001; // ANDI
                        default: ALUcont = 5'b00000;
                    endcase
                end
            end
            // ----------------- Load / Store / Other -----------------------------
            `OP_I_LOAD ,
            `OP_S      ,
            `OP_I_JALR ,
            `OP_LUI    ,
            `OP_AUIPC  ,
            `OP_JAL    : ALUcont = 5'b00000; // ADD-like (base + offset)
            // ----------------- Branch -------------------------------------------
            `OP_B:  ALUcont = 5'b10000;         // use SUB for comparison (Zero flag)
            `OP_NN: ALUcont = 5'b00000; // DNN operation, no specific ALU control
            // --------------------------------------------------------------------
            default: ALUcont = 5'b00000;
        endcase
    end

    always @(*) begin
        if (opcode == `OP_NN)
            dnn_start = 1'b1; // Start DNN operation
        else
            dnn_start = 1'b0; // Not a DNN operation
    end

endmodule