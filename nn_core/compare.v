module compare
#(
)
(
    input clk,
    input reset_n,
    input enable,                     // 계산 시작 신호
    input [199:0] i_data,          
    output [3:0] max_index,                 // 계산 결과 출력, nn_core와 연동
    output o_finish                   // 계산 완료 신호, nn_core와 연동
);

    wire signed [19:0] data[9:0];
    
    genvar i;
    generate
    for (i = 0; i < 10; i = i + 1) begin
        assign data[i] = i_data[20*i+19 : 20*i];
    end
    endgenerate
    
    reg [3:0] r_index;
    reg signed [19:0] temp;
    reg [3:0] cnt;

    always @ (posedge clk) begin
        if(!reset_n)
            cnt <= 0;
        else if(enable && cnt==9)
            cnt <= 0;
        else if(enable)
            cnt <= cnt+1;
    end

    always @ (posedge clk) begin
        case(cnt)
            4'd0 : begin 
                temp <= data[cnt+1]>=data[cnt] ? data[cnt+1] : data[cnt];
                r_index <= data[cnt+1]>=data[cnt] ? cnt+1 : cnt;
            end
            4'd1 : begin 
                temp <= data[cnt+1]>=temp ? data[cnt+1] : temp;
                r_index <= data[cnt+1]>=temp ? cnt+1 : r_index;
            end
            4'd2 : begin 
                temp <= data[cnt+1]>=temp ? data[cnt+1] : temp;
                r_index <= data[cnt+1]>=temp ? cnt+1 : r_index;
            end
            4'd3 : begin 
                temp <= data[cnt+1]>=temp ? data[cnt+1] : temp;
                r_index <= data[cnt+1]>=temp ? cnt+1 : r_index;
            end
            4'd4 : begin 
                temp <= data[cnt+1]>=temp ? data[cnt+1] : temp;
                r_index <= data[cnt+1]>=temp ? cnt+1 : r_index;
            end
            4'd5 : begin 
                temp <= data[cnt+1]>=temp ? data[cnt+1] : temp;
                r_index <= data[cnt+1]>=temp ? cnt+1 : r_index;
            end
            4'd6 : begin 
                temp <= data[cnt+1]>=temp ? data[cnt+1] : temp;
                r_index <= data[cnt+1]>=temp ? cnt+1 : r_index;
            end
            4'd7 : begin 
                temp <= data[cnt+1]>=temp ? data[cnt+1] : temp;
                r_index <= data[cnt+1]>=temp ? cnt+1 : r_index;
            end
            4'd8 : begin 
                temp <= data[cnt+1]>=temp ? data[cnt+1] : temp;
                r_index <= data[cnt+1]>=temp ? cnt+1 : r_index;
            end
            default : begin 
                temp <= temp;
                r_index <= r_index;
            end
        endcase
    end

    assign max_index = r_index;
    assign o_finish = enable && cnt==8;

endmodule