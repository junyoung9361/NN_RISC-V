module interlock(
    input [4:0] rs1_addr,
    input [4:0] rs2_addr,
    input [4:0] id_ex_rd_addr,
    input       id_ex_MemtoReg,
    input       id_ex_dnn_start,
    input       dnn_done,
    output reg  stall
);
    
    always@(*)begin
        if(id_ex_MemtoReg && ((id_ex_rd_addr[4:0] == rs1_addr[4:0]) || (id_ex_rd_addr[4:0] == rs2_addr[4:0]))) 
            stall=1'b1;
        else if (dnn_done)
            stall=1'b0;   
        else if(id_ex_dnn_start)
            stall=1'b1;
        else
            stall=1'b0;
    end
    
endmodule    