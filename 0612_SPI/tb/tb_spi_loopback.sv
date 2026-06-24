`timescale 1ns/1ps

module tb_spi_loopback;
    logic clk = 1'b0;
    logic rst_n = 1'b0;
    logic start = 1'b0;
    logic [7:0] master_tx = 8'h00;
    logic [7:0] master_rx;
    logic master_busy;
    logic master_done;
    logic sclk;
    logic mosi;
    logic miso;
    logic cs_n;
    logic [7:0] slave_tx = 8'h3C;
    logic [7:0] slave_rx;
    logic slave_rx_valid;
    logic slave_seen_valid;

    always #5 clk = ~clk;

    always @(posedge slave_rx_valid or negedge rst_n) begin
        if (!rst_n) begin
            slave_seen_valid <= 1'b0;
        end else begin
            slave_seen_valid <= 1'b1;
        end
    end

    spi_master #(
        .CLK_DIV(2),
        .CPOL(1'b0),
        .CPHA(1'b0)
    ) dut_master (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .tx_data(master_tx),
        .rx_data(master_rx),
        .busy(master_busy),
        .done(master_done),
        .sclk(sclk),
        .mosi(mosi),
        .miso(miso),
        .cs_n(cs_n)
    );

    spi_slave #(
        .CPOL(1'b0),
        .CPHA(1'b0)
    ) dut_slave (
        .rst_n(rst_n),
        .sclk(sclk),
        .mosi(mosi),
        .miso(miso),
        .cs_n(cs_n),
        .tx_data(slave_tx),
        .rx_data(slave_rx),
        .rx_valid(slave_rx_valid)
    );

    initial begin
        repeat (4) @(posedge clk);
        rst_n = 1'b1;
        repeat (2) @(posedge clk);

        master_tx = 8'hA5;
        start = 1'b1;
        @(posedge clk);
        start = 1'b0;

        wait (master_done);
        @(posedge clk);

        assert (master_rx == slave_tx)
            else $fatal(1, "master_rx=%02h expected=%02h", master_rx, slave_tx);
        assert (slave_seen_valid)
            else $fatal(1, "slave rx_valid was not asserted");
        assert (slave_rx == master_tx)
            else $fatal(1, "slave_rx=%02h expected=%02h", slave_rx, master_tx);

        $display("SPI loopback test passed: master_rx=%02h slave_rx=%02h", master_rx, slave_rx);
        $finish;
    end
endmodule
