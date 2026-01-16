module FAS (
    input data_valid, 
    input [15:0] data, 
    input clk, 
    input rst, 
    output fir_valid, 
    output [15:0] fir_d, 
    output fft_valid, 
    output done, 
    output [3:0] freq,
    output [31:0] fft_d0, fft_d1, fft_d2, fft_d3, fft_d4, fft_d5, fft_d6, fft_d7,
    output [31:0] fft_d8, fft_d9, fft_d10, fft_d11, fft_d12, fft_d13, fft_d14, fft_d15
);

    // STP 與 FFT 之間的連線 (16條 32-bit 線)
    wire sfft_valid;
    wire [31:0] stp_d0, stp_d1, stp_d2, stp_d3, stp_d4, stp_d5, stp_d6, stp_d7;
    wire [31:0] stp_d8, stp_d9, stp_d10, stp_d11, stp_d12, stp_d13, stp_d14, stp_d15;
    
    FIR u_FIR(
        .CLK(clk), .RST(rst),
        .data_valid(data_valid), .data(data),
        .fir_valid(fir_valid), .fir_d(fir_d)
    );

    STP u_STP(
        .CLK(clk), .RST(rst),
        .fir_valid(fir_valid), .fir_d(fir_d),
        .fft_valid(stp_fft_valid),
        .fft_d0(stp_d0), .fft_d1(stp_d1), .fft_d2(stp_d2), .fft_d3(stp_d3),
        .fft_d4(stp_d4), .fft_d5(stp_d5), .fft_d6(stp_d6), .fft_d7(stp_d7),
        .fft_d8(stp_d8), .fft_d9(stp_d9), .fft_d10(stp_d10), .fft_d11(stp_d11),
        .fft_d12(stp_d12), .fft_d13(stp_d13), .fft_d14(stp_d14), .fft_d15(stp_d15)
    );

    FFT u_FFT(
        .CLK(clk), .RST(rst),
        .in_valid(stp_fft_valid),
        .in_d0(stp_d0), .in_d1(stp_d1), .in_d2(stp_d2), .in_d3(stp_d3),
        .in_d4(stp_d4), .in_d5(stp_d5), .in_d6(stp_d6), .in_d7(stp_d7),
        .in_d8(stp_d8), .in_d9(stp_d9), .in_d10(stp_d10), .in_d11(stp_d11),
        .in_d12(stp_d12), .in_d13(stp_d13), .in_d14(stp_d14), .in_d15(stp_d15),
        
        .fft_valid(fft_valid),
        .fft_d0(fft_d0), .fft_d1(fft_d1), .fft_d2(fft_d2), .fft_d3(fft_d3),
        .fft_d4(fft_d4), .fft_d5(fft_d5), .fft_d6(fft_d6), .fft_d7(fft_d7),
        .fft_d8(fft_d8), .fft_d9(fft_d9), .fft_d10(fft_d10), .fft_d11(fft_d11),
        .fft_d12(fft_d12), .fft_d13(fft_d13), .fft_d14(fft_d14), .fft_d15(fft_d15)
    );

    Analysis u_Analysis(
        .CLK(clk), .RST(rst),
        .fft_valid(fft_valid),
        .fft_d0(fft_d0), .fft_d1(fft_d1), .fft_d2(fft_d2), .fft_d3(fft_d3),
        .fft_d4(fft_d4), .fft_d5(fft_d5), .fft_d6(fft_d6), .fft_d7(fft_d7),
        .fft_d8(fft_d8), .fft_d9(fft_d9), .fft_d10(fft_d10), .fft_d11(fft_d11),
        .fft_d12(fft_d12), .fft_d13(fft_d13), .fft_d14(fft_d14), .fft_d15(fft_d15),
        .done(done), .freq(freq)
    );
endmodule
