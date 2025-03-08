`include "defines.vh"

// TODO: 解决 Load-Use 数据前递（前递前需要阻塞一个周期）
module id(
    input   wire                    rst,
    input   wire    [`InstAddrBus]  pc_i,
    input   wire    [`InstBus]      inst_i,

    // values input from regfile
    input   wire    [`RegBus]       reg1_data_i,
    input   wire    [`RegBus]       reg2_data_i,

    // values output to regfile
    output  reg                     reg1_read_o,
    output  reg                     reg2_read_o,
    output  reg     [`RegAddrBus]   reg1_addr_o,
    output  reg     [`RegAddrBus]   reg2_addr_o,

    // values output to EXE stage
    output  reg     [`AluOpBus]     aluop_o,
    output  reg     [`AluSelBus]    alusel_o,
    output  reg     [`RegBus]       reg1_o,
    output  reg     [`RegBus]       reg2_o,
    output  reg     [`RegAddrBus]   wd_o,
    output  reg                     wreg_o,

    // data forward: RAW situation between ID and EX stage
    input  wire                     ex_wreg_i,
    input  wire     [`RegBus]       ex_wdata_i,
    input  wire     [`RegAddrBus]   ex_wd_i,

    // data forward: RAW situation between ID and MEM stage
    input  wire                     mem_wreg_i,
    input  wire     [`RegBus]       mem_wdata_i,
    input  wire     [`RegAddrBus]   mem_wd_i
);

    // 取得指令的指令码和功能码
    wire [5:0] op    = inst_i [31:26];  // 指令码 op
    wire [4:0] op2   = inst_i [10: 5];
    wire [5:0] op3   = inst_i [ 5: 0];  // 功能码 func
    wire [4:0] op4   = inst_i [20:16];  // rt 寄存器（一般）

    // 保存指令执行所需的立即数
    reg [`RegBus]   imm;

    // 指示指令是否有效
    reg instvalid;

    // ***** 1st stage: decode the instruction *****

    always @(*) begin
        if (rst == `RstEnable) begin
            aluop_o     <= `EXE_NOP_OP;
            alusel_o    <= `EXE_RES_NOP;
            wd_o        <= `NOPRegAddr;
            wreg_o      <= `WriteDisable;
            instvalid   <= `InstValid;
            reg1_read_o <= 1'b0;
            reg2_read_o <= 1'b0;
            reg1_addr_o <= `NOPRegAddr;
            reg2_addr_o <= `NOPRegAddr;
            imm         <= `ZeroWord;
        end else begin
            aluop_o     <= `EXE_NOP_OP;
            alusel_o    <= `EXE_RES_NOP;
            wd_o        <= inst_i[15:11];
            wreg_o      <= `WriteDisable;
            instvalid   <= `InstInvalid;
            reg1_read_o <= 1'b0;
            reg2_read_o <= 1'b0;
            reg1_addr_o <= inst_i[25:21];
            reg2_addr_o <= inst_i[20:16];
            imm         <= `ZeroWord;

            case(op)
                `EXE_SPECIAL_INST: begin
                    case(op2)
                        5'b00000:   begin
                            case(op3)
                                `EXE_OR:    begin                           // or
                                    wreg_o      <= `WriteEnable;
                                    aluop_o     <= `EXE_OR_OP;
                                    alusel_o    <= `EXE_RES_LOGIC;
                                    reg1_read_o <= 1'b1;
                                    reg2_read_o <= 1'b1;
                                    instvalid   <= `InstValid;
                                end
                                `EXE_AND:    begin                          // and
                                    wreg_o      <= `WriteEnable;
                                    aluop_o     <= `EXE_AND_OP;
                                    alusel_o    <= `EXE_RES_LOGIC;
                                    reg1_read_o <= 1'b1;
                                    reg2_read_o <= 1'b1;
                                    instvalid   <= `InstValid;
                                end
                                `EXE_XOR:    begin                          // xor
                                    wreg_o      <= `WriteEnable;
                                    aluop_o     <= `EXE_XOR_OP;
                                    alusel_o    <= `EXE_RES_LOGIC;
                                    reg1_read_o <= 1'b1;
                                    reg2_read_o <= 1'b1;
                                    instvalid   <= `InstValid;
                                end
                                `EXE_NOR:    begin                          // nor
                                    wreg_o      <= `WriteEnable;
                                    aluop_o     <= `EXE_NOR_OP;
                                    alusel_o    <= `EXE_RES_LOGIC;
                                    reg1_read_o <= 1'b1;
                                    reg2_read_o <= 1'b1;
                                    instvalid   <= `InstValid;
                                end
                                `EXE_SLLV:    begin                         // sllv
                                    wreg_o      <= `WriteEnable;
                                    aluop_o     <= `EXE_SLL_OP;
                                    alusel_o    <= `EXE_RES_SHIFT;
                                    reg1_read_o <= 1'b1;
                                    reg2_read_o <= 1'b1;
                                    instvalid   <= `InstValid;
                                end
                                `EXE_SRLV:    begin                         // srlv
                                    wreg_o      <= `WriteEnable;
                                    aluop_o     <= `EXE_SRL_OP;
                                    alusel_o    <= `EXE_RES_SHIFT;
                                    reg1_read_o <= 1'b1;
                                    reg2_read_o <= 1'b1;
                                    instvalid   <= `InstValid;
                                end
                                `EXE_SRAV:    begin                         // srav
                                    wreg_o      <= `WriteEnable;
                                    aluop_o     <= `EXE_SRA_OP;
                                    alusel_o    <= `EXE_RES_SHIFT;
                                    reg1_read_o <= 1'b1;
                                    reg2_read_o <= 1'b1;
                                    instvalid   <= `InstValid;
                                end
                                `EXE_SYNC:    begin                         // sync
                                    wreg_o      <= `WriteDisable;
                                    aluop_o     <= `EXE_NOP_OP;
                                    alusel_o    <= `EXE_RES_NOP;
                                    reg1_read_o <= 1'b1;
                                    reg2_read_o <= 1'b1;
                                    instvalid   <= `InstValid;
                                end
                                `EXE_MFHI: begin                            // mfhi
                                    wreg_o      <= `WriteEnable;
                                    alusel_o    <= `EXE_RES_MOVE;
                                    aluop_o     <= `EXE_MFHI_OP;
                                    reg1_read_o <= 1'b0;
                                    reg2_read_o <= 1'b0;
                                    instvalid   <= `InstInvalid;
                                end         
                                `EXE_MFLO: begin                            // mflo
                                    wreg_o      <= `WriteEnable;
                                    aluop_o     <= `EXE_MFLO_OP;
                                    alusel_o    <= `EXE_RES_MOVE;
                                    reg1_read_o <= 1'b0;
                                    reg2_read_o <= 1'b0;
                                    instvalid   <= `InstInvalid;
                                end
                                `EXE_MTHI: begin                            // mthi
                                    wreg_o      <= `WriteDisable;
                                    aluop_o     <= `EXE_MTHI_OP;
                                    reg1_read_o <= 1'b1;
                                    reg2_read_o <= 1'b0;
                                    instvalid   <= `InstInvalid;
                                end
                                `EXE_MTLO: begin                            // mtlo
                                    wreg_o      <= `WriteDisable;
                                    aluop_o     <= `EXE_MTLO_OP;
                                    reg1_read_o <= 1'b1;
                                    reg2_read_o <= 1'b0;
                                    instvalid   <= `InstInvalid;
                                end
                                `EXE_MOVN: begin                            // movn
                                    aluop_o     <= `EXE_MOVN_OP;
                                    alusel_o    <= `EXE_RES_MOVE;
                                    reg1_read_o <= 1'b1;
                                    reg2_read_o <= 1'b1;
                                    instvalid   <= `InstValid;
                                    if (reg2_data_i != 1'b0) begin
                                        wreg_o  <= `WriteEnable;
                                    end
                                    else begin
                                        wreg_o  <= `WriteDisable;
                                    end
                                end
                                `EXE_MOVZ: begin                            // movz
                                    aluop_o     <= `EXE_MOVZ_OP;
                                    alusel_o    <= `EXE_RES_MOVE;
                                    reg1_read_o <= 1'b1;
                                    reg2_read_o <= 1'b1;
                                    instvalid   <= `InstValid;
                                    if (reg2_data_i == 1'b0) begin
                                        wreg_o  <= `WriteEnable;
                                    end
                                    else begin
                                        wreg_o  <= `WriteDisable;
                                    end
                                end
                                default:    begin
                                    // nothing
                                end
                            endcase
                        end
                        default:    begin
                            // nothing
                        end
                    endcase
                end

                `EXE_ORI:   begin                                           // ori
                    wreg_o      <= `WriteEnable;
                    aluop_o     <= `EXE_OR_OP;
                    alusel_o    <= `EXE_RES_LOGIC;
                    reg1_read_o <= 1'b1;
                    reg2_read_o <= 1'b0;
                    imm         <= {16'h0, inst_i[15:0]};
                    wd_o        <= inst_i[20:16];
                    instvalid   <= `InstValid;
                end
                `EXE_ANDI:  begin                                           // andi
                    wreg_o      <= `WriteEnable;
                    aluop_o     <= `EXE_AND_OP;
                    alusel_o    <= `EXE_RES_LOGIC;
                    reg1_read_o <= 1'b1;
                    reg2_read_o <= 1'b0;
                    imm         <= {16'h0, inst_i[15:0]};
                    wd_o        <= inst_i[20:16];
                    instvalid   <= `InstValid;
                end
                `EXE_XORI:  begin                                           // xori
                    wreg_o      <= `WriteEnable;
                    aluop_o     <= `EXE_XOR_OP;
                    alusel_o    <= `EXE_RES_LOGIC;
                    reg1_read_o <= 1'b1;
                    reg2_read_o <= 1'b0;
                    imm         <= {16'h0, inst_i[15:0]};
                    wd_o        <= inst_i[20:16];
                    instvalid   <= `InstValid;
                end
                `EXE_LUI:  begin                                            // lui
                    wreg_o      <= `WriteEnable;
                    aluop_o     <= `EXE_OR_OP;
                    alusel_o    <= `EXE_RES_LOGIC;
                    reg1_read_o <= 1'b1;
                    reg2_read_o <= 1'b0;
                    imm         <= {inst_i[15:0], 16'h0};
                    wd_o        <= inst_i[20:16];
                    instvalid   <= `InstValid;
                end
                `EXE_PREF:  begin                                           // pref
                    wreg_o      <= `WriteDisable;
                    aluop_o     <= `EXE_NOP_OP;
                    alusel_o    <= `EXE_RES_NOP;
                    reg1_read_o <= 1'b0;
                    reg2_read_o <= 1'b0;
                    instvalid   <= `InstValid;
                end
                default:    begin
                    // do nothing
                end
            endcase


            // 特殊情况
            if (inst_i[31:21] == 11'b000_0000_0000) begin
                if (op3 == `EXE_SLL) begin                                  // sll
                    wreg_o      <= `WriteEnable;
                    aluop_o     <= `EXE_SLL_OP;
                    alusel_o    <= `EXE_RES_SHIFT;
                    reg1_read_o <= 1'b0;
                    reg2_read_o <= 1'b1;
                    imm[4:0]    <= inst_i[10:6];
                    wd_o        <= inst_i[15:11];
                    instvalid   <= `InstValid;
                end
                else if (op3 == `EXE_SRL) begin                             // srl
                    wreg_o      <= `WriteEnable;
                    aluop_o     <= `EXE_SRL_OP;
                    alusel_o    <= `EXE_RES_SHIFT;
                    reg1_read_o <= 1'b0;
                    reg2_read_o <= 1'b1;        // ?
                    imm[4:0]    <= inst_i[10:6];
                    wd_o        <= inst_i[15:11];
                    instvalid   <= `InstValid;
                end
                else if (op3 == `EXE_SRA) begin                             // sra
                    wreg_o      <= `WriteEnable;
                    aluop_o     <= `EXE_SRA_OP;
                    alusel_o    <= `EXE_RES_SHIFT;
                    reg1_read_o <= 1'b0;
                    reg2_read_o <= 1'b1;
                    imm[4:0]    <= inst_i[10:6];
                    wd_o        <= inst_i[15:11];
                    instvalid   <= `InstValid;
                end
                else begin
                    // nothing
                end
            end
        end
    end


    // ***** 2nd stage: get source operands 1 *****

    always @(*) begin
        if (rst == `RstEnable) begin
            reg1_o <= `ZeroWord;
        end
        // data forward: 提前将 EX 阶段的运算结果前递到 ID 阶段作为寄存器 1 读取结果
        else if ((ex_wreg_i == 1'b1) && (reg1_read_o == 1'b1) && (ex_wd_i == reg1_addr_o)) begin
            reg1_o <= ex_wdata_i;
        end
        // data forward: 提前将 MEM 阶段的运算结果前递到 ID 阶段作为寄存器 1 读取结果
        else if ((mem_wreg_i == 1'b1) && (reg1_read_o == 1'b1) && (mem_wd_i == reg1_addr_o)) begin
            reg1_o <= mem_wdata_i;
        end
        else if (reg1_read_o == 1'b1) begin
            reg1_o <= reg1_data_i;
        end else if (reg1_read_o == 1'b0) begin
            reg1_o <= imm;
        end else begin
            reg1_o <= `ZeroWord;
        end
    end


    // ***** 3rd stage: get source operand 2 *****

    always @(*) begin
        if (rst == `RstEnable) begin
            reg2_o <= `ZeroWord;
        end 
        // data forward: 提前将 EX 阶段的运算结果前递到 ID 阶段作为寄存器 2 读取结果
        else if ((ex_wreg_i == 1'b1) && (reg2_read_o == 1'b1) && (ex_wd_i == reg2_addr_o)) begin
            reg2_o <= ex_wdata_i;
        end
        // data forward: 提前将 MEM 阶段的运算结果前递到 ID 阶段作为寄存器 2 读取结果
        else if ((mem_wreg_i == 1'b1) && (reg2_read_o == 1'b1) && (mem_wd_i == reg2_addr_o)) begin
            reg2_o <= mem_wdata_i;
        end
        else if (reg2_read_o == 1'b1) begin
            reg2_o <= reg2_data_i;
        end else if (reg2_read_o == 1'b0) begin
            reg2_o <= imm;
        end else begin
            reg2_o <= `ZeroWord;
        end
    end


endmodule