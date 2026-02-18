module Extension_Unit (
  input  wire [11:0] imm,       // I-type 즉시값 비트[11:0]
  output wire [31:0] ext_imm    // Sign-Extension된 즉시값
);
  // 부호비트 imm[11]을 20번 복제
  assign ext_imm = {{20{imm[11]}}, imm};
endmodule