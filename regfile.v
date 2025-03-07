`include "defines.vh"


module regfile(
        input   wire                clk         ,
        input   wire                rst         ,

        // write ports
        input   wire [`RegAddrBus]  waddr       ,
        input   wire [`RegBus]      wdata       ,
        input   wire                we          ,

        // read ports
        input   wire                re1         ,
        input   wire [`RegAddrBus]  raddr1      ,
        output  reg  [`RegBus]      rdata1      ,
        input   wire                re2         ,
        input   wire [`RegAddrBus]  raddr2      ,
        output  reg  [`RegBus]      rdata2
    );

    reg [`RegBus] regs [`RegNum-1:1];

    // regfile write logic
    always @(posedge clk) begin
        if (rst == `RstDisable)  begin
            // dont write to no.1 reg
            if (we == `WriteEnable && waddr != `RegNum'h0) begin
                regs[waddr] <= wdata;
            end
        end
    end

    // regfile read port 1
    always @(*) begin
        if (rst == `RstEnable) begin
            rdata1 = `ZeroWord;
        end
        else if (raddr1 == `RegNumLog2'h0) begin
            rdata1 = `ZeroWord;
        end
        else if ((raddr1 == waddr) && we == `WriteEnable &&
                 re1 == `ReadEnable) begin          // 流水线译码、写回阶段 RAW 冒险的数据前递
            rdata1 = wdata;
        end
        else if (re1 == `ReadEnable) begin
            rdata1 = regs[raddr1];
        end
        else begin
            rdata1 = `ZeroWord;
        end
    end

    // regfile read port 2
    always @(*) begin
        if (rst == `RstEnable) begin
            rdata2 = `ZeroWord;
        end
        else if (raddr2 == `RegNumLog2'h0) begin
            rdata2 = `ZeroWord;
        end
        else if ((raddr2 == waddr) && we == `WriteEnable &&
                 re2 == `ReadEnable) begin          // 流水线译码、写回阶段 RAW 冒险的数据前递
            rdata2 = wdata;
        end
        else if (re2 == `ReadEnable) begin
            rdata2 = regs[raddr2];
        end
        else begin
            rdata2 = `ZeroWord;
        end
    end


endmodule
