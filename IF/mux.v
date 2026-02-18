module mux (
    input [31:0] a,       // 입력 1
    input [31:0] b,       // 입력 2
    input select,         // 선택 신호 (0이면 a, 1이면 b)
    output [31:0] out     // 출력
);
    assign out = (select) ? b : a;  // select에 따라 a 또는 b를 선택
endmodule
