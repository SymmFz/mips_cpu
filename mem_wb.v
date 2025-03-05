`include "defines.vh"


module mem_wb(
    input   wire                rst,
    input   wire                clk,

    // input from MEM stage
    input   wire [`RegAddrBus]  mem_wd,
    input   wire                mem_wreg,
    input   wire [`RegBus]      mem_wdata,

    // MEM output
    output  reg  [`RegAddrBus]  wb_wd,
    output  reg                 wb_wreg,
    output  reg  [`RegBus]      wb_wdata
);

    always @(posedge clk or posedge rst) begin
        if (rst == `RstEnable) begin
            wb_wd    = `NOPRegAddr;
            wb_wreg  = `WriteDisable;
            wb_wdata = `ZeroWord;
        end else begin
            wb_wd    = mem_wd;
            wb_wreg  = mem_wreg;
            wb_wdata = mem_wdata;
        end
    end

endmodule