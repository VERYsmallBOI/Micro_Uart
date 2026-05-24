`timescale 1ns / 1ps
`include "baud.v"
`include "u_xmit.v"
`include "u_rec.v"
`include "uart.v"
`include "inc.h"
module tb_uart_top;

reg clk;
initial clk = 0;
always #10 clk = ~clk;
reg rst;
reg  [`WORD_LEN-1:0] xmit_dataH;
reg xmitH;
wire uart_XMIT_dataH;
wire xmit_doneH;
wire xmit_active;
reg uart_REC_dataH;
wire [`WORD_LEN-1:0] rec_dataH;
wire rec_readyH;
wire rec_busy;
uart uart_dut (
    .sys_clk(clk),
    .sys_rst_l(rst),
    .xmit_dataH(xmit_dataH),
    .xmitH(xmitH),
    .uart_REC_dataH(uart_REC_dataH),
    .uart_XMIT_dataH(uart_XMIT_dataH),
    .xmit_doneH(xmit_doneH),
    .xmit_active(xmit_active),
    .rec_dataH(rec_dataH),
    .rec_readyH(rec_readyH),
    .rec_busy(rec_busy)
);
wire uart_clk_tb;
baud  b1 (.clk(clk),.rst(rst),.clko(uart_clk_tb));
integer pass_count;
integer fail_count;
//task for checking signal changes
task check_sig;
    input actual;
    input expected;
    input [8*24:1] name;
    begin
        if (actual === expected) begin
            $display("  PASS  %-24s = %b  t=%0t", name, actual, $time);
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL  %-24s = %b  (expected %b)  t=%0t",name, actual, expected, $time);
            fail_count = fail_count + 1;
        end
    end
endtask
//task to check flags of the dut
task check_flag;
    input        actual;
    input        expected;
    input [8*20:1] name;
    begin
        if (actual === expected) begin
            $display("  PASS  %-20s = %b  t=%0t", name, actual, $time);
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL  %-20s = %b (expected %b)  t=%0t",
                      name, actual, expected, $time);
            fail_count = fail_count + 1;
        end
    end
