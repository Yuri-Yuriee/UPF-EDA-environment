# 從這裡開始

本目錄由 baseline_golden_design_environment_20261021_143114.tar.gz 全新建立，未沿用舊版來源檔或遮蔽內容。保留原始 config 檔位（包含 private config），實際值改成 FILL_IN 填空。

1. 先用 `sha256sum -c SHA256SUMS` 驗證未修改的範本。
2. 準備本地 EDA、PDK、library、cell 模型與驗證 deck。
3. 使用者日常設定直接填 `script/PR/TECH_MV/setup/config/` 各 stage 檔案。保持 `set 變數 {填入值}` 或 array 的直接資料格式，不使用 setup_command、PUBLIC_CFG 或跨 Tcl 取值。verify/config 仍依檔案格式填寫。private 範本保留供舊工具使用，不是 stage config 的取值入口。本包不含 build_PR；依 Makefile 建立執行目錄後，檢查執行副本是否一致。
4. 填合成、模擬、UPF、RTL 中的 library 路徑與 cell 名稱。cell 類型提示不是 pin／電壓相容性保證。
5. Tcl 的 set 指令欄位填完整命令；literal 欄位填資料。list/dict/JSON 維持資料型別與語法。`.spec` 同時填搜尋目錄與 SRAM subckt 關鍵字；`.sed` 需核對匹配／取代規則。
6. 用 `rg -n 'FILL_IN_' Makefile src include sim script .private_config` 檢查即將執行流程的未填值。其他未使用範本可保留填空。
7. 先做工具載入檢查與小範圍模擬，再做原生流程。不要在設定未完成時啟動全流程。

逐欄提示：[guide/CONFIG_FILL_GUIDE.md](guide/CONFIG_FILL_GUIDE.md)。本地設定未完成時不保證每個流程都會提前報錯。填寫後的工作目錄可能重新含敏感資訊，不應直接分享。

掃描保留原介面名稱與設計邏輯；不是完全匿名或原生 EDA 功能驗證。

## 製程中性命名

本次將製程相關名稱統一為 TECH／FOUNDRY 等中性名稱，並同步其引用。請使用本包現有路徑與環境變數，不要套用舊包名稱。config 仍原處 set／array 填寫；沒有新增跨檔取值層。
