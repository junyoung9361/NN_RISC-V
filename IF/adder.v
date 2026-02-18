module adder (
    input [31:0] a,      // 입력 값 a
    input [31:0] b,      // 입력 값 b
    output [31:0] sum    // 출력 값 (a + b)
);
    assign sum = a + b;  // a와 b를 더한 값을 출력
endmodule

