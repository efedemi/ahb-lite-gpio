// =============================================================================
// ahb_lite_gpio.sv  —  AHB-Lite slave peripheral: memory-mapped GPIO/registers
// -----------------------------------------------------------------------------
// Author : Efe Demir
// A zero-wait-state AHB-Lite slave exposing three 32-bit registers. This is the
// same bus the APEX SoC used to hang peripherals off its ARM Cortex-M0; here is
// a clean, standalone slave that follows the AHB address/data pipeline.
//
//   Offset  Name       Access  Function
//   0x00    DATA_OUT   R/W     drives the gpio_out pins
//   0x04    DATA_IN    RO      reads the gpio_in pins
//   0x08    DIR        R/W     direction register (1 = output)
// =============================================================================
`default_nettype none

module ahb_lite_gpio #(
    parameter int ADDR_W = 12
)(
    input  wire              HCLK,
    input  wire              HRESETn,
    // ---- AHB-Lite slave port ----
    input  wire              HSEL,
    input  wire [ADDR_W-1:0] HADDR,
    input  wire              HWRITE,
    input  wire [1:0]        HTRANS,
    input  wire [31:0]       HWDATA,
    input  wire              HREADY,      // bus ready (qualifies the address phase)
    output logic [31:0]      HRDATA,
    output logic             HREADYOUT,
    output logic             HRESP,
    // ---- GPIO pins ----
    output logic [31:0]      gpio_out,
    input  wire  [31:0]      gpio_in,
    output logic [31:0]      gpio_dir
);
    localparam logic [7:0] ADDR_DOUT = 8'h00;
    localparam logic [7:0] ADDR_DIN  = 8'h04;
    localparam logic [7:0] ADDR_DIR  = 8'h08;

    // ---- Address-phase capture (registered into the data phase) ----
    logic              valid_q, wr_q;
    logic [ADDR_W-1:0] addr_q;

    wire trans_active = HTRANS[1];               // NONSEQ (10) or SEQ (11)
    wire ahb_access   = HSEL & HREADY & trans_active;

    always_ff @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            valid_q <= 1'b0; wr_q <= 1'b0; addr_q <= '0;
        end else begin
            valid_q <= ahb_access;
            wr_q    <= ahb_access & HWRITE;
            addr_q  <= HADDR;
        end
    end

    // Low byte of the captured address selects the register. Computed as a net
    // (not a procedural part-select) so it is clean across all simulators.
    wire [7:0] off = addr_q[7:0];

    // ---- Data-phase write ----
    always_ff @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            gpio_out <= '0; gpio_dir <= '0;
        end else if (valid_q && wr_q) begin
            case (off)
                ADDR_DOUT: gpio_out <= HWDATA;
                ADDR_DIR : gpio_dir <= HWDATA;
                default  : /* read-only or unmapped */ ;
            endcase
        end
    end

    // ---- Data-phase read (mux on the registered address) ----
    always_comb begin
        case (off)
            ADDR_DOUT: HRDATA = gpio_out;
            ADDR_DIN : HRDATA = gpio_in;
            ADDR_DIR : HRDATA = gpio_dir;
            default  : HRDATA = 32'h0;
        endcase
    end

    assign HREADYOUT = 1'b1;     // zero wait states
    assign HRESP     = 1'b0;     // always OKAY

endmodule

`default_nettype wire