endtask
//task to check data of the receiver
task check_data;
    input [`WORD_LEN-1:0] expected;
    begin
        if (rec_dataH === expected) begin
            $display("  PASS  rec_dataH = 0x%02h  (expected 0x%02h)  t=%0t",rec_dataH, expected, $time);
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL  rec_dataH = 0x%02h  (expected 0x%02h)  t=%0t",rec_dataH, expected, $time);
            fail_count = fail_count + 1;
        end
    end
endtask
//task to check the bit of input of receiver the serial bits with stop and start
task check_bit;
    input        expected;
    input [63:0] bit_name;
    begin
        if (uart_XMIT_dataH === expected) begin
            $display("PASS bit[%0d]: uart_XMIT_dataH=%b (expected %b) t=%0t",bit_name, uart_XMIT_dataH, expected, $time);
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL  bit[%0d]: uart_XMIT_dataH=%b (expected %b)  t=%0t",bit_name, uart_XMIT_dataH, expected, $time);
            fail_count = fail_count + 1;
        end
    end
endtask
//task to check idle state of receiver
task check_idle_state;
    begin
        $display("  [IDLE CHECK - RX]");
        check_sig(uart_REC_dataH, 1'b1, "uart_REC_dataH(line)");
        check_sig(rec_readyH,     1'b1, "rec_readyH");
        check_sig(rec_busy,       1'b0, "rec_busy");
    end
endtask
//task of sending serial frames for receiver
task drive_frame;
    input [`WORD_LEN-1:0] data;
    input valid_stop;
    integer i;
    begin
        @(posedge uart_clk_tb);
        uart_REC_dataH = 1'b0;
        repeat(16) @(posedge uart_clk_tb);
        for (i = 0; i < `WORD_LEN; i = i + 1) begin
            uart_REC_dataH = data[i];
            repeat(16) @(posedge uart_clk_tb);
        end
        uart_REC_dataH = valid_stop ? 1'b1 : 1'b0;
        repeat(16) @(posedge uart_clk_tb);
        uart_REC_dataH = 1'b1;
    end
endtask
//reference model of the receiver for the final data
task ref_model_check_rx;
    input [`WORD_LEN-1:0] data_sent;
    begin
        $display("\n  [RX REF MODEL] data=0x%02h", data_sent);
        repeat(6) @(posedge uart_clk_tb);
        check_sig(rec_busy,   1'b1, "rec_busy(during frame)");
        check_sig(rec_readyH, 1'b0, "rec_readyH(during frame)");
        @(posedge rec_readyH);
        @(posedge uart_clk_tb);
        check_data(data_sent);
        check_sig(rec_readyH, 1'b1, "rec_readyH(after frame)");
        check_sig(rec_busy,   1'b0, "rec_busy(after frame)");
        $display("  [RX REF MODEL] done.\n");
    end
endtask
//for false start of the receiver
task drive_glitch;
    input integer n_cycles;
    begin
        @(posedge uart_clk_tb);
        uart_REC_dataH = 1'b0;
        repeat(n_cycles) @(posedge uart_clk_tb);
        uart_REC_dataH = 1'b1;
    end
endtask
//task for transmitter to start xmith
task drive_xmit;
    input [`WORD_LEN-1:0] data;
    begin
        xmit_dataH = data;
        @(posedge uart_clk_tb);
        xmitH = 1'b1;
        @(posedge uart_clk_tb);
        xmitH = 1'b0;
    end
endtask
//task for checking idle transmitter
task check_idle_tx;
    begin
        $display("  [IDLE CHECK - TX]");
        check_flag(uart_XMIT_dataH, 1'b1, "TX line idle");
        check_flag(xmit_active,     1'b0, "xmit_active idle");
        check_flag(xmit_doneH,      1'b1, "xmit_doneH idle");
    end
endtask
//task for conitnuous driving of input 
task wait_done_tx;
    begin
        @(posedge xmit_doneH);
        @(posedge uart_clk_tb);
    end
endtask
//reference model for transmitter
task ref_model_check_tx;
    input [`WORD_LEN-1:0] data_sent;
    integer i;
    reg [9:0] frame;
    begin
        frame[0]=1'b0;
        frame[9]=1'b1;
        for(i=0 ; i<`WORD_LEN; i = i+1) frame[i+1]=data_sent[i];
            $display("\n  [REF MODEL] Checking frame for data=0x%02h", data_sent);
            $display("  Expected frame (start,D0..D7,stop): %b_%b%b%b%b%b%b%b%b_%b",frame[0],frame[1],frame[2],frame[3],frame[4],frame[5],frame[6],frame[7],frame[8],frame[9]);
            repeat(8) @(posedge uart_clk_tb);
            $display("  --- START BIT ---");
            check_bit(frame[0],0);
            check_flag(xmit_doneH,1'b0,"xmitdone_h (during)");
            check_flag(xmit_active,1'b1,"xmit_active(during)");
            $display(" --- DATA BITS ---");
            for(i = 0;i<`WORD_LEN;i=i+1)begin
                repeat(16) @(posedge uart_clk_tb);
                check_bit(frame[i+1],i);
            end
            repeat(16) @(posedge uart_clk_tb);
            $display("  --- STOP BIT ---");
            check_bit(frame[9], 9);
            repeat(16) @(posedge uart_clk_tb);
            $display("--- FLAGS AFTER FRAME ---");
            check_flag(xmit_doneH,1'b1,"xmit_doneH(after)");
            check_flag(xmit_active,1'b0,"xmit_active(after)");
            $display("  [REF MODEL] Frame check complete.\n");
        end
endtask
//checking with the feedback sending from transmitter and giving it to receiver
reg loopback_en;
always @(*) begin
    if (loopback_en) uart_REC_dataH = uart_XMIT_dataH;
end
//driving the cases starting 
initial begin
    pass_count = 0;
    fail_count = 0;
    rst = 0;
    xmitH = 0;
    xmit_dataH = 0;
    uart_REC_dataH = 1'b1;
    loopback_en = 0;

    $display("\n========== RESET ==========");
    repeat(5) @(posedge clk);
    rst = 1;
    repeat(10) @(posedge uart_clk_tb);

    $display("\n========== TC1: TX Idle after reset ==========");
    check_idle_tx;

    $display("\n========== TC2: Transmit 0xA5 ==========");
    drive_xmit(8'hA5);
    ref_model_check_tx(8'hA5);

    $display("\n========== TC3: Transmit 0x00 (all zeros) ==========");
    @(posedge uart_clk_tb);
    drive_xmit(8'h00);
    ref_model_check_tx(8'h00);

    $display("\n========== TC4: Transmit 0xFF (all ones) ==========");
    @(posedge uart_clk_tb);
    drive_xmit(8'hFF);
    ref_model_check_tx(8'hFF);

    $display("\n========== TC5: Transmit 0x55 ==========");
    @(posedge uart_clk_tb);
    drive_xmit(8'h55);
    ref_model_check_tx(8'h55);

    $display("\n========== TC6: Transmit 0x01 (LSB check) ==========");
    @(posedge uart_clk_tb);
    drive_xmit(8'h01);
    ref_model_check_tx(8'h01);

    $display("\n========== TC7: Transmit 0x80 (MSB check) ==========");
    @(posedge uart_clk_tb);
    drive_xmit(8'h80);
    ref_model_check_tx(8'h80);

    $display("\n========== TC8: TX Reset mid-transmission ==========");
    @(posedge uart_clk_tb);
    xmit_dataH = 8'hBE;
    xmitH = 1'b1;
    @(posedge uart_clk_tb);
    xmitH = 1'b0;
    repeat(5) @(posedge uart_clk_tb);
    rst = 0;
    repeat(3) @(posedge clk);
    rst = 1;
    repeat(5) @(posedge uart_clk_tb);
    $display("  [TC8] After mid-tx reset:");
    check_idle_tx;

    $display("\n========== TC9: xmitH ignored during TX ==========");
    @(posedge uart_clk_tb);
    drive_xmit(8'hAA);
    @(posedge uart_clk_tb);
    xmitH = 1'b1;
    @(posedge uart_clk_tb);
    xmitH = 1'b0;
    $display("  [TC9] xmit_doneH during frame (expect 0):");
    check_flag(xmit_doneH, 1'b0, "xmit_doneH(mid-tx)");
    @(posedge xmit_doneH);
    @(posedge uart_clk_tb);
    $display("  [TC9] After frame completes:");
    check_flag(xmit_doneH,  1'b1, "xmit_doneH(done)");
    check_flag(xmit_active, 1'b0, "xmit_active(done)");

    $display("\n========== RX TC1: RX Idle after reset ==========");
    rst = 0;
    repeat(3) @(posedge clk);
    rst = 1;
    uart_REC_dataH = 1'b1;
    repeat(40) @(posedge uart_clk_tb);
    check_idle_state;

    $display("\n========== RX TC2: Receive 0xA5 ==========");
    fork
        drive_frame(8'hA5, 1'b1);
        ref_model_check_rx(8'hA5);
    join

    $display("\n========== RX TC3: Receive 0x00 (all zeros) ==========");
    @(posedge uart_clk_tb);
    fork
        drive_frame(8'h00, 1'b1);
        ref_model_check_rx(8'h00);
    join

    $display("\n========== RX TC4: Receive 0xFF (all ones) ==========");
    @(posedge uart_clk_tb);
    fork
        drive_frame(8'hFF, 1'b1);
        ref_model_check_rx(8'hFF);
    join

    $display("\n========== RX TC5: Receive 0x55 ==========");
    @(posedge uart_clk_tb);
    fork
        drive_frame(8'h55, 1'b1);
        ref_model_check_rx(8'h55);
    join

    $display("\n========== RX TC6: Receive 0x01 (LSB check) ==========");
    @(posedge uart_clk_tb);
    fork
        drive_frame(8'h01, 1'b1);
        ref_model_check_rx(8'h01);
    join

    $display("\n========== RX TC7: Receive 0x80 (MSB check) ==========");
    @(posedge uart_clk_tb);
    fork
        drive_frame(8'h80, 1'b1);
        ref_model_check_rx(8'h80);
    join

    $display("\n========== RX TC8: Walking-one 0x01..0x80 ==========");
    begin : walking_one
        integer k;
        reg [`WORD_LEN-1:0] w;
        for (k = 0; k < `WORD_LEN; k = k + 1) begin
            w = (1 << k);
            @(posedge uart_clk_tb);
            $display("  [WALK] sending 0x%02h", w);
            fork
                drive_frame(w, 1'b1);
                ref_model_check_rx(w);
            join
        end
    end

    $display("\n========== RX TC9: False start rejection (glitch) ==========");
    @(posedge uart_clk_tb);
    drive_glitch(6);
    repeat(20) @(posedge uart_clk_tb);
    $display("  [GLITCH] FSM should have returned to idle:");
    check_sig(rec_busy,   1'b0, "rec_busy(after glitch)");
    check_sig(rec_readyH, 1'b1, "rec_readyH(after glitch)");

    $display("\n========== RX TC10: busy asserts on start ==========");
    @(posedge uart_clk_tb);
    uart_REC_dataH = 1'b0;
    repeat(4) @(posedge uart_clk_tb);
    check_sig(rec_busy,   1'b1, "rec_busy(start detected)");
    check_sig(rec_readyH, 1'b0, "rec_readyH(start detected)");
    repeat(12) @(posedge uart_clk_tb);
    begin : complete_after_busy_check
        integer j;
        for (j = 0; j < `WORD_LEN; j = j + 1) begin
            uart_REC_dataH = 1'b0;
            repeat(16) @(posedge uart_clk_tb);
        end
        uart_REC_dataH = 1'b1;
        repeat(20) @(posedge uart_clk_tb);
    end
    uart_REC_dataH = 1'b1;
    repeat(5) @(posedge uart_clk_tb);

    $display("\n========== RX TC11: Reset mid-reception ==========");
    @(posedge uart_clk_tb);
    uart_REC_dataH = 1'b0;
    repeat(30) @(posedge uart_clk_tb);
    rst = 0;
    repeat(3) @(posedge clk);
    rst = 1;
    uart_REC_dataH = 1'b1;
    repeat(40) @(posedge uart_clk_tb);
    $display("  [RX RST MID-RX] After reset during frame:");
    check_sig(rec_readyH, 1'b1, "rec_readyH(after mid-rx rst)");
    check_sig(rec_busy,   1'b0, "rec_busy(after mid-rx rst)");

    $display("\n========== RX TC12: Framing error (stop bit = 0) ==========");
    $display("  NOTE: This test EXPOSES BUG in the RTL.");
    $display("        Expected: rec_busy=0, rec_readyH=1 after bad stop.");
    $display("        DUT will FAIL if RTL missing else branch in STOP state.");
    @(posedge uart_clk_tb);
    drive_frame(8'hAA, 1'b0);
    repeat(5) @(posedge uart_clk_tb);
    $display("  [FRAMING ERR] rec_dataH must NOT update:");
    check_sig(rec_readyH, 1'b1, "rec_readyH(after bad stop)");
    check_sig(rec_busy,   1'b0, "rec_busy(after bad stop)");
    rst = 0;
    repeat(3) @(posedge clk);
    rst = 1;
    uart_REC_dataH = 1'b1;
    repeat(40) @(posedge uart_clk_tb);

    $display("\n========== RX TC13: rec_dataH holds until next frame ==========");
    @(posedge uart_clk_tb);
    fork
        drive_frame(8'hA5, 1'b1);
        ref_model_check_rx(8'hA5);
    join
    repeat(50) @(posedge uart_clk_tb);
    $display("  [HOLD] rec_dataH should still be 0xA5 after 50 idle ticks:");
    check_data(8'hA5);

    $display("\n========== RX TC14: Back-to-back frames 0xA5 then 0x5A ==========");
    @(posedge uart_clk_tb);
    fork
        drive_frame(8'hA5, 1'b1);
        ref_model_check_rx(8'hA5);
    join
    @(posedge uart_clk_tb);
    fork
        drive_frame(8'h5A, 1'b1);
        ref_model_check_rx(8'h5A);
    join


    $display("\n========== SUMMARY ==========");
    $display("  PASS: %0d", pass_count);
    $display("  FAIL: %0d", fail_count);
    if (fail_count == 0)
        $display("  ALL TESTS PASSED");
    else
        $display("  SOME TESTS FAILED -- check FAIL lines above");
    $display("==============================\n");
    $finish;
end

initial begin
    #2_000_000_000;
    $display("TIMEOUT");
    $finish;
end

initial begin
    $dumpfile("tb_uart_top.vcd");
    $dumpvars(0, tb_uart_top);
end

endmodule