
module FIR(
    input CLK,
    input RST,
    input data_valid,
    input signed [15:0] data,
    output reg fir_valid,
    output reg signed [15:0] fir_d
);
integer i;
reg signed [15:0] mem [0:31];

// =========================================================
//  Shift Register 
// =========================================================
always @(posedge CLK or posedge RST) begin
    if (RST) begin
        for (i=0; i<32; i=i+1) begin
            mem[i] <= 16'd0;     
        end
    end else if (data_valid) begin
        mem[0] <= data;           
        for (i=0; i<31; i=i+1) begin
            mem[i+1] <= mem[i];   
        end
    end
end

// 載入FIR係數 (裡面定義了 FIR_C00 到 FIR_C31，且為 signed)
`include "./dat/FIR_coefficient.dat"
// =========================================================
//  Multiply and Accumulate 
// =========================================================
// data: Q1.7.8 (16 bits: 1 sign, 7 int, 8 frac) 
// Coeff: Q1.3.16 (20 bits: 1 sign, 3 int, 16 frac) 
// Product: Q.10.24 (36 bits)
// Sum: 需要加上 log2(32) = 5 bits buffer， around 40 bits 
// if 20ns cycle time fail --> 將加法樹切 Pipeline (例如每 8 個 tap 加一級 register)
wire signed [39:0] product_sum; 
assign product_sum = (mem[0] * FIR_C00) +
                     (mem[1] * FIR_C01) +
                     (mem[2] * FIR_C02) +
                     (mem[3] * FIR_C03) +
                     (mem[4] * FIR_C04) +
                     (mem[5] * FIR_C05) +
                     (mem[6] * FIR_C06) +
                     (mem[7] * FIR_C07) +
                     (mem[8] * FIR_C08) +
                     (mem[9] * FIR_C09) +
                     (mem[10] * FIR_C10) +
                     (mem[11] * FIR_C11) +
                     (mem[12] * FIR_C12) +
                     (mem[13] * FIR_C13) +
                     (mem[14] * FIR_C14) +
                     (mem[15] * FIR_C15) +
                     (mem[16] * FIR_C16) +
                     (mem[17] * FIR_C17) +
                     (mem[18] * FIR_C18) +
                     (mem[19] * FIR_C19) +
                     (mem[20] * FIR_C20) +
                     (mem[21] * FIR_C21) +
                     (mem[22] * FIR_C22) +
                     (mem[23] * FIR_C23) +
                     (mem[24] * FIR_C24) +
                     (mem[25] * FIR_C25) +
                     (mem[26] * FIR_C26) +
                     (mem[27] * FIR_C27) +
                     (mem[28] * FIR_C28) +
                     (mem[29] * FIR_C29) +
                     (mem[30] * FIR_C30) +
                     (mem[31] * FIR_C31); 

// =========================================================
//  Output Valid Control (第32筆後才輸出)
// =========================================================
// data_cnt
reg [5:0] data_cnt; // 數到 32(6-bit)
always @(posedge CLK or posedge RST) begin
    if (RST) begin
        data_cnt <= 0;
    end else if (data_valid && data_cnt < 32) begin
            data_cnt <= data_cnt + 1;
    end
end

// fir_valid 
// 當 input data 停止，fir_valid 也應該拉低 
always @(posedge CLK or posedge RST) begin
    if (RST) begin
        fir_valid <= 0;
    end else if (data_cnt == 15 && data_valid) // 當計數器滿了，且 data_valid 為 high，則 fir_valid 為 high
        fir_valid <= 1;                         // 如果要加 pipeline register，fir_valid 也要跟著 delay
    else
        fir_valid <= 0;
end

// =========================================================
//  Output Truncation 
// =========================================================
// fir_d: 16-bit (Q7.8) 
// 運算結果小數點位置: 24 bits (8 from data + 16 from coeff)
// 我們需要保留小數點後 8 bits，所以捨棄最低的 16 bits
// 39...............24.23...........16.15............0
// |   Integer    |  Target Frac     |  Dropped Frac |
// 
// 截取範圍： product_sum[31:16] 
always @(posedge CLK or posedge RST) begin
    if (RST) begin
        fir_d <= 0;
    end else if (data_valid && (data_cnt == 31)) begin 
         // 這裡做截斷
         fir_d <= product_sum[31:16];
         // 若要四捨五入 (Rounding)：
         // fir_d <= product_sum[31:16] + product_sum[15];
    end else begin
        fir_d <= 0;
    end
end
endmodule