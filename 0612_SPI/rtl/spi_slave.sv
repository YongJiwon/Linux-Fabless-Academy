// 8-bit SPI slave with programmable clock polarity/phase.
// Data is shifted MSB first while chip-select is active low.
module spi_slave #(
    parameter bit CPOL = 1'b0,
    parameter bit CPHA = 1'b0
) (
    input  logic       rst_n,

    input  logic       sclk,
    input  logic       mosi,
    output logic       miso,
    input  logic       cs_n,

    input  logic [7:0] tx_data,
    output logic [7:0] rx_data,
    output logic       rx_valid
);

    logic [7:0] rx_shift;
    logic [7:0] tx_shift;
    logic [2:0] bit_index;
    logic sclk_d;
    logic cs_n_d;

    wire sclk_rise = (sclk == 1'b1) && (sclk_d == 1'b0);
    wire sclk_fall = (sclk == 1'b0) && (sclk_d == 1'b1);
    wire cs_assert = (cs_n == 1'b0) && (cs_n_d == 1'b1);
    wire cs_deassert = (cs_n == 1'b1) && (cs_n_d == 1'b0);
    wire sample_on_rise = (CPOL == CPHA);
    wire sample_edge = sample_on_rise ? sclk_rise : sclk_fall;
    wire shift_edge = sample_on_rise ? sclk_fall : sclk_rise;

    always @(sclk or cs_n or rst_n) begin
        if (!rst_n) begin
            rx_shift  <= 8'h00;
            tx_shift  <= 8'h00;
            bit_index <= 3'd7;
            rx_data   <= 8'h00;
            rx_valid  <= 1'b0;
            miso      <= 1'b0;
            sclk_d    <= CPOL;
            cs_n_d    <= 1'b1;
        end else begin
            rx_valid <= 1'b0;

            if (cs_assert) begin
                rx_shift  <= 8'h00;
                tx_shift  <= tx_data;
                bit_index <= 3'd7;
                miso      <= (CPHA == 1'b0) ? tx_data[7] : 1'b0;
            end else if (cs_deassert) begin
                miso <= 1'b0;
            end else if (!cs_n) begin
                if (sample_edge) begin
                    rx_shift[bit_index] <= mosi;

                    if (bit_index == 3'd0) begin
                        rx_data  <= {rx_shift[7:1], mosi};
                        rx_valid <= 1'b1;
                    end

                    if ((CPHA == 1'b1) && (bit_index != 3'd0)) begin
                        bit_index <= bit_index - 3'd1;
                    end
                end

                if (shift_edge) begin
                    if (CPHA == 1'b1) begin
                        miso <= tx_shift[bit_index];
                    end else if (bit_index != 3'd0) begin
                        bit_index <= bit_index - 3'd1;
                        miso <= tx_shift[bit_index - 3'd1];
                    end
                end
            end

            sclk_d <= sclk;
            cs_n_d <= cs_n;
        end
    end
endmodule
