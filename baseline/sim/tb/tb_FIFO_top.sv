`timescale 1ns/1ps

module tb_FIFO_TOP;

    localparam integer WIDTH       = 34;
    localparam integer DEPTH       = 8;
    localparam integer POINTER_BIT = $clog2(DEPTH) + 1;
    localparam integer SYNC_FF_NUM = 2;

    localparam integer RANDOM_TEST_NUM = 64;
    localparam integer MAX_WAIT_CYCLE  = 200;

    logic                 clk_in;
    logic                 clk_out;
    logic                 rst_n;

    logic [WIDTH-1:0]     data_in;
    logic                 data_in_valid;
    logic                 data_in_ready;

    logic [WIDTH-1:0]     data_out;
    logic                 data_out_valid;
    logic                 data_out_ready;

    mailbox expected_mb;

    integer write_count;
    integer read_count;
    integer error_count;

    FIFO_TOP #(
        .width       (WIDTH),
        .depath      (DEPTH),
        .pointer_bit (POINTER_BIT),
        .SYNC_FF_NUM (SYNC_FF_NUM)
    ) dut (
        .clk_in         (clk_in),
        .clk_out        (clk_out),
        .rst_n          (rst_n),

        .data_in        (data_in),
        .data_in_valid  (data_in_valid),
        .data_in_ready  (data_in_ready),

        .data_out       (data_out),
        .data_out_valid (data_out_valid),
        .data_out_ready (data_out_ready)
    );

    /*
     * Input clock
     * Period = 10 ns
     */
    initial begin
        clk_in = 1'b0;

        forever begin
            #5;
            clk_in = ~clk_in;
        end
    end

    /*
     * Output clock
     * Period = 14 ns
     */
    initial begin
        clk_out = 1'b0;

        forever begin
            #7;
            clk_out = ~clk_out;
        end
    end

    /*
     * Waveform dump
     */
`ifdef FSDB
    initial begin
        $fsdbDumpfile("tb_FIFO_TOP.fsdb");
        $fsdbDumpvars(0, tb_FIFO_TOP);
    end
