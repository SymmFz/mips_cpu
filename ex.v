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


    reg [`RegBus] logicout;     // 保存逻辑运算的结果
    reg [`RegBus] shiftres;     // 保存移位运算结果


    // ***  calculate logic answer
    always @(*) begin
        if (rst == `RstEnable) begin
            logicout = `ZeroWord;
        end
        else begin
            case (aluop_i)
                `EXE_OR_OP: begin
                    logicout = reg1_i | reg2_i;     // 或运算 or
                end
                `EXE_AND_OP: begin
                    logicout = reg1_i & reg2_i;     // 与运算 and
                end
                `EXE_XOR_OP: begin
                    logicout = reg1_i ^ reg2_i;     // 异或运算 xor
                end
                `EXE_NOR_OP: begin
                    logicout = ~(reg1_i | reg2_i);  // 或非运算 nor
                end
                default:    begin
                    logicout = `ZeroWord;
                end
            endcase
        end
    end

    // *** calculate shift answer
    always @(*) begin
        if (rst == `RstEnable) begin
            shiftres = `ZeroWord;
        end
        else begin
            case (aluop_i)
                `EXE_SLL_OP: begin
                    shiftres = reg2_i << reg1_i[4:0];   // 逻辑左移
                end
                `EXE_SRL_OP: begin
                    shiftres = reg2_i >> reg1_i[4:0];   // 逻辑右移
                end
                `EXE_SRA_OP: begin  // 算数右移
                    shiftres = ({32{reg2_i[31]}} << 6'd32 - {1'b0, reg1_i[4:0]})
                                | reg2_i >> reg1_i[4:0];
                end
                default: begin
                    // nothing
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
            `EXE_RES_SHIFT: begin
                wdata_o = shiftres;
            end
            default:        begin
                wdata_o = `ZeroWord;
            end
        endcase
    end


endmodule
