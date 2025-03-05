`include "defines.vh"


module ex(
        input   wire                rst,

        input   wire [`AluSelBus]   alusel_i,
        input   wire [`AluOpBus]    aluop_i,
        input   wire [`RegBus]      reg1_i,
        input   wire [`RegBus]      reg2_i,
        input   wire [`RegAddrBus]  wd_i,
        input   wire                wreg_i,

        // output
        output  reg  [`RegAddrBus]  wd_o,
        output  reg                 wreg_o,
        output  reg  [`RegBus]      wdata_o
    );

    // 保存逻辑运算的结果
    reg [`RegBus] logicout;


    // *** stage 1: calculate logic answer
    always @(*) begin
        if (rst == `RstEnable) begin
            logicout = `ZeroWord;
        end
        else begin
            case (aluop_i)
                `EXE_OR_OP: begin
                    logicout = reg1_i | reg2_i;
                end
                default:    begin
                    logicout = `ZeroWord;
                end
            endcase
        end
    end


    // *** stage 2: select a type of answer as final answer
    always @(*) begin
        wd_o    = wd_i;
        wreg_o  = wreg_i;
        case (alusel_i)
            `EXE_RES_LOGIC: begin
                wdata_o = logicout;
            end
            default:        begin
                wdata_o = `ZeroWord;
            end
        endcase
    end


endmodule
