module FIR(
    input CLK,
    input RST,
    input data_valid,
    input signed [15:0] data,
    output reg fir_valid_d,
    output reg signed [15:0] fir_d
);


`include "FIR_coefficient.dat"
integer i;
reg signed[15:0] mem[0:31];

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

// =========================================================
//  Multiply and Accumulate (Tree Structure)
// =========================================================
// data: Q1.7.8 (16 bits: 1 sign, 7 int, 8 frac) 
// Coeff: Q1.3.16 (20 bits: 1 sign, 3 int, 16 frac) 
// Product: Q.10.24 (36 bits)

// Step 1: 乘法運算 (32 個乘積)
wire signed [35:0] fir_tmp [31:0];

assign fir_tmp[0]  = mem[0]  * FIR_C00;  assign fir_tmp[1]  = mem[1]  * FIR_C01;
assign fir_tmp[2]  = mem[2]  * FIR_C02;  assign fir_tmp[3]  = mem[3]  * FIR_C03;
assign fir_tmp[4]  = mem[4]  * FIR_C04;  assign fir_tmp[5]  = mem[5]  * FIR_C05;
assign fir_tmp[6]  = mem[6]  * FIR_C06;  assign fir_tmp[7]  = mem[7]  * FIR_C07;
assign fir_tmp[8]  = mem[8]  * FIR_C08;  assign fir_tmp[9]  = mem[9]  * FIR_C09;
assign fir_tmp[10] = mem[10] * FIR_C10;  assign fir_tmp[11] = mem[11] * FIR_C11;
assign fir_tmp[12] = mem[12] * FIR_C12;  assign fir_tmp[13] = mem[13] * FIR_C13;
assign fir_tmp[14] = mem[14] * FIR_C14;  assign fir_tmp[15] = mem[15] * FIR_C15;
assign fir_tmp[16] = mem[16] * FIR_C16;  assign fir_tmp[17] = mem[17] * FIR_C17;
assign fir_tmp[18] = mem[18] * FIR_C18;  assign fir_tmp[19] = mem[19] * FIR_C19;
assign fir_tmp[20] = mem[20] * FIR_C20;  assign fir_tmp[21] = mem[21] * FIR_C21;
assign fir_tmp[22] = mem[22] * FIR_C22;  assign fir_tmp[23] = mem[23] * FIR_C23;
assign fir_tmp[24] = mem[24] * FIR_C24;  assign fir_tmp[25] = mem[25] * FIR_C25;
assign fir_tmp[26] = mem[26] * FIR_C26;  assign fir_tmp[27] = mem[27] * FIR_C27;
assign fir_tmp[28] = mem[28] * FIR_C28;  assign fir_tmp[29] = mem[29] * FIR_C29;
assign fir_tmp[30] = mem[30] * FIR_C30;  assign fir_tmp[31] = mem[31] * FIR_C31;

// Step 2: Adder tree 第一層加法 - 32個數分成4組，每組8個相加 (max 39 bits)
wire signed [38:0] sum_1 [3:0];

assign sum_1[0] = fir_tmp[0]  + fir_tmp[1]  + fir_tmp[2]  + fir_tmp[3]  + 
                  fir_tmp[4]  + fir_tmp[5]  + fir_tmp[6]  + fir_tmp[7];
                  
assign sum_1[1] = fir_tmp[8]  + fir_tmp[9]  + fir_tmp[10] + fir_tmp[11] + 
                  fir_tmp[12] + fir_tmp[13] + fir_tmp[14] + fir_tmp[15];
                  
assign sum_1[2] = fir_tmp[16] + fir_tmp[17] + fir_tmp[18] + fir_tmp[19] + 
                  fir_tmp[20] + fir_tmp[21] + fir_tmp[22] + fir_tmp[23];
                  
assign sum_1[3] = fir_tmp[24] + fir_tmp[25] + fir_tmp[26] + fir_tmp[27] + 
                  fir_tmp[28] + fir_tmp[29] + fir_tmp[30] + fir_tmp[31];

// Step 3: 第二層加法 - 4個數分成2組，每組2個相加 (max 40 bits)
wire signed [39:0] sum_2 [1:0];

assign sum_2[0] = sum_1[0] + sum_1[1];
assign sum_2[1] = sum_1[2] + sum_1[3];

// Step 4: 第三層加法 - 最終結果 (max 41 bits)
wire signed [40:0] sum_3;

assign sum_3 = sum_2[0] + sum_2[1];  // FIR 最終總和

// =========================================================
//  Output Valid Control (第32筆後才輸出)
// =========================================================
// data_cnt
reg [5:0] data_cnt; // 數到 32(6-bit)
always @(posedge CLK or posedge RST) begin
    if (RST) begin
        data_cnt <= 0;
    end else if (data_valid && data_cnt<32) begin
        data_cnt <= data_cnt + 1;
    end
end

// fir_valid 
reg fir_valid;
always @(posedge CLK or posedge RST) begin
    if (RST) begin
        fir_valid <= 0;
    end else if (data_cnt == 32) 
        fir_valid <= 1;         
    else
        fir_valid <= 0;
end

// fir_valid_d 
always @(posedge CLK or posedge RST) begin
    if (RST) begin
        fir_valid_d <= 0;
    end else 
        fir_valid_d <= fir_valid;    
end

// =========================================================
//  Output Truncation 
// =========================================================
// fir_d: 16-bit (Q7.8) 
always @(posedge CLK or posedge RST) begin
    if (RST) begin
        fir_d <= 0;
    end else if (data_valid) begin 
        fir_d <= sum_3[31:16] + sum_3[40]; 
        //如果對所有的數都做 Floor 運算，整體數值的平均誤差會是負的。
        //正數的誤差是負的（3 - 3.9 = -0.9）
        //負數的誤差也是負的（-4 - (-3.9) = -0.1）
        //在 FFT 或濾波器運算中，如果一直累積這種負的誤差，訊號就會產生一個負的直流偏移（Negative DC Offset）
        //，導致訊號「往下降」，這會影響頻譜分析在 0Hz (DC) 附近的準確度。
    end else begin
        fir_d <= 0;
    end
end

endmodule
