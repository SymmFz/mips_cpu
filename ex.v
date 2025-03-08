`include "defines.vh"


module ex(
        input   wire                rst,

        input   wire [`AluSelBus]   alusel_i,
        input   wire [`AluOpBus]    aluop_i,
        input   wire [`RegBus]      reg1_i,
        input   wire [`RegBus]      reg2_i,
        input   wire [`RegAddrBus]  wd_i,
        input   wire                wreg_i,

        // HILO 模块给出的 HI,LO 寄存器的值
        input   wire [`RegBus]      hi_i,
        input   wire [`RegBus]      lo_i,

        // 写回阶段的指令是否要写 HI,LO，用于检测 HI,LO 寄存器的 RAW 数据冒险
        input   wire                wb_whilo_i,
        input   wire [`RegBus]      wb_hi_i,
        input   wire [`RegBus]      wb_lo_i,

        // 访存阶段的指令是否要写 HI,LO，用于检测 HI,LO 寄存器 RAW 数据冒险
        input   wire                mem_whilo_i,
        input   wire [`RegBus]      mem_hi_i,
        input   wire [`RegBus]      mem_lo_i,

        // 处于执行阶段的指令是否要写 HI,LO
        output  reg                 whilo_o,
        output  reg  [`RegBus]      hi_o,
        output  reg  [`RegBus]      lo_o,

        // output
        output  reg  [`RegAddrBus]  wd_o,
        output  reg                 wreg_o,
        output  reg  [`RegBus]      wdata_o
    );


    reg [`RegBus] logicout;     // 保存逻辑运算的结果
    reg [`RegBus] shiftres;     // 保存移位运算结果
    reg [`RegBus] moveres;      // 保存移动操作的结果
    reg [`RegBus] HI;           // 保存 HI 寄存器的最新结果
    reg [`RegBus] LO;           // 保存 LO 寄存器的最新结果


    // *** 得到最新的 HI, LO 寄存器的值，并且处理数据冒险问题
    always @(*) begin
        if (rst == `RstEnable) begin
            HI = `ZeroWord;
            LO = `ZeroWord;
        end
        else if (mem_whilo_i == `WriteEnable) begin // data forward: HI,LO register from MEM stage
            HI = mem_hi_i;
            LO = mem_lo_i;
        end
        else if (wb_whilo_i == `WriteEnable) begin  // data forward: HI,LO register from WB stage
            HI = wb_hi_i;
            LO = wb_lo_i;
        end
        else begin
            HI = hi_i;
            LO = lo_i;
        end
    end


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
                `EXE_SRA_OP: begin                      // 算数右移
                    shiftres = ({32{reg2_i[31]}} << 6'd32 - {1'b0, reg1_i[4:0]})
                                | reg2_i >> reg1_i[4:0];
                end
                default: begin
                    // nothing
                end
            endcase
        end
    end

    // *** calculate move answer
    always @(*) begin
        if (rst == `RstEnable) begin
            moveres = `ZeroWord;
        end
        else begin
            case(aluop_i)
                `EXE_MOVZ_OP: begin
                    moveres = reg1_i;
                end
                `EXE_MOVN_OP: begin
                    moveres = reg1_i;
                end
                `EXE_MFHI_OP: begin
                    moveres = HI;
                end
                `EXE_MFLO_OP: begin
                    moveres = LO;
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
            `EXE_RES_MOVE: begin
                wdata_o = moveres;
            end
            default:        begin
                wdata_o = `ZeroWord;
            end
        endcase
    end

    // *** for mthi,mtlo inst: output the whilo_o, hi_o, lo_i values.
    always @(*) begin
        if (rst == `RstEnable) begin
            whilo_o = `WriteDisable;
            hi_o    = `ZeroWord;
            lo_o    = `ZeroWord;
        end
        else if (aluop_i == `EXE_MTHI_OP) begin
            whilo_o = `WriteEnable;
            hi_o    = reg1_i;
            lo_o    = LO;       // shouldn't be zeroword, keep it value.
        end
        else if (aluop_i == `EXE_MTLO_OP) begin
            whilo_o = `WriteEnable;
            hi_o    = HI;
            lo_o    = reg1_i;
        end
        else begin
            whilo_o = `WriteDisable;
            hi_o    = `ZeroWord;
            lo_o    = `ZeroWord;
        end
    end

endmodule
