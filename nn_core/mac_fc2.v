module mac_fc2
#(
)
(
    input clk,
    input reset_n,
    input enable,                     // ��� ���� ��ȣ
    input [143:0] i_neuron,          // 32-bit ������ �������̽�, true_sync_dpbram�� ����
    input [31:0] weight_data,         // 32-bit ������ �������̽�, true_sync_dpbram�� ����
    output [199:0] o_neuron,        // ��� ��� ���, nn_core�� ����
    output o_finish                   // ��� �Ϸ� ��ȣ, nn_core�� ����
);

    // ����: �� ������ ��Ʈ�� 4���� 8��Ʈ �ȼ�/����ġ�� ����
    wire signed [8:0] i_data[15:0];
    wire signed [7:0] weights[3:0];
    reg signed [16:0] products[3:0];
    reg [1:0] neuron_cnt;

    // 32��Ʈ �Է��� 4���� 8��Ʈ ������ ����(�ȼ��� ���κ�Ʈ �߰�)
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin
            assign weights[i] = weight_data[8*i+7 : 8*i];
        end
    endgenerate

    generate
        for (i = 0; i < 16; i = i + 1) begin
            assign i_data[i] = i_neuron[9*i+8 : 9*i];
        end
    endgenerate

    // �� �ȼ��� ����ġ�� ����
    always @(*) begin
        case(neuron_cnt)
            2'b00 : begin 
                products[0] <= i_data[0] * weights[0];
                products[1] <= i_data[1] * weights[1];
                products[2] <= i_data[2] * weights[2];
                products[3] <= i_data[3] * weights[3];
            end
            2'b01 : begin 
                products[0] <= i_data[4] * weights[0];
                products[1] <= i_data[5] * weights[1];
                products[2] <= i_data[6] * weights[2];
                products[3] <= i_data[7] * weights[3];
            end
            2'b10 : begin 
                products[0] <= i_data[8] * weights[0];
                products[1] <= i_data[9] * weights[1];
                products[2] <= i_data[10] * weights[2];
                products[3] <= i_data[11] * weights[3];
            end
            2'b11 : begin 
                products[0] <= i_data[12] * weights[0];
                products[1] <= i_data[13] * weights[1];
                products[2] <= i_data[14] * weights[2];
                products[3] <= i_data[15] * weights[3];
            end
        endcase
    end

    always @(posedge clk) begin
        if(!reset_n)
            neuron_cnt <= 0;
        else if(enable)
            neuron_cnt <= neuron_cnt+1;
    end


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
    assign w_finish = neuron_cnt==2'b11;

    reg [199:0] r_neuron;
    reg [3:0] mux_cnt;

    always @(posedge clk) begin
        if (!reset_n) begin
            r_neuron <= 0;
        end else if (w_finish && enable) begin
            case(mux_cnt)
                4'd0: r_neuron[20*0+19:20*0] <= sum[19] ? 0 : sum;       //ReLU
                4'd1: r_neuron[20*1+19:20*1] <= sum[19] ? 0 : sum;
                4'd2: r_neuron[20*2+19:20*2] <= sum[19] ? 0 : sum;
                4'd3: r_neuron[20*3+19:20*3] <= sum[19] ? 0 : sum;
                4'd4: r_neuron[20*4+19:20*4] <= sum[19] ? 0 : sum;
                4'd5: r_neuron[20*5+19:20*5] <= sum[19] ? 0 : sum;
                4'd6: r_neuron[20*6+19:20*6] <= sum[19] ? 0 : sum;
                4'd7: r_neuron[20*7+19:20*7] <= sum[19] ? 0 : sum;
                4'd8: r_neuron[20*8+19:20*8] <= sum[19] ? 0 : sum;
                4'd9: r_neuron[20*9+19:20*9] <= sum[19] ? 0 : sum;
            endcase
        end
    end

    always @(posedge clk) begin
        if (!reset_n) begin
            mux_cnt <= 0;
        end else if (mux_cnt==4'd9) begin
            mux_cnt <= 0;
        end else if (w_finish && enable) begin
            mux_cnt <= mux_cnt+1;                                                            
        end
    end

    assign o_neuron = r_neuron;
    assign o_finish = (mux_cnt==4'd9 && w_finish);

endmodule