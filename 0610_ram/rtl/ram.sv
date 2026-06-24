`timescale 1ns/1ps

module ram #(
    parameter   ADDR_WIDTH = 8,
                DATA_WIDTH = 8
)(
    input logic clk,
    input logic [ADDR_WIDTH-1:0] addr,
    input logic [DATA_WIDTH-1:0] wdata,
    input logic we,
    output logic [DATA_WIDTH-1:0] rdata

);
    
localparam DEPTH = 1 << ADDR_WIDTH;

logic [ADDR_WIDTH-1:0] mem [0:DATA_WIDTH-1];

always_ff @(posedge clk) begin
    if (we) begin
        mem[addr] <= wdata;
    end else begin
        rdata <= mem[addr];
    end
end



endmodule