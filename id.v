`include "defines.vh"

module id(
    input   wire                    rst,
    input   wire    [`RegAddrBus]   pc_i,
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
    output  reg                     wreg_o
);

    // 取得指令的指令码和功能码
    wire [5:0] op    = inst_i [31:26];
    wire [4:0] op2   = inst_i [10: 5];
    wire [5:0] op3   = inst_i [ 5: 0];
    wire [4:0] op4   = inst_i [20:16];

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
                `EXE_ORI:   begin
                    wreg_o      <= `WriteEnable;
                    aluop_o     <= `EXE_OR_OP;
                    alusel_o    <= `EXE_RES_LOGIC;
                    reg1_read_o <= 1'b1;
                    reg2_read_o <= 1'b0;
                    imm         <= {16'h0, inst_i[15:0]};
                    wd_o        <= inst_i[20:16];
                    instvalid   <= `InstValid;
                end
                default:    begin
                    // do nothing
                end
            endcase
        end
    end


    // ***** 2nd stage: get source operands 1 *****

    always @(*) begin
        if (rst == `RstEnable) begin
            reg1_o <= `ZeroWord;
        end else if (reg1_read_o == 1'b1) begin
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
        end else if (reg2_read_o == 1'b1) begin
            reg2_o <= reg2_data_i;
        end else if (reg2_read_o == 1'b0) begin
            reg2_o <= imm;
        end else begin
            reg2_o <= `ZeroWord;
        end
    end


endmodule