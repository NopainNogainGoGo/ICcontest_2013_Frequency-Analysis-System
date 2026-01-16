# --- 變數定義 ---
VCS = vcs
TOP_TB = testfixture1.v
FILELIST = file.f
SIMV = simv

# 編譯參數 
VCS_FLAGS = -full64 \
            -R \
            -debug_access+all \
            +v2k \
            -f $(FILELIST)

# --- 目錄/動作規則 ---

# 預設動作：編譯並執行
all: clean compile

# 執行 VCS
compile:
	$(VCS) $(TOP_TB) $(VCS_FLAGS) -l comp.log

# 開啟圖形介面 (例如 DVE)
dve:
	./$(SIMV) -gui &

# 清除暫存檔 (VCS 產生的中間檔非常多，建議養成清除習慣)
clean:
	rm -rf csrc $(SIMV) $(SIMV).daidir ucli.key
	rm -rf *.log inter.vpd DVEfiles
	rm -rf stack.info.* .vdb
