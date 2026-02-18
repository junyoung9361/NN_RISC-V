module Register_File (
    input  wire        clk,          // system clock
    input  wire        rst,          // asynchronous reset
    input  wire        RegWrite,     // write enable
    input  wire [31:0] instr,        // RISC-V 32bit instruction
    input  wire [4:0]  rd_addr,      // writeback destination
    input  wire [31:0] rd_data,      // writeback data
    output reg [31:0] rs1_data,     // read port 1
    output reg [31:0] rs2_data      // read port 2
);

    // --- 내부 레지스터 파일 ---
    reg [31:0] regs [0:31];
    integer i;

    // --- instruction에서 주소 필드 분리 ---
    wire [4:0] rs1_addr = instr[19:15];
    wire [4:0] rs2_addr = instr[24:20];

    // --- Reset + Write ---
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            for (i = 0; i < 32; i = i + 1)
                regs[i] <= 32'b0;
        end else if (RegWrite && (rd_addr != 5'd0)) begin
            regs[rd_addr] <= rd_data;
        end
    end

    always @(*) begin
        if(rs1_addr == rd_addr && RegWrite && (rd_addr != 5'd0)) begin
            rs1_data = rd_data; 
        end else begin
            rs1_data = (rs1_addr == 5'd0) ? 32'b0 : regs[rs1_addr];
        end
    end

    always @(*) begin
        if(rs2_addr == rd_addr && RegWrite && (rd_addr != 5'd0)) begin
            rs2_data = rd_data; 
        end else begin
            rs2_data = (rs1_addr == 5'd0) ? 32'b0 : regs[rs1_addr];
        end
    end

endmodule