module controller 
#(
    parameter integer MEM_DWIDTH = 32,
    parameter integer MEM_AWIDTH = 32,
    parameter integer MEM_DEPTH  = 32 
)
(
    input clk,
    input rst,

    input                         dnn_done,
    input  [31:0]                 ex_mem_alu_result,

    // Control RAM I/F
    output [MEM_AWIDTH-1:0]       ctrl_ram_addr0,
    output                        ctrl_ram_ce0,
    output [3:0]                  ctrl_ram_we0,
    output [MEM_DWIDTH-1:0]       ctrl_ram_d0,
    input  [MEM_DWIDTH-1:0]       ctrl_ram_q0, // [0] : start signal, [5:1] : instruction count 

    // Instruction RAM I/F
    output                        inst_ram_ce0,
    output [3:0]                  inst_ram_we0,
    output [MEM_DWIDTH-1:0]       inst_ram_d0
);

    localparam S_IDLE = 2'b00;
    localparam S_RUN  = 2'b01;
    localparam S_WAIT = 2'b10;
    localparam S_DONE = 2'b11;

    reg  [1:0] ps, ns;
    wire [1:0] status;
    reg  [MEM_AWIDTH-1:0] cnt;

    always @ (posedge clk, negedge rst) begin
        if (!rst)
            ps <= S_IDLE;
        else
            ps <= ns;
    end

    always @ (*) begin
        case(ps)
            S_IDLE  : ns = (ctrl_ram_q0[0] == 1'b1) ? S_RUN : S_IDLE;
            S_RUN   : ns = (cnt == ctrl_ram_q0[5:1] - 1) ? S_WAIT : S_RUN;
            S_WAIT  : ns = (cnt == 5*ctrl_ram_q0[5:1] - 1) ? S_DONE : S_WAIT;
            //S_WAIT  : ns = (dnn_done == 1'b1) ? S_DONE : S_WAIT;
            S_DONE  : ns = S_IDLE;
            default : ns = S_IDLE;
        endcase
    end

    always@ (posedge clk, negedge rst) begin
        if(!rst)
            cnt <= 0;
        else if(ps == S_RUN || ps == S_WAIT)
            cnt <= cnt + 1;
        else
            cnt <= 0;
    end

    assign ctrl_ram_addr0 = (ps == S_DONE) ? 32'd1 : 32'd0;
    assign ctrl_ram_ce0   = ((ps == S_IDLE) || (ps == S_DONE)) ? 4'b1111 : 4'b0000;
    assign ctrl_ram_we0   = (ps == S_DONE) ? 4'b1111 : 4'b0000;
    assign ctrl_ram_d0    = (ps == S_DONE) ? {13'b0, ex_mem_alu_result, 5'b0, 1'b0} : 32'b0;
    assign inst_ram_ce0   = ((ps == S_RUN) || (ps == S_WAIT)) ? 1'b1 : 1'b0;
    assign inst_ram_we0   = 4'b0000;
    assign inst_ram_d0    = 32'd0;

endmodule