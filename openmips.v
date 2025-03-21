`include "defines.vh"


module openmips(
    input   wire            clk,
    input   wire            rst,
    input   wire [`RegBus]  rom_data_i,
    output  wire [`RegBus]  rom_addr_o,
    output  wire            rom_ce_o
);

    wire [`InstAddrBus] pc;

    // 链接 IF/ID 模块和译码阶段 ID 模块
    wire [`InstAddrBus] id_pc_i;
    wire [`InstBus]     id_inst_i;
 
    // 链接译码阶段 ID 模块与 ID/EX 模块的输入的变量
    wire [`AluOpBus]    id_aluop_o;
    wire [`AluSelBus]   id_alusel_o;
    wire [`RegBus]      id_reg1_o;
    wire [`RegBus]      id_reg2_o;
    wire                id_wreg_o;
    wire [`RegAddrBus]  id_wd_o;

    // 链接 ID/EX 模块与执行阶段 EX 模块的输入的变量
    wire [`AluOpBus]    ex_aluop_i;
    wire [`AluSelBus]   ex_alusel_i;
    wire [`RegBus]      ex_reg1_i;
    wire [`RegBus]      ex_reg2_i;
    wire                ex_wreg_i;
    wire [`RegAddrBus]  ex_wd_i;

    // 链接执行阶段 EX 模块与 EX/MEM 模块的输入的变量
    wire                ex_wreg_o;
    wire [`RegAddrBus]  ex_wd_o;
    wire [`RegBus]      ex_wdata_o;
    wire                ex_whilo_o;
    wire [`RegBus]      ex_hi_o;
    wire [`RegBus]      ex_lo_o;

    // 链接 EX/MEM 模块的输出与 MEM 模块的输入的变量
    wire                mem_wreg_i;
    wire [`RegAddrBus]  mem_wd_i;
    wire [`RegBus]      mem_wdata_i;
    wire                mem_whilo_i;
    wire [`RegBus]      mem_hi_i;
    wire [`RegBus]      mem_lo_i;

    // 链接访存阶段 MEM 模块的输出与 MEM/WB 模块的输入的变量
    wire                mem_wreg_o;
    wire [`RegAddrBus]  mem_wd_o;
    wire [`RegBus]      mem_wdata_o;
    wire                mem_whilo_o;
    wire [`RegBus]      mem_hi_o;
    wire [`RegBus]      mem_lo_o;


    // 链接 MEM/WB 模块的输出与写回阶段的输入的变量
    wire                wb_wreg_i;
    wire [`RegAddrBus]  wb_wd_i;
    wire [`RegBus]      wb_wdata_i;
    wire                wb_whilo_i;
    wire [`RegBus]      wb_hi_i;
    wire [`RegBus]      wb_lo_i;   


    // 链接译码阶段 ID 模块与通用寄存器 regfile 模块的变量
    wire                reg1_read;
    wire                reg2_read;
    wire [`RegAddrBus]  reg1_addr;
    wire [`RegAddrBus]  reg2_addr;
    wire [`RegBus]      reg1_data;
    wire [`RegBus]      reg2_data;

    // 链接写回阶段 HI,LO 寄存器的输出与执行阶段 ex 模块的输入
    wire [`RegBus]      hi;
    wire [`RegBus]      lo;


    // pc_reg 模块
    pc_reg u_pc_reg(
        .rst    (rst),
        .clk    (clk),
        .pc     (pc),
        .ce     (rom_ce_o)
    );

    assign rom_addr_o = pc;     // 指令寄存器的输入


    // IF/ID
    if_id u_if_id(
        .rst     (rst),
        .clk     (clk),
        .if_pc   (pc),
        .if_inst (rom_data_i),
        .id_pc   (id_pc_i),
        .id_inst (id_inst_i)
    );

    // ID
    id u_id(
        .rst            (rst),
        .pc_i           (id_pc_i),   
        .inst_i         (id_inst_i), 
        .reg1_data_i    (reg1_data),
        .reg2_data_i    (reg2_data),
        .reg1_read_o    (reg1_read),
        .reg2_read_o    (reg2_read),
        .reg1_addr_o    (reg1_addr),
        .reg2_addr_o    (reg2_addr),
        .aluop_o        (id_aluop_o),
        .alusel_o       (id_alusel_o),   
        .reg1_o         (id_reg1_o), 
        .reg2_o         (id_reg2_o), 
        .wd_o           (id_wd_o),   
        .wreg_o         (id_wreg_o),

        // data forward: from EXE stage
        .ex_wreg_i      (ex_wreg_o),
        .ex_wdata_i     (ex_wdata_o),
        .ex_wd_i        (ex_wd_o),
        // data forward: from MEM stage
        .mem_wreg_i     (mem_wreg_o),
        .mem_wdata_i    (mem_wdata_o),
        .mem_wd_i       (mem_wd_o)
    );


    // regfile
    regfile u_regfile(
        .clk   (clk),
        .rst   (rst),
        .waddr (wb_wd_i),
        .wdata (wb_wdata_i),
        .we    (wb_wreg_i),
        .re1   (reg1_read),
        .raddr1(reg1_addr),
        .rdata1(reg1_data),
        .re2   (reg2_read),
        .raddr2(reg2_addr),
        .rdata2(reg2_data)
    );
    
    // ID/EX

    id_ex u_id_ex(
        .rst            (rst),
        .clk            (clk),
        .id_alusel      (id_alusel_o),
        .id_aluop       (id_aluop_o),
        .id_reg1        (id_reg1_o),
        .id_reg2        (id_reg2_o),
        .id_wd          (id_wd_o),
        .id_wreg        (id_wreg_o),
        .ex_alusel      (ex_alusel_i),
        .ex_aluop       (ex_aluop_i ),
        .ex_reg1        (ex_reg1_i  ),
        .ex_reg2        (ex_reg2_i  ),
        .ex_wd          (ex_wd_i    ),
        .ex_wreg        (ex_wreg_i  )
    );


    // ex
    ex u_ex(
        .rst           (rst),
        .alusel_i      (ex_alusel_i),
        .aluop_i       (ex_aluop_i),
        .reg1_i        (ex_reg1_i ),
        .reg2_i        (ex_reg2_i ),
        .wd_i          (ex_wd_i   ),
        .wreg_i        (ex_wreg_i ),
        // hi,lo reg input
        .hi_i          (hi),
        .lo_i          (lo),
        .wb_whilo_i    (wb_whilo_i),
        .wb_hi_i       (wb_hi_i),
        .wb_lo_i       (wb_lo_i),
        .mem_whilo_i   (mem_whilo_o),
        .mem_hi_i      (mem_hi_o),
        .mem_lo_i      (mem_lo_o),
        
        .whilo_o       (ex_whilo_o),
        .hi_o          (ex_hi_o),
        .lo_o          (ex_lo_o),

        .wd_o          (ex_wd_o   ),
        .wreg_o        (ex_wreg_o ),
        .wdata_o       (ex_wdata_o)
    );
    

    // ex/mem
    ex_mem u_ex_mem(
        .rst            (rst      ),
        .clk            (clk      ),
        .ex_wd          (ex_wd_o    ),
        .ex_wreg        (ex_wreg_o  ),
        .ex_wdata       (ex_wdata_o ),
        .ex_whilo       (ex_whilo_o),
        .ex_hi          (ex_hi_o),
        .ex_lo          (ex_lo_o),
        .mem_wd         (mem_wd_i   ),
        .mem_wreg       (mem_wreg_i ),
        .mem_wdata      (mem_wdata_i),
        .mem_whilo      (mem_whilo_i),
        .mem_hi         (mem_hi_i),
        .mem_lo         (mem_lo_i)
    );

    // mem
    mem u_mem(
        .rst         (rst      ),
        .wd_i        (mem_wd_i    ),
        .wreg_i      (mem_wreg_i  ),
        .wdata_i     (mem_wdata_i ),
        .whilo_i     (mem_whilo_i),
        .hi_i        (mem_hi_i),
        .lo_i        (mem_lo_i),
        .wd_o        (mem_wd_o   ),
        .wreg_o      (mem_wreg_o ),
        .wdata_o     (mem_wdata_o),
        .whilo_o     (mem_whilo_o),
        .hi_o        (mem_hi_o),
        .lo_o        (mem_lo_o)
    );

    // mem/wb
    mem_wb u_mem_wb(
        .rst            (rst),
        .clk            (clk),
        .mem_wd         (mem_wd_o),
        .mem_wreg       (mem_wreg_o ),
        .mem_wdata      (mem_wdata_o),
        .mem_whilo      (mem_whilo_o),
        .mem_hi         (mem_hi_o),
        .mem_lo         (mem_lo_o),
        .wb_wd          (wb_wd_i    ),
        .wb_wreg        (wb_wreg_i  ),
        .wb_wdata       (wb_wdata_i ),
        .wb_whilo       (wb_whilo_i),
        .wb_hi          (wb_hi_i),
        .wb_lo          (wb_lo_i)
    );

    // hilo reg
    hilo_reg u_hilo_reg(
        .rst        (rst),
        .clk        (clk),
        .we         (wb_whilo_i),
        .hi_i       (wb_hi_i),
        .lo_i       (wb_lo_i),
        .hi_o       (hi),
        .lo_o       (lo)
    );

endmodule
