module adder_32bit(
    input [31:0] A, B,
    input cin,
    output [31:0] sum,
    output N,
    output Z,
    output C,
    output V
);
    wire [32:0] ctmp; //
    assign ctmp = {1'b0, A} + {1'b0, B} + cin; 
    assign sum = ctmp[31:0];
    assign N = sum[31]; //msb
    assign Z = (sum == 32'b0) ? 1'b1 : 1'b0; //beq같은거 위해서 있는 flag.
    assign C = ctmp[32]; //carry check
    assign V = ctmp[32] ^ ctmp[31]; // overflow check
    
endmodule