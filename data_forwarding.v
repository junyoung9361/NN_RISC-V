module data_Forwarding(
    input wire[4:0]  rs1_exe,
    input wire[4:0]  rs2_exe,
    input wire[4:0]  ex_mem_rd_addr,
    input wire[4:0]  mem_wb_rd_addr,
    input wire       ex_mem_RegWrite,
    input wire       mem_wb_RegWrite,
    
    output reg [1:0] afwd,
    output reg [1:0] bfwd,
    output reg       mem_fwd
    );
    
    always @(*) begin
        if (mem_wb_RegWrite && (mem_wb_rd_addr != 0) && (mem_wb_rd_addr == rs1_exe))
            afwd = 2'b10; // WB data
        else if (ex_mem_RegWrite && (ex_mem_rd_addr != 0) && (ex_mem_rd_addr == rs1_exe))
            afwd = 2'b01; // MEM data
        else
            afwd = 2'b00; // RF data
    end

    always @(*) begin
        if (mem_wb_RegWrite && (mem_wb_rd_addr != 0) && (mem_wb_rd_addr == rs2_exe))
            bfwd = 2'b10;
        else if (ex_mem_RegWrite && (ex_mem_rd_addr != 0) && (ex_mem_rd_addr == rs2_exe))
            bfwd = 2'b01;
        else
            bfwd = 2'b00;
    end

    always @(*) begin
        if (mem_wb_RegWrite && (mem_wb_rd_addr != 5'b0) && (mem_wb_rd_addr == rs2_exe))
            mem_fwd = 1'b1;
        else
            mem_fwd = 1'b0;
    end

endmodule
