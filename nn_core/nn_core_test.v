module nn_core 
#(
	parameter CNT_BIT = 31,
// BRAM
	parameter DWIDTH = 32,
	parameter AWIDTH0 = 32,
	parameter AWIDTH1 = 32,
	parameter MEM_SIZE0 = 256,
	parameter MEM_SIZE1 = 4096,
	parameter IN_DATA_WIDTH = 8
)
(
    input        clk,
    input        reset_n,
    input        i_run,
    input [30:0] i_num_cnt,

// Memory I/F (Read from bram0)
	output [AWIDTH0-1:0] 	addr_b0,
	output 				    ce_b0,
	output [3:0]		    we_b0,
	input  [DWIDTH-1:0]     q_b0,
	output [DWIDTH-1:0]     d_b0,

// Memory I/F (Read to bram1)
	output [AWIDTH1-1:0] 	addr_b1,
	output 				    ce_b1,
	output [3:0]		    we_b1,
	input  [DWIDTH-1:0]     q_b1,
	output [DWIDTH-1:0] 	d_b1,

    output [DWIDTH-1:0]     result_0,
    output       o_done
);

    localparam S_IDLE = 2'b00;
    localparam S_RUN = 2'b01;
    localparam S_DONE = 2'b10;
    
    reg [1:0] c_state;
    reg [1:0] n_state;
    
    wire is_done;
    wire w_run;
    assign w_run = (c_state == S_RUN);
    
    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            c_state <= S_IDLE;
        end else begin
            c_state <= n_state;
        end
    end
    
    always @(*) begin
        case(c_state)
            S_IDLE: if(i_run)
                        n_state = S_RUN;
                    else
                        n_state = S_IDLE;
            S_RUN : if(is_done)
                        n_state = S_DONE;
                    else
                        n_state = S_RUN;
            S_DONE : n_state = S_IDLE;
        endcase
    end
    
    assign o_done = (c_state == S_DONE);
    
    reg [6:0] num_cnt;
    
    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            num_cnt <= 0;
        end else if(i_run) begin
            num_cnt <= i_num_cnt;
        end else if(is_done) begin
            num_cnt <= 0;
        end
    end
    
    reg [6:0] cnt_always;
    
    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            cnt_always <= 0;
        end else if(is_done) begin
            cnt_always <= 0;
        end else if(w_run) begin
            cnt_always <= cnt_always + 1;
        end
    end
    
    assign is_done = w_run && (cnt_always == 10);
    assign result_0 = (c_state == S_DONE) ? 32'd1 : 32'd0;


endmodule