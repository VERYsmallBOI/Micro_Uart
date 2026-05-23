module ref(sys_clk,
sys_rst_l,
xmitH,
xmit_dataH,
uart_REC_dataH,
uart_XMIT_dataH,
xmit_doneH,
rec_dataH,
rec_readyH,
xmit_active,
rec_busy);

input [`WORD_LEN-1:0] xmit_dataH;
input sys_clk,sys_rst_l,xmitH,uart_REC_dataH;
output rec_busy,xmit_active,rec_readyH,  xmit_doneH, uart_XMIT_dataH;
output [`WORD_LEN-1:0]rec_dataH;
wire downed_clk;

reg en,k;

reg rec_busy_r,rec_readyH_r;
reg [`WORD_LEN-1:0]rec_dataH_r;
reg [`WORD_LEN-1:0]rec_dataH_r1;//temp register to hold recieved data bfr assigning to rec reg


buad b1(.rst(sys_rst_l),.clk(sys_clk),.clko(downed_clk));
//reusing baud alone


always @(posedge downed_clk, negedge rst) begin
  if (!rst) begin
    // Use non-blocking assignments for sequential logic
    en          <= 0;
    rec_dataH_r1 <= 0;
    rec_busy_r   <= 0;
    rec_readyH_r <= 1;
    rec_dataH_r  <= 0;
    // Kill the currently running task (if any)
    disable all_tasks;
  end else begin
    if (~en) begin
      fork : all_tasks
        my_task();   // This task must set en=1 at start and en=0 at finish
      join_none
    end
  end
end

task my_task();
  en = 1;  // Lock – prevent new tasks from starting

  // Wait for start bit (UART_REC_dataH == 0)
  // But first, check if reset is already active? The task starts only when en==0 and clk edge, reset inactive.
  // The following assumes reset may become active during waiting.

  if (uart_REC_dataH == 0) begin
    // --- Start bit sampling (7 cycles) ---
    rec_busy_r   <= 1;
    rec_readyH_r <= 0;
    repeat (7) begin
      if (!rst) begin
        // Reset asserted: abort now
        en <= 0;
        rec_busy_r   <= 0;
        rec_readyH_r <= 1;
        return;
      end
      @(posedge downed_clk);
    end

    // --- Data bits (WORD_LEN bits) ---
    for (int i = 0; i < `WORD_LEN; i++) begin
      // Wait for middle of bit (16 cycles per bit)
      repeat (16) begin
        if (!rst) begin
          en <= 0;
          rec_busy_r   <= 0;
          rec_readyH_r <= 1;
          return;
        end
        @(posedge downed_clk);
      end
      // Sample the bit and shift into register
      rec_dataH_r1 <= {uart_REC_dataH, rec_dataH_r1[`WORD_LEN-1:1]}; // adjust for your shift direction
    end

    // --- Stop bit (must be 1) ---
    repeat (16) begin
      if (!rst) begin
        en <= 0;
        rec_busy_r   <= 0;
        rec_readyH_r <= 1;
        return;
      end
      @(posedge downed_clk);
    end
    if (uart_REC_dataH == 1) begin
      // Stop bit OK – transaction complete
      // rec_dataH_r1 already contains received word
      // Keep rec_busy_r = 0, rec_readyH_r = 1 (they are already set at end)
    end else begin
      // Stop bit error – optionally handle (here just finish)
    end
  end

  // Normal completion
  rec_busy_r   <= 0;
  rec_readyH_r <= 1;
  en <= 0;  // Unlock – allow next spawn
endtask




//transmitter
always@(posedge downed_clk or negedge sys_rst_l)
begin

if(!sys_rst_l)
begin

xmit_active=0;
xmit_doneH=0;
uart_XMIT_dataH=0;
end
else
    begin
    if(xmitH==1)
    begin 
        k=1;
   trains();
    end

end
end



task trains;
begin
 repeat(16)
    begin
        if(sys_rst_l==1)
         @(posedge downed_clk);
        else
        return
        
    
    end
if(uart_REC_dataH!=0) return
repeat(16)
    begin
        if(sys_rst_l==1)
         @(posedge downed_clk);
        else
        return
        
    
    end
end
endtask



endmodule