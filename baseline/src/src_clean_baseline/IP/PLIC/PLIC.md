Offset	Register	說明
0x0000 + 4*ID	priority[ID]	source ID 優先權，ID 從 1 開始
0x1000 + 4*word	pending	pending bit，read-only
0x2000 + 4*word	enable	enable bit
0x200000	threshold	優先權要大於 threshold 才會觸發 IRQ
0x200004	claim / complete	read = claim ID；write = complete ID