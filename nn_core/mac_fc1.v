module mac_fc1
#(
    parameter AWIDTH0 = 8,
    parameter AWIDTH1 = 12
)
(
    input clk,
    input reset_n,
    input enable,                     // ��� ���� ��ȣ
    input [AWIDTH0-1:0] i_addr_i_cnt,
    input [AWIDTH1-1:0] i_addr_w_cnt,
    input [31:0] pixel_data,          // 32-bit ������ �������̽�, true_sync_dpbram�� ����
    input [31:0] weight_data,         // 32-bit ������ �������̽�, true_sync_dpbram�� ����
    output [143:0] o_neuron,        // ��� ��� ���, nn_core�� ����
    output o_finish                   // ��� �Ϸ� ��ȣ, nn_core�� ����
);

    // ����: �� ������ ��Ʈ�� 4���� 8��Ʈ �ȼ�/����ġ�� ����
    wire signed [8:0] pixels[3:0];
    wire signed [7:0] weights[3:0];
    wire signed [16:0] products[3:0];

    // 32��Ʈ �Է��� 4���� 8��Ʈ ������ ����(�ȼ��� ���κ�Ʈ �߰�)
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin
            assign pixels[i] = {1'b0, pixel_data[8*i+7 : 8*i]};
            assign weights[i] = weight_data[8*i+7 : 8*i];
        end
    endgenerate

    // �� �ȼ��� ����ġ�� ����
    generate
        for (i = 0; i < 4; i = i + 1) begin
            assign products[i] = pixels[i] * weights[i];
        end
    endgenerate


    // ���� ����� ���� �հ� ���
    wire signed [19:0] sum;
    reg signed [19:0] sum_out;
    assign sum = ((products[0] + products[1]) + (products[2] + products[3])) + sum_out;

    always @(posedge clk) begin
        if (!reset_n) begin
            sum_out <= 0;
        end else if (w_finish) begin
            sum_out <= 0;
        end else if (enable) begin
            sum_out <= sum;
        end
    end

    wire w_finish;
    assign w_finish = (i_addr_w_cnt>12'd0 && i_addr_i_cnt==8'd0) ? 1 : 0;

    reg [143:0] r_neuron;
    reg [3:0] mux_cnt;

    always @(posedge clk) begin
        if (!reset_n) begin
            r_neuron <= 0;
        end else if (w_finish && enable) begin
            case(mux_cnt)
                4'd0: r_neuron[9*0+8:9*0] <= sum[19] ? 0 : sum[19:11];       //ReLU
                4'd1: r_neuron[9*1+8:9*1] <= sum[19] ? 0 : sum[19:11];
                4'd2: r_neuron[9*2+8:9*2] <= sum[19] ? 0 : sum[19:11];
                4'd3: r_neuron[9*3+8:9*3] <= sum[19] ? 0 : sum[19:11];
                4'd4: r_neuron[9*4+8:9*4] <= sum[19] ? 0 : sum[19:11];
                4'd5: r_neuron[9*5+8:9*5] <= sum[19] ? 0 : sum[19:11];
                4'd6: r_neuron[9*6+8:9*6] <= sum[19] ? 0 : sum[19:11];
                4'd7: r_neuron[9*7+8:9*7] <= sum[19] ? 0 : sum[19:11];
                4'd8: r_neuron[9*8+8:9*8] <= sum[19] ? 0 : sum[19:11];
                4'd9: r_neuron[9*9+8:9*9] <= sum[19] ? 0 : sum[19:11];
                4'd10: r_neuron[9*10+8:9*10] <= sum[19] ? 0 : sum[19:11];
                4'd11: r_neuron[9*11+8:9*11] <= sum[19] ? 0 : sum[19:11];
                4'd12: r_neuron[9*12+8:9*12] <= sum[19] ? 0 : sum[19:11];
                4'd13: r_neuron[9*13+8:9*13] <= sum[19] ? 0 : sum[19:11];
                4'd14: r_neuron[9*14+8:9*14] <= sum[19] ? 0 : sum[19:11];
                4'd15: r_neuron[9*15+8:9*15] <= sum[19] ? 0 : sum[19:11];
            endcase
        end
    end

    always @(posedge clk) begin
        if (!reset_n) begin
            mux_cnt <= 0;
        end else if (w_finish && enable) begin
            mux_cnt <= mux_cnt+1;                                                            
        end
    end

    assign o_neuron = r_neuron;
    assign o_finish = mux_cnt==4'd15 && w_finish;

endmodule