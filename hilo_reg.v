`include "defines.vh"


module hilo_reg(
    input   wire                    rst,
    input   wire                    clk,

    input   wire                    we,
    input   wire    [`RegBus]       hi_i,
    input   wire    [`RegBus]       lo_i,

    // output
    output  reg     [`RegBus]       hi_o,
    output  reg     [`RegBus]       lo_o
);

    always @(posedge clk or posedge rst) begin
        if (rst == `RstEnable) begin
            hi_o <= `ZeroWord;
            lo_o <= `ZeroWord;
        end
        else if (we == `WriteEnable) begin
            hi_o <= hi_i;
            lo_o <= lo_i;
        end
    end

endmodule