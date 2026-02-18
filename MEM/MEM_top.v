module MEM_top (
    input  wire        clk,
    input  wire        rst,
    input  wire [31:0] ex_mem_alu_result,
    input  wire [31:0] ex_mem_rs2_data,
    input  wire [3:0]  ex_mem_MemWrite,
    input  wire        ex_mem_MemtoReg,
    input  wire        ex_mem_RegWrite,
    input  wire [4:0]  ex_mem_rd_addr,

    output reg  [31:0] mem_wb_alu_result,
    output reg  [4:0]  mem_wb_rd_addr,
    output reg         mem_wb_MemtoReg,
    output reg         mem_wb_RegWrite
);

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            mem_wb_alu_result <= 32'd0;
            mem_wb_rd_addr    <= 5'd0;
            mem_wb_MemtoReg   <= 1'b0;
            mem_wb_RegWrite   <= 1'b0;
        end else begin
            mem_wb_alu_result <= ex_mem_alu_result;
            mem_wb_rd_addr    <= ex_mem_rd_addr;
            mem_wb_MemtoReg   <= ex_mem_MemtoReg;
            mem_wb_RegWrite   <= ex_mem_RegWrite;
        end
    end

endmodule