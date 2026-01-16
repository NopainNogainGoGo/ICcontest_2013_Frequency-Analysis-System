module FFT(
    input CLK, RST, stp_valid,
    input [31:0] in_d0, in_d1, in_d2, in_d3, in_d4, in_d5, in_d6, in_d7,
    input [31:0] in_d8, in_d9, in_d10, in_d11, in_d12, in_d13, in_d14, in_d15,

    output reg fft_valid,
    output [31:0] fft_d0, fft_d1, fft_d2, fft_d3, fft_d4, fft_d5, fft_d6, fft_d7,
    output [31:0] fft_d8, fft_d9, fft_d10, fft_d11, fft_d12, fft_d13, fft_d14, fft_d15
);
    `include "Real_Value_Ref.dat"
    `include "Imag_Value_Ref.dat"
        
    // =========================================================
    //  Stage 1 - Combinational Logic (Stride=8)
    //  Directly use in_d0 ~ in_d15
    // =========================================================
    wire signed [32:0] stage1_real  [15:0];
    wire signed [32:0] stage1_image [15:0];
    
    // -------------------------
    // 上半部: A + B
    // real = (A + B), image = 0
    // Use <<< 8 instead of concatenation to preserve Sign Bit (Sign Extension)
    // -------------------------
    assign stage1_real[0] = ($signed(in_d0 [31:16]) + $signed(in_d8 [31:16])) <<< 8;
    assign stage1_real[1] = ($signed(in_d1 [31:16]) + $signed(in_d9 [31:16])) <<< 8;
    assign stage1_real[2] = ($signed(in_d2 [31:16]) + $signed(in_d10[31:16])) <<< 8;
    assign stage1_real[3] = ($signed(in_d3 [31:16]) + $signed(in_d11[31:16])) <<< 8;
    assign stage1_real[4] = ($signed(in_d4 [31:16]) + $signed(in_d12[31:16])) <<< 8;
    assign stage1_real[5] = ($signed(in_d5 [31:16]) + $signed(in_d13[31:16])) <<< 8;
    assign stage1_real[6] = ($signed(in_d6 [31:16]) + $signed(in_d14[31:16])) <<< 8;
    assign stage1_real[7] = ($signed(in_d7 [31:16]) + $signed(in_d15[31:16])) <<< 8;

    assign stage1_image[0] = 33'sd0;
    assign stage1_image[1] = 33'sd0;
    assign stage1_image[2] = 33'sd0;
    assign stage1_image[3] = 33'sd0;
    assign stage1_image[4] = 33'sd0;
    assign stage1_image[5] = 33'sd0;
    assign stage1_image[6] = 33'sd0;
    assign stage1_image[7] = 33'sd0;

    // -------------------------
    // 下半部: (A - B) * W
    // real = (A-B)*Wr , image = (A-B)*Wi
    // -------------------------
    assign stage1_real[8]  = (($signed(in_d0 [31:16]) - $signed(in_d8 [31:16]))  * Wr0) >>> 8;
    assign stage1_real[9]  = (($signed(in_d1 [31:16]) - $signed(in_d9 [31:16]))  * Wr1) >>> 8;
    assign stage1_real[10] = (($signed(in_d2 [31:16]) - $signed(in_d10[31:16])) * Wr2) >>> 8;
    assign stage1_real[11] = (($signed(in_d3 [31:16]) - $signed(in_d11[31:16])) * Wr3) >>> 8;
    assign stage1_real[12] = (($signed(in_d4 [31:16]) - $signed(in_d12[31:16])) * Wr4) >>> 8;
    assign stage1_real[13] = (($signed(in_d5 [31:16]) - $signed(in_d13[31:16])) * Wr5) >>> 8;
    assign stage1_real[14] = (($signed(in_d6 [31:16]) - $signed(in_d14[31:16])) * Wr6) >>> 8;
    assign stage1_real[15] = (($signed(in_d7 [31:16]) - $signed(in_d15[31:16])) * Wr7) >>> 8;

    assign stage1_image[8]  = (($signed(in_d0 [31:16]) - $signed(in_d8 [31:16]))  * Wi0) >>> 8;
    assign stage1_image[9]  = (($signed(in_d1 [31:16]) - $signed(in_d9 [31:16]))  * Wi1) >>> 8;
    assign stage1_image[10] = (($signed(in_d2 [31:16]) - $signed(in_d10[31:16])) * Wi2) >>> 8;
    assign stage1_image[11] = (($signed(in_d3 [31:16]) - $signed(in_d11[31:16])) * Wi3) >>> 8;
    assign stage1_image[12] = (($signed(in_d4 [31:16]) - $signed(in_d12[31:16])) * Wi4) >>> 8;
    assign stage1_image[13] = (($signed(in_d5 [31:16]) - $signed(in_d13[31:16])) * Wi5) >>> 8;
    assign stage1_image[14] = (($signed(in_d6 [31:16]) - $signed(in_d14[31:16])) * Wi6) >>> 8;
    assign stage1_image[15] = (($signed(in_d7 [31:16]) - $signed(in_d15[31:16])) * Wi7) >>> 8;





    // =========================================================
    //  Stage 2 - Combinational Logic (Stride=4)
    // =========================================================
    wire signed [34:0] stage2_real  [15:0];
    wire signed [34:0] stage2_image [15:0];

    // 上半部: 直接相加 (無虛部)
    assign stage2_real[0] = stage1_real[0] + stage1_real[4];
    assign stage2_real[1] = stage1_real[1] + stage1_real[5];
    assign stage2_real[2] = stage1_real[2] + stage1_real[6];
    assign stage2_real[3] = stage1_real[3] + stage1_real[7];

    assign stage2_image[0] = 35'd0; assign stage2_image[1] = 35'd0;
    assign stage2_image[2] = 35'd0; assign stage2_image[3] = 35'd0;

    // 下半部: 複數乘法
    assign stage2_real[4] = ((stage1_real[0] - stage1_real[4]) * Wr0) >>> 16;
    assign stage2_real[5] = ((stage1_real[1] - stage1_real[5]) * Wr2) >>> 16;
    assign stage2_real[6] = ((stage1_real[2] - stage1_real[6]) * Wr4) >>> 16;
    assign stage2_real[7] = ((stage1_real[3] - stage1_real[7]) * Wr6) >>> 16;

    assign stage2_image[4] = ((stage1_real[0] - stage1_real[4]) * Wi0) >>> 16;
    assign stage2_image[5] = ((stage1_real[1] - stage1_real[5]) * Wi2) >>> 16;
    assign stage2_image[6] = ((stage1_real[2] - stage1_real[6]) * Wi4) >>> 16;
    assign stage2_image[7] = ((stage1_real[3] - stage1_real[7]) * Wi6) >>> 16;

    // Group 2: 有實部和虛部
    assign stage2_real[8]  = stage1_real[8]  + stage1_real[12];
    assign stage2_real[9]  = stage1_real[9]  + stage1_real[13];
    assign stage2_real[10] = stage1_real[10] + stage1_real[14];
    assign stage2_real[11] = stage1_real[11] + stage1_real[15];

    assign stage2_real[12] = ((stage1_real[8]  - stage1_real[12]) * Wr0 + (stage1_image[12] - stage1_image[8])  * Wi0) >>> 16;
    assign stage2_real[13] = ((stage1_real[9]  - stage1_real[13]) * Wr2 + (stage1_image[13] - stage1_image[9])  * Wi2) >>> 16;
    assign stage2_real[14] = ((stage1_real[10] - stage1_real[14]) * Wr4 + (stage1_image[14] - stage1_image[10]) * Wi4) >>> 16;
    assign stage2_real[15] = ((stage1_real[11] - stage1_real[15]) * Wr6 + (stage1_image[15] - stage1_image[11]) * Wi6) >>> 16;

    assign stage2_image[8]  = stage1_image[8]  + stage1_image[12];
    assign stage2_image[9]  = stage1_image[9]  + stage1_image[13];
    assign stage2_image[10] = stage1_image[10] + stage1_image[14];
    assign stage2_image[11] = stage1_image[11] + stage1_image[15];

    assign stage2_image[12] = ((stage1_real[8]  - stage1_real[12]) * Wi0 + (stage1_image[8]  - stage1_image[12]) * Wr0) >>> 16;
    assign stage2_image[13] = ((stage1_real[9]  - stage1_real[13]) * Wi2 + (stage1_image[9]  - stage1_image[13]) * Wr2) >>> 16;
    assign stage2_image[14] = ((stage1_real[10] - stage1_real[14]) * Wi4 + (stage1_image[10] - stage1_image[14]) * Wr4) >>> 16;
    assign stage2_image[15] = ((stage1_real[11] - stage1_real[15]) * Wi6 + (stage1_image[11] - stage1_image[15]) * Wr6) >>> 16;

    // =========================================================
    //  Stage 3 - Combinational Logic (Stride=2)
    // =========================================================
    wire signed [36:0] stage3_real  [15:0];
    wire signed [36:0] stage3_image [15:0];

    // Group 1 (0~3)
    assign stage3_real[0] = stage2_real[0] + stage2_real[2];
    assign stage3_real[1] = stage2_real[1] + stage2_real[3];
    
    assign stage3_real[2] = ((stage2_real[0] - stage2_real[2]) * Wr0 + (stage2_image[2] - stage2_image[0]) * Wi0) >>> 16;
    assign stage3_real[3] = ((stage2_real[1] - stage2_real[3]) * Wr4 + (stage2_image[3] - stage2_image[1]) * Wi4) >>> 16;

    assign stage3_image[0] = stage2_image[0] + stage2_image[2];
    assign stage3_image[1] = stage2_image[1] + stage2_image[3];
    
    assign stage3_image[2] = ((stage2_real[0] - stage2_real[2]) * Wi0 + (stage2_image[0] - stage2_image[2]) * Wr0) >>> 16;
    assign stage3_image[3] = ((stage2_real[1] - stage2_real[3]) * Wi4 + (stage2_image[1] - stage2_image[3]) * Wr4) >>> 16;

    // Group 2 (4~7)
    assign stage3_real[4] = stage2_real[4] + stage2_real[6];
    assign stage3_real[5] = stage2_real[5] + stage2_real[7];
    
    assign stage3_real[6] = ((stage2_real[4] - stage2_real[6]) * Wr0 + (stage2_image[6] - stage2_image[4]) * Wi0) >>> 16;
    assign stage3_real[7] = ((stage2_real[5] - stage2_real[7]) * Wr4 + (stage2_image[7] - stage2_image[5]) * Wi4) >>> 16;

    assign stage3_image[4] = stage2_image[4] + stage2_image[6];
    assign stage3_image[5] = stage2_image[5] + stage2_image[7];
    
    assign stage3_image[6] = ((stage2_real[4] - stage2_real[6]) * Wi0 + (stage2_image[4] - stage2_image[6]) * Wr0) >>> 16;
    assign stage3_image[7] = ((stage2_real[5] - stage2_real[7]) * Wi4 + (stage2_image[5] - stage2_image[7]) * Wr4) >>> 16;

    // Group 3 (8~11)
    assign stage3_real[8]  = stage2_real[8]  + stage2_real[10];
    assign stage3_real[9]  = stage2_real[9]  + stage2_real[11];
    
    assign stage3_real[10] = ((stage2_real[8]  - stage2_real[10]) * Wr0 + (stage2_image[10] - stage2_image[8])  * Wi0) >>> 16;
    assign stage3_real[11] = ((stage2_real[9]  - stage2_real[11]) * Wr4 + (stage2_image[11] - stage2_image[9])  * Wi4) >>> 16;

    assign stage3_image[8] = stage2_image[8] + stage2_image[10];
    assign stage3_image[9] = stage2_image[9] + stage2_image[11];
    
    assign stage3_image[10] = ((stage2_real[8]  - stage2_real[10]) * Wi0 + (stage2_image[8]  - stage2_image[10]) * Wr0) >>> 16;
    assign stage3_image[11] = ((stage2_real[9]  - stage2_real[11]) * Wi4 + (stage2_image[9]  - stage2_image[11]) * Wr4) >>> 16;

    // Group 4 (12~15)
    assign stage3_real[12] = stage2_real[12] + stage2_real[14];
    assign stage3_real[13] = stage2_real[13] + stage2_real[15];
    
    assign stage3_real[14] = ((stage2_real[12] - stage2_real[14]) * Wr0 + (stage2_image[14] - stage2_image[12]) * Wi0) >>> 16;
    assign stage3_real[15] = ((stage2_real[13] - stage2_real[15]) * Wr4 + (stage2_image[15] - stage2_image[13]) * Wi4) >>> 16;

    assign stage3_image[12] = stage2_image[12] + stage2_image[14];
    assign stage3_image[13] = stage2_image[13] + stage2_image[15];
    
    assign stage3_image[14] = ((stage2_real[12] - stage2_real[14]) * Wi0 + (stage2_image[12] - stage2_image[14]) * Wr0) >>> 16;
    assign stage3_image[15] = ((stage2_real[13] - stage2_real[15]) * Wi4 + (stage2_image[13] - stage2_image[15]) * Wr4) >>> 16;

    // =========================================================
    //  Stage 4 - Combinational Logic (Stride=1)
    // =========================================================
    wire signed [39:0] stage4_real  [15:0];
    wire signed [39:0] stage4_image [15:0];

    // 只有 W0，所有組都是相同模式
    assign stage4_real[0] = stage3_real[0] + stage3_real[1];
    assign stage4_real[1] = ((stage3_real[0] - stage3_real[1]) * Wr0 + (stage3_image[1] - stage3_image[0]) * Wi0) >>> 16;
    
    assign stage4_image[0] = stage3_image[0] + stage3_image[1];
    assign stage4_image[1] = ((stage3_real[0] - stage3_real[1]) * Wi0 + (stage3_image[0] - stage3_image[1]) * Wr0) >>> 16;

    assign stage4_real[2] = stage3_real[2] + stage3_real[3];
    assign stage4_real[3] = ((stage3_real[2] - stage3_real[3]) * Wr0 + (stage3_image[3] - stage3_image[2]) * Wi0) >>> 16;
    
    assign stage4_image[2] = stage3_image[2] + stage3_image[3];
    assign stage4_image[3] = ((stage3_real[2] - stage3_real[3]) * Wi0 + (stage3_image[2] - stage3_image[3]) * Wr0) >>> 16;

    assign stage4_real[4] = stage3_real[4] + stage3_real[5];
    assign stage4_real[5] = ((stage3_real[4] - stage3_real[5]) * Wr0 + (stage3_image[5] - stage3_image[4]) * Wi0) >>> 16;
    
    assign stage4_image[4] = stage3_image[4] + stage3_image[5];
    assign stage4_image[5] = ((stage3_real[4] - stage3_real[5]) * Wi0 + (stage3_image[4] - stage3_image[5]) * Wr0) >>> 16;

    assign stage4_real[6] = stage3_real[6] + stage3_real[7];
    assign stage4_real[7] = ((stage3_real[6] - stage3_real[7]) * Wr0 + (stage3_image[7] - stage3_image[6]) * Wi0) >>> 16;
    
    assign stage4_image[6] = stage3_image[6] + stage3_image[7];
    assign stage4_image[7] = ((stage3_real[6] - stage3_real[7]) * Wi0 + (stage3_image[6] - stage3_image[7]) * Wr0) >>> 16;

    assign stage4_real[8] = stage3_real[8] + stage3_real[9];
    assign stage4_real[9] = ((stage3_real[8] - stage3_real[9]) * Wr0 + (stage3_image[9] - stage3_image[8]) * Wi0) >>> 16;
    
    assign stage4_image[8] = stage3_image[8] + stage3_image[9];
    assign stage4_image[9] = ((stage3_real[8] - stage3_real[9]) * Wi0 + (stage3_image[8] - stage3_image[9]) * Wr0) >>> 16;

    assign stage4_real[10] = stage3_real[10] + stage3_real[11];
    assign stage4_real[11] = ((stage3_real[10] - stage3_real[11]) * Wr0 + (stage3_image[11] - stage3_image[10]) * Wi0) >>> 16;
    
    assign stage4_image[10] = stage3_image[10] + stage3_image[11];
    assign stage4_image[11] = ((stage3_real[10] - stage3_real[11]) * Wi0 + (stage3_image[10] - stage3_image[11]) * Wr0) >>> 16;

    assign stage4_real[12] = stage3_real[12] + stage3_real[13];
    assign stage4_real[13] = ((stage3_real[12] - stage3_real[13]) * Wr0 + (stage3_image[13] - stage3_image[12]) * Wi0) >>> 16;
    
    assign stage4_image[12] = stage3_image[12] + stage3_image[13];
    assign stage4_image[13] = ((stage3_real[12] - stage3_real[13]) * Wi0 + (stage3_image[12] - stage3_image[13]) * Wr0) >>> 16;

    assign stage4_real[14] = stage3_real[14] + stage3_real[15];
    assign stage4_real[15] = ((stage3_real[14] - stage3_real[15]) * Wr0 + (stage3_image[15] - stage3_image[14]) * Wi0) >>> 16;
    
    assign stage4_image[14] = stage3_image[14] + stage3_image[15];
    assign stage4_image[15] = ((stage3_real[14] - stage3_real[15]) * Wi0 + (stage3_image[14] - stage3_image[15]) * Wr0) >>> 16;

    // =========================================================
    //  FFT Output with Bit Reversal
    // =========================================================
    assign fft_d0  = {stage4_real[0] [23:8], stage4_image[0] [23:8]};
    assign fft_d1  = {stage4_real[8] [23:8], stage4_image[8] [23:8]};
    assign fft_d2  = {stage4_real[4] [23:8], stage4_image[4] [23:8]};
    assign fft_d3  = {stage4_real[12][23:8], stage4_image[12][23:8]};
    assign fft_d4  = {stage4_real[2] [23:8], stage4_image[2] [23:8]};
    assign fft_d5  = {stage4_real[10][23:8], stage4_image[10][23:8]};
    assign fft_d6  = {stage4_real[6] [23:8], stage4_image[6] [23:8]};
    assign fft_d7  = {stage4_real[14][23:8], stage4_image[14][23:8]};
    assign fft_d8  = {stage4_real[1] [23:8], stage4_image[1] [23:8]};
    assign fft_d9  = {stage4_real[9] [23:8], stage4_image[9] [23:8]};
    assign fft_d10 = {stage4_real[5] [23:8], stage4_image[5] [23:8]};
    assign fft_d11 = {stage4_real[13][23:8], stage4_image[13][23:8]};
    assign fft_d12 = {stage4_real[3] [23:8], stage4_image[3] [23:8]};
    assign fft_d13 = {stage4_real[11][23:8], stage4_image[11][23:8]};
    assign fft_d14 = {stage4_real[7] [23:8], stage4_image[7] [23:8]};
    assign fft_d15 = {stage4_real[15][23:8], stage4_image[15][23:8]};

    // =========================================================
    //  Valid Signal
    // =========================================================
    always @(posedge CLK or posedge RST) begin
        if (RST) 
            fft_valid <= 0;
        else 
            fft_valid <= stp_valid;
    end

endmodule

