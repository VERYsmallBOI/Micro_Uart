module transmitter(clk, rst, start, inp, op_done, op_data, op_active);
    input [`WORD_LEN-1:0] inp;
    input clk, start, rst;
    output reg op_data, op_active, op_done;

    // done from stop to initial end and active flag 
    reg [3:0] count;
    reg [`WLR-1:0] countn;
    reg [`WORD_LEN-1:0] sample;
    reg [1:0] state;

    always @(posedge clk, negedge rst) begin
        if (!rst) begin
            op_data   <= 1;
            op_active <= 0;
            op_done   <= 1;
            sample    <= 0;
            count     <= 0;
            countn    <= 0;
            state     <= 0;
        end
        else begin
            // sample assigns do now
            case (state)
                2'b00: begin
                    if (start) begin // start transmission only if start==1
                        sample    <= inp;
                        op_done   <= 0;
                        op_data   <= 0;
                        op_active <= 1;
                        state     <= 1;
                        count     <= 0;
                        countn    <= 0;
                    end
                    else begin
                        count     <= 0;
                        sample    <= 0;
                        op_done   <= 1;
                        op_active <= 0;
                        state     <= 0;
                        op_data   <= 1;
                        countn    <= 0;
                    end
                end

                2'b01: begin
                    if (&count) begin
                        state     <= 2;
                        sample    <= sample >> 1;
                        op_data   <= sample[0];
                        count     <= 0;
                        countn    <= 0;
                        op_active <= 1;
                        op_done   <= 0;
                    end
                    else begin
                        count     <= count + 1;
                        state     <= 1;
                        sample    <= sample;
                        op_data   <= op_data;
                        op_active <= 1;
                        op_done   <= 0;
                        countn    <= 0;
                    end
                end

                2'b10: begin
                    if (&count) begin
                        if (&countn) begin // seq finsish
                            state     <= 3;
                            count     <= 0;
                            op_data   <= 1;
                            op_done   <= 0;
                            op_active <= 1;
                            sample    <= 0;
                            countn    <= 0;
                        end
                        else begin
                            state     <= 2;
                            sample    <= sample >> 1;
                            op_data   <= sample[0];
                            op_active <= 1;
                            op_done   <= 0;
                            count     <= 0;
                            countn    <= countn + 1;
                        end
                    end
                    else begin
                        count     <= count + 1;
                        countn    <= countn;
                        sample    <= sample;
                        op_data   <= op_data;
                        op_active <= 1;
                        op_done   <= 0;
                    end
                end

                2'b11: begin
                    if (&(count+1)) begin
                        op_done   <= 1;
                        count     <= 0;
                        if (start) begin
                            sample    <= inp;
                            op_data   <= 0;
                            op_active <= 1;
                            state     <= 1;
                            countn    <= 0;
                        end
                        else begin
                            sample    <= 0;
                            op_data   <= 1;
                            op_active <= 0;
                            state     <= 0;
                            countn    <= 0;
                        end
                    end
                    else begin
                        sample    <= 0;
                        op_done   <= 0;
                        op_data   <= 1;
                        op_active <= 1;
                        state     <= 3;
                        count     <= count + 1;
                        countn    <= 0;
                    end
                end

                default: begin
                    op_data   <= 1;
                    op_active <= 0;
                    op_done   <= 1;
                    sample    <= 0;
                    count     <= 0;
                    countn    <= 0;
                    state     <= 0;
                end
            endcase
        end
    end

endmodule