`else
    initial begin
        $dumpfile("tb_FIFO_TOP.vcd");
        $dumpvars(0, tb_FIFO_TOP);
    end
`endif

    /*
     * Apply asynchronous reset and wait for synchronized release.
     */
    task automatic apply_reset;
        begin
            rst_n          = 1'b0;
            data_in        = '0;
            data_in_valid  = 1'b0;
            data_out_ready = 1'b0;

            repeat (4) @(posedge clk_in);
            repeat (4) @(posedge clk_out);

            rst_n = 1'b1;

            fork
                repeat (SYNC_FF_NUM + 3) @(posedge clk_in);
                repeat (SYNC_FF_NUM + 3) @(posedge clk_out);
            join

            $display("[%0t] Reset completed", $time);
        end
    endtask

    /*
     * Send one data word through the input ready-valid interface.
     */
    task automatic send_word (
        input logic [WIDTH-1:0] send_data,
        input integer           idle_cycles
    );
        integer wait_cycle;

        begin
            repeat (idle_cycles) @(posedge clk_in);

            @(negedge clk_in);

            data_in       = send_data;
            data_in_valid = 1'b1;
            wait_cycle    = 0;

            while (1) begin
                @(posedge clk_in);

                if (
                    (data_in_valid === 1'b1) &&
                    (data_in_ready === 1'b1)
                ) begin
                    expected_mb.put(send_data);
                    write_count = write_count + 1;

                    $display(
                        "[%0t] WRITE[%0d] data=%h",
                        $time,
                        write_count,
                        send_data
                    );

                    break;
                end

                wait_cycle = wait_cycle + 1;

                if (wait_cycle >= MAX_WAIT_CYCLE) begin
                    $error(
                        "[%0t] Input handshake timeout, data=%h",
                        $time,
                        send_data
                    );

                    error_count = error_count + 1;
                    break;
                end
            end

            @(negedge clk_in);

            data_in_valid = 1'b0;
            data_in       = '0;
        end
    endtask

    /*
     * Receive one data word through the output ready-valid interface.
     *
     * The data is sampled on the clock edge where both valid and ready
     * are asserted.
     */
    task automatic receive_word (
        input integer idle_cycles
    );
        logic [WIDTH-1:0] sampled_data;
        logic [WIDTH-1:0] expected_data;

        integer wait_cycle;
        integer get_result;

        begin
            repeat (idle_cycles) @(posedge clk_out);

            @(negedge clk_out);

            data_out_ready = 1'b1;
            wait_cycle     = 0;

            while (1) begin
                @(posedge clk_out);

                if (
                    (data_out_valid === 1'b1) &&
                    (data_out_ready === 1'b1)
                ) begin
                    sampled_data = data_out;

                    get_result = expected_mb.try_get(expected_data);

                    if (get_result == 0) begin
                        $error(
                            "[%0t] Scoreboard underflow",
                            $time
                        );

                        error_count = error_count + 1;
                    end
                    else begin
                        read_count = read_count + 1;

                        if (sampled_data !== expected_data) begin
                            $error(
                                "[%0t] READ[%0d] mismatch: expected=%h actual=%h",
                                $time,
                                read_count,
                                expected_data,
                                sampled_data
                            );

                            error_count = error_count + 1;
                        end
                        else begin
                            $display(
                                "[%0t] READ[%0d] PASS: data=%h",
                                $time,
                                read_count,
                                sampled_data
                            );
                        end
                    end

                    break;
                end

                wait_cycle = wait_cycle + 1;

                if (wait_cycle >= MAX_WAIT_CYCLE) begin
                    $error(
                        "[%0t] Output handshake timeout",
                        $time
                    );

                    error_count = error_count + 1;
                    break;
                end
            end

            @(negedge clk_out);

            data_out_ready = 1'b0;
        end
    endtask

    /*
     * Wait until the input interface indicates FIFO full.
     */
    task automatic wait_for_full;
        integer wait_cycle;

        begin
            wait_cycle = 0;

            while (
                (data_in_ready !== 1'b0) &&
                (wait_cycle < MAX_WAIT_CYCLE)
            ) begin
                @(posedge clk_in);
                wait_cycle = wait_cycle + 1;
            end

            if (data_in_ready !== 1'b0) begin
                $error(
                    "[%0t] FIFO full timeout",
                    $time
                );

                error_count = error_count + 1;
            end
            else begin
                $display(
                    "[%0t] FIFO full detected",
                    $time
                );
            end
        end
    endtask

    /*
     * Wait until the output interface indicates FIFO empty.
     */
    task automatic wait_for_empty;
        integer wait_cycle;

        begin
            wait_cycle = 0;

            while (
                (data_out_valid !== 1'b0) &&
                (wait_cycle < MAX_WAIT_CYCLE)
            ) begin
                @(posedge clk_out);
                wait_cycle = wait_cycle + 1;
            end

            if (data_out_valid !== 1'b0) begin
                $error(
                    "[%0t] FIFO empty timeout",
                    $time
                );

                error_count = error_count + 1;
            end
            else begin
                $display(
                    "[%0t] FIFO empty detected",
                    $time
                );
            end
        end
    endtask

    /*
     * Verify that input data remains blocked while the FIFO is full.
     */
    task automatic full_backpressure_test;
        logic [WIDTH-1:0] blocked_data;

        begin
            blocked_data = {WIDTH{1'b1}};

            @(negedge clk_in);

            data_in       = blocked_data;
            data_in_valid = 1'b1;

            repeat (3) begin
                @(posedge clk_in);

                if (data_in_ready !== 1'b0) begin
                    $error(
                        "[%0t] data_in_ready asserted while FIFO is full",
                        $time
                    );

                    error_count = error_count + 1;
                end
            end

            @(negedge clk_in);

            data_in_valid = 1'b0;
            data_in       = '0;
        end
    endtask

    /*
     * Verify that no output transfer occurs while the FIFO is empty.
     */
    task automatic empty_read_test;
        begin
            @(negedge clk_out);

            data_out_ready = 1'b1;

            repeat (3) begin
                @(posedge clk_out);

                if (data_out_valid !== 1'b0) begin
                    $error(
                        "[%0t] data_out_valid asserted while FIFO is empty",
                        $time
                    );

                    error_count = error_count + 1;
                end
            end

            @(negedge clk_out);

            data_out_ready = 1'b0;
        end
    endtask

    initial begin : main_test
        integer i;

        logic [WIDTH-1:0] test_data;
        logic [WIDTH-1:0] random_data;

        expected_mb = new();

        write_count = 0;
        read_count  = 0;
        error_count = 0;

        rst_n          = 1'b0;
        data_in        = '0;
        data_in_valid  = 1'b0;
        data_out_ready = 1'b0;

        $display("");
        $display("========================================");
        $display("FIFO TOP TEST START");
        $display("========================================");

        apply_reset();

        /*
         * Reset state check
         */
        if (data_in_ready !== 1'b1) begin
            $error(
                "[%0t] data_in_ready should be high after reset",
                $time
            );

            error_count = error_count + 1;
        end

        if (data_out_valid !== 1'b0) begin
            $error(
                "[%0t] data_out_valid should be low after reset",
                $time
            );

            error_count = error_count + 1;
        end

        /*
         * Test 1: Fill the FIFO
         */
        $display("");
        $display("========================================");
        $display("TEST 1: FILL FIFO");
        $display("========================================");

        for (i = 0; i < DEPTH; i = i + 1) begin
            test_data = i + 1;

            send_word(
                test_data,
                0
            );
        end

        wait_for_full();

        /*
         * Test 2: Input backpressure while full
         */
        $display("");
        $display("========================================");
        $display("TEST 2: FULL BACKPRESSURE");
        $display("========================================");

        full_backpressure_test();

        /*
         * Test 3: Drain the FIFO
         */
        $display("");
        $display("========================================");
        $display("TEST 3: DRAIN FIFO");
        $display("========================================");

        for (i = 0; i < DEPTH; i = i + 1) begin
            receive_word(0);
        end

        wait_for_empty();

        /*
         * Test 4: Read request while empty
         */
        $display("");
        $display("========================================");
        $display("TEST 4: EMPTY READ");
        $display("========================================");

        empty_read_test();

        /*
         * Test 5: Concurrent asynchronous read and write
         */
        $display("");
        $display("========================================");
        $display("TEST 5: CONCURRENT READ AND WRITE");
        $display("========================================");

        fork
            begin : writer_process
                integer writer_index;

                for (
                    writer_index = 0;
                    writer_index < RANDOM_TEST_NUM;
                    writer_index = writer_index + 1
                ) begin
                    random_data = {
                        $urandom,
                        $urandom
                    };

                    send_word(
                        random_data,
                        $urandom_range(0, 2)
                    );
                end
            end

            begin : reader_process
                integer reader_index;

                repeat (4) @(posedge clk_out);

                for (
                    reader_index = 0;
                    reader_index < RANDOM_TEST_NUM;
                    reader_index = reader_index + 1
                ) begin
                    receive_word(
                        $urandom_range(0, 3)
                    );
                end
            end
        join

        wait_for_empty();

        /*
         * Final scoreboard check
         */
        if (expected_mb.num() != 0) begin
            $error(
                "[%0t] Scoreboard contains %0d remaining entries",
                $time,
                expected_mb.num()
            );

            error_count = error_count + 1;
        end

        repeat (5) @(posedge clk_out);

        $display("");
        $display("========================================");

        if (error_count == 0) begin
            $display("FIFO TOP TEST PASSED");
            $display("Total writes = %0d", write_count);
            $display("Total reads  = %0d", read_count);
        end
        else begin
            $display("FIFO TOP TEST FAILED");
            $display("Error count = %0d", error_count);
            $fatal(1);
        end

        $display("========================================");
        $display("");

        $finish;
    end

    /*
     * Global simulation timeout
     */
    initial begin
        #1000000;

        $fatal(
            1,
            "[%0t] Simulation timeout",
            $time
        );
    end

endmodule