module Analysis(
    input CLK,
    input RST,
    input fft_valid,
    // 輸入 16 筆 32-bit 複數資料 (高16位:實部, 低16位:虛部)
    input [31:0] fft_d0, fft_d1, fft_d2, fft_d3, fft_d4, fft_d5, fft_d6, fft_d7,
    input [31:0] fft_d8, fft_d9, fft_d10, fft_d11, fft_d12, fft_d13, fft_d14, fft_d15,
    output reg done,
    output reg [3:0] freq
);
    reg [31:0] power [0:15];
    integer k;

    // =========================================================
    // Power Calculation
    // Power = Real^2 + Imag^2  只需要比較大小
    // =========================================================
    always @(posedge CLK) begin
        if (fft_valid) begin
            power[0]  <= ($signed(fft_d0[31:16])  * $signed(fft_d0[31:16]))  + ($signed(fft_d0[15:0])  * $signed(fft_d0[15:0]));
            power[1]  <= ($signed(fft_d1[31:16])  * $signed(fft_d1[31:16]))  + ($signed(fft_d1[15:0])  * $signed(fft_d1[15:0]));
            power[2]  <= ($signed(fft_d2[31:16])  * $signed(fft_d2[31:16]))  + ($signed(fft_d2[15:0])  * $signed(fft_d2[15:0]));
            power[3]  <= ($signed(fft_d3[31:16])  * $signed(fft_d3[31:16]))  + ($signed(fft_d3[15:0])  * $signed(fft_d3[15:0]));
            power[4]  <= ($signed(fft_d4[31:16])  * $signed(fft_d4[31:16]))  + ($signed(fft_d4[15:0])  * $signed(fft_d4[15:0]));
            power[5]  <= ($signed(fft_d5[31:16])  * $signed(fft_d5[31:16]))  + ($signed(fft_d5[15:0])  * $signed(fft_d5[15:0]));
            power[6]  <= ($signed(fft_d6[31:16])  * $signed(fft_d6[31:16]))  + ($signed(fft_d6[15:0])  * $signed(fft_d6[15:0]));
            power[7]  <= ($signed(fft_d7[31:16])  * $signed(fft_d7[31:16]))  + ($signed(fft_d7[15:0])  * $signed(fft_d7[15:0]));
            power[8]  <= ($signed(fft_d8[31:16])  * $signed(fft_d8[31:16]))  + ($signed(fft_d8[15:0])  * $signed(fft_d8[15:0]));
            power[9]  <= ($signed(fft_d9[31:16])  * $signed(fft_d9[31:16]))  + ($signed(fft_d9[15:0])  * $signed(fft_d9[15:0]));
            power[10] <= ($signed(fft_d10[31:16]) * $signed(fft_d10[31:16])) + ($signed(fft_d10[15:0]) * $signed(fft_d10[15:0]));
            power[11] <= ($signed(fft_d11[31:16]) * $signed(fft_d11[31:16])) + ($signed(fft_d11[15:0]) * $signed(fft_d11[15:0]));
            power[12] <= ($signed(fft_d12[31:16]) * $signed(fft_d12[31:16])) + ($signed(fft_d12[15:0]) * $signed(fft_d12[15:0]));
            power[13] <= ($signed(fft_d13[31:16]) * $signed(fft_d13[31:16])) + ($signed(fft_d13[15:0]) * $signed(fft_d13[15:0]));
            power[14] <= ($signed(fft_d14[31:16]) * $signed(fft_d14[31:16])) + ($signed(fft_d14[15:0]) * $signed(fft_d14[15:0]));
            power[15] <= ($signed(fft_d15[31:16]) * $signed(fft_d15[31:16])) + ($signed(fft_d15[15:0]) * $signed(fft_d15[15:0]));
        end
    end

    // =========================================================
    // Delay Logic
    // 因為 power 計算是 Sequential Logic，需要 1 個 cycle 的時間，
    // 所以把 valid 訊號也延遲 1 個 cycle，這樣才能拿到算好的 power
    // =========================================================
    reg valid_d1;

    always @(posedge CLK or posedge RST) begin
        if (RST) valid_d1 <= 0;
        else valid_d1 <= fft_valid;
    end

    // =========================================================
    // Find Maximum
    // 比較 16 個 power 值，找出最大
    // =========================================================
    reg [31:0] max_val;
    reg [3:0]  max_idx;
    reg [3:0]  cnt;

    // cnt
    always @(posedge CLK or posedge RST) begin
        if (RST) cnt <= 0;
        else if (valid_d1) cnt <= cnt + 1;
    end

    always @(posedge CLK or posedge RST) begin
        if (RST) begin
            max_val <= power[0];
            max_idx <= 0;
        end
        else if (power[cnt] > max_val) begin
            max_val <= power[cnt];
            max_idx <= cnt;
        end
    end

    // freq
    always @(posedge CLK or posedge RST) begin
        if (RST) freq <= 0;
        else if (cnt == 15) freq <= max_idx;
    end

    // done
    always @(posedge CLK or posedge RST) begin
        if (RST) done <= 0;
        else if (cnt ==15) done <= 1;
        else done <= 0;
    end

endmodule