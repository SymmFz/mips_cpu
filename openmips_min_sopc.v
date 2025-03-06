`include "defines.vh"

module openmips_min_sopc(
    input wire clk,
    input wire rst
);

    // 链接指令存储器
    wire [`InstAddrBus] inst_addr;
    wire [`InstBus]     inst;
    wire                rom_ce;

    openmips u_openmips(
        .clk(clk),
        .rst(rst),
        .rom_addr_o(inst_addr),
        .rom_ce_o(rom_ce),
        .rom_data_i(inst)
    );

    inst_rom u_inst_rom(
        .ce(rom_ce),
        .addr(inst_addr),
        .inst(inst)
    );

endmodule
