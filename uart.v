`include "inc.h"

module uart(sys_clk,
sys_rst_l,
xmitH,
xmit_dataH,
uart_REC_dataH,
uart_XMIT_dataH,
xmit_doneH,
rec_dataH,
rec_readyH,
xmit_active,
rec_busy
);

input [`WORD_LEN-1:0] xmit_dataH;
input sys_clk,sys_rst_l,xmitH,uart_REC_dataH;
output rec_busy,xmit_active,rec_readyH,  xmit_doneH, uart_XMIT_dataH;
output [`WORD_LEN-1:0]rec_dataH; 

wire downed_clk;

buad b1(.rst(sys_rst_l),.clk(sys_clk),.clko(downed_clk));

transmitter t1(.clk(downed_clk),.rst(sys_rst_l),.start(xmitH),.inp(xmit_dataH),.op_done(xmit_doneH),.op_data(uart_XMIT_dataH),.op_active(xmit_active));
//clk,rst,inp,op_done,op_data,op_active

receiver r1(.clk(downed_clk),.rst( sys_rst_l),.ready(rec_readyH),.busy(rec_busy),.op( rec_dataH),.inp(uart_REC_dataH));

endmodule