module STP(
    input CLK, RST, fir_valid,
    input signed [15:0] fir_d,
    output reg fft_valid,
    input [31:0] in_d0, in_d1, in_d2, in_d3, in_d4, in_d5, in_d6, in_d7,
    input [31:0] in_d8, in_d9, in_d10, in_d11, in_d12, in_d13, in_d14, in_d15,
);

    reg [3:0] cnt;
    reg [31:0] buf_data [0:15]; // 內部 Buffer

    always @(posedge CLK or posedge RST) begin
        if (RST) begin
            cnt <= 0;
            fft_valid <= 0;
        end else if (fir_valid) begin
            if (cnt == 15) begin
                fft_valid <= 1;
                cnt <= 0;
            end else begin
                fft_valid <= 0;
                cnt <= cnt + 1;
            end
        end else begin
            fft_valid <= 0;
        end
    end

    // 資料存入 Buffer (補上虛部 0)
    always @(posedge CLK) begin
        if (fir_valid)
            buf_data[cnt] <= {fir_d, 16'd0}; 
    end

    // 並列輸出
    always @(posedge CLK or posedge RST) begin
        if (RST) begin
            in_d0 <= 0; in_d1 <= 0; /* ...其他歸0 */ fft_d15 <= 0;
        end else if (fir_valid && cnt == 15) begin
            in_d0 <= buf_data[0];  in_d1 <= buf_data[1];
            in_d2 <= buf_data[2];  in_d3 <= buf_data[3];
            in_d4 <= buf_data[4];  in_d5 <= buf_data[5];
            in_d6 <= buf_data[6];  in_d7 <= buf_data[7];
            in_d8 <= buf_data[8];  in_d9 <= buf_data[9];
            in_d10<= buf_data[10]; in_d11<= buf_data[11];
            in_d12<= buf_data[12]; in_d13<= buf_data[13];
            in_d14<= buf_data[14]; in_d15<= {fir_d, 16'd0}; // 最後一筆直接 bypass
        end
    end
endmodule