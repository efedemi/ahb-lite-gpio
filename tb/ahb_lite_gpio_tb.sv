// =============================================================================
// ahb_lite_gpio_tb.sv  —  self-checking AHB-Lite master driving the slave
//   iverilog -g2012 -o sim.out rtl/ahb_lite_gpio.sv tb/ahb_lite_gpio_tb.sv
//   vvp sim.out
// =============================================================================
`timescale 1ns/1ps
`default_nettype none

module ahb_lite_gpio_tb;
    localparam int AW = 12;

    logic              HCLK = 1'b0;
    logic              HRESETn;
    logic              HSEL, HWRITE;
    logic [AW-1:0]     HADDR;
    logic [1:0]        HTRANS;
    logic [31:0]       HWDATA;
    logic              HREADY;
    logic [31:0]       HRDATA;
    logic              HREADYOUT, HRESP;
    logic [31:0]       gpio_out, gpio_in, gpio_dir;

    int errors = 0, checks = 0;
    logic [31:0] rd;

    ahb_lite_gpio #(.ADDR_W(AW)) dut (.*);

    always #5 HCLK = ~HCLK;

    // AHB-Lite single write (address phase, then data phase)
    task automatic ahb_write(input [AW-1:0] addr, input [31:0] data);
        @(posedge HCLK); HSEL <= 1; HADDR <= addr; HWRITE <= 1; HTRANS <= 2'b10;
        @(posedge HCLK); HSEL <= 0; HWRITE <= 0; HTRANS <= 2'b00; HWDATA <= data;
        @(posedge HCLK); HWDATA <= 32'h0;
    endtask

    // AHB-Lite single read (data returned in the data phase)
    task automatic ahb_read(input [AW-1:0] addr, output [31:0] data);
        @(posedge HCLK); HSEL <= 1; HADDR <= addr; HWRITE <= 0; HTRANS <= 2'b10;
        @(posedge HCLK); HSEL <= 0; HTRANS <= 2'b00;
        #1 data = HRDATA;
    endtask

    task automatic chk(input [31:0] act, input [31:0] exp, input string label);
        checks++;
        if (act === exp) $display("[ pass] %-20s = 0x%08h", label, act);
        else begin
            errors++;
            $display("[FAIL ] %-20s = 0x%08h (exp 0x%08h)", label, act, exp);
        end
    endtask

    initial begin
        $dumpfile("ahb_lite_gpio.vcd"); $dumpvars(0, ahb_lite_gpio_tb);
        HSEL=0; HWRITE=0; HADDR=0; HTRANS=0; HWDATA=0; HREADY=1; gpio_in=0;
        HRESETn=0; repeat (3) @(posedge HCLK); HRESETn=1; @(posedge HCLK);

        ahb_write(12'h000, 32'hDEAD_BEEF);                 // DATA_OUT
        ahb_read (12'h000, rd); chk(rd,       32'hDEAD_BEEF, "read DATA_OUT");
        chk(gpio_out,            32'hDEAD_BEEF, "gpio_out pins");

        ahb_write(12'h008, 32'h0000_FFFF);                 // DIR
        ahb_read (12'h008, rd); chk(rd,       32'h0000_FFFF, "read DIR");
        chk(gpio_dir,            32'h0000_FFFF, "gpio_dir pins");

        gpio_in = 32'h1234_5678;                           // external inputs
        ahb_read (12'h004, rd); chk(rd,       32'h1234_5678, "read DATA_IN");

        ahb_write(12'h000, 32'h0000_0001);                 // overwrite DATA_OUT
        ahb_read (12'h000, rd); chk(rd,       32'h0000_0001, "DATA_OUT updated");

        $display("\n==== %0d checks, %0d failure(s) ====", checks, errors);
        if (errors == 0) $display(">>> ALL TESTS PASSED <<<");
        else             $display(">>> %0d TEST(S) FAILED <<<", errors);
        $finish;
    end
endmodule

`default_nettype wire
