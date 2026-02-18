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
    input 				    clk,
    input 				    reset_n,
	input 				    i_run,
	input  [CNT_BIT-1:0]	i_num_cnt,

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

// result
	output [DWIDTH-1:0]     result_0,
    output                  o_done
    );

    //state machine//
    reg [2:0] p_state, n_state;
    localparam S_IDLE	= 3'b000;
    localparam S_RUN0	= 3'b001;
    localparam S_RUN1	= 3'b010;
    localparam S_RUN2	= 3'b011;
    localparam S_DONE  	= 3'b100;
    
    wire w_finish0;
    wire w_finish1;
    wire w_finish2;
    
    always @ (posedge clk) begin
        if(!reset_n)
            p_state <= S_IDLE;
        else
            p_state <= n_state;
    end
    
    always @ (*) begin
        case(p_state)
            S_IDLE : n_state = i_run ? S_RUN0 : S_IDLE;
            S_RUN0 : n_state = w_finish0 ? S_RUN1 : S_RUN0;
            S_RUN1 : n_state = w_finish1 ? S_RUN2 : S_RUN1;
            S_RUN2 : n_state = w_finish2 ? S_DONE : S_RUN2;
            S_DONE : n_state = S_IDLE;
            default : n_state = S_IDLE;
        endcase
    end
    
    //ram data control//
    reg [AWIDTH0-1:0] addr_i_cnt;     //input ram address
    reg [AWIDTH1-1:0] addr_w_cnt;     //weight ram address

    wire w_we_b0 = 4'b0000; 
    wire w_we_b1 = 4'b0000;
    wire w_ce_b0, w_ce_b1;
    assign w_ce_b0 = p_state==S_RUN0;
    assign w_ce_b1 = p_state==S_RUN0 || p_state==S_RUN1;
    
    always @ (posedge clk) begin        //input ram control
        if(!reset_n) begin
            addr_i_cnt <= 0;
        end
        else if(addr_i_cnt==195) begin
            addr_i_cnt <= 0;
        end
        else if(p_state==S_RUN0) begin
            addr_i_cnt <= addr_i_cnt+1;
        end
        else begin
            addr_i_cnt <= 0;
        end
    end
    
    always @ (posedge clk) begin        //weight ram control
        if(!reset_n) begin
            addr_w_cnt <= 0;
        end
        else if(p_state==S_RUN0 || p_state==S_RUN1) begin
            addr_w_cnt <= addr_w_cnt+1;
        end 
        else begin
            addr_w_cnt <= 0;
        end
    end
    
    assign ce_b0 = w_ce_b0;
    assign ce_b1 = w_ce_b1;
    assign we_b0 = w_we_b0;
    assign we_b1 = w_we_b1;
    assign addr_b0 = addr_i_cnt;
    assign addr_b1 = addr_w_cnt;


    //MAC core, ReLU core//
    wire fc1_en;
    assign fc1_en = p_state==S_RUN0;
    wire [143:0] w_neuron;


    mac_fc1 #(
        .AWIDTH0(AWIDTH0),
        .AWIDTH1(AWIDTH1)
    ) inst_fc1 (
        .clk         (clk), 
        .reset_n     (reset_n),
        .enable      (fc1_en),
        .i_addr_i_cnt(addr_i_cnt),
        .i_addr_w_cnt(addr_w_cnt),
        .pixel_data  (q_b0),
        .weight_data (q_b1),
        .o_neuron    (w_neuron),
        .o_finish    (w_finish0)
    );

    wire fc2_en;
    assign fc2_en = p_state==S_RUN1;
    wire [199:0] w_output;


    mac_fc2 #(
    ) inst_fc2 (
        .clk         (clk), 
        .reset_n     (reset_n),
        .enable      (fc2_en),
        .i_neuron    (w_neuron),
        .weight_data (q_b1),
        .o_neuron    (w_output),
        .o_finish    (w_finish1)
    );

    wire com_en;
    assign com_en = p_state==S_RUN2;
    wire [3:0] w_max_index;

    compare #(
    ) inst_com (
        .clk         (clk), 
        .reset_n     (reset_n),
        .enable      (com_en),
        .i_data      (w_output),
        .max_index   (w_max_index),
        .o_finish    (w_finish2)
    );

    assign result_0 = {28'd0, w_max_index};
    assign o_done   = (p_state == S_DONE) ? 1'b1 : 1'b0;

endmodule