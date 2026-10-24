module arbitrator #(
   parameter int Master       = 3,
   parameter int Master_index = (Master <= 1) ? 1 : $clog2(Master),

   parameter logic [1:0] M_priority [2][Master] = '{default:2'd2}
) 
(
    input  logic ACLK,
    input  logic ARESETn,

    input  logic race,

    input  logic [Master-1:0] ARVALID_req, 
    input  logic [Master-1:0] AWVALID_req,

    output logic RW,
    output logic [Master_index-1:0] index
);

    // =====================================================
    // robin counter
    // [0] = Read
    // [1] = Write
    // =====================================================
    logic [1:0] robin_counter_RW    [2][Master];
    logic [1:0] robin_counter_RW_in [2][Master];

    logic       comparater_RW_M          [Master];
    logic [1:0] comparater_RW_M_priority [Master];

    logic       winner_RW;
    logic [Master_index-1:0] winner_index;
    logic [1:0] winner_priority;

    assign RW    = winner_RW;
    assign index = winner_index;


    // ======================================================================
    // Stage 0: 建立所有 Master 的 R/W counter with valid masking
    // ======================================================================
    always @(*) begin
        for (int i = 0; i < Master; i = i + 1) begin
            robin_counter_RW_in[0][i] = (ARVALID_req[i]) ? robin_counter_RW[0][i] : 2'd0;
            robin_counter_RW_in[1][i] = (AWVALID_req[i]) ? robin_counter_RW[1][i] : 2'd0;
        end
    end


    // ======================================================================
    // Stage 1: 每個 Master 先比較自己的 Read / Write
    //
    // comparater_RW_M[i] = 0: Read winner
    // comparater_RW_M[i] = 1: Write winner
    //
    // 注意：
    // 原本邏輯是 W > R 才選 W
    // 所以 W == R 時會選 R
    // ======================================================================
    always @(*) begin
        for (int i = 0; i < Master; i = i + 1) begin
            comparater_RW_M[i] = 
                (robin_counter_RW_in[1][i] > robin_counter_RW_in[0][i]);

            comparater_RW_M_priority[i] = 
                (comparater_RW_M[i]) ? robin_counter_RW_in[1][i]
                                     : robin_counter_RW_in[0][i];
        end
    end


    // ======================================================================
    // Stage 2: 在所有 Master 裡找 priority 最大者
    //
    // 注意：
    // 這裡用 >，不是 >=
    // 所以 priority 相同時會保留較小 index
    // ======================================================================
    always @(*) begin
        winner_priority = comparater_RW_M_priority[0];
        winner_RW       = comparater_RW_M[0];
        winner_index    = '0;

        for (int i = 1; i < Master; i = i + 1) begin
            if (comparater_RW_M_priority[i] > winner_priority) begin
                winner_priority = comparater_RW_M_priority[i];
                winner_RW       = comparater_RW_M[i];
                winner_index    = i[Master_index-1:0];
            end
        end
    end


    // ======================================================================
    // Stage 3: robin_counter update
    // ======================================================================
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            for (int i = 0; i < Master; i = i + 1) begin
                robin_counter_RW[0][i] <= M_priority[0][i]; // Read
                robin_counter_RW[1][i] <= M_priority[1][i]; // Write
            end
        end
        else if (race) begin

            // ------------------------------
            // Read counter update
            // ------------------------------
            for (int i = 0; i < Master; i = i + 1) begin
                if (robin_counter_RW[0][i] == 2'd1)
                    robin_counter_RW[0][i] <= M_priority[0][i];
                else if (winner_RW == 1'b0 && winner_index == i[Master_index-1:0])
                    robin_counter_RW[0][i] <= robin_counter_RW[0][i] - 2'd1;
            end

            // ------------------------------
            // Write counter update
            // ------------------------------
            for (int i = 0; i < Master; i = i + 1) begin
                if (robin_counter_RW[1][i] == 2'd1)
                    robin_counter_RW[1][i] <= M_priority[1][i];
                else if (winner_RW == 1'b1 && winner_index == i[Master_index-1:0])
                    robin_counter_RW[1][i] <= robin_counter_RW[1][i] - 2'd1;
            end
        end
    end

endmodule
// `define MASTER 3

// module arbitrator #(
//    parameter int M_priority [2][3] = '{'{2'd2, 2'd2, 2'd2}, '{2'd2, 2'd2, 2'd2}},
//    parameter Master = 3,
//    parameter Master_index = 2
// ) 
// (
//     input ACLK, ARESETn,
//     input race,
//     input [2:0] ARVALID_req, 
//     input [2:0] AWVALID_req,
//     output RW,
//     output [Master_index-1:0] index
// );

//     reg [1:0] robin_counter_RW  [1:0][`MASTER-1:0];

//     wire winner_RW;
//     wire [1:0] winner_index;   // 因為 3 masters → 需要至少 2 bits

//     assign RW    = winner_RW;
//     assign index = winner_index;

// `ifdef PB_tree
//     // PB-tree 版本（略）
// `else

//     // ======================================================================
//     // Stage 0: 建立所有 Master 的 R/W counter (with valid masking)
//     // ======================================================================
//     reg [1:0] robin_counter_RW_in [1:0][`MASTER-1:0];

//     always @(*) begin
//         for (int i=0; i<`MASTER; i=i+1) begin
//             robin_counter_RW_in[0][i] = (ARVALID_req[i]) ? robin_counter_RW[0][i] : 2'd0;
//             robin_counter_RW_in[1][i] = (AWVALID_req[i]) ? robin_counter_RW[1][i] : 2'd0;
//         end
//     end


//     // ======================================================================
//     // Stage 1: 先比較 RW read/write winner per master
//     // comparator_RW_M# = 哪個 (R/W) counter 比較大 → RW = 0:R / 1:W
//     // ======================================================================

//     // M0
//     wire       comparater_RW_M0         = (robin_counter_RW_in[1][0] > robin_counter_RW_in[0][0]);
//     wire [1:0] comparater_RW_M0_priority = comparater_RW_M0 ? robin_counter_RW_in[1][0]
//                                                             : robin_counter_RW_in[0][0];

//     // M1
//     wire       comparater_RW_M1         = (robin_counter_RW_in[1][1] > robin_counter_RW_in[0][1]);
//     wire [1:0] comparater_RW_M1_priority = comparater_RW_M1 ? robin_counter_RW_in[1][1]
//                                                             : robin_counter_RW_in[0][1];

//     // M2  /* 新增 */
//     wire       comparater_RW_M2         = (robin_counter_RW_in[1][2] > robin_counter_RW_in[0][2]);
//     wire [1:0] comparater_RW_M2_priority = comparater_RW_M2 ? robin_counter_RW_in[1][2]
//                                                             : robin_counter_RW_in[0][2];


//     // ======================================================================
//     // Stage 2: 找出 priority 最大的 Master
//     // 先比 M0 vs M1 → 得到 group01
//     // 再讓 group01 vs M2
//     // ======================================================================

//     // -------- M0 vs M1 --------
//     wire M1_gt_M0 = (comparater_RW_M1_priority > comparater_RW_M0_priority);
//     wire [1:0] group01_priority = M1_gt_M0 ? comparater_RW_M1_priority
//                                            : comparater_RW_M0_priority;
//     wire       group01_RW       = M1_gt_M0 ? comparater_RW_M1 : comparater_RW_M0;
//     wire [1:0] group01_index    = M1_gt_M0 ? 2'd1 : 2'd0;

//     // -------- group01 vs M2 --------
//     wire M2_gt_group01 = (comparater_RW_M2_priority > group01_priority);

//     assign winner_index = M2_gt_group01 ? 2'd2 : group01_index;
//     assign winner_RW    = M2_gt_group01 ? comparater_RW_M2 : group01_RW;

// `endif


//     // ======================================================================
//     // Stage 3: robin_counter update
//     // ======================================================================
//     always @(posedge ACLK) begin
//         if (!ARESETn) begin
//             for (int i=0; i<`MASTER; i=i+1) begin
//                 robin_counter_RW[0][i] <= M_priority[0][i]; // R
//                 robin_counter_RW[1][i] <= M_priority[1][i]; // W
//             end
//         end
//         else if (race) begin
//             // R counter update
//             for (int i=0; i<`MASTER; i=i+1) begin
//                 if (robin_counter_RW[0][i] == 2'd1)
//                     robin_counter_RW[0][i] <= M_priority[0][i];
//                 else if (winner_RW == 1'b0 && winner_index == i)
//                     robin_counter_RW[0][i] <= robin_counter_RW[0][i] - 2'd1;
//             end
//             // W counter update
//             for (int i=0; i<`MASTER; i=i+1) begin
//                 if (robin_counter_RW[1][i] == 2'd1)
//                     robin_counter_RW[1][i] <= M_priority[1][i];
//                 else if (winner_RW == 1'b1 && winner_index == i)
//                     robin_counter_RW[1][i] <= robin_counter_RW[1][i] - 2'd1;
//             end
//         end
//     end

// endmodule
