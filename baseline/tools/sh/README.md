# 根目錄 Shell 工具

四個原根目錄 sh 的實體檔案集中於此；沒有 soft link 或根目錄副本。

- pack_tech_mv_sync.sh：打包目前 Flow。預設输出 temp/sync_export，可用 BASELINE、OUTDIR 覆寫。只產生本地壓縮包，不會上傳；包內仍可能有敏感來源。
- sync_build_PR_to_TECH_MV_v3.sh：舊版反向同步工具；目前唯一來源模式會拒絕執行，避免把 Runtime 入口覆蓋到正式實作。
- private/TT_extract_spice_cells.sh：讀取指定 library，輸出 temp/debug/TT_spice_extract；第二個參數可指定輸出目錄。輸出仍可能敏感。
- private/TT_extract_lowpower_spice_safe.sh：輸出 temp/debug 下的 SPICE；第二個參數可覆寫。SAFE 名稱不代表能公開。

可由任何工作目錄使用絕對路徑呼叫。正式 Verify／Stage 內部 sh 仍保留既有位置，避免破壞已驗證的內部相依性。

```sh
bash tools/sh/sync_build_PR_to_TECH_MV_v3.sh --dry-run
make clean_root_debug_preview
make clean_root_debug
```

## TECH_MV 環境建立

`build_tech_runtime.sh` 依正式來源的 `runtime_sources.list` 建立 Runtime；不執行 Tcl／EDA、不使用 Python installer。從專案根目錄執行：

```sh
make pr_build
python3 tools/check_tech_sync.py --strict-defaults
```

新檔從來源複製，Tcl 相容入口以實際檔案產生，不使用 soft link。現有設定與程式檔保留；缺少的宣告檔可以補建。普通建立不會反向同步使用者修改。需要保存新 Runtime 預設值時應先備份並審查，不能用舊的整棵覆寫同步。

`make innovus` 共用同一建立步驟；`make verify_build` 可只建立 Verify。以上環境檢查不等於 APR／Calibre regression。
