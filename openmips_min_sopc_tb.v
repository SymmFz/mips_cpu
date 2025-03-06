`timescale 1ns/1ps
`include "defines.vh"

module openmips_min_sopc_tb();

    reg clk;
    reg rst;

    initial begin
        $dumpfile("vcd.vcd");
        $dumpvars();
        clk = 1'b0;
        rst = `RstEnable;
        #195 rst = `RstDisable;
        #1000 $stop;
    end

    always #10 clk = ~clk;

    openmips_min_sopc u_openmips_min_sopc (
        .clk 	(clk  ),
        .rst 	(rst  )
    );


endmodule
