資料來源：使用者提供 layout.spi；CHIP.spi 的 SW instance statements 由 Stage2 壓縮包擷取，並由既有 source_sw_chain.tsv 保留所有 3312 個 SW 的 EN_IN/OUT/TVDD。未取得完整 CHIP.spi，因此僅能對 SW 關聯子圖作比較，不能宣稱全晶片 LVS 等價。

結果：
- Layout 展開 3312 SW；Source 3312 SW；兩邊 25 條 chain；長度分布 270×2、135×20、24×3，無未歸入 chain SW。
- 25 條 chain 使用預估物理重心與 chain 長度做一對一匹配。
- 108 顆 CPU SW layout TVDD 並非 TOP:VDD_LEVEL_01；Source TVDD 均預期 VDD_LEVEL_01；全部在 C18（Layout L24）。
- 108 個對照的 Source 編碼位置與 Layout 抽取階層展開位置差 < [請填入本地確認的尺寸]，支持對應但並非 layout/GDS 完整 signoff。
- 尚有 174 個依 chain step 對應的配對座標差 >[請填入本地確認的尺寸]（分布於 C01、C02、C19、C20、C21、C22）；可能是 SPICE instance 命名座標、hierarchy orient、順序、placement 或局部重排造成，尚不能直接宣告 EN net 實際短路/開路。應在 Innovus 核對及以 layout extracted net endpoints 追蹤。
- Layout 108 顆 TVDD 連到獨立局部 net，但其 bulk 接 TOP:VDD_LEVEL_01。

包含：
chain_mapping.csv : chain 一對一的重心配對（此對照為地理推斷，非 Calibre 配對認證）。
sw_full_pairing.csv : 全部 3312 個 step-to-step 對照、位置與 TVDD。
sw_tvdd_108_innovus_candidates.csv : 108 顆異常對應之 Innovus 具名 SW。
layout_tvdd_not_vdd0p8.csv : Layout 108 個階層實例。
highlight_tvdd_108.tcl : Innovus 只讀查詢+GUI highlight（不更改 DB）；如果 mapping 缺失則不執行 highlight。

用法：
  source /完整路徑/highlight_tvdd_108.tcl
  TT_HIGHLIGHT_TVDD_108 /完整路徑/sw_tvdd_108_innovus_candidates.csv
請使用與產生 LVS source/GDS 相同 checkpoint。
