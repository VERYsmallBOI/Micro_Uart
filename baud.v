`include "inc.h"

module baud (
    input rst,
    input clk,
    output reg clko
);

    reg [`CWR-1:0] clocker;

    always @(posedge clk, negedge rst) begin
        if (!rst) begin
            clocker <= 0;
            clko    <= 0;
        end else begin
            if (clocker == (`CW - 1)) begin
                clocker <= 0;
                clko    <= ~clko;
            end else begin
                clocker <= clocker + 1;
                clko    <= clko;
            end
        end
    end

endmodule