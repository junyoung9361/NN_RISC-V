module ALU (
    input  [31:0] A, B,
    input  [4:0]  ALUcont,  // 연산 종류 선택 (5비트)
    output reg [31:0] result,
    output reg Z,
    output reg N,
    output reg C,
    output reg V
);

    wire [31:0] sum;          // 32-bit adder 결과
    wire [31:0] b2;           // SUB 시 B를 반전한 값
    wire C_adder, V_adder;    // Carry, Overflow adder output
    wire Z_adder, N_adder;    // Zero, Negative adder output
    wire slt, sltu;           // 비교 연산 결과

    assign b2 = ALUcont[4] ? ~B : B;  // ALUcont[4]가 1이면 SUB -> B 반전

    assign slt  = N_adder ^ V_adder;  // signed 비교 (SLT)
    assign sltu = ~C_adder;           // unsigned 비교 (SLTU)

    // 32-bit adder 인스턴스
    adder_32bit adder_inst (
        .A(A),
        .B(b2),
        .cin(ALUcont[4]),     // SUB일 때 cin = 1
        .sum(sum),
        .N(N_adder),
        .Z(Z_adder),
        .C(C_adder),
        .V(V_adder)
    );

    // ALU 동작
    always @(*) begin
        case (ALUcont[3:0])
            4'b0000: begin // ADD, SUB
                result = sum;
                Z = (sum == 32'b0);
                N = sum[31];
                C = C_adder;
                V = V_adder;
            end
            4'b0001: begin // AND
                result = A & B;
                Z = (result == 32'b0);
                N = result[31];
                C = 0;
                V = 0;
            end
            4'b0010: begin // OR
                result = A | B;
                Z = (result == 32'b0);
                N = result[31];
                C = 0;
                V = 0;
            end
            4'b0011: begin // XOR
                result = A ^ B;
                Z = (result == 32'b0);
                N = result[31];
                C = 0;
                V = 0;
            end
            4'b0100: begin // SLL (Shift Left Logical)
                result = A << B[4:0];
                Z = (result == 32'b0);
                N = result[31];
                C = 0;
                V = 0;
            end
            4'b0101: begin // SRL (Shift Right Logical)
                result = A >> B[4:0];
                Z = (result == 32'b0);
                N = result[31];
                C = 0;
                V = 0;
            end
            4'b0111: begin // SLTU
                result = {31'b0, sltu};
                Z = (result == 32'b0);
                N = result[31];
                C = 0;
                V = 0;
            end
            4'b1000: begin // SLT
                result = {31'b0, slt};
                Z = (result == 32'b0);
                N = result[31];
                C = 0;
                V = 0;
            end
            default: begin // 기본값
                result = 32'h0000_0000;
                Z = 1;
                N = 0;
                C = 0;
                V = 0;
            end
        endcase
    end

endmodule