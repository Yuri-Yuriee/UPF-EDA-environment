# 填空 IO 設定範本；不含原始 pad、net、座標或 offset。
# 請依本地封裝／library 定義填入 cell 對應的 instance 與各邊 pad 清單。
# 請填入所需 offset；不要沿用其他設計的實際配置。
(globals
    version = 3
    io_order = default
)
(iopad
    (top
        (inst name="FILL_IN_TOP_PAD_INSTANCE" offset=FILL_IN_TOP_PAD_OFFSET)
    )
    (right
        (inst name="FILL_IN_RIGHT_PAD_INSTANCE" offset=FILL_IN_RIGHT_PAD_OFFSET)
    )
    (bottom
        (inst name="FILL_IN_BOTTOM_PAD_INSTANCE" offset=FILL_IN_BOTTOM_PAD_OFFSET)
    )
    (left
        (inst name="FILL_IN_LEFT_PAD_INSTANCE" offset=FILL_IN_LEFT_PAD_OFFSET)
    )
)
