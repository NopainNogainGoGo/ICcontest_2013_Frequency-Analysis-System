module FFT(
    input CLK, RST, in_valid,
    // 輸入資料 (16筆, 32-bit: 高16實部, 低16虛部)
    input [31:0] in_d0, in_d1, in_d2, in_d3, in_d4, in_d5, in_d6, in_d7,
    input [31:0] in_d8, in_d9, in_d10, in_d11, in_d12, in_d13, in_d14, in_d15,

    output reg fft_valid,
    output reg [31:0] fft_d0, fft_d1, fft_d2, fft_d3, fft_d4, fft_d5, fft_d6, fft_d7,
    output reg [31:0] fft_d8, fft_d9, fft_d10, fft_d11, fft_d12, fft_d13, fft_d14, fft_d15
);
    // 32-bit
    `include "./Real_Value_Ref.dat"
    `include "./Imag_Value_Ref.dat"

    // stage
    reg signed [31:0] s1 [0:15]; 
    reg signed [31:0] s2 [0:15]; 
    reg signed [31:0] s3 [0:15]; 
    reg signed [31:0] s4 [0:15]; 
    
    reg [4:0] val_del; 
    integer i;

    // =========================================================
    //  Stage 1 (16-point, Stride=8)
    // =========================================================
    //  FFT data 前面實部，後面虛部: fft_d0[31:16] is real number, fft_d0[15:0] is image number
    always @(posedge CLK) begin
        if (in_valid) begin
            // --- 上半部: A + B ---
            // {(實部 + 實部), (虛部 + 虛部)}
            s1[0] <= { ($signed(in_d0[31:16]) + $signed(in_d8[31:16])), ($signed(in_d0[15:0]) + $signed(in_d8[15:0])) };
            s1[1] <= { ($signed(in_d1[31:16]) + $signed(in_d9[31:16])), ($signed(in_d1[15:0]) + $signed(in_d9[15:0])) };
            s1[2] <= { ($signed(in_d2[31:16]) + $signed(in_d10[31:16])), ($signed(in_d2[15:0]) + $signed(in_d10[15:0])) };
            s1[3] <= { ($signed(in_d3[31:16]) + $signed(in_d11[31:16])), ($signed(in_d3[15:0]) + $signed(in_d11[15:0])) };
            s1[4] <= { ($signed(in_d4[31:16]) + $signed(in_d12[31:16])), ($signed(in_d4[15:0]) + $signed(in_d12[15:0])) };
            s1[5] <= { ($signed(in_d5[31:16]) + $signed(in_d13[31:16])), ($signed(in_d5[15:0]) + $signed(in_d13[15:0])) };
            s1[6] <= { ($signed(in_d6[31:16]) + $signed(in_d14[31:16])), ($signed(in_d6[15:0]) + $signed(in_d14[15:0])) };
            s1[7] <= { ($signed(in_d7[31:16]) + $signed(in_d15[31:16])), ($signed(in_d7[15:0]) + $signed(in_d15[15:0])) };

            // --- 下半部 ---
            // W0 = 1+0j: 直接減，無需乘
            s1[8] <= { ($signed(in_d0[31:16]) - $signed(in_d8[31:16])), ($signed(in_d0[15:0]) - $signed(in_d8[15:0])) };

            // FFT 小數點位於 第 16 位 (Q16.16 格式)
            // 當執行 Diff * Wr 時，硬體做的是整數乘法：
            // 運算出來的結果被放大了 2^16 倍。如果不處理，這個數值會變大，且小數點的位置會跑掉
            // W1 ~ W7: 複數乘法與移位 (>>> 16)
            // Real = (Diff_R * Wr - Diff_I * Wi) >>> 16
            // Imag = (Diff_R * Wi + Diff_I * Wr) >>> 16
            
            // s1[9] (W1)
            s1[9][31:16] <= ( ($signed(in_d1[31:16]) - $signed(in_d9[31:16])) * Wr1 - ($signed(in_d1[15:0]) - $signed(in_d9[15:0])) * Wi1 ) >>> 16;
            s1[9][15:0]  <= ( ($signed(in_d1[31:16]) - $signed(in_d9[31:16])) * Wi1 + ($signed(in_d1[15:0]) - $signed(in_d9[15:0])) * Wr1 ) >>> 16;
            
            // s1[10] (W2)
            s1[10][31:16]<= ( ($signed(in_d2[31:16]) - $signed(in_d10[31:16])) * Wr2 - ($signed(in_d2[15:0]) - $signed(in_d10[15:0])) * Wi2 ) >>> 16;
            s1[10][15:0] <= ( ($signed(in_d2[31:16]) - $signed(in_d10[31:16])) * Wi2 + ($signed(in_d2[15:0]) - $signed(in_d10[15:0])) * Wr2 ) >>> 16;

            // s1[11] (W3)
            s1[11][31:16]<= ( ($signed(in_d3[31:16]) - $signed(in_d11[31:16])) * Wr3 - ($signed(in_d3[15:0]) - $signed(in_d11[15:0])) * Wi3 ) >>> 16;
            s1[11][15:0] <= ( ($signed(in_d3[31:16]) - $signed(in_d11[31:16])) * Wi3 + ($signed(in_d3[15:0]) - $signed(in_d11[15:0])) * Wr3 ) >>> 16;

            // s1[12] (W4 = -j): 優化 -> (R + jI) * -j = I - jR (交換實虛部並變號)
            s1[12][31:16]<= ($signed(in_d4[15:0]) - $signed(in_d12[15:0]));              // New Real = Old Imag
            s1[12][15:0] <= -($signed(in_d4[31:16]) - $signed(in_d12[31:16]));           // New Imag = -Old Real

            // s1[13] (W5)
            s1[13][31:16]<= ( ($signed(in_d5[31:16]) - $signed(in_d13[31:16])) * Wr5 - ($signed(in_d5[15:0]) - $signed(in_d13[15:0])) * Wi5 ) >>> 16;
            s1[13][15:0] <= ( ($signed(in_d5[31:16]) - $signed(in_d13[31:16])) * Wi5 + ($signed(in_d5[15:0]) - $signed(in_d13[15:0])) * Wr5 ) >>> 16;

            // s1[14] (W6)
            s1[14][31:16]<= ( ($signed(in_d6[31:16]) - $signed(in_d14[31:16])) * Wr6 - ($signed(in_d6[15:0]) - $signed(in_d14[15:0])) * Wi6 ) >>> 16;
            s1[14][15:0] <= ( ($signed(in_d6[31:16]) - $signed(in_d14[31:16])) * Wi6 + ($signed(in_d6[15:0]) - $signed(in_d14[15:0])) * Wr6 ) >>> 16;

            // s1[15] (W7)
            s1[15][31:16]<= ( ($signed(in_d7[31:16]) - $signed(in_d15[31:16])) * Wr7 - ($signed(in_d7[15:0]) - $signed(in_d15[15:0])) * Wi7 ) >>> 16;
            s1[15][15:0] <= ( ($signed(in_d7[31:16]) - $signed(in_d15[31:16])) * Wi7 + ($signed(in_d7[15:0]) - $signed(in_d15[15:0])) * Wr7 ) >>> 16;
        end
    end

    // =========================================================
    //  Stage 2 (Stride=4, Groups=2)
    // W sequence: W0, W2, W4, W6
    // =========================================================
    always @(posedge CLK) begin
        // Group 1 (0~7)
        s2[0] <= { ($signed(s1[0][31:16]) + $signed(s1[4][31:16])), ($signed(s1[0][15:0]) + $signed(s1[4][15:0])) };
        s2[1] <= { ($signed(s1[1][31:16]) + $signed(s1[5][31:16])), ($signed(s1[1][15:0]) + $signed(s1[5][15:0])) };
        s2[2] <= { ($signed(s1[2][31:16]) + $signed(s1[6][31:16])), ($signed(s1[2][15:0]) + $signed(s1[6][15:0])) };
        s2[3] <= { ($signed(s1[3][31:16]) + $signed(s1[7][31:16])), ($signed(s1[3][15:0]) + $signed(s1[7][15:0])) };

        // W0 (1)
        s2[4] <= { ($signed(s1[0][31:16]) - $signed(s1[4][31:16])), ($signed(s1[0][15:0]) - $signed(s1[4][15:0])) };
        // W2
        s2[5][31:16] <= ( ($signed(s1[1][31:16]) - $signed(s1[5][31:16])) * Wr2 - ($signed(s1[1][15:0]) - $signed(s1[5][15:0])) * Wi2 ) >>> 16;
        s2[5][15:0]  <= ( ($signed(s1[1][31:16]) - $signed(s1[5][31:16])) * Wi2 + ($signed(s1[1][15:0]) - $signed(s1[5][15:0])) * Wr2 ) >>> 16;
        // W4 (-j)
        s2[6][31:16] <= ($signed(s1[2][15:0]) - $signed(s1[6][15:0]));
        s2[6][15:0]  <= -($signed(s1[2][31:16]) - $signed(s1[6][31:16]));
        // W6
        s2[7][31:16] <= ( ($signed(s1[3][31:16]) - $signed(s1[7][31:16])) * Wr6 - ($signed(s1[3][15:0]) - $signed(s1[7][15:0])) * Wi6 ) >>> 16;
        s2[7][15:0]  <= ( ($signed(s1[3][31:16]) - $signed(s1[7][31:16])) * Wi6 + ($signed(s1[3][15:0]) - $signed(s1[7][15:0])) * Wr6 ) >>> 16;

        // Group 2 (8~15)
        s2[8] <= { ($signed(s1[8][31:16]) + $signed(s1[12][31:16])), ($signed(s1[8][15:0]) + $signed(s1[12][15:0])) };
        s2[9] <= { ($signed(s1[9][31:16]) + $signed(s1[13][31:16])), ($signed(s1[9][15:0]) + $signed(s1[13][15:0])) };
        s2[10]<= { ($signed(s1[10][31:16])+ $signed(s1[14][31:16])), ($signed(s1[10][15:0])+ $signed(s1[14][15:0])) };
        s2[11]<= { ($signed(s1[11][31:16])+ $signed(s1[15][31:16])), ($signed(s1[11][15:0])+ $signed(s1[15][15:0])) };

        // W0 (1)
        s2[12]<= { ($signed(s1[8][31:16]) - $signed(s1[12][31:16])), ($signed(s1[8][15:0]) - $signed(s1[12][15:0])) };
        // W2
        s2[13][31:16]<= ( ($signed(s1[9][31:16]) - $signed(s1[13][31:16])) * Wr2 - ($signed(s1[9][15:0]) - $signed(s1[13][15:0])) * Wi2 ) >>> 16;
        s2[13][15:0] <= ( ($signed(s1[9][31:16]) - $signed(s1[13][31:16])) * Wi2 + ($signed(s1[9][15:0]) - $signed(s1[13][15:0])) * Wr2 ) >>> 16;
        // W4 (-j)
        s2[14][31:16]<= ($signed(s1[10][15:0]) - $signed(s1[14][15:0]));
        s2[14][15:0] <= -($signed(s1[10][31:16]) - $signed(s1[14][31:16]));
        // W6
        s2[15][31:16]<= ( ($signed(s1[11][31:16]) - $signed(s1[15][31:16])) * Wr6 - ($signed(s1[11][15:0]) - $signed(s1[15][15:0])) * Wi6 ) >>> 16;
        s2[15][15:0] <= ( ($signed(s1[11][31:16]) - $signed(s1[15][31:16])) * Wi6 + ($signed(s1[11][15:0]) - $signed(s1[15][15:0])) * Wr6 ) >>> 16;
    end

    // =========================================================
    //  Stage 3 (Stride=2, Groups=4)
    // W sequence: W0, W4
    // =========================================================
    always @(posedge CLK) begin
        // Loop over 4 groups (base: 0, 4, 8, 12)
        // Group 1 (0,1,2,3)
        s3[0] <= { ($signed(s2[0][31:16]) + $signed(s2[2][31:16])), ($signed(s2[0][15:0]) + $signed(s2[2][15:0])) };
        s3[1] <= { ($signed(s2[1][31:16]) + $signed(s2[3][31:16])), ($signed(s2[1][15:0]) + $signed(s2[3][15:0])) };
        // W0
        s3[2] <= { ($signed(s2[0][31:16]) - $signed(s2[2][31:16])), ($signed(s2[0][15:0]) - $signed(s2[2][15:0])) };
        // W4 (-j)
        s3[3][31:16] <= ($signed(s2[1][15:0]) - $signed(s2[3][15:0]));
        s3[3][15:0]  <= -($signed(s2[1][31:16]) - $signed(s2[3][31:16]));

        // Group 2 (4,5,6,7)
        s3[4] <= { ($signed(s2[4][31:16]) + $signed(s2[6][31:16])), ($signed(s2[4][15:0]) + $signed(s2[6][15:0])) };
        s3[5] <= { ($signed(s2[5][31:16]) + $signed(s2[7][31:16])), ($signed(s2[5][15:0]) + $signed(s2[7][15:0])) };
        s3[6] <= { ($signed(s2[4][31:16]) - $signed(s2[6][31:16])), ($signed(s2[4][15:0]) - $signed(s2[6][15:0])) };
        s3[7][31:16] <= ($signed(s2[5][15:0]) - $signed(s2[7][15:0]));
        s3[7][15:0]  <= -($signed(s2[5][31:16]) - $signed(s2[7][31:16]));

        // Group 3 (8,9,10,11)
        s3[8] <= { ($signed(s2[8][31:16]) + $signed(s2[10][31:16])), ($signed(s2[8][15:0]) + $signed(s2[10][15:0])) };
        s3[9] <= { ($signed(s2[9][31:16]) + $signed(s2[11][31:16])), ($signed(s2[9][15:0]) + $signed(s2[11][15:0])) };
        s3[10]<= { ($signed(s2[8][31:16]) - $signed(s2[10][31:16])), ($signed(s2[8][15:0]) - $signed(s2[10][15:0])) };
        s3[11][31:16]<= ($signed(s2[9][15:0]) - $signed(s2[11][15:0]));
        s3[11][15:0] <= -($signed(s2[9][31:16]) - $signed(s2[11][31:16]));

        // Group 4 (12,13,14,15)
        s3[12]<= { ($signed(s2[12][31:16])+ $signed(s2[14][31:16])), ($signed(s2[12][15:0])+ $signed(s2[14][15:0])) };
        s3[13]<= { ($signed(s2[13][31:16])+ $signed(s2[15][31:16])), ($signed(s2[13][15:0])+ $signed(s2[15][15:0])) };
        s3[14]<= { ($signed(s2[12][31:16])- $signed(s2[14][31:16])), ($signed(s2[12][15:0])- $signed(s2[14][15:0])) };
        s3[15][31:16]<= ($signed(s2[13][15:0]) - $signed(s2[15][15:0]));
        s3[15][15:0] <= -($signed(s2[13][31:16]) - $signed(s2[15][31:16]));
    end

    // =========================================================
    //  Stage 4 (Stride=1, Groups=8)
    // W sequence: W0 only
    // =========================================================
    always @(posedge CLK) begin
        // Only Add and Sub (W0 = 1)
        // Group 1
        s4[0] <= { ($signed(s3[0][31:16]) + $signed(s3[1][31:16])), ($signed(s3[0][15:0]) + $signed(s3[1][15:0])) };
        s4[1] <= { ($signed(s3[0][31:16]) - $signed(s3[1][31:16])), ($signed(s3[0][15:0]) - $signed(s3[1][15:0])) };
        // Group 2
        s4[2] <= { ($signed(s3[2][31:16]) + $signed(s3[3][31:16])), ($signed(s3[2][15:0]) + $signed(s3[3][15:0])) };
        s4[3] <= { ($signed(s3[2][31:16]) - $signed(s3[3][31:16])), ($signed(s3[2][15:0]) - $signed(s3[3][15:0])) };
        // Group 3
        s4[4] <= { ($signed(s3[4][31:16]) + $signed(s3[5][31:16])), ($signed(s3[4][15:0]) + $signed(s3[5][15:0])) };
        s4[5] <= { ($signed(s3[4][31:16]) - $signed(s3[5][31:16])), ($signed(s3[4][15:0]) - $signed(s3[5][15:0])) };
        // Group 4
        s4[6] <= { ($signed(s3[6][31:16]) + $signed(s3[7][31:16])), ($signed(s3[6][15:0]) + $signed(s3[7][15:0])) };
        s4[7] <= { ($signed(s3[6][31:16]) - $signed(s3[7][31:16])), ($signed(s3[6][15:0]) - $signed(s3[7][15:0])) };
        // Group 5
        s4[8] <= { ($signed(s3[8][31:16]) + $signed(s3[9][31:16])), ($signed(s3[8][15:0]) + $signed(s3[9][15:0])) };
        s4[9] <= { ($signed(s3[8][31:16]) - $signed(s3[9][31:16])), ($signed(s3[8][15:0]) - $signed(s3[9][15:0])) };
        // Group 6
        s4[10]<= { ($signed(s3[10][31:16])+ $signed(s3[11][31:16])), ($signed(s3[10][15:0])+ $signed(s3[11][15:0])) };
        s4[11]<= { ($signed(s3[10][31:16])- $signed(s3[11][31:16])), ($signed(s3[10][15:0])- $signed(s3[11][15:0])) };
        // Group 7
        s4[12]<= { ($signed(s3[12][31:16])+ $signed(s3[13][31:16])), ($signed(s3[12][15:0])+ $signed(s3[13][15:0])) };
        s4[13]<= { ($signed(s3[12][31:16])- $signed(s3[13][31:16])), ($signed(s3[12][15:0])- $signed(s3[13][15:0])) };
        // Group 8
        s4[14]<= { ($signed(s3[14][31:16])+ $signed(s3[15][31:16])), ($signed(s3[14][15:0])+ $signed(s3[15][15:0])) };
        s4[15]<= { ($signed(s3[14][31:16])- $signed(s3[15][31:16])), ($signed(s3[14][15:0])- $signed(s3[15][15:0])) };
    end

    // =========================================================
    //  Output Mapping
    // =========================================================
    always @(posedge CLK or posedge RST) begin
        if (RST) begin
            fft_d0 <= 0; fft_d1 <= 0; fft_d2 <= 0; fft_d3 <= 0;
            fft_d4 <= 0; fft_d5 <= 0; fft_d6 <= 0; fft_d7 <= 0;
            fft_d8 <= 0; fft_d9 <= 0; fft_d10<= 0; fft_d11<= 0;
            fft_d12<= 0; fft_d13<= 0; fft_d14<= 0; fft_d15<= 0;
        end else begin
            //  Bit Reversal
            if (val_del[3]) begin
                fft_d0  <= s4[0];  // 0000 -> 0000 (0)
                fft_d1  <= s4[8];  // 0001 -> 1000 (8)
                fft_d2  <= s4[4];  // 0010 -> 0100 (4)
                fft_d3  <= s4[12]; // 0011 -> 1100 (12)
                fft_d4  <= s4[2];  // 0100 -> 0010 (2)
                fft_d5  <= s4[10]; // 0101 -> 1010 (10)
                fft_d6  <= s4[6];  // 0110 -> 0110 (6)
                fft_d7  <= s4[14]; // 0111 -> 1110 (14)
                fft_d8  <= s4[1];  // 1000 -> 0001 (1)
                fft_d9  <= s4[9];  // 1001 -> 1001 (9)
                fft_d10 <= s4[5];  // 1010 -> 0101 (5)
                fft_d11 <= s4[13]; // 1011 -> 1101 (13)
                fft_d12 <= s4[3];  // 1100 -> 0011 (3)
                fft_d13 <= s4[11]; // 1101 -> 1011 (11)
                fft_d14 <= s4[7];  // 1110 -> 0111 (7)
                fft_d15 <= s4[15]; // 1111 -> 1111 (15)
            end
        end
    end


    // fft_vaild
    always @(posedge CLK or posedge RST) begin
        if (RST) fft_valid <= 0;
        else  fft_valid <= val_del[3];  // 取 val_del[3]，延遲 4 個 cycle
    end


    //FFT 運算是 Pipeline 架構，資料從輸入 (in_d) 到算出結果 (s4)，
    //經過了 Stage 1 ~ Stage 4，總共需要 4 個 cycle 的時間 
    // Valid Signal Delay
    always @(posedge CLK or posedge RST) begin
        if (RST) val_del <= 0;
        else val_del <= {val_del[3:0], in_valid}; 
    end

endmodule