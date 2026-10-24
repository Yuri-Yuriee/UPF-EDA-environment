# 製程資訊排除檢查

本次依使用者要求，保留原生 config 與直接填空方式，排除工具生成物；製程／供應商／cell-family 識別名稱已同步改為中性名稱，包含資料夾、巨集、環境變數、函式與其引用。原 config 檔名保持，部分父目錄改為 TECH_MV。

stage config 不使用 setup_command、PUBLIC_CFG、動態載入或其他 Tcl 取值。直接填入 FILL_IN 欄位；cell 提示依用途分類。舊介面名稱不再提供相容別名。

已做字串與檔名掃描、config 保留比對、Tcl／Shell／Python／JSON 結構及校驗。沒有執行原生 EDA regression。規則掃描不能證明設計內容沒有任何其他商業機密。
