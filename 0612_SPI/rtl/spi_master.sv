// 8-bit SPI master with programmable clock polarity/phase.
// CPOL=0/CPHA=0 is the default SPI mode 0.
module spi_master #(
    parameter int unsigned CLK_DIV = 4,
    parameter bit CPOL = 1'b0,
    parameter bit CPHA = 1'b0
) (
    input  logic       clk,
    input  logic       rst_n,

    input  logic       start,
    input  logic [7:0] tx_data,
    output logic [7:0] rx_data,
    output logic       busy,
    output logic       done,

    output logic       sclk,
    output logic       mosi,
    input  logic       miso,
    output logic       cs_n
);

    localparam int unsigned DIV_WIDTH = (CLK_DIV <= 1) ? 1 : $clog2(CLK_DIV);

    logic [7:0] rx_shift;
    logic [7:0] tx_shift;
    logic [2:0] bit_index;
    logic [3:0] sample_count;
    logic [DIV_WIDTH-1:0] div_count;
    logic toggled_sclk;
    logic leading_edge;
    logic sample_edge;
    logic shift_edge;

    assign toggled_sclk = ~sclk;
    assign leading_edge = (toggled_sclk == ~CPOL);
    assign sample_edge  = (CPHA == 1'b0) ? leading_edge : ~leading_edge;
    assign shift_edge   = ~sample_edge;

    initial begin
        if (CLK_DIV < 1) begin
            $error("CLK_DIV must be greater than zero");
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_data      <= 8'h00;
            rx_shift     <= 8'h00;
            tx_shift     <= 8'h00;
            bit_index    <= 3'd7;
            sample_count <= 4'd0;
            div_count    <= '0;
            sclk         <= CPOL;
            mosi         <= 1'b0;
            cs_n         <= 1'b1;
            busy         <= 1'b0;
            done         <= 1'b0;
        end else begin
            done <= 1'b0;

            if (!busy) begin
                sclk      <= CPOL;
                div_count <= '0;

                if (start) begin
                    busy         <= 1'b1;
                    cs_n         <= 1'b0;
                    tx_shift     <= tx_data;
                    rx_shift     <= 8'h00;
                    bit_index    <= 3'd7;
                    sample_count <= 4'd0;
                    mosi         <= (CPHA == 1'b0) ? tx_data[7] : 1'b0;
                end else begin
                    cs_n <= 1'b1;
                    mosi <= 1'b0;
                end
            end else if (div_count == CLK_DIV - 1) begin
                div_count <= '0;
                sclk      <= toggled_sclk;

                if (sample_edge) begin
                    rx_shift[bit_index] <= miso;
                    sample_count <= sample_count + 4'd1;
                end

                if (shift_edge) begin
                    if (sample_count == 4'd8) begin
                        busy    <= 1'b0;
                        done    <= 1'b1;
                        cs_n    <= 1'b1;
                        sclk    <= CPOL;
                        rx_data <= rx_shift;
                        mosi    <= 1'b0;
                    end else if (CPHA == 1'b1) begin
                        mosi <= tx_shift[bit_index];
                    end else begin
                        bit_index <= bit_index - 3'd1;
                        mosi      <= tx_shift[bit_index - 3'd1];
                    end
                end else if (sample_edge && CPHA == 1'b1) begin
                    if (bit_index != 3'd0) begin
                        bit_index <= bit_index - 3'd1;
                    end
                end
            end else begin
                div_count <= div_count + 1'b1;
            end
        end
    end
endmodule
