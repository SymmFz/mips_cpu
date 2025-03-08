`include "defines.vh"


module inst_rom(
        input   wire                ce,
        input   wire [`InstAddrBus] addr,
        output  reg  [`InstBus]     inst
    );

    // define the instruction rom
    reg [`InstBus]  inst_mem [`InstMemNum-1:0];

    // 使用文件 inst_rom.data 初始化指令存储器
    initial
        $readmemh("inst_rom.data", inst_mem);

    // 复位信号无效时，根据输入的地址，给出指令存储器 ROM 中对应的元素
    always @(*) begin
        if (ce == `ChipDisable) begin
            inst = `ZeroWord;
        end
        else begin
            inst = inst_mem[addr[`InstMemNumLog2 + 1 : 2]];
        end
    end

endmodule
