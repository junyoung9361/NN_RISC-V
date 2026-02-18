module WB_top (
    // MEM→WB 파이프라인에서 넘어온 신호
    input            clk,
    input            rst,
    input  wire [31:0] mem_wb_read_data,  // DataMem에서 읽어온 값
    input  wire [31:0] mem_wb_alu_result, // EX에서 전달된 ALU 결과
    input  wire [4:0]  mem_wb_rd_addr,    // 목적 레지스터 주소
    input  wire        mem_wb_MemtoReg,   // WB MUX 선택 신호
    input  wire        mem_wb_RegWrite,   // RF 쓰기 인에이블
    input  wire        btaken,

    // WB → Register File 포트
    output wire        RegWrite,          // RF 쓰기 인에이블
    output wire [4:0]  rd_addr,           // RF 목적 레지스터 주소
    output wire [31:0] rd_data,            // RF에 쓰일 데이터
    output reg         btaken_delay
);

    always@ (negedge clk or negedge rst) begin
        if (!rst) begin
            btaken_delay <= 1'b0;
        end else begin
            btaken_delay <= btaken;
        end
    end
    
    // 제어 신호 그대로 전달
    assign RegWrite = mem_wb_RegWrite;
    assign rd_addr  = mem_wb_rd_addr;

    // WB MUX: Load냐 ALU냐 골라서 rd_data로
    assign rd_data  = (mem_wb_MemtoReg) ? mem_wb_read_data : mem_wb_alu_result;

endmodule
