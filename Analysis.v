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
    // Find Maximum
    // 比較 16 個 power 值，找出最大
    // =========================================================
    wire [31:0] max_val;
    wire [3:0]  max_idx;

    // =========================================================
    // Stage 1: 16 -> 8
    // =========================================================
    wire [31:0] v1_0, v1_1, v1_2, v1_3, v1_4, v1_5, v1_6, v1_7;
    wire [3:0]  i1_0, i1_1, i1_2, i1_3, i1_4, i1_5, i1_6, i1_7;

    assign {v1_0, i1_0} = (power[0]  >= power[1])  ? {power[0],  4'd0}  : {power[1],  4'd1};
    assign {v1_1, i1_1} = (power[2]  >= power[3])  ? {power[2],  4'd2}  : {power[3],  4'd3};
    assign {v1_2, i1_2} = (power[4]  >= power[5])  ? {power[4],  4'd4}  : {power[5],  4'd5};
    assign {v1_3, i1_3} = (power[6]  >= power[7])  ? {power[6],  4'd6}  : {power[7],  4'd7};
    assign {v1_4, i1_4} = (power[8]  >= power[9])  ? {power[8],  4'd8}  : {power[9],  4'd9};
    assign {v1_5, i1_5} = (power[10] >= power[11]) ? {power[10], 4'd10} : {power[11], 4'd11};
    assign {v1_6, i1_6} = (power[12] >= power[13]) ? {power[12], 4'd12} : {power[13], 4'd13};
    assign {v1_7, i1_7} = (power[14] >= power[15]) ? {power[14], 4'd14} : {power[15], 4'd15};

    // =========================================================
    // Stage 2: 8 -> 4
    // =========================================================
    wire [31:0] v2_0, v2_1, v2_2, v2_3;
    wire [3:0]  i2_0, i2_1, i2_2, i2_3;

    assign {v2_0, i2_0} = (v1_0 >= v1_1) ? {v1_0, i1_0} : {v1_1, i1_1};
    assign {v2_1, i2_1} = (v1_2 >= v1_3) ? {v1_2, i1_2} : {v1_3, i1_3};
    assign {v2_2, i2_2} = (v1_4 >= v1_5) ? {v1_4, i1_4} : {v1_5, i1_5};
    assign {v2_3, i2_3} = (v1_6 >= v1_7) ? {v1_6, i1_6} : {v1_7, i1_7};

    // =========================================================
    // Stage 3: 4 -> 2
    // =========================================================
    wire [31:0] v3_0, v3_1;
    wire [3:0]  i3_0, i3_1;

    assign {v3_0, i3_0} = (v2_0 >= v2_1) ? {v2_0, i2_0} : {v2_1, i2_1};
    assign {v3_1, i3_1} = (v2_2 >= v2_3) ? {v2_2, i2_2} : {v2_3, i2_3};

    // =========================================================
    // Stage 4: 2 -> 1 (Final Result)
    // =========================================================
    assign {max_val, max_idx} = (v3_0 >= v3_1) ? {v3_0, i3_0} : {v3_1, i3_1};


    // =========================================================
    // Pipeline Control: 延遲 fft_valid 訊號
    // =========================================================
    reg valid_d1; // 代表 power 暫存器已更新
    reg valid_d2; // 代表 freq 暫存器可以抓取比較結果

    always @(posedge CLK or posedge RST) begin
        if (RST) begin
            valid_d1 <= 1'b0;
            valid_d2 <= 1'b0;
        end else begin
            valid_d1 <= fft_valid; // 延遲 1 拍，與 power[] 同步
            valid_d2 <= valid_d1;  // 延遲 2 拍，用於觸發最終結果
        end
    end

    // =========================================================
    // freq 輸出邏輯
    // =========================================================
    always @(posedge CLK or posedge RST) begin
        if (RST) 
            freq <= 4'd0;
        else if (valid_d2) // 當 power 資料準備好時，下一拍存入 freq
            freq <= max_idx;
    end

    // =========================================================
    // done 輸出邏輯 (產生一個週期的脈衝)
    // =========================================================
    always @(posedge CLK or posedge RST) begin
        if (RST) 
            done <= 1'b0;
        else if (valid_d2) // 與 freq 同時更新，或是根據需求延後一拍
            done <= 1'b1;
        else 
            done <= 1'b0;
    end

endmodule

