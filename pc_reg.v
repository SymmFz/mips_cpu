`include "defines.vh"



module pc_reg(
        input   wire                rst,
        input   wire                clk,
        output  reg[`InstAddrBus]   pc,
        output  reg                 ce
    );

    // ce logic
    always @(posedge clk or posedge rst) begin
        if (rst == `RstEnable) begin
            ce <= `ChipDisable;
        end else begin
            ce <= `ChipEnable;
        end
    end

    // pc logic
    always @(posedge clk) begin
        if (ce == `ChipDisable) begin
            pc <= `ZeroWord;
        end else begin
            pc <= pc + 32'h4;
        end
    end

endmodule