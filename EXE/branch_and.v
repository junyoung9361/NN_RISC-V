module branch_and (
    input  wire beq,      // Control Unit의 beq 신호
    input  wire zero,     // ALU의 zero 플래그
    output wire btaken    // 분기 실행 여부
);
    assign btaken = beq & zero;
endmodule
