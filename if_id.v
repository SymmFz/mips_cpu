`include "defines.vh"



module if_id(
        input   wire                    rst     ,
        input   wire                    clk     ,

        // if stage signal
        input   wire    [`InstAddrBus]  if_pc   ,
        input   wire    [`InstBus]      if_inst ,

        // id stage signal
        output  reg     [`InstAddrBus]  id_pc   ,
        output  reg     [`InstBus]      id_inst
    );

    always @(posedge clk or posedge rst) begin
        if (rst == `RstEnable) begin
            id_pc <= `ZeroWord;
        end
        else begin
            id_pc <= if_pc;
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst == `RstEnable) begin
            id_inst <= `ZeroWord;
        end
        else begin
            id_inst <= if_inst;
        end
    end

endmodule
