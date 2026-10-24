# ioPADt 檢查規則設定

這份文件只說明介面，不含真實 Library、Cell 或 Pin 資料。實際設定檔是 **目前設計的** `setup/config/private/ioPADt.rules.json`，屬於私有資料。一般 APR 使用者不需要逐次調整它；換 IO Library、元件家族或檢查規則時才需修改。

## 從哪裡開始

1. 先備份目前 JSON。在已授權的 IO Library／已載入 Innovus 設計中確認 **Cell master** 與 Pin，不能用 instance 名稱代替 master。
2. 先檢查 `master_roles`、查詢家族清單，再確認 `signatures` 的 Pin 集合。大小寫必須一致。
3. 確認各 rail 的來源角色、Pin，以及跨 domain 的一致／互斥規則。這些是使用者指定的規則，不能只憑 Pin 字串猜測。
4. 一次只改一組相關欄位，儲存 JSON，完整關閉後重開 ioPADt。設定在程式啟動時載入，已開啟的 GUI 不會自動重讀。
5. 重新 query 目前 DB，先檢查分類、rail 連通與 domain 檢查結果。設定載入成功不等於電氣功能已驗證；確認結果之前不要 Apply。

正常啟動由 `setup/config/00_library.config.tcl` 指定此設計的 profile。Python 優先使用環境變數 `IOPADT_RULES_FILE`；未設定時才使用 Runtime-relative 路徑。若結果與檔案不一致，先核對啟動時使用的 profile 路徑。不要修改共享 TECH_MV 的模板來調整當前設計。

## 需要自己填的資料

| 欄位 | 型別 | 如何填／用途 |
|---|---|---|
| `profile_id` | string | 方便自己辨識 Library／規則版本的標籤。不是檔案路徑。 |
| `corner_master_family` | string | 已確認的 corner master family。依既有 H/V 正規化規則填 family。 |
| `master_roles` | object | 正規化後的 master family → 現有邏輯角色。改左側名稱時同步檢查查詢清單。右側角色不是任意顯示文字；保留現有角色語意。 |
| `query_master_families` | string array | 要查詢的確切 family 清單。不接受 wildcard；H/V 展開仍由既有工具執行。 |
| `query_confirmed_families` | string array | 既有查詢的 confirmed 清單。只填已確認支援的 family。 |
| `signatures` | object | 使用下面的 Pin 規則辨識元件；Pin 名称來自 Library，不是 net 名稱。 |
| `rail_defs` | object | 每條既有 rail 的來源角色、carrier 類型與 Pin。詳見下節。 |
| `rail_cut_at_boundary` | object of boolean | 各既有 rail 到 boundary 是否中斷。JSON 使用 `true`／`false`，不要填字串。 |
| `expected_rail_pins` | object | 既有 rail 名稱 → 預期 carrier Pin；必須與 rail 設定一起檢查。 |
| `domain_exclusive_pins` | string array | 應維持跨 domain 排他性的 Pin。 |
| `domain_consistent_pins` | string array | 同一 domain 內應一致的 Pin。不能與 exclusive 清單重疊。 |
| `domain_column_pins` | object | 既有 GUI domain 欄位 → 要檢查的 Pin。左側是既有欄位 ID，右側才是可配置的 Pin。 |
| `ground_expectations` | object | 兩個既有 ground 檢查 Pin → 既有預期角色標籤。不是任意 Pin → net 強制映射。保持原本兩項順序與角色語意。 |

以上名稱清單必須是非空、無重複的字串陣列；mapping 的鍵和值也必須是非空字串。查詢家族只接受字母、數字與底線。**請不要把所有 Cell 都塞入查詢清單，只填這個工具實際支援的 IO 元件。**

### signatures：exact 與 required 不相同

| 子欄位 | 判斷方式 |
|---|---|
| `boundary_pg_exact` | PG Pin 集合必須完全相同，且不能有 signal Pin。 |
| `rte_signal_exact` | Signal Pin 集合必須完全相同。 |
| `signal_required` | 兩個既有功能 Signal Pin 必須存在；目前必須恰好設定兩個。 |
| `power_signal_exact` | Power 類型的 Signal Pin 集合必須完全相同。 |
| `power_pg_required` | Power 類型必須含有指定 PG Pin；允許其他 PG Pin。 |

`exact` 清單多填或少填都會改變分類；`required` 是必需存在的集合。不要將兩者互換。

### rail_defs：每個 rail 的四個欄位

| 子欄位 | 如何填 |
|---|---|
| `source_role` | 既有來源元件邏輯角色，與 `master_roles` 保持一致。 |
| `carrier_kind` | `pg`：PG Pin；`pin`：Signal Pin。不能任意換其他字串。 |
| `carrier_pin` | 該類元件實際承載此 rail 的 Pin。 |
| `label` | 保留既有 rail label 語意；不是新 net 指派介面。 |

`rail_defs`、`rail_cut_at_boundary`、`expected_rail_pins` 必須使用同一組既有 rail 鍵。目前演算法固定支援三個 rail 身分，不能單靠新增 JSON 項目擴充。

### 修改範例（只有片段，不能直接取代整份 JSON）

```json
"master_roles": {
  "YOUR_SIGNAL_MASTER_FAMILY": "SIGNAL"
}
```

左側換成已授權 Library 的實際 family；保留其他既有角色。這個片段不是完整可載入 profile，也不代表工具能自動支援所有新 Library。

## 暫時不要自行改的介面

- `schema_version`：目前為 `1`。頂層欄位必須完整且不能自行新增欄位。
- `master_normalization_pattern`：目前固定為 `^(.*)_([HV])$`。Python 與內嵌 Tcl 的 H/V 規則仍耦合，不能只改這個 regex。
- `literal_tokens`：不是一般使用者設定。這是既有 Python／內嵌 Tcl 的名稱替換對照，其中部分 token 是 Pin／Cell 名称，部分是角色、rail 或欄位身分。不可刪除或單獨改名，也不要把 opaque token 當作新增檢查的入口。需要另做一致性整理後才能變成直觀的設定介面。
- 現有 role、rail、GUI 欄位 ID 與 ground 預期標籤：屬於程式介面，與 Library 名稱不同。換 Library 時須檢查對應用途，不能全域搜尋取代。

**目前尚不能宣稱換一份 JSON 就能完全移植到另一製程。** 此次沒有新增任意 net override、severity、檢查啟停或新修復流程。

## 儲存後如何檢查

從 `build_PR` 執行：

```sh
python3 -m json.tool setup/config/private/ioPADt.rules.json > /dev/null
```

此命令只檢查 JSON 語法，不輸出私有內容；它不檢查工具規則或電氣正確性。工具啟動時還會檢查 schema、欄位集合、清單重複、rail 身分、Pin 分類等限制，失敗時明確報錯，不會退回內建 Cell 名稱。

若出現規則載入錯誤，先還原備份，再逐組比對修改。不要為了跳過錯誤而關閉驗證。若 GUI 分類／連通結果不同，用同一 DB、同一 query 與未修改 profile 比較，保留本機結果供審查。

## private 內另外兩個檔案

- `geometry_values.tcl`：可選的舊式幾何覆寫 dictionary。空 dictionary 表示沒有覆寫；不是缺資料。查值順序為此覆寫 → 支援的 Innovus 即時查詢 → `geometry_review.config.tcl`。日常設定仍編輯可讀的 stage config；不要填入猜測值。
- `lef_geometry_*.json`：完整 LEF 盤點不是執行設定，可能含大量製程幾何與私有來源資訊。本次舊盤點已移至專案本機私有備份，不再放在 Runtime 設定區。不要將它用作 profile 或公开範例。

不要公開實際 rules JSON、geometry 覆寫或私有備份。這份說明不包含實際 Library 名稱／Pin／製程數值。
