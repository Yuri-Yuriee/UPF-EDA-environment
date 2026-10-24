# ioPADt.rules.json 使用介紹

`ioPADt.rules.json` 是這個設計的 IO Library 與檢查規則設定。它讓 ioPADt 判斷元件角色、Pin 類型、rail 傳遞及 domain 連通規則；它不是 APR Stage config，也不是執行 Tcl 的檔案。

## 平常怎麼使用

同一套 IO Library 通常不必修改這份 JSON。正常啟動 ioPADt 時會載入它。若 Innovus 已載入 GUI bridge，在允許調整 IO 的 checkpoint 執行：

```tcl
TT_IOPAD_GUI_START
TT_IOPAD_GUI_STATUS
```

不要因為調整規則就重新執行整個 Floorplan。IO filler／固定 IO 完成後，也不要把 GUI 啟動當成允許重建 IO 的依據；仍遵守既有 checkpoint 限制。

GUI 啟動優先使用 `IOPADT_RULES_FILE` 指定的檔案；正常 Flow 由 `00_library.config.tcl` 設定。未指定時才使用工具的 Runtime-relative 預設位置。如果載入結果不符合預期，先核對實際 profile 路徑。

## 什麼情況需要修改

- 換 IO Library 或更換支援的 Cell master family。
- Library 的 Pin 名稱／Pin 組合改變。
- 需要調整現有 rail 的 carrier Pin，或既有 domain 一致／互斥檢查對應。

修改前備份 JSON，用已授權 Library 或目前 Innovus DB 確認資料。Cell master 與 instance 不同；Pin 與 net 名稱也不同。不要只依名稱猜電氣用途。

## 先看哪些欄位

| 目的 | 欄位 |
|---|---|
| 哪些 master 屬於哪一種 IO 角色 | `master_roles`、`corner_master_family` |
| Innovus 要查哪些 master family | `query_master_families`、`query_confirmed_families` |
| 用哪些 Pin 組合辨識元件 | `signatures` |
| 每條 rail 從哪種元件、哪個 Pin 傳遞 | `rail_defs`、`expected_rail_pins` |
| rail 是否在 boundary 中斷 | `rail_cut_at_boundary` |
| 哪些 Pin 要跨 domain 排他、同 domain 一致 | `domain_exclusive_pins`、`domain_consistent_pins` |
| GUI domain 欄位檢查哪個 Pin | `domain_column_pins` |
| 既有 ground 檢查的預期角色 | `ground_expectations` |

`signatures` 中 `exact` 表示集合完全相同；`required` 表示必須包含那些 Pin。混用會改變元件分類。預期 net 仍由原本的 query 與 domain／rail 傳遞計算，這份 JSON 不是任意 Pin → net 指派介面。

## 修改與確認步驟

1. 備份 JSON，選一組相關欄位修改；保留其餘內容。
2. 從 `build_PR` 執行下列語法檢查，不會印出私有內容：

   ```sh
   python3 -m json.tool setup/config/private/ioPADt.rules.json > /dev/null
   ```

3. 完整關閉後重開 ioPADt。已開啟的 GUI 不會自動重讀 JSON。
4. 重新 query 同一個 DB，檢查元件分類、rail 連通與 domain 檢查結果。
5. 與原 profile 結果比較；確認前不要 Apply。若不符預期，還原備份再重開。

JSON 語法通過只代表格式正確。啟動時還會做 schema／清單／mapping 驗證；電氣正確性仍需從實際 DB 檢查。

## 暫時不要自由修改

`schema_version`、`master_normalization_pattern`、現有 role／rail／GUI 欄位 ID 及 `literal_tokens` 與程式介面耦合。尤其 `literal_tokens` 是舊名稱替換表，並不是直觀的一般使用者設定。不能靠改 JSON 擴充任意 rail 或新增檢查，也不能宣稱換 profile 就能完整移植另一製程。

完整欄位、型別與現有限制請看 [設定指南](../README.ioPADt_rules.md)。實際 JSON 含 Library／Pin 資料，仍不公開。

## 同資料夾另兩份 Tcl 是什麼

- `geometry_values.tcl`：可選的舊式幾何覆寫 dictionary。目前回傳空 dictionary，所以沒有覆寫。相關查值依序使用此覆寫、支援的 Innovus 即時查詢、`../geometry_review.config.tcl`。日常調整仍在各 stage config。
- `setup_commands.tcl`：之前隔離私有設定時建立的相容資料包，保存原始設定指令与 Library 資料。建立新 Runtime 時，既有 materializer 用它展開為可讀設定；舊模板也可透過 helper 讀它。目前 Runtime stage config 已沒有這種指令間接引用，Library 也有直接陣列，因此平常不編輯這包。改它不會覆蓋已展開的設定。安裝／舊介面仍使用它，本次保留。
