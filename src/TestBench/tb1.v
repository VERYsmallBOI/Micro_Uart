`timescale 1ns/1ps
`include "inc.h"
module tb;
//dut outs
wire DUT_rec_busy, DUT_xmit_active, DUT_rec_readyH, DUT_xmit_doneH, DUT_uart_XMIT_dataH;
wire [`WORD_LEN-1:0] DUT_rec_dataH;
//ref outs
wire REF_rec_busy, REF_xmit_active, REF_rec_readyH, REF_xmit_doneH, REF_uart_XMIT_dataH;
wire [`WORD_LEN-1:0] REF_rec_dataH;
//ins
reg [`WORD_LEN-1:0] xmit_dataH;
reg sys_clk,sys_rst_l,xmitH,uart_REC_dataH;
reg rst_b=1;
string testc;
//16x clk for refence
// 16x clk for reference
wire mainclk;

baud b1 (
    .clk(sys_clk),
    .rst(rst_b),
    .clko(mainclk)
);

// Reference Model Instance
uart u1 (

    .sys_clk(sys_clk),

    .sys_rst_l(sys_rst_l),

    .xmitH(xmitH),

    .xmit_dataH(xmit_dataH),

    .uart_REC_dataH(uart_REC_dataH),

    

    // Connected to REF outputs

    .uart_XMIT_dataH(REF_uart_XMIT_dataH),

    .xmit_doneH(REF_xmit_doneH),

    .rec_dataH(REF_rec_dataH),

    .rec_readyH(REF_rec_readyH),

    .xmit_active(REF_xmit_active),

    .rec_busy(REF_rec_busy)

);

// Design Under Test (DUT) Instance
top u2 (
    .sys_clk(sys_clk),
    .sys_rst_l(sys_rst_l),
    .xmitH(xmitH),
    .xmit_dataH(xmit_dataH),
    .uart_REC_dataH(uart_REC_dataH),
    
    .uart_xmit_dataH(DUT_uart_XMIT_dataH),
    .xmit_active(DUT_xmit_active),
    .xmit_doneH(DUT_xmit_doneH),
    .rec_readyH(DUT_rec_readyH),
    .rec_dataH(DUT_rec_dataH),
    .rec_busy(DUT_rec_busy)
);
always begin 
#(10) sys_clk=~sys_clk;
end
initial begin
    sys_clk=0;
    xmitH=0;
    rst_b=0;

    uart_REC_dataH=1;
    xmit_dataH=0;
sys_rst_l=1;
@(posedge sys_clk);
rst_b=1;
@(posedge mainclk);
sys_rst_l=0;
@(posedge mainclk);
checker_T(.op_done(1), .op_data(1), .op_active(0), .testname("reset test trans")); //check transmitter flags
sys_rst_l=1;
@(posedge mainclk);
trains();




@(posedge mainclk);
sys_rst_l=0;
@(posedge mainclk);

sys_rst_l=1;
@(posedge mainclk);
rece();
#10000
$stop;

end


task automatic rece;
integer j=0;
// ------------------------------------------------------------
// Test 3: Reset during 4th data bit
// ------------------------------------------------------------
    
    uart_REC_dataH = 0;
    repeat(16) @(posedge mainclk);
    
    for(j = 0; j < 4; j++) begin
        uart_REC_dataH = ('H0F >> j) & 1'b1;
        repeat(16) @(posedge mainclk);
    end
    sys_rst_l = 0;                     // assert reset in middle of 4th bit
    for(j = 4; j < 8; j++) begin
        uart_REC_dataH = ('H0F >> j) & 1'b1;
        repeat(16) @(posedge mainclk);
    end
    checker_R(.ready(1), .busy(0), .op(0),
              .testname("Test 3: Reset during 4th data bit - bfr release"));
    sys_rst_l = 1;
        repeat(16) @(posedge mainclk);//buffer
// ------------------------------------------------------------
// Test 5: Normal frame (single)
// ------------------------------------------------------------
    uart_REC_dataH = 0;
    repeat(16) @(posedge mainclk);
    apply_testr('HFF);                  // data = 0xFF
    uart_REC_dataH = 1;
    repeat(15) @(posedge mainclk);     // intentional 15-cycle stop (checks intermediate state)
    checker_R(.ready(REF_rec_readyH), .busy(REF_rec_busy), .op(REF_rec_dataH),
              .testname("Test 5: Normal frame - before stop completes (15 cycles)"));
    @(posedge mainclk);
    checker_R(.ready(REF_rec_readyH), .busy(REF_rec_busy), .op(REF_rec_dataH),
              .testname("Test 5: Normal frame - after stop completes (16th cycle)"));
    repeat(16) @(posedge mainclk); //bufffer
// ------------------------------------------------------------
// Test 6: Two successive frames (no idle time)
// ------------------------------------------------------------
    uart_REC_dataH = 0;
    repeat(16) @(posedge mainclk);
    apply_testr('H0F);                  // first frame data = 0x0F
    uart_REC_dataH = 1;
    repeat(15) @(posedge mainclk);
    checker_R(.ready(REF_rec_readyH), .busy(REF_rec_busy), .op(REF_rec_dataH),
              .testname("Test 6: Two frames - first frame (before stop)"));
    @(posedge mainclk);
    checker_R(.ready(REF_rec_readyH), .busy(REF_rec_busy), .op(REF_rec_dataH),
              .testname("Test 6: Two frames - first frame (after stop)"));

    // second frame immediately follows
    uart_REC_dataH = 0; 
    repeat(16) @(posedge mainclk);
    apply_testr('HAA);                  // second frame data = 0xAA
    uart_REC_dataH = 1;
    repeat(15) @(posedge mainclk);
    checker_R(.ready(REF_rec_readyH), .busy(REF_rec_busy), .op(REF_rec_dataH),
              .testname("Test 6: Two frames - second frame (before stop)"));
    @(posedge mainclk);
    checker_R(.ready(REF_rec_readyH), .busy(REF_rec_busy), .op(REF_rec_dataH),
              .testname("Test 6: Two frames - second frame (after stop)"));

// ------------------------------------------------------------
// Test 7: False stop – stop bit always 0
// ------------------------------------------------------------
    uart_REC_dataH = 0;
    repeat(16) @(posedge mainclk);
    apply_testr('H23);                  // data = 0x23
    uart_REC_dataH = 0;                // stop bit low for 15 cycles (framing error)
    repeat(15) @(posedge mainclk);
    checker_R(.ready(REF_rec_readyH), .busy(REF_rec_busy), .op(REF_rec_dataH),
              .testname("Test 7: False stop (always 0) - before stop would end"));
    @(posedge mainclk);
    checker_R(.ready(REF_rec_readyH), .busy(REF_rec_busy), .op(REF_rec_dataH),
              .testname("Test 7: False stop (always 0) - after 16 cycles low"));

// ------------------------------------------------------------
// Test 8: False stop – 0 only during sampling window (8 cycles low, then high)
// ------------------------------------------------------------
    uart_REC_dataH = 0;
    repeat(16) @(posedge mainclk);
    apply_testr('HE0);                  // data = 0xE0
    uart_REC_dataH = 0;
    repeat(8) @(posedge mainclk);      // low for first half of stop
    uart_REC_dataH = 1;
    repeat(8) @(posedge mainclk);      // high for second half (total 16 cycles)
    checker_R(.ready(REF_rec_readyH), .busy(REF_rec_busy), .op(REF_rec_dataH),
              .testname("Test 8: False stop (0 only during sampling window) - after stop"));
    @(posedge mainclk);
    checker_R(.ready(REF_rec_readyH), .busy(REF_rec_busy), .op(REF_rec_dataH),
              .testname("Test 8: False stop - next clock edge"));

// ------------------------------------------------------------
// Extra: Technically correct stop (8 cycles high, then 8 cycles low)
// Not in table, but kept as is
// ------------------------------------------------------------
    uart_REC_dataH = 0;
    repeat(16) @(posedge mainclk);
    apply_testr('HE0);
    uart_REC_dataH = 1;
    repeat(8) @(posedge mainclk);
    uart_REC_dataH = 0;
    repeat(8) @(posedge mainclk);
    checker_R(.ready(REF_rec_readyH), .busy(REF_rec_busy), .op(REF_rec_dataH),
              .testname("Extra: Technically correct stop (8 high + 8 low) - after stop"));
    @(posedge mainclk);
    checker_R(.ready(REF_rec_readyH), .busy(REF_rec_busy), .op(REF_rec_dataH),
              .testname("Extra: Technically correct stop - next clock"));

// ------------------------------------------------------------
// Test 9: Technically correct start (start bit low for only 8 cycles)
// ------------------------------------------------------------
    uart_REC_dataH = 0;
    repeat(8) @(posedge mainclk);      // start bit low for 8 cycles
    uart_REC_dataH = 1;
    repeat(8) @(posedge mainclk);      // then high for 8 cycles (still valid)
    apply_testr('H00);                  // data = 0x00
    uart_REC_dataH = 1;
    repeat(15) @(posedge mainclk);
    checker_R(.ready(REF_rec_readyH), .busy(REF_rec_busy), .op(REF_rec_dataH),
              .testname("Test 9: Technically correct start (8 low + 8 high) - before stop"));
    @(posedge mainclk);
    checker_R(.ready(REF_rec_readyH), .busy(REF_rec_busy), .op(REF_rec_dataH),
              .testname("Test 9: Technically correct start - after stop"));

// ------------------------------------------------------------
// Test 4: False start (1 cycle low)
// ------------------------------------------------------------
    uart_REC_dataH = 0;
    @(posedge mainclk);
    uart_REC_dataH = 1;
    @(posedge mainclk);
    checker_R(.ready(REF_rec_readyH), .busy(REF_rec_busy), .op(REF_rec_dataH),
              .testname("Test 4: False start (1 cycle low) - after glitch"));
endtask



//pending
task trains;
    // Helper: ensure transmitter is idle and reset deasserted before each test
    // (assuming sys_rst_l=1, xmitH=0, and enough idle cycles)

    fork 
        begin : a
            forever begin
                @(posedge mainclk);
                checker_T(.op_active(REF_xmit_active), .op_done(REF_xmit_doneH), 
                          .op_data(REF_uart_XMIT_dataH), .testname(testc));
            end
        end

        begin : b
            // ================================================
            // T1: Normal transmission
            // ================================================
            testc = "transmit_normal";
            apply_testt('hFF);                 // loads data and asserts start for 1 cycle
            repeat(15) @(posedge mainclk);    // start bit (first 15 cycles)
            repeat(16*`WORD_LEN) @(posedge mainclk); // data bits
            repeat(16) @(posedge mainclk);    // stop bit
            repeat(16) @(posedge mainclk);    // idle gap between tests

            // ================================================
            // T2: Two continuous transmissions (back-to-back)
            // ================================================
            testc = "back_to_back_frame1";
            apply_testt('h1F);
            repeat(15) @(posedge mainclk);    // start bit
            repeat(16*`WORD_LEN) @(posedge mainclk);
            repeat(15) @(posedge mainclk);    // stop bit – only 15 cycles so next start can begin immediately

            testc = "back_to_back_frame2";
            apply_testt('hFF);
            repeat(16) @(posedge mainclk);    // start bit
            repeat(16*`WORD_LEN) @(posedge mainclk);
            repeat(16) @(posedge mainclk);    // stop bit
            repeat(16) @(posedge mainclk);    // idle gap

            // ================================================
            // T3a: Reset at start – early (after 1 cycle)
            // ================================================
            testc = "reset_during_start_early";
            apply_testt('hFF);
            sys_rst_l = 0;                    // reset asserted immediately after start
            repeat(15) @(posedge mainclk);    // start bit (reset active)
            repeat(16*`WORD_LEN) @(posedge mainclk);
            repeat(16) @(posedge mainclk);
            sys_rst_l = 1;
            repeat(16) @(posedge mainclk);    // idle gap

            // ================================================
            // T3b: Reset at start – last cycle (cycle 16)
            // ================================================
            testc = "reset_at_last_cycle_of_start";
            apply_testt('hFF);
            repeat(14) @(posedge mainclk);    // first 14 cycles of start
            sys_rst_l = 0;
            @(posedge mainclk);               // 15th cycle? Actually this is the 16th edge? Let's keep as last cycle
            repeat(16*`WORD_LEN) @(posedge mainclk);
            repeat(16) @(posedge mainclk);
            sys_rst_l = 1;
            repeat(16) @(posedge mainclk);

            // ================================================
            // T5: Reset during middle of transmission (e.g., during 3rd data bit)
            // ================================================
            testc = "reset_during_middle_of_transmission";
            apply_testt('hFF);
            repeat(15) @(posedge mainclk);                // start bit
            repeat(4*`WORD_LEN-1) @(posedge mainclk);     // go into data bits
            sys_rst_l = 0;
            repeat(4*`WORD_LEN-1) @(posedge mainclk);
            sys_rst_l = 1;
            repeat(16) @(posedge mainclk);                // idle gap

            // ================================================
            // T6a: Reset during stop bit (at cycle 8 of stop)
            // ================================================
            testc = "reset_during_stop_bit";
            apply_testt('hFF);
            repeat(15) @(posedge mainclk);                // start
            repeat(16*`WORD_LEN) @(posedge mainclk);      // data
            repeat(8) @(posedge mainclk);                 // first half of stop
            sys_rst_l = 0;
            repeat(8) @(posedge mainclk);                 // second half of stop (reset active)
            sys_rst_l = 1;
            repeat(16) @(posedge mainclk);                // idle gap

            // ================================================
            // T6b: Reset one cycle after stop bit ends (already idle)
            // ================================================
            testc = "reset_after_stop_bit_idle";
            apply_testt('hFF);
            repeat(15) @(posedge mainclk);                // start
            repeat(16*`WORD_LEN) @(posedge mainclk);      // data
            repeat(16) @(posedge mainclk);                // stop bit
            @(posedge mainclk);                           // one extra cycle (idle)
            sys_rst_l = 0;
            repeat(5) @(posedge mainclk);                 // hold reset
            sys_rst_l = 1;
            repeat(16) @(posedge mainclk);                // idle gap

            // ================================================
            // T4: Reset at idle (before any transmission)
            // ================================================
            testc = "reset_at_idle";
            sys_rst_l = 0;
            repeat(10) @(posedge mainclk);
            sys_rst_l = 1;
            repeat(16) @(posedge mainclk);



            // Stop the monitor process
            disable a;
        end
    join
endtask


task apply_testt;
input reg [`WORD_LEN-1:0]sample;


begin
xmitH=1;
xmit_dataH=sample;
@(posedge mainclk);
xmitH=0;
end
endtask


task automatic apply_testr;
input reg [`WORD_LEN-1:0]a;
integer i=0;

begin

for(i=0;i<`WORD_LEN;i++)
begin
uart_REC_dataH=(a>>i)&(1'b1);
repeat(16) @(posedge mainclk);
end

end

endtask

task automatic checker_R(
    input bit ready,      // Expected DUT_rec_readyH
    input bit busy,       // Expected DUT_rec_busy
    input [`WORD_LEN-1:0] op,         // Expected DUT_rec_dataH
    input string testname
);
    if ((ready == DUT_rec_readyH) &&
        (busy  == DUT_rec_busy) &&
        (op    == DUT_rec_dataH)) begin
        $display("%s: PASS", testname);
    end else begin
        $display("%s: FAIL", testname);
        $display("  Expected: ready=%0b, busy=%0b, op=%0b", ready, busy, op);
        $display("  Actual  : ready=%0b, busy=%0b, op=%0b", 
                 DUT_rec_readyH, DUT_rec_busy, DUT_rec_dataH);
    end
endtask

task automatic checker_T(
    input bit op_done,
    input bit op_data,
    input bit op_active,
    input string testname
);
    if ((op_done   == DUT_xmit_doneH) &&
        (op_data   == DUT_uart_XMIT_dataH) &&
        (op_active == DUT_xmit_active)) begin
        $display("%s: PASS", testname);
    end else begin
        $display("%s: FAIL", testname);
        $display("  Expected: op_done=%0b, op_data=%0b, op_active=%0b",
                 op_done, op_data, op_active);
        $display("  Actual  : op_done=%0b, op_data=%0b, op_active=%0b",
                 DUT_xmit_doneH, DUT_uart_XMIT_dataH, DUT_xmit_active);
    end
endtask

initial begin
  $dumpfile("tb.vcd");
  $dumpvars;      // dumps everything
end
endmodule