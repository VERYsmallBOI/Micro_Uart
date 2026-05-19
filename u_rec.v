module syncronizer (clk,rst,inp,op);
input clk,rst,inp;
output reg op;
reg inter;

always @(posedge clk,negedge rst) begin
    if(!rst)
    begin
        op<=1;
        inter<=1;
    end
    else 
    begin
        op<=inter;
        inter<=inp;
end
end
endmodule

module receiver(clk, rst, ready, busy, op, inp);
    input inp, clk, rst;
    output reg ready, busy;
    output reg [`WORD_LEN-1:0] op;
    reg [`WORD_LEN-1:0] op1;

    reg [3:0] count;
    reg [`WLR-1:0] countn;

    wire inp_s;
    reg [1:0] state;

    syncronizer s1(.clk(clk), .rst(rst), .inp(inp), .op(inp_s));

    always @(posedge clk, negedge rst) begin
        if (!rst) begin
            op1     <= 0;
            busy   <= 0;
            ready  <= 0;
            state  <= 0;
            op<=0;
        end
        else begin
            op<=op;
            case (state)
                2'b0: begin
                    op1     <= 0;
                    if (inp_s == 0) begin
                        state  <= 1;
                        ready  <= 0;
                        busy   <= 1;
                        countn <= 0;
                        count  <= 0;
                    end
                    else begin
                        state  <= 0;
                        ready  <= 1;
                        busy   <= 0;
                        countn <= 0;
                        count  <= 0;
                    end
                end

                2'b01: begin
                    
                    op1     <= 0;
                    if (count == 5) begin
                        count  <= 0;
                        countn <= 0;
                        if(inp_s==0)begin
                        state  <= 2;
                        ready  <= 0;
                        busy   <= 1;
                        end
                        else 
                        begin
                        state  <= 0;
                        ready  <= 1;
                        busy   <= 0;
                        end
                    end
                    else begin
                        count  <= count + 1;
                        state  <= 1;
                        countn <= 0;
                    end
                end

                2'b10: begin
                    ready  <= 0;
                    busy   <= 1;
                    if (&count) begin
                        op1     <= {inp_s, op1[7:1]};
                        count  <= 0;

                        if (&countn) begin
                            state  <= 3;
                            countn <= 0;
                        end
                        else begin
                            state  <= 2;
                            countn <= countn + 1;
                        end
                    end
                    else begin
                        count  <= count + 1;
                        state  <= 2;
                        countn <= countn;
                    end
                end

                2'b11: begin
                    
                    if (&count) begin
                        if(inp_s==1'b1) begin
                            op<=op1;
                        end
                        else begin
                        op<=op;
                        end
                        count  <= 0;
                        state  <= 0;
                        countn <= 0;
                        ready  <= 1;
                        busy   <= 0;
                        op1    <= 0;
                    end
                    else begin
                        op1    <= op1;
                        count  <= count + 1;
                        state  <= 3;
                        ready  <= 0;
                        busy   <= 1;
                        countn <= 0;
                    end
                end

                default: begin
                    state  <= 1;
                    ready  <= 0;
                    busy   <= 1;
                    countn <= 0;
                    op1     <= 0;
                    count  <= 0;
                end
            endcase
        end
    end

endmodule