module IF_top (
    input           clk,
    input           rst,           

    // Branch inputs
    input           btaken,         
    input  [31:0]   branch_target,  
    input           inst_ram_ce0,
    input           stall,

    // IF/ID pipeline outputs
    output [31:0]   if_id_pc,
    output [31:0]   o_pc   
);

    reg  [31:0] PC;
    wire [31:0] pc_plus4;
    wire [31:0] pc_next;

    adder u_adder (
        .a  (PC),
        .b  (32'd4),
        .sum(pc_plus4)
    );

    mux u_mux (
        .a     (pc_plus4),
        .b     (branch_target),
        .select(btaken),
        .out   (pc_next)
    );

    always @(posedge clk or negedge rst) begin
        if (!rst)
            PC <= 32'b0;
        else if (inst_ram_ce0 && !stall)
            PC <= pc_next;
        else
            PC <= PC;
    end

    reg [31:0] if_id_pc_reg;
    always @(posedge clk or negedge rst) begin
        if (!rst)
            if_id_pc_reg <= 32'b0;
        else
            if_id_pc_reg <= PC;
    end

    assign if_id_pc    = if_id_pc_reg;
    assign o_pc        = {26'b0, PC[7:2]};

endmodule